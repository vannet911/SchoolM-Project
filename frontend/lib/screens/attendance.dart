// lib/screens/attendance.dart
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/services/api_service.dart';
import 'package:schoolms_portal/utils/app_constants.dart';
import 'package:schoolms_portal/widgets/table_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _teachers = [];

  List<Map<String, dynamic>> _summaries = [];
  List<Map<String, dynamic>> _filtered = [];

  bool _loading = true;
  bool _exporting = false;

  final _searchCtrl = TextEditingController();
  final GlobalKey _searchBoxKey = GlobalKey();
  OverlayEntry? _filterOverlay;

  Map<String, dynamic>? _selectedSummary;
  bool _showForm = false;
  Map<String, dynamic>? _editSummary;

  String? _sortColumn;
  bool _sortAscending = true;
  int _currentPage = 1;
  int _pageSize = 25;

  String _classFilter = 'all';
  String _subjectFilter = 'all';
  String _teacherFilter = 'all';
  final Set<String> _checkedKeys = {};

  int get _activeFilterCount =>
      [_classFilter != 'all', _subjectFilter != 'all', _teacherFilter != 'all'].where((v) => v).length;
  int get _totalPages => (_filtered.length / _pageSize).ceil().clamp(1, 999);
  List<Map<String, dynamic>> get _paginated {
    final start = (_currentPage - 1) * _pageSize;
    return _filtered.skip(start).take(_pageSize).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_filter);
    _searchCtrl.dispose();
    _filterOverlay?.remove();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getAttendance().catchError((_) => <dynamic>[]),
        _api.getStudents().catchError((_) => <dynamic>[]),
        _api.getClasses().catchError((_) => <dynamic>[]),
        _api.getSubjects().catchError((_) => <dynamic>[]),
        _api.getTeachers().catchError((_) => <dynamic>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _records  = List<Map<String, dynamic>>.from(results[0]);
        _students = List<Map<String, dynamic>>.from(results[1]);
        _classes  = List<Map<String, dynamic>>.from(results[2]);
        _subjects = List<Map<String, dynamic>>.from(results[3]);
        _teachers = List<Map<String, dynamic>>.from(results[4]);
        _loading = false;
      });
      _buildSummaries();
      _filter();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final t = AppTranslations.translations[context.read<LocaleProvider>().locale] ??
          AppTranslations.translations['en']!;
      _showSnack(t['failed_load'] ?? 'Failed to load', isError: true);
    }
  }

  Future<void> _reloadRecords() async {
    if (!mounted) return;
    try {
      final data = await _api.getAttendance().catchError((_) => <dynamic>[]);
      if (!mounted) return;
      setState(() => _records = List<Map<String, dynamic>>.from(data));
      _buildSummaries();
      _filter(resetPage: false);
    } catch (_) {}
  }

  void _buildSummaries() {
    final grouped = <String, Map<String, dynamic>>{};
    for (final r in _records) {
      final date = _parseDate(r);
      final cls = _rClassName(r);
      final subj = _rSubjectName(r);
      final key = '$date|$cls|$subj';

      final teacher = _rTeacherName(r);
      grouped.putIfAbsent(key, () => {
        'key': key,
        'date': date,
        'className': cls,
        'subjectName': subj,
        'teacherName': teacher,
        'teacherId': r['teacherId'],
        'present': 0, 'absent': 0, 'late': 0, 'excused': 0,
        'code': '',
        'remark': '',
        'period': null,
        'records': <Map<String, dynamic>>[],
      });

      final g = grouped[key]!;
      (g['records'] as List).add(r);
      switch ((r['status'] as String? ?? '').toLowerCase()) {
        case 'present':  g['present']  = (g['present']  as int) + 1;
        case 'absent':   g['absent']   = (g['absent']   as int) + 1;
        case 'late':     g['late']     = (g['late']     as int) + 1;
        case 'excused':  g['excused']  = (g['excused']  as int) + 1;
      }
      // Collect first non-empty code, note, and teacher from any record in this session
      final code = r['code'] as String? ?? '';
      if (code.isNotEmpty && (g['code'] as String).isEmpty) g['code'] = code;
      final note = r['notes'] as String? ?? '';
      if (note.isNotEmpty && (g['remark'] as String).isEmpty) g['remark'] = note;
      if (teacher.isNotEmpty && (g['teacherName'] as String).isEmpty) {
        g['teacherName'] = teacher;
        g['teacherId'] = r['teacherId'];
      }
      final period = r['period'];
      if (period != null && g['period'] == null) g['period'] = period;
    }

    setState(() {
      _summaries = grouped.values.map((g) {
        final total = (g['records'] as List).length;
        final present = g['present'] as int;
        final late = g['late'] as int;
        final rate = total > 0 ? (present + late) / total * 100.0 : 0.0;
        return {...g, 'total': total, 'rate': rate};
      }).toList();
    });
  }

  void _filter({bool resetPage = true}) {
    final q = _searchCtrl.text.toLowerCase();
    var list = _summaries.where((s) {
      final cls     = (s['className']   as String? ?? '').toLowerCase();
      final subj    = (s['subjectName'] as String? ?? '').toLowerCase();
      final date    = (s['date']        as String? ?? '').toLowerCase();
      final teacher = (s['teacherName'] as String? ?? '').toLowerCase();
      final searchOk   = q.isEmpty || cls.contains(q) || subj.contains(q) || date.contains(q) || teacher.contains(q);
      final classOk    = _classFilter   == 'all' || s['className']   == _classFilter;
      final subjOk     = _subjectFilter == 'all' || s['subjectName'] == _subjectFilter;
      final teacherOk  = _teacherFilter == 'all' || s['teacherName'] == _teacherFilter;
      return searchOk && classOk && subjOk && teacherOk;
    }).toList();

    if (_sortColumn != null) {
      list.sort((a, b) {
        final av = _sortVal(a, _sortColumn!);
        final bv = _sortVal(b, _sortColumn!);
        return _sortAscending ? av.compareTo(bv) : bv.compareTo(av);
      });
    }
    _checkedKeys.clear();
    setState(() {
      _filtered = list;
      if (resetPage) _currentPage = 1;
    });
  }

  String _sortVal(Map<String, dynamic> s, String col) {
    switch (col) {
      case 'date':    return s['date']        as String? ?? '';
      case 'teacher': return (s['teacherName'] as String? ?? '').toLowerCase();
      case 'class':   return (s['className']   as String? ?? '').toLowerCase();
      case 'subject': return (s['subjectName'] as String? ?? '').toLowerCase();
      case 'total':   return (s['total']   as int).toString().padLeft(6, '0');
      case 'present': return (s['present'] as int).toString().padLeft(6, '0');
      case 'absent':  return (s['absent']  as int).toString().padLeft(6, '0');
      case 'late':    return (s['late']    as int).toString().padLeft(6, '0');
      case 'rate':    return (s['rate'] as double).toStringAsFixed(2).padLeft(6, '0');
      default:        return '';
    }
  }

  void _sort(String col) {
    setState(() {
      if (_sortColumn == col) { _sortAscending = !_sortAscending; }
      else { _sortColumn = col; _sortAscending = true; }
    });
    _filter(resetPage: false);
  }

  // ── Field helpers ────────────────────────────────────────────────

  String _parseDate(Map<String, dynamic> r) {
    final d = r['date'] as String?;
    if (d == null || d.length < 10) return '';
    return d.substring(0, 10);
  }
  String _formatDate(String d) => d.replaceAll('-', '/');
  String _rClassName(Map<String, dynamic> r) {
    final direct = r['className'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    final fromStudent = r['student']?['className'] as String?;
    if (fromStudent != null && fromStudent.isNotEmpty) return fromStudent;
    final cid = r['classId'] as int?;
    if (cid != null) {
      final cls = _classes.where((c) => c['id'] == cid).firstOrNull;
      final name = cls?['name']?.toString() ?? '';
      if (name.isNotEmpty) return name;
    }
    return '';
  }

  String _rSubjectName(Map<String, dynamic> r) {
    final direct = r['subjectName'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    final fromSubject = r['subject']?['name'] as String?;
    if (fromSubject != null && fromSubject.isNotEmpty) return fromSubject;
    final sid = r['subjectId'] as int?;
    if (sid != null) {
      final subj = _subjects.where((s) => s['id'] == sid).firstOrNull;
      final name = subj?['name']?.toString() ?? '';
      if (name.isNotEmpty) return name;
    }
    return '';
  }
  String _rTeacherName(Map<String, dynamic> r) {
    final direct = r['teacherName'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    final tid = r['teacherId'] as int?;
    if (tid != null) {
      final t = _teachers.where((t) => t['id'] == tid).firstOrNull;
      final name = t?['name']?.toString() ?? '';
      if (name.isNotEmpty) return name;
    }
    return '';
  }

  String _studentName(Map<String, dynamic> s) {
    if (s['firstName'] != null) return '${s['firstName']} ${s['lastName'] ?? ''}'.trim();
    return s['name']?.toString() ?? '';
  }
  List<Map<String, dynamic>> _studentsInClass(int? classId, String? className) {
    if (classId == null && className == null) return [];
    return _students.where((s) {
      if (classId != null && s['classId'] == classId) return true;
      final cn = s['className'] as String? ?? s['class']?['name'] as String?;
      return className != null && cn == className;
    }).toList();
  }

  // ── Row selection ────────────────────────────────────────────────

  void _onRowTap(Map<String, dynamic> s) {
    final key = s['key'] as String;
    setState(() {
      if (_checkedKeys.contains(key)) {
        _checkedKeys.remove(key);
        if (_selectedSummary?['key'] == key) _selectedSummary = null;
      } else {
        _checkedKeys.add(key);
        _selectedSummary = s;
      }
    });
  }

  // ── Actions ──────────────────────────────────────────────────────

  void _openForm({Map<String, dynamic>? summary}) =>
      setState(() { _editSummary = summary; _showForm = true; });
  void _closeForm() => setState(() { _showForm = false; _editSummary = null; });

  Future<void> _saveSession({
    required String date,
    required int? classId, required String? className,
    required int? subjectId, required String? subjectName,
    required int? teacherId,
    required int? period,
    required List<Map<String, dynamic>> attendances,
    required bool isEdit, required List<Map<String, dynamic>> existingRecords,
  }) async {
    final t = AppTranslations.translations[context.read<LocaleProvider>().locale] ??
        AppTranslations.translations['en']!;
    try {
      if (isEdit) {
        for (final a in attendances) {
          final sid = a['studentId'] as int;
          final existing = existingRecords.where((r) => r['studentId'] == sid).firstOrNull;
          final payload = {
            'date': date, 'studentId': sid,
            if (classId != null) 'classId': classId,
            if (subjectId != null) 'subjectId': subjectId,
            if (teacherId != null) 'teacherId': teacherId,
            if (period != null) 'period': period,
            if ((a['code'] as String? ?? '').isNotEmpty) 'code': a['code'],
            'status': a['status'], 'notes': a['notes'] ?? '',
          };
          if (existing != null) {
            await _api.updateAttendance(existing['id'] as int, payload);
          } else {
            await _api.createAttendance(payload);
          }
        }
        _showSnack(t['attendance_updated'] ?? 'Attendance updated!');
      } else {
        for (final a in attendances) {
          await _api.createAttendance({
            'date': date, 'studentId': a['studentId'],
            if (classId != null) 'classId': classId,
            if (subjectId != null) 'subjectId': subjectId,
            if (teacherId != null) 'teacherId': teacherId,
            if (period != null) 'period': period,
            if ((a['code'] as String? ?? '').isNotEmpty) 'code': a['code'],
            'status': a['status'], 'notes': a['notes'] ?? '',
          });
        }
        _showSnack(t['attendance_created'] ?? 'Attendance recorded!');
      }
      _closeForm();
      await _reloadRecords();
    } catch (e) { _showSnack(e.toString(), isError: true); }
  }


  Future<void> _deleteChecked(Map<String, String> t) async {
    if (_checkedKeys.isEmpty) return;
    final toDelete = _filtered.where((s) => _checkedKeys.contains(s['key'])).toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t['confirm_delete'] ?? 'Confirm Delete'),
        content: Text(
          (t['confirm_delete_multiple'] ?? 'Total delete is {count}. Are you sure want to delete?')
              .replaceAll('{count}', '${toDelete.length}'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t['cancel'] ?? 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(t['delete'] ?? 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      for (final s in toDelete) {
        for (final r in (s['records'] as List).cast<Map<String, dynamic>>()) {
          await _api.deleteAttendance(r['id'] as int);
        }
      }
      _checkedKeys.clear();
      setState(() => _selectedSummary = null);
      _showSnack(t['attendance_deleted'] ?? 'Deleted.');
      await _reloadRecords();
    } catch (e) { _showSnack(e.toString(), isError: true); }
  }

  Future<void> _exportRecords(Map<String, String> t) async {
    if (_exporting || _filtered.isEmpty) return;
    setState(() => _exporting = true);
    try {
      final rows = _checkedKeys.isNotEmpty
          ? _filtered.where((s) => _checkedKeys.contains(s['key'])).toList()
          : _filtered;
      final workbook = Excel.createExcel();
      workbook.rename('Sheet1', 'Attendance');
      final sheet = workbook['Attendance'];
      sheet.appendRow(['#','Date','Teacher Name','Class','Subject','Total','Present','Absent','Late','Rate (%)']
          .map((h) => TextCellValue(h)).toList());
      for (var i = 0; i < rows.length; i++) {
        final s = rows[i];
        final rate = s['rate'] as double;
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(_formatDate(s['date'] as String? ?? '')),
          TextCellValue(s['teacherName'] as String? ?? ''),
          TextCellValue(s['className']   as String? ?? ''),
          TextCellValue(s['subjectName'] as String? ?? ''),
          IntCellValue(s['total']   as int),
          IntCellValue(s['present'] as int),
          IntCellValue(s['absent']  as int),
          IntCellValue(s['late']    as int),
          TextCellValue('${rate.toStringAsFixed(1)}%'),
        ]);
      }
      final bytes = workbook.encode()!;
      final date = DateTime.now().toIso8601String().split('T').first;
      final filename = 'attendance_$date.xlsx';
      final blob = html.Blob([Uint8List.fromList(bytes)],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)..setAttribute('download', filename)..click();
      html.Url.revokeObjectUrl(url);
      _showSnack(filename);
    } catch (_) {
      _showSnack(t['save_failed'] ?? 'Export failed', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Filter overlay ───────────────────────────────────────────────

  void _toggleFilter() {
    if (_filterOverlay != null) { _filterOverlay!.remove(); _filterOverlay = null; return; }
    final keyCtx = _searchBoxKey.currentContext;
    if (keyCtx == null) return;
    final box = keyCtx.findRenderObject() as RenderBox;
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final width = box.size.width;
    final boxHeight = box.size.height;

    final locale = context.read<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ?? AppTranslations.translations['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final classNames = _classes.map((c) => c['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList()..sort();
    final subjectNames = _subjects.map((s) => s['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList()..sort();
    final teacherNames = _summaries.map((s) => s['teacherName'] as String? ?? '').where((n) => n.isNotEmpty).toSet().toList()..sort();

    _filterOverlay = OverlayEntry(
      builder: (_) => Stack(children: [
        Positioned.fill(child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () { _filterOverlay?.remove(); _filterOverlay = null; },
          child: const ColoredBox(color: Colors.transparent),
        )),
        Positioned(
          left: pos.dx,
          top: pos.dy + boxHeight + 6,
          width: width,
          child: GestureDetector(
            onTap: () {},
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: _FilterPanel(
                t: t, isDark: isDark,
                classFilter: _classFilter, subjectFilter: _subjectFilter, teacherFilter: _teacherFilter,
                availableClasses: classNames, availableSubjects: subjectNames, availableTeachers: teacherNames,
                onApply: (cls, subj, teacher) {
                  _filterOverlay?.remove(); _filterOverlay = null;
                  setState(() { _classFilter = cls; _subjectFilter = subj; _teacherFilter = teacher; });
                  _filter();
                },
              ),
            ),
          ),
        ),
      ]),
    );
    Overlay.of(context).insert(_filterOverlay!);
  }

  void _showSnack(String msg, {bool isError = false, bool isWarning = false}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _ToastNotification(
      message: msg, isError: isError, isWarning: isWarning,
      onDismiss: () { if (entry.mounted) entry.remove(); },
    ));
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () { if (entry.mounted) entry.remove(); });
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ?? AppTranslations.translations['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;

    return Stack(children: [
      _buildContent(t, isDark, isMobile, isTablet),
      if (_showForm)
        _TakeAttendanceForm(
          t: t, isDark: isDark,
          editSummary: _editSummary,
          recordCount: _summaries.length,
          classes: _classes, subjects: _subjects, teachers: _teachers,
          studentsInClass: _studentsInClass,
          studentName: _studentName,
          onSave: _saveSession,
          onCancel: _closeForm,
        ),
    ]);
  }

  Widget _buildContent(Map<String, String> t, bool isDark, bool isMobile, bool isTablet) {
    final textColor = isDark ? Colors.white70 : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white70 : AppColors.textMuted;
    final fieldBg = isDark ? const Color(0xFF0D0D1C) : const Color(0xFFF2F3F7);
    final checkboxShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));

    WidgetStateBorderSide checkboxSide(bool active) =>
        WidgetStateBorderSide.resolveWith((_) => BorderSide(
          color: active ? AppColors.primary : textColor, width: 1.5,
        ));

    // ── Action callbacks ──────────────────────────────────────────
    void onAdd() => _openForm();
    void onEdit() {
      if (_selectedSummary != null) {
        _openForm(summary: _selectedSummary);
      } else {
        _showSnack(t['select_row_first'] ?? 'Please select a row first', isWarning: true);
      }
    }
    void onDelete() {
      if (_checkedKeys.isNotEmpty) {
        _deleteChecked(t);
      } else {
        _showSnack(t['select_row_first'] ?? 'Please select a row first', isWarning: true);
      }
    }
    final VoidCallback? onExport = _filtered.isEmpty ? null : () => _exportRecords(t);

    // ── Toolbar ───────────────────────────────────────────────────
    final Widget toolbar;
    if (isMobile) {
      toolbar = Row(children: [
        Expanded(child: KeyedSubtree(key: _searchBoxKey, child: _SearchBox(
          controller: _searchCtrl, hint: t['search'] ?? 'Search...', fullWidth: true,
          onFilter: _toggleFilter, filterCount: _activeFilterCount,
        ))),
        const SizedBox(width: 8),
        _AddButton(label: t['add'] ?? 'Add', onTap: onAdd, iconOnly: true),
        const SizedBox(width: 8),
        _EditButton(label: t['edit'] ?? 'Edit', onTap: onEdit, iconOnly: true),
        const SizedBox(width: 8),
        _DeleteButton(label: t['delete'] ?? 'Delete', onTap: onDelete, iconOnly: true),
        const SizedBox(width: 8),
        _ExportButton(label: t['export'] ?? 'Export', exporting: _exporting, isDark: isDark, iconOnly: true, onTap: onExport),
      ]);
    } else {
      toolbar = LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final searchW = (constraints.maxWidth * 0.28).clamp(160.0, 400.0);
        return Row(children: [
          SizedBox(width: searchW, child: KeyedSubtree(key: _searchBoxKey, child: _SearchBox(
            controller: _searchCtrl, hint: t['search'] ?? 'Search...', fullWidth: true,
            onFilter: _toggleFilter, filterCount: _activeFilterCount,
          ))),
          const SizedBox(width: 8),
          const Spacer(),
          _AddButton(label: t['add'] ?? 'Add', onTap: onAdd, iconOnly: compact),
          const SizedBox(width: 8),
          _EditButton(label: t['edit'] ?? 'Edit', onTap: onEdit, iconOnly: compact),
          const SizedBox(width: 8),
          _DeleteButton(label: t['delete'] ?? 'Delete', onTap: onDelete, iconOnly: compact),
          const SizedBox(width: 8),
          _ExportButton(label: t['export'] ?? 'Export', exporting: _exporting, isDark: isDark, iconOnly: compact, onTap: onExport),
        ]);
      });
    }

    // ── Checkbox helpers ──────────────────────────────────────────
    final allPageChecked = _paginated.isNotEmpty &&
        _paginated.every((s) => _checkedKeys.contains(s['key']));
    final anyPageChecked = _paginated.any((s) => _checkedKeys.contains(s['key']));
    final headerActive = allPageChecked || anyPageChecked;

    final headerCheckbox = Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 32, child: Checkbox(
        tristate: true,
        value: allPageChecked ? true : (anyPageChecked ? null : false),
        onChanged: (v) => setState(() {
          if (v == true) {
            for (final s in _paginated) { _checkedKeys.add(s['key'] as String); }
          } else {
            for (final s in _paginated) { _checkedKeys.remove(s['key'] as String); }
          }
        }),
        fillColor: WidgetStateProperty.all(headerActive ? AppColors.primary : fieldBg),
        checkColor: Colors.white,
        shape: checkboxShape,
        side: checkboxSide(headerActive),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      )),
      const SizedBox(width: 10),
    ]);

    Widget rowCheckbox(Map<String, dynamic> s) {
      final checked = _checkedKeys.contains(s['key'] as String);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          final k = s['key'] as String;
          if (checked) {
            _checkedKeys.remove(k);
            if (_selectedSummary?['key'] == k) _selectedSummary = null;
          } else {
            _checkedKeys.add(k);
            _selectedSummary = s;
          }
        }),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 32, child: Checkbox(
            value: checked,
            onChanged: (v) => setState(() {
              final k = s['key'] as String;
              if (v == true) { _checkedKeys.add(k); _selectedSummary = s; }
              else { _checkedKeys.remove(k); if (_selectedSummary?['key'] == k) _selectedSummary = null; }
            }),
            fillColor: WidgetStateProperty.all(checked ? AppColors.primary : fieldBg),
            checkColor: Colors.white,
            shape: checkboxShape,
            side: checkboxSide(checked),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          )),
          const SizedBox(width: 10),
        ]),
      );
    }

    // ── Table header ──────────────────────────────────────────────
    final Row tableHeader;
    if (isMobile) {
      tableHeader = Row(children: [
        headerCheckbox,
        const TableHeader(label: '#', flex: 1, textAlign: TextAlign.center),
        TableHeader(label: t['date'] ?? 'Date', flex: 3, onSort: () => _sort('date'), isSorted: _sortColumn == 'date', sortAscending: _sortAscending),
        TableHeader(label: t['teacher_name'] ?? 'Teacher Name', flex: 3, onSort: () => _sort('teacher'), isSorted: _sortColumn == 'teacher', sortAscending: _sortAscending),
        TableHeader(label: t['class_name'] ?? 'Class', flex: 4, onSort: () => _sort('class'), isSorted: _sortColumn == 'class', sortAscending: _sortAscending),
        TableHeader(label: t['rate'] ?? 'Rate', flex: 2, textAlign: TextAlign.center, onSort: () => _sort('rate'), isSorted: _sortColumn == 'rate', sortAscending: _sortAscending),
      ]);
    } else if (isTablet) {
      tableHeader = Row(children: [
        headerCheckbox,
        const TableHeader(label: '#', flex: 1, textAlign: TextAlign.center),
        TableHeader(label: t['date'] ?? 'Date', flex: 3, onSort: () => _sort('date'), isSorted: _sortColumn == 'date', sortAscending: _sortAscending),
        TableHeader(label: t['teacher_name'] ?? 'Teacher Name', flex: 3, onSort: () => _sort('teacher'), isSorted: _sortColumn == 'teacher', sortAscending: _sortAscending),
        TableHeader(label: t['class_name'] ?? 'Class', flex: 3, onSort: () => _sort('class'), isSorted: _sortColumn == 'class', sortAscending: _sortAscending),
        TableHeader(label: t['subject'] ?? 'Subject', flex: 3, onSort: () => _sort('subject'), isSorted: _sortColumn == 'subject', sortAscending: _sortAscending),
        TableHeader(label: t['present'] ?? 'Present', flex: 2, textAlign: TextAlign.center, onSort: () => _sort('present'), isSorted: _sortColumn == 'present', sortAscending: _sortAscending),
        TableHeader(label: t['absent'] ?? 'Absent', flex: 2, textAlign: TextAlign.center, onSort: () => _sort('absent'), isSorted: _sortColumn == 'absent', sortAscending: _sortAscending),
        TableHeader(label: t['rate'] ?? 'Rate', flex: 2, textAlign: TextAlign.center, onSort: () => _sort('rate'), isSorted: _sortColumn == 'rate', sortAscending: _sortAscending),
      ]);
    } else {
      tableHeader = Row(children: [
        headerCheckbox,
        const TableHeader(label: '#', flex: 1, textAlign: TextAlign.center),
        TableHeader(label: t['date'] ?? 'Date', flex: 3, onSort: () => _sort('date'), isSorted: _sortColumn == 'date', sortAscending: _sortAscending),
        TableHeader(label: t['teacher_name'] ?? 'Teacher Name', flex: 3, onSort: () => _sort('teacher'), isSorted: _sortColumn == 'teacher', sortAscending: _sortAscending),
        TableHeader(label: t['class_name'] ?? 'Class', flex: 3, onSort: () => _sort('class'), isSorted: _sortColumn == 'class', sortAscending: _sortAscending),
        TableHeader(label: t['subject'] ?? 'Subject', flex: 3, onSort: () => _sort('subject'), isSorted: _sortColumn == 'subject', sortAscending: _sortAscending),
        TableHeader(label: t['total_students'] ?? 'Total', flex: 2, textAlign: TextAlign.center, onSort: () => _sort('total'), isSorted: _sortColumn == 'total', sortAscending: _sortAscending),
        TableHeader(label: t['present'] ?? 'Present', flex: 2, textAlign: TextAlign.center, onSort: () => _sort('present'), isSorted: _sortColumn == 'present', sortAscending: _sortAscending),
        TableHeader(label: t['absent'] ?? 'Absent', flex: 2, textAlign: TextAlign.center, onSort: () => _sort('absent'), isSorted: _sortColumn == 'absent', sortAscending: _sortAscending),
        TableHeader(label: t['late'] ?? 'Late', flex: 2, textAlign: TextAlign.center, onSort: () => _sort('late'), isSorted: _sortColumn == 'late', sortAscending: _sortAscending),
        TableHeader(label: t['rate'] ?? 'Rate', flex: 2, textAlign: TextAlign.center, onSort: () => _sort('rate'), isSorted: _sortColumn == 'rate', sortAscending: _sortAscending),
      ]);
    }

    // ── Row cells builder ─────────────────────────────────────────
    List<Widget> buildCells(Map<String, dynamic> s, int globalIdx) {
      final rate = s['rate'] as double;
      final rateText = '${rate.toStringAsFixed(1)}%';
      final teacherName = s['teacherName'] as String? ?? '';
      final teacherWidget = teacherName.isNotEmpty
          ? Text(teacherName, style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)
          : Text('—', style: AppTextStyles.body.copyWith(color: mutedColor));

      if (isMobile) {
        return [
          rowCheckbox(s),
          Expanded(flex: 1, child: Text('$globalIdx', style: AppTextStyles.body.copyWith(color: textColor), textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text(_formatDate(s['date'] as String? ?? ''), style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: teacherWidget),
          Expanded(flex: 4, child: Text(s['className'] as String? ?? '—', style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(rateText, style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
        ];
      } else if (isTablet) {
        return [
          rowCheckbox(s),
          Expanded(flex: 1, child: Text('$globalIdx', style: AppTextStyles.body.copyWith(color: textColor), textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text(_formatDate(s['date'] as String? ?? ''), style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: teacherWidget),
          Expanded(flex: 3, child: Text(s['className'] as String? ?? '—', style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(s['subjectName'] as String? ?? '—', style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text('${s['present']}', style: AppTextStyles.body.copyWith(color: const Color(0xFF16A34A), fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('${s['absent']}', style: AppTextStyles.body.copyWith(color: AppColors.error, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(rateText, style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
        ];
      } else {
        return [
          rowCheckbox(s),
          Expanded(flex: 1, child: Text('$globalIdx', style: AppTextStyles.body.copyWith(color: textColor), textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text(_formatDate(s['date'] as String? ?? ''), style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: teacherWidget),
          Expanded(flex: 3, child: Text(s['className'] as String? ?? '—', style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(s['subjectName'] as String? ?? '—', style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text('${s['total']}', style: AppTextStyles.body.copyWith(color: mutedColor, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('${s['present']}', style: AppTextStyles.body.copyWith(color: const Color(0xFF16A34A), fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('${s['absent']}', style: AppTextStyles.body.copyWith(color: AppColors.error, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('${s['late']}', style: AppTextStyles.body.copyWith(color: const Color(0xFFD97706), fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(rateText, style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
        ];
      }
    }

    final startIdx = (_currentPage - 1) * _pageSize;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        toolbar,
        const SizedBox(height: 12),
        Expanded(
          child: _TableCard(
            loading: _loading,
            empty: _filtered.isEmpty,
            emptyIcon: Icons.fact_check_outlined,
            emptyLabel: t['no_attendance_data'] ?? 'No attendance records',
            header: tableHeader,
            body: ListView.builder(
              itemCount: _paginated.length,
              itemBuilder: (_, i) {
                final s = _paginated[i];
                final globalIdx = startIdx + i + 1;
                return _TableRow(
                  index: i,
                  isSelected: _checkedKeys.contains(s['key'] as String),
                  onTap: () => _onRowTap(s),
                  children: buildCells(s, globalIdx),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _PaginationRow(
          currentPage: _currentPage,
          totalPages: _totalPages,
          pageSize: _pageSize,
          selectedCount: _checkedKeys.length,
          translations: t,
          onPageChanged: (p) => setState(() => _currentPage = p),
          onPageSizeChanged: (s) => setState(() { _pageSize = s; _currentPage = 1; }),
        ),
      ]),
    );
  }
}

// ── Take Attendance Form ──────────────────────────────────────────────────────

class _TakeAttendanceForm extends StatefulWidget {
  final Map<String, String> t;
  final bool isDark;
  final Map<String, dynamic>? editSummary;
  final int recordCount;
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> subjects;
  final List<Map<String, dynamic>> teachers;
  final List<Map<String, dynamic>> Function(int? classId, String? className) studentsInClass;
  final String Function(Map<String, dynamic>) studentName;
  final Future<void> Function({
    required String date, required int? classId, required String? className,
    required int? subjectId, required String? subjectName,
    required int? teacherId,
    required int? period,
    required List<Map<String, dynamic>> attendances,
    required bool isEdit, required List<Map<String, dynamic>> existingRecords,
  }) onSave;
  final VoidCallback onCancel;

  const _TakeAttendanceForm({
    required this.t, required this.isDark, required this.editSummary,
    required this.recordCount,
    required this.classes, required this.subjects, required this.teachers,
    required this.studentsInClass,
    required this.studentName, required this.onSave, required this.onCancel,
  });

  @override
  State<_TakeAttendanceForm> createState() => _TakeAttendanceFormState();
}

class _TakeAttendanceFormState extends State<_TakeAttendanceForm> {
  late DateTime _date;
  late TextEditingController _codeCtrl;
  late TextEditingController _dateCtrl;
  final TextEditingController _remarkCtrl = TextEditingController();
  int? _classId;
  int? _subjectId;
  int? _teacherId;
  int? _period;
  List<Map<String, dynamic>> _classStudents = [];
  final Map<int, String> _statuses = {};
  bool _saving = false;

  Map<String, dynamic>? get _selectedClass =>
      _classId != null ? widget.classes.where((c) => c['id'] == _classId).firstOrNull : null;
  Map<String, dynamic>? get _selectedSubject =>
      _subjectId != null ? widget.subjects.where((s) => s['id'] == _subjectId).firstOrNull : null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editSummary;
    if (edit != null) {
      _date = DateTime.tryParse(edit['date'] as String? ?? '') ?? DateTime.now();
      final cls = widget.classes.where((c) => c['name'] == edit['className']).firstOrNull;
      _classId = cls?['id'] as int?;
      final subj = widget.subjects.where((s) => s['name'] == edit['subjectName']).firstOrNull;
      _subjectId = subj?['id'] as int?;
      _teacherId = (edit['teacherId'] as num?)?.toInt();
      for (final r in (edit['records'] as List).cast<Map<String, dynamic>>()) {
        final sid = r['studentId'] as int?;
        if (sid != null) _statuses[sid] = r['status'] as String? ?? 'Present';
      }
      if (_classId != null) {
        _classStudents = widget.studentsInClass(_classId, cls?['name'] as String?);
        for (final s in _classStudents) {
          final id = s['id'] as int?;
          if (id != null) _statuses.putIfAbsent(id, () => 'Present');
        }
      }
      _codeCtrl = TextEditingController(text: edit['code'] as String? ?? '');
      _remarkCtrl.text = edit['remark'] as String? ?? '';
      _period = (edit['period'] as num?)?.toInt();
    } else {
      _date = DateTime.now();
      _codeCtrl = TextEditingController();
    }
    _dateCtrl = TextEditingController(text: _fmtDateOnly(_date));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _dateCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  String _fmtDateOnly(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')}';

  void _onClassChanged(int? id) {
    final cls = id != null ? widget.classes.where((c) => c['id'] == id).firstOrNull : null;
    setState(() {
      _classId = id;
      _classStudents = widget.studentsInClass(id, cls?['name'] as String?);
      _statuses.clear();
      for (final s in _classStudents) {
        final sid = s['id'] as int?;
        if (sid != null) _statuses[sid] = 'Present';
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute);
      _dateCtrl.text = _fmtDateOnly(_date);
    });
  }

  Future<void> _submit() async {
    if (_classId == null || _classStudents.isEmpty) return;
    final attendances = _classStudents.map((s) {
      final id = s['id'] as int;
      return {'studentId': id, 'status': _statuses[id] ?? 'Present', 'code': _codeCtrl.text.trim(), 'notes': _remarkCtrl.text.trim()};
    }).toList();
    final cls = _selectedClass; final subj = _selectedSubject;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        date: '${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}T${_date.hour.toString().padLeft(2,'0')}:${_date.minute.toString().padLeft(2,'0')}:00',
        classId: _classId, className: cls?['name'] as String?,
        subjectId: _subjectId, subjectName: subj?['name'] as String?,
        teacherId: _teacherId,
        period: _period,
        attendances: attendances,
        isEdit: widget.editSummary != null,
        existingRecords: widget.editSummary != null
            ? (widget.editSummary!['records'] as List).cast<Map<String, dynamic>>()
            : [],
      );
    } finally { if (mounted) setState(() => _saving = false); }
  }

  String _studentCode(Map<String, dynamic> s, int index) {
    final code = s['code'] as String? ?? s['studentCode'] as String?;
    if (code != null && code.isNotEmpty) return code;
    return 'ST${(index + 1).toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t; final isDark = widget.isDark;
    final bgColor    = isDark ? const Color(0xFF16213E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor   = isDark ? Colors.white : AppColors.textPrimary;
    final isEdit = widget.editSummary != null;

    // ── Input decoration — exactly matches _inputDecoration in StudentFormPanel ──
    // null borders when no error → inherits OutlineInputBorder from theme
    InputDecoration inputDeco({String hint = '', Widget? suffix, bool hasError = false}) => InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: isDark ? Colors.white70 : AppColors.textMuted),
      suffixIcon: suffix,
      enabledBorder: hasError ? OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.error)) : null,
      focusedBorder: hasError ? OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.error, width: 1.5)) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
    );

    // ── Label helpers (matches _labeled / _requiredLabeled) ──────────────
    Widget labeled(String label, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
    Widget requiredLabeled(String label, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          TextSpan(text: ' *', style: AppTextStyles.body.copyWith(color: AppColors.error)),
        ])),
        const SizedBox(height: 6),
        child,
      ],
    );

    // ── Dropdown — exact copy of _StyledDropdown from table_widgets.dart ──
    final dropBg     = isDark ? const Color(0xFF16213E) : AppColors.white;
    final mutedColor = isDark ? Colors.white70 : AppColors.textMuted;
    final iconColor  = isDark ? Colors.white70 : AppColors.textSecondary;
    final activeColor = isDark ? const Color(0xFF6DBF67) : AppColors.primary;

    // Uses showMenu() exactly like _StyledDropdown, not DropdownButton.
    Widget styledDropdown<T>({
      required T? value,
      required List<T?> dropItems,
      required List<String> labels,
      required String hint,
      required ValueChanged<T?>? onChanged,
    }) {
      final idx = dropItems.indexOf(value);
      final display = idx >= 0 ? labels[idx] : null;

      void openMenu(BuildContext ctx) {
        final box = ctx.findRenderObject() as RenderBox;
        final overlayBox = Overlay.of(ctx).context.findRenderObject() as RenderBox;
        final buttonWidth = box.size.width;
        final rect = RelativeRect.fromRect(
          Rect.fromPoints(
            box.localToGlobal(Offset(0, box.size.height), ancestor: overlayBox),
            box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlayBox),
          ),
          Offset.zero & overlayBox.size,
        );
        showMenu<int>(
          context: ctx,
          position: rect,
          elevation: 4,
          color: dropBg,
          constraints: BoxConstraints(minWidth: buttonWidth, maxWidth: buttonWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: borderColor),
          ),
          items: dropItems.asMap().entries.map((e) {
            final isSelected = e.value == value;
            return PopupMenuItem<int>(
              value: e.key,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(children: [
                Expanded(child: Text(labels[e.key], style: AppTextStyles.body.copyWith(
                  color: isSelected ? activeColor : textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ))),
                if (isSelected) Icon(Icons.check_rounded, size: 15, color: activeColor),
              ]),
            );
          }).toList(),
        ).then((pickedIdx) {
          if (pickedIdx != null && onChanged != null) onChanged(dropItems[pickedIdx]);
        });
      }

      return Builder(builder: (ctx) => InkWell(
        onTap: onChanged == null ? null : () => openMenu(ctx),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: dropBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(children: [
            Expanded(child: Text(
              display ?? hint,
              style: AppTextStyles.body.copyWith(
                color: display != null ? textColor : mutedColor,
              ),
              overflow: TextOverflow.ellipsis,
            )),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: iconColor),
          ]),
        ),
      ));
    }

    // ── Status checkboxes ─────────────────────────────────────────────────
    final fieldBg = isDark ? const Color(0xFF0D0D1C) : const Color(0xFFF2F3F7);
    final checkShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));
    WidgetStateBorderSide checkSide(bool active) => WidgetStateBorderSide.resolveWith(
      (_) => BorderSide(color: active ? AppColors.primary : (isDark ? Colors.white38 : AppColors.border), width: 1.5));
    Widget statusCheckbox(int sid, String target) {
      final checked = (_statuses[sid] ?? 'Present') == target;
      return SizedBox(width: 20, height: 20, child: Checkbox(
        value: checked,
        onChanged: (_) => setState(() => _statuses[sid] = target),
        fillColor: WidgetStateProperty.all(checked ? AppColors.primary : fieldBg),
        checkColor: Colors.white,
        shape: checkShape,
        side: checkSide(checked),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ));
    }

    // ── Top bar (matches StudentFormPanel header exactly) ─────────────────
    final topBar = Padding(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Row(children: [
        SizedBox(
          width: 38, height: 38,
          child: InkWell(
            onTap: widget.onCancel,
            borderRadius: BorderRadius.circular(18),
            child: const Center(child: Icon(Icons.arrow_back_rounded, size: 22, color: AppColors.textSecondary)),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          isEdit ? (t['edit_attendance'] ?? 'Edit Attendance') : (t['add_attendance'] ?? 'Add Attendance'),
          style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check, size: 18),
          label: Text(t['save'] ?? 'Save'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            side: BorderSide(color: isDark ? const Color(0xFF2A2A4A) : AppColors.border, width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
      ]),
    );

    // ── Form content ──────────────────────────────────────────────────────
    final formBody = Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Row 1: Code + Teacher
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: requiredLabeled(
                    '${t['code'] ?? 'Code'}:',
                    SizedBox(height: 44, child: TextField(
                      controller: _codeCtrl,
                      style: AppTextStyles.body.copyWith(color: textColor),
                      decoration: inputDeco(hint: t['enter_code'] ?? 'e.g. AT001'),
                    )),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: labeled(
                    '${t['teacher'] ?? 'Teacher'}:',
                    styledDropdown<int?>(
                      value: _teacherId,
                      dropItems: widget.teachers.map((t) => (t['id'] as num?)?.toInt()).toList(),
                      labels: widget.teachers.map((t) => t['name']?.toString() ?? '').toList(),
                      hint: t['select_teacher'] ?? 'Select Teacher',
                      onChanged: (v) => setState(() => _teacherId = v),
                    ),
                  )),
                ]),

                const SizedBox(height: 16),

                // Row 2: Date + Time
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: requiredLabeled(
                    '${t['date'] ?? 'Date'}:',
                    SizedBox(height: 44, child: TextField(
                      controller: _dateCtrl,
                      readOnly: true,
                      onTap: _pickDate,
                      style: AppTextStyles.body.copyWith(color: textColor),
                      decoration: inputDeco(
                        hint: 'YYYY/MM/DD',
                        suffix: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                      ),
                    )),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: labeled(
                    '${t['period'] ?? 'Period'}:',
                    styledDropdown<int?>(
                      value: _period,
                      dropItems: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
                      labels: const [
                        '07 AM  07:00 – 08:00',
                        '08 AM  08:00 – 09:00',
                        '09 AM  09:00 – 10:00',
                        '10 AM  10:00 – 11:00',
                        '11 AM  11:00 – 12:00',
                        '01 PM  01:00 – 02:00 PM',
                        '02 PM  02:00 – 03:00 PM',
                        '03 PM  03:00 – 04:00 PM',
                        '04 PM  04:00 – 05:00 PM',
                        '05 PM  05:00 – 06:00 PM',
                      ],
                      hint: t['select_period'] ?? 'Select Period',
                      onChanged: (v) => setState(() => _period = v),
                    ),
                  )),
                ]),

                const SizedBox(height: 16),

                // Row 3: Class + Subject
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: requiredLabeled(
                    '${t['class_name'] ?? 'Class'}:',
                    styledDropdown<int>(
                      value: _classId,
                      dropItems: widget.classes.map((c) => c['id'] as int?).toList(),
                      labels: widget.classes.map((c) => c['name']?.toString() ?? '').toList(),
                      hint: t['select_class'] ?? 'Select Class',
                      onChanged: isEdit ? null : (v) => _onClassChanged(v),
                    ),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: labeled(
                    '${t['subject'] ?? 'Subject'}:',
                    styledDropdown<int?>(
                      value: _subjectId,
                      dropItems: widget.subjects.map((s) => s['id'] as int?).toList(),
                      labels: widget.subjects.map((s) => s['name']?.toString() ?? '').toList(),
                      hint: t['select_subject'] ?? 'Select Subject',
                      onChanged: (v) => setState(() => _subjectId = v),
                    ),
                  )),
                ]),

                const SizedBox(height: 16),

                // Row 4: Total Students + Remark
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: labeled(
                    '${t['total_students'] ?? 'Total Students'}:',
                    Text(
                      _classStudents.isEmpty ? '—' : _classStudents.length.toString().padLeft(2, '0'),
                      style: AppTextStyles.body.copyWith(
                        color: _classStudents.isEmpty ? AppColors.textSecondary : AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: labeled(
                    '${t['remark'] ?? 'Remark'}:',
                    SizedBox(height: 44, child: TextField(
                      controller: _remarkCtrl,
                      style: AppTextStyles.body.copyWith(color: textColor),
                      decoration: inputDeco(hint: t['enter_remark'] ?? 'Enter your remark...'),
                    )),
                  )),
                ]),

                const SizedBox(height: 24),

                // Student Info table — no outer border, plain header, _TableRow rows
                Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(children: [
                      Expanded(child: Text(t['student_info'] ?? 'Student Info',
                          style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.w600))),
                      SizedBox(width: 76, child: Text(t['present'] ?? 'Present',
                          style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center)),
                      SizedBox(width: 76, child: Text(t['absent'] ?? 'Absent',
                          style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center)),
                      SizedBox(width: 76, child: Text(t['late'] ?? 'Late',
                          style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center)),
                    ]),
                  ),
                  if (_classId == null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 40, 14, 20),
                      child: Text(t['select_class_first'] ?? 'Please select a class to view students',
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                    )
                  else if (_classStudents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 40, 14, 20),
                      child: Text(t['no_students_in_class'] ?? 'No students in this class',
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                    )
                  else
                    ...List.generate(_classStudents.length, (i) {
                      final student = _classStudents[i];
                      final sid = student['id'] as int?;
                      final name = widget.studentName(student);
                      final code = _studentCode(student, i);
                      return _TableRow(
                        index: i,
                        children: [
                          Expanded(child: Text('$code • $name',
                              style: AppTextStyles.body.copyWith(color: textColor),
                              overflow: TextOverflow.ellipsis)),
                          if (sid != null) ...[
                            SizedBox(width: 76, child: Center(child: statusCheckbox(sid, 'Present'))),
                            SizedBox(width: 76, child: Center(child: statusCheckbox(sid, 'Absent'))),
                            SizedBox(width: 76, child: Center(child: statusCheckbox(sid, 'Late'))),
                          ],
                        ],
                      );
                    }),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );

    return Positioned.fill(child: Material(
      color: bgColor,
      child: Column(children: [topBar, formBody]),
    ));
  }
}

// ── Search Box ────────────────────────────────────────────────────────────────

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool fullWidth;
  final VoidCallback? onFilter;
  final int filterCount;

  const _SearchBox({
    required this.controller, required this.hint,
    this.fullWidth = false, this.onFilter, this.filterCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white70 : AppColors.textMuted;
    final activeFilter = filterCount > 0;

    return SizedBox(
      width: fullWidth ? double.infinity : 240, height: 42,
      child: TextField(
        controller: controller, style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint, hintStyle: AppTextStyles.body.copyWith(color: mutedColor),
          prefixIcon: Icon(Icons.search, size: 18, color: mutedColor),
          suffixIcon: onFilter != null
              ? _FilterIconSuffix(onTap: onFilter!, activeFilter: activeFilter, filterCount: filterCount, mutedColor: mutedColor, isDark: isDark)
              : null,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          filled: true, fillColor: bgColor,
        ),
      ),
    );
  }
}

class _FilterIconSuffix extends StatefulWidget {
  final VoidCallback onTap;
  final bool activeFilter;
  final int filterCount;
  final Color mutedColor;
  final bool isDark;
  const _FilterIconSuffix({required this.onTap, required this.activeFilter, required this.filterCount, required this.mutedColor, required this.isDark});
  @override
  State<_FilterIconSuffix> createState() => _FilterIconSuffixState();
}

class _FilterIconSuffixState extends State<_FilterIconSuffix> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    final hoverBg = widget.isDark ? Colors.white.withValues(alpha: 0.0) : AppColors.primarySurface;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _hovering = true); }),
      onExit:  (_) => WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _hovering = false); }),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 0),
            width: 32, height: 32, margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: widget.activeFilter
                  ? AppColors.primary.withValues(alpha: 0.0)
                  : _hovering ? hoverBg : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.tune_rounded, size: 18,
              color: widget.activeFilter ? AppColors.primary : _hovering ? AppColors.primary : widget.mutedColor),
          ),
          if (widget.activeFilter)
            Positioned(top: 6, right: 4,
              child: Container(
                width: 14, height: 14,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Center(child: Text('${widget.filterCount}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
              )),
        ]),
      ),
    );
  }
}

// ── Filter Panel ──────────────────────────────────────────────────────────────

class _FilterPanel extends StatefulWidget {
  final Map<String, String> t;
  final bool isDark;
  final String classFilter;
  final String subjectFilter;
  final String teacherFilter;
  final List<String> availableClasses;
  final List<String> availableSubjects;
  final List<String> availableTeachers;
  final void Function(String cls, String subj, String teacher) onApply;

  const _FilterPanel({
    required this.t, required this.isDark,
    required this.classFilter, required this.subjectFilter, required this.teacherFilter,
    required this.availableClasses, required this.availableSubjects, required this.availableTeachers,
    required this.onApply,
  });
  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late String _cls;
  late String _subj;
  late String _teacher;
  @override
  void initState() { super.initState(); _cls = widget.classFilter; _subj = widget.subjectFilter; _teacher = widget.teacherFilter; }

  Widget _section(String title, List<Widget> chips) {
    final mutedColor = widget.isDark ? Colors.white60 : AppColors.textSecondary;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.label.copyWith(color: mutedColor, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: chips),
    ]);
  }

  Widget _chip(String label, String value, String current, void Function(String) onSelect) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => setState(() => onSelect(value)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : (widget.isDark ? const Color(0xFF1C2A4A) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: AppTextStyles.body.copyWith(color: selected ? AppColors.primary : AppColors.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          if (selected) ...[const SizedBox(width: 6), const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary)],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t; final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(children: [
            const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(t['filter'] ?? 'Filter', style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.w600))),
            TextButton(
              onPressed: () => setState(() { _cls = 'all'; _subj = 'all'; _teacher = 'all'; }),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
              child: Text(t['reset'] ?? 'Reset', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            ),
          ]),
        ),
        Divider(height: 1, color: borderColor),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _section(t['class_name'] ?? 'Class', [
              _chip(t['all_classes'] ?? 'All', 'all', _cls, (v) => _cls = v),
              ...widget.availableClasses.map((c) => _chip(c, c, _cls, (v) => _cls = v)),
            ]),
            if (widget.availableSubjects.isNotEmpty) ...[
              const SizedBox(height: 16),
              _section(t['subject'] ?? 'Subject', [
                _chip(t['all_subjects'] ?? 'All', 'all', _subj, (v) => _subj = v),
                ...widget.availableSubjects.map((s) => _chip(s, s, _subj, (v) => _subj = v)),
              ]),
            ],
            if (widget.availableTeachers.isNotEmpty) ...[
              const SizedBox(height: 16),
              _section(t['teacher_name'] ?? 'Teacher Name', [
                _chip(t['all_teachers'] ?? 'All', 'all', _teacher, (v) => _teacher = v),
                ...widget.availableTeachers.map((n) => _chip(n, n, _teacher, (v) => _teacher = v)),
              ]),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 40,
              child: ElevatedButton(
                onPressed: () => widget.onApply(_cls, _subj, _teacher),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                child: Text(t['confirm'] ?? 'Apply', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Table Card ────────────────────────────────────────────────────────────────

class _TableCard extends StatelessWidget {
  final bool loading;
  final bool empty;
  final IconData emptyIcon;
  final String emptyLabel;
  final Widget header;
  final Widget body;
  const _TableCard({required this.loading, required this.empty, required this.emptyIcon, required this.emptyLabel, required this.header, required this.body});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final mutedColor = isDark ? Colors.white70 : AppColors.textMuted;
    return Container(
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(AppConstants.cardRadius)),
      child: loading
          ? Column(children: [Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: header), const Expanded(child: SkeletonTableLoader())])
          : Column(children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: header),
              if (empty)
                Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(emptyIcon, size: 48, color: mutedColor),
                  const SizedBox(height: 12),
                  Text(emptyLabel, style: AppTextStyles.body.copyWith(color: mutedColor)),
                ])))
              else
                Expanded(child: body),
            ]),
    );
  }
}

// ── Table Row ─────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback? onTap;
  final bool isSelected;
  final int index;
  const _TableRow({required this.children, required this.index, this.onTap, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEven = index % 2 == 0;
    final baseColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.10)
        : isDark
            ? (isEven ? const Color(0xFF16213E) : const Color(0xFF1C2A4A))
            : (isEven ? Colors.white : const Color(0xFFF5F7FA));
    return Material(
      color: baseColor,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        hoverColor: AppColors.primary.withValues(alpha: 0.10),
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        mouseCursor: SystemMouseCursors.click,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Row(children: children)),
      ),
    );
  }
}

// ── Pagination Row ────────────────────────────────────────────────────────────

class _PaginationRow extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final int selectedCount;
  final Map<String, String> translations;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  const _PaginationRow({
    required this.currentPage, required this.totalPages, required this.pageSize,
    required this.selectedCount, required this.translations,
    required this.onPageChanged, required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final t = translations;

    final btnStyle = OutlinedButton.styleFrom(
      foregroundColor: textColor, backgroundColor: Colors.transparent, elevation: 0,
      minimumSize: const Size(44, 44), padding: EdgeInsets.zero,
      side: BorderSide(color: borderColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );

    final navRow = Row(mainAxisSize: MainAxisSize.min, children: [
      OutlinedButton(onPressed: currentPage > 1 ? () => onPageChanged(1) : null, style: btnStyle, child: const Icon(Icons.first_page, size: 18)),
      const SizedBox(width: 4),
      OutlinedButton(onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null, style: btnStyle, child: const Icon(Icons.chevron_left, size: 18)),
      const SizedBox(width: 8),
      Text('$currentPage ${t['of'] ?? 'of'} $totalPages', style: AppTextStyles.body.copyWith(color: textColor)),
      const SizedBox(width: 8),
      OutlinedButton(onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null, style: btnStyle, child: const Icon(Icons.chevron_right, size: 18)),
      const SizedBox(width: 4),
      OutlinedButton(onPressed: currentPage < totalPages ? () => onPageChanged(totalPages) : null, style: btnStyle, child: const Icon(Icons.last_page, size: 18)),
    ]);

    final showRow = Row(mainAxisSize: MainAxisSize.min, children: [
      Text(t['show'] ?? 'Show', style: AppTextStyles.body.copyWith(color: textColor)),
      const SizedBox(width: 8),
      Container(
        height: 38, width: 84, padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(6)),
        child: DropdownButtonHideUnderline(child: DropdownButton<int>(
          value: pageSize, isDense: true,
          style: AppTextStyles.body.copyWith(color: textColor), dropdownColor: bgColor,
          items: [25, 50, 100].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
          onChanged: (v) => onPageSizeChanged(v!),
        )),
      ),
    ]);

    final selectedBadge = selectedCount > 0
        ? Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('$selectedCount ${t['selected'] ?? 'selected'}',
                    style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
          ])
        : const SizedBox.shrink();

    return LayoutBuilder(builder: (_, constraints) {
      if (constraints.maxWidth >= 380) {
        return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          navRow, const Spacer(),
          if (selectedCount > 0) ...[selectedBadge, const SizedBox(width: 16)],
          showRow,
        ]);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: navRow), const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [selectedBadge, showRow]),
      ]);
    });
  }
}

// ── Toolbar Buttons ───────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final String label; final VoidCallback onTap; final bool iconOnly;
  const _AddButton({required this.label, required this.onTap, this.iconOnly = false});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final style = OutlinedButton.styleFrom(foregroundColor: AppColors.primaryLight, elevation: 0,
      padding: iconOnly ? const EdgeInsets.all(0) : const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      side: BorderSide(color: borderColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      minimumSize: iconOnly ? const Size(48, 48) : null);
    if (iconOnly) return OutlinedButton(onPressed: onTap, style: style, child: const Icon(Icons.add, size: 18));
    return OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.add, size: 18), label: Text(label), style: style);
  }
}

class _EditButton extends StatelessWidget {
  final String label; final VoidCallback onTap; final bool iconOnly;
  const _EditButton({required this.label, required this.onTap, this.iconOnly = false});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final style = OutlinedButton.styleFrom(foregroundColor: AppColors.primaryLight, elevation: 0,
      padding: iconOnly ? const EdgeInsets.all(0) : const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      side: BorderSide(color: borderColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      minimumSize: iconOnly ? const Size(48, 48) : null);
    if (iconOnly) return OutlinedButton(onPressed: onTap, style: style, child: const Icon(Icons.edit_outlined, size: 18));
    return OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.edit_outlined, size: 18), label: Text(label), style: style);
  }
}

class _DeleteButton extends StatelessWidget {
  final String label; final VoidCallback onTap; final bool iconOnly;
  const _DeleteButton({required this.label, required this.onTap, this.iconOnly = false});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final style = OutlinedButton.styleFrom(foregroundColor: AppColors.primaryLight, elevation: 0,
      padding: iconOnly ? const EdgeInsets.all(0) : const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      side: BorderSide(color: borderColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      minimumSize: iconOnly ? const Size(48, 48) : null);
    if (iconOnly) return OutlinedButton(onPressed: onTap, style: style, child: const Icon(Icons.delete_outline, size: 18));
    return OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.delete_outline, size: 18), label: Text(label), style: style);
  }
}

class _ExportButton extends StatelessWidget {
  final String label; final bool exporting; final VoidCallback? onTap; final bool isDark; final bool iconOnly;
  const _ExportButton({required this.label, required this.exporting, required this.isDark, this.onTap, this.iconOnly = false});
  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final style = OutlinedButton.styleFrom(foregroundColor: AppColors.primaryLight, elevation: 0,
      padding: iconOnly ? const EdgeInsets.all(0) : const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      side: BorderSide(color: borderColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      overlayColor: AppColors.primaryLight.withValues(alpha: 0.08),
      minimumSize: iconOnly ? const Size(48, 48) : null);
    final icon = exporting
        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight))
        : const Icon(Icons.download_rounded, size: 18);
    if (iconOnly) return OutlinedButton(onPressed: exporting ? null : onTap, style: style, child: icon);
    return OutlinedButton(onPressed: exporting ? null : onTap, style: style,
        child: Row(mainAxisSize: MainAxisSize.min, children: [icon, const SizedBox(width: 8), Text(label)]));
  }
}

// ── Toast Notification ────────────────────────────────────────────────────────

class _ToastNotification extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isWarning;
  final VoidCallback onDismiss;
  const _ToastNotification({required this.message, required this.isError, required this.onDismiss, this.isWarning = false});
  @override
  State<_ToastNotification> createState() => _ToastNotificationState();
}

class _ToastNotificationState extends State<_ToastNotification> with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();
  }
  @override
  void dispose() { _progress.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.isError ? AppColors.error : widget.isWarning ? const Color(0xFFF59E0B) : AppColors.primary;
    final icon  = widget.isError ? Icons.close : widget.isWarning ? Icons.warning_amber_rounded : Icons.check;
    final title = widget.isError ? (t['error'] ?? 'Error') : widget.isWarning ? (t['warning'] ?? 'Warning') : (t['success'] ?? 'Success');
    final bgColor    = isDark ? const Color(0xFF1C2A4A) : AppColors.white;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final msgColor   = isDark ? Colors.white60 : AppColors.textSecondary;
    final closeColor = isDark ? Colors.white54 : AppColors.textSecondary;

    return Positioned(
      top: 24, right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: color), child: Icon(icon, color: Colors.white, size: 28)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: AppTextStyles.heading3.copyWith(color: titleColor)),
                    const SizedBox(height: 2),
                    Text(widget.message, style: AppTextStyles.body.copyWith(color: msgColor)),
                  ])),
                  const SizedBox(width: 8),
                  GestureDetector(onTap: widget.onDismiss, child: Icon(Icons.close, size: 20, color: closeColor)),
                ]),
              ),
              AnimatedBuilder(
                animation: _progress,
                builder: (_, __) => Align(alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(widthFactor: 1.0 - _progress.value, child: Container(height: 4, color: color))),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
