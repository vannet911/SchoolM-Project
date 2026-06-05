// lib/screens/students.dart
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/services/api_service.dart';
import 'package:schoolms_portal/utils/app_constants.dart';
import 'package:schoolms_portal/widgets/table_widgets.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final GlobalKey _searchBoxKey = GlobalKey();
  OverlayEntry? _filterOverlay;
  bool _exporting = false;
  final _searchCtrl = TextEditingController();
  Map<String, dynamic>? _selectedStudent;
  Map<String, dynamic>? _detailStudent;
  bool _showForm = false;
  Map<String, dynamic>? _formStudent;
  String? _sortColumn;
  bool _sortAscending = true;
  int _currentPage = 1;
  int _pageSize = 25;

  // Active filters
  String _genderFilter = 'all';
  String _classFilter = 'all';
  String _statusFilter = 'all';

  // Multi-select
  final Set<dynamic> _checkedIds = {};

  int get _activeFilterCount => [
        _genderFilter != 'all',
        _classFilter != 'all',
        _statusFilter != 'all',
      ].where((v) => v).length;

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
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getStudents();
      if (!mounted) return;
      setState(() {
        _students = data.cast<Map<String, dynamic>>();
        _loading = false;
      });
      _filter();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final t = AppTranslations.translations[
          context.read<LocaleProvider>().locale] ?? AppTranslations.translations['en']!;
      _showSnack(t['failed_load'] ?? 'Failed to load students', isError: true);
    }
  }

  void _filter({bool resetPage = true}) {
    final q = _searchCtrl.text.toLowerCase();
    var list = _students.where((s) {
      final searchOk = q.isEmpty ||
          '${s['firstName']} ${s['lastName']} ${s['email']} ${s['className'] ?? ''}'
              .toLowerCase()
              .contains(q);
      final gender = (s['gender'] as String?)?.toLowerCase() ?? '';
      final genderOk = _genderFilter == 'all' ||
          gender == _genderFilter.toLowerCase();
      final cls = (s['className'] as String?) ?? '';
      final classOk = _classFilter == 'all' || cls == _classFilter;
      final active = s['status'] == true;
      final statusOk = _statusFilter == 'all' ||
          (_statusFilter == 'active' && active) ||
          (_statusFilter == 'inactive' && !active);
      return searchOk && genderOk && classOk && statusOk;
    }).toList();

    if (_sortColumn != null) {
      list.sort((a, b) {
        final av = _sortValue(a, _sortColumn!);
        final bv = _sortValue(b, _sortColumn!);
        return _sortAscending ? av.compareTo(bv) : bv.compareTo(av);
      });
    }
    _checkedIds.clear();
    setState(() {
      _filtered = list;
      if (resetPage) _currentPage = 1;
    });
  }

  List<String> _buildUniqueClasses() {
    final seen = <String>{};
    final result = <String>[];
    for (final s in _students) {
      final cn = s['className'];
      if (cn is String && cn.isNotEmpty && seen.add(cn)) result.add(cn);
    }
    result.sort();
    return result;
  }

  Future<void> _exportStudents(Map<String, String> t) async {
    if (_exporting || _filtered.isEmpty) return;
    setState(() => _exporting = true);
    try {
      final workbook = Excel.createExcel();
      workbook.rename('Sheet1', 'Students');
      final sheet = workbook['Students'];
      final headers = ['#', 'Code', 'First Name', 'Last Name', 'Gender',
          'Class', 'Date of Birth', 'Email', 'Phone', 'Address', 'Status'];
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
      for (var i = 0; i < _filtered.length; i++) {
        final s = _filtered[i];
        final dob = s['dateOfBirth'] != null
            ? (s['dateOfBirth'] as String).split('T').first
            : '';
        final active = s['status'] == true;
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(s['code']?.toString() ?? ''),
          TextCellValue(s['firstName']?.toString() ?? ''),
          TextCellValue(s['lastName']?.toString() ?? ''),
          TextCellValue(s['gender']?.toString() ?? ''),
          TextCellValue(s['className']?.toString() ?? ''),
          TextCellValue(dob),
          TextCellValue(s['email']?.toString() ?? ''),
          TextCellValue(s['phoneNumber']?.toString() ?? ''),
          TextCellValue(s['address']?.toString() ?? ''),
          TextCellValue(active ? (t['active'] ?? 'Active') : (t['inactive'] ?? 'Inactive')),
        ]);
      }
      final bytes = workbook.encode()!;
      final date = DateTime.now().toIso8601String().split('T').first;
      final filename = 'students_$date.xlsx';
      final blob = html.Blob(
        [Uint8List.fromList(bytes)],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      _showSnack(filename);
    } catch (e) {
      _showSnack(t['save_failed'] ?? 'Export failed', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportChecked(Map<String, String> t) async {
    final selected = _filtered.where((s) => _checkedIds.contains(s['id'])).toList();
    if (selected.isEmpty || _exporting) return;
    setState(() => _exporting = true);
    try {
      final workbook = Excel.createExcel();
      workbook.rename('Sheet1', 'Students');
      final sheet = workbook['Students'];
      final headers = ['#', 'Code', 'First Name', 'Last Name', 'Gender',
          'Class', 'Date of Birth', 'Email', 'Phone', 'Address', 'Status'];
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
      for (var i = 0; i < selected.length; i++) {
        final s = selected[i];
        final dob = s['dateOfBirth'] != null
            ? (s['dateOfBirth'] as String).split('T').first : '';
        final active = s['status'] == true;
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(s['code']?.toString() ?? ''),
          TextCellValue(s['firstName']?.toString() ?? ''),
          TextCellValue(s['lastName']?.toString() ?? ''),
          TextCellValue(s['gender']?.toString() ?? ''),
          TextCellValue(s['className']?.toString() ?? ''),
          TextCellValue(dob),
          TextCellValue(s['email']?.toString() ?? ''),
          TextCellValue(s['phoneNumber']?.toString() ?? ''),
          TextCellValue(s['address']?.toString() ?? ''),
          TextCellValue(active ? (t['active'] ?? 'Active') : (t['inactive'] ?? 'Inactive')),
        ]);
      }
      final bytes = workbook.encode()!;
      final date = DateTime.now().toIso8601String().split('T').first;
      final filename = 'students_selected_$date.xlsx';
      final blob = html.Blob([Uint8List.fromList(bytes)],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      _showSnack(filename);
    } catch (_) {
      _showSnack(t['save_failed'] ?? 'Export failed', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteChecked(Map<String, String> t) async {
    if (_checkedIds.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t['confirm_delete'] ?? 'Confirm Delete'),
        content: Text(
          (t['confirm_delete_multiple'] ?? 'Total delete is {count}. Are you sure want to delete?')
              .replaceAll('{count}', '${_checkedIds.length}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t['cancel'] ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(t['delete'] ?? 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      for (final id in _checkedIds.toList()) {
        await _api.deleteStudent(id);
      }
      _checkedIds.clear();
      _showSnack(t['student_deleted'] ?? 'Students deleted');
      _load();
    } catch (_) {
      _showSnack(t['delete_failed'] ?? 'Delete failed', isError: true);
    }
  }

  void _toggleFilter() {
    if (_filterOverlay != null) {
      _filterOverlay!.remove();
      _filterOverlay = null;
      return;
    }

    final keyCtx = _searchBoxKey.currentContext;
    if (keyCtx == null) return;
    final box = keyCtx.findRenderObject() as RenderBox;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final width = box.size.width;
    final boxHeight = box.size.height;

    final locale = context.read<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uniqueClasses = _buildUniqueClasses();

    _filterOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Full-screen transparent barrier — closes panel on outside tap
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _filterOverlay?.remove();
                _filterOverlay = null;
              },
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          // Filter panel positioned below the search box
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
                  genderFilter: _genderFilter,
                  classFilter: _classFilter,
                  statusFilter: _statusFilter,
                  availableClasses: uniqueClasses,
                  t: t,
                  isDark: isDark,
                  onApply: (g, c, s) {
                    _filterOverlay?.remove();
                    _filterOverlay = null;
                    setState(() {
                      _genderFilter = g;
                      _classFilter = c;
                      _statusFilter = s;
                    });
                    _filter();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_filterOverlay!);
  }

  String _sortValue(Map<String, dynamic> s, String col) {
    switch (col) {
      case 'code':
        return s['code']?.toString().toLowerCase() ?? '';
      case 'name':
        return '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.toLowerCase();
      case 'dob':
        return s['dateOfBirth']?.toString() ?? '';
      case 'gender':
        return s['gender']?.toString().toLowerCase() ?? '';
      case 'class':
        return s['className']?.toString().toLowerCase() ?? '';
      case 'email':
        return s['email']?.toString().toLowerCase() ?? '';
      case 'address':
        return s['address']?.toString().toLowerCase() ?? '';
      case 'status':
        final st = s['status'];
        return st is bool ? (st ? 'active' : 'inactive') : (st?.toString().toLowerCase() ?? '');
      default:
        return '';
    }
  }

  void _sortBy(String col) {
    if (_sortColumn == col) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = col;
      _sortAscending = true;
    }
    _filter(resetPage: false);
  }

  void _showSnack(String msg, {bool isError = false, bool isWarning = false}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastNotification(
        message: msg,
        isError: isError,
        isWarning: isWarning,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  Future<void> _delete(Map<String, dynamic> s) async {
    final t = AppTranslations.translations[
        context.read<LocaleProvider>().locale] ?? AppTranslations.translations['en']!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t['confirm_delete'] ?? 'Confirm Delete'),
        content: Text(
            "${s['code'] ?? ''} - ${s['firstName']} ${s['lastName']}?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t['cancel'] ?? 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: Text(t['delete'] ?? 'Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _api.deleteStudent(s['id']);
        _showSnack(t['student_deleted'] ?? 'Student deleted');
        _load();
      } catch (_) {
        _showSnack(t['delete_failed'] ?? 'Delete failed', isError: true);
      }
    }
  }

  void _openStudentDetail(Map<String, dynamic> student) {
    final id = student['id'];
    setState(() {
      _selectedStudent = student;
      if (_checkedIds.contains(id)) {
        _checkedIds.remove(id);
      } else {
        _checkedIds.add(id);
      }
    });
  }

  void _openDetail(Map<String, dynamic> student) {
    setState(() {
      _selectedStudent = student;
      _detailStudent = student;
    });
  }

  void _closeDetail() {
    setState(() => _detailStudent = null);
  }

  void _openForm({Map<String, dynamic>? student}) {
    setState(() {
      _showForm = true;
      _formStudent = student;
      _detailStudent = null;
    });
  }

  void _closeForm() {
    setState(() {
      _showForm = false;
      _formStudent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;

    if (_showForm) {
      return StudentFormPanel(
        student: _formStudent,
        onCancel: _closeForm,
        onSave: (data) async {
          try {
            if (_formStudent == null) {
              await _api.createStudent(data);
              _showSnack(t['student_created'] ?? 'Student created!');
            } else {
              await _api.updateStudent(_formStudent!['id'], data);
              _showSnack(t['student_updated'] ?? 'Student updated!');
            }
            _closeForm();
            _load();
          } catch (_) {
            _showSnack(t['save_failed'] ?? 'Save failed', isError: true);
          }
        },
      );
    }

    if (_detailStudent != null) {
      return StudentDetailPanel(
        student: _detailStudent!,
        onBack: _closeDetail,
        onEdit: () => _openForm(student: _detailStudent),
        onDelete: () async {
          try {
            await _api.deleteStudent(_detailStudent!['id']);
            _showSnack(t['student_deleted'] ?? 'Student deleted');
            _closeDetail();
            _load();
          } catch (_) {
            _showSnack(t['delete_failed'] ?? 'Delete failed', isError: true);
          }
        },
      );
    }

    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;
    return _buildTableView(t, isMobile: isMobile, isTablet: isTablet);
  }

  Widget _buildTableView(Map<String, String> t,
      {bool isMobile = false, bool isTablet = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : AppColors.textPrimary;

    // ── Action callbacks ─────────────────────────────────────────
    void onAdd() => _openForm();
    void onEdit() {
      if (_selectedStudent != null) {
        _openForm(student: _selectedStudent);
      } else {
        _showSnack(t['select_row_first'] ?? 'Please select a row first', isWarning: true);
      }
    }
    void onDelete() {
      if (_checkedIds.isNotEmpty) {
        _deleteChecked(t);
      } else if (_selectedStudent != null) {
        _delete(_selectedStudent!);
      } else {
        _showSnack(t['select_row_first'] ?? 'Please select a row first', isWarning: true);
      }
    }

    // ── Toolbar ──────────────────────────────────────────────────
    final Widget toolbar;
    if (isMobile) {
      toolbar = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        KeyedSubtree(
          key: _searchBoxKey,
          child: _SearchBox(
            controller: _searchCtrl,
            hint: t['search'] ?? 'Searching...',
            fullWidth: true,
            onFilter: _toggleFilter,
            filterCount: _activeFilterCount,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            _AddButton(label: t['add'] ?? 'Add', onTap: onAdd),
            _EditButton(label: t['edit'] ?? 'Edit', onTap: onEdit),
            _DeleteButton(label: t['delete'] ?? 'Delete', onTap: onDelete),
            _ExportButton(
              label: t['export'] ?? 'Export',
              exporting: _exporting,
              onTap: _checkedIds.isNotEmpty
                  ? () => _exportChecked(t)
                  : (_filtered.isEmpty ? null : () => _exportStudents(t)),
              isDark: isDark,
            ),
          ],
        ),
      ]);
    } else {
      final btns = [
        _AddButton(label: t['add'] ?? 'Add', onTap: onAdd),
        const SizedBox(width: 8),
        _EditButton(label: t['edit'] ?? 'Edit', onTap: onEdit),
        const SizedBox(width: 8),
        _DeleteButton(label: t['delete'] ?? 'Delete', onTap: onDelete),
        const SizedBox(width: 8),
        _ExportButton(
          label: t['export'] ?? 'Export',
          exporting: _exporting,
          onTap: _checkedIds.isNotEmpty
              ? () => _exportChecked(t)
              : (_filtered.isEmpty ? null : () => _exportStudents(t)),
          isDark: isDark,
        ),
      ];
      toolbar = LayoutBuilder(
        builder: (_, constraints) {
          final searchBox = KeyedSubtree(
            key: _searchBoxKey,
            child: _SearchBox(
              controller: _searchCtrl,
              hint: t['search'] ?? 'Searching...',
              fullWidth: constraints.maxWidth <= 650,
              onFilter: _toggleFilter,
              filterCount: _activeFilterCount,
            ),
          );
          if (constraints.maxWidth > 650) {
            return Row(children: [
              searchBox,
              const Spacer(),
              ...btns,
            ]);
          }
          return Row(children: [
            Expanded(child: searchBox),
            const SizedBox(width: 10),
            ...btns,
          ]);
        },
      );
    }

    // ── Table header & rows by breakpoint ────────────────────────
    final Row tableHeader;
    List<Widget> Function(Map<String, dynamic> s, int globalIdx) buildCells;

    String dob(Map<String, dynamic> s) => s['dateOfBirth'] != null
        ? (s['dateOfBirth'] as String).substring(0, 10).replaceAll('-', '/')
        : '—';

    // Checkbox helpers
    final allPageChecked = _paginated.isNotEmpty &&
        _paginated.every((s) => _checkedIds.contains(s['id']));
    final anyPageChecked = _paginated.any((s) => _checkedIds.contains(s['id']));

    final fieldBg = isDark ? const Color(0xFF0D0D1C) : const Color(0xFFF2F3F7);
    final checkboxShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));

    WidgetStateBorderSide checkboxSide(bool active) =>
        WidgetStateBorderSide.resolveWith((_) => BorderSide(
          color: active ? AppColors.primary : textColor,
          width: 1.5,
        ));

    final headerActive = allPageChecked || anyPageChecked;
    final headerCheckbox = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32,
          child: Checkbox(
            tristate: true,
            value: allPageChecked ? true : (anyPageChecked ? null : false),
            onChanged: (v) => setState(() {
              if (v == true) {
                for (final s in _paginated) { _checkedIds.add(s['id']); }
              } else {
                for (final s in _paginated) { _checkedIds.remove(s['id']); }
              }
            }),
            fillColor: WidgetStateProperty.all(headerActive ? AppColors.primary : fieldBg),
            checkColor: Colors.white,
            shape: checkboxShape,
            side: checkboxSide(headerActive),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 10),
      ],
    );

    Widget rowCheckbox(Map<String, dynamic> s) {
      final checked = _checkedIds.contains(s['id']);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          if (checked) { _checkedIds.remove(s['id']); }
          else { _checkedIds.add(s['id']); }
        }),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              child: Checkbox(
                value: checked,
                onChanged: (v) => setState(() {
                  if (v == true) { _checkedIds.add(s['id']); }
                  else { _checkedIds.remove(s['id']); }
                }),
                fillColor: WidgetStateProperty.all(checked ? AppColors.primary : fieldBg),
                checkColor: Colors.white,
                shape: checkboxShape,
                side: checkboxSide(checked),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      );
    }

    if (isMobile) {
      tableHeader = Row(children: [
        headerCheckbox,
        const TableHeader(label: '#', flex: 1, textAlign: TextAlign.center),
        TableHeader(label: t['student_name'] ?? 'Name', flex: 4, onSort: () => _sortBy('name'), isSorted: _sortColumn == 'name', sortAscending: _sortAscending),
        TableHeader(label: t['class_name'] ?? 'Class', flex: 3, onSort: () => _sortBy('class'), isSorted: _sortColumn == 'class', sortAscending: _sortAscending),
        TableHeader(label: t['status'] ?? 'Status', flex: 2, onSort: () => _sortBy('status'), isSorted: _sortColumn == 'status', sortAscending: _sortAscending, textAlign: TextAlign.center),
      ]);
      buildCells = (s, idx) => [
        rowCheckbox(s),
        Expanded(flex: 1, child: Text('$idx', style: AppTextStyles.body.copyWith(color: textColor), textAlign: TextAlign.center)),
        Expanded(flex: 4, child: Text('${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim().isEmpty ? '—' : '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim(), style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 3, child: Text(s['className'] ?? '—', style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Center(child: _StatusBadge(status: s['status'] ?? 'Active'))),
      ];
    } else if (isTablet) {
      tableHeader = Row(children: [
        headerCheckbox,
        const TableHeader(label: '#', flex: 1, textAlign: TextAlign.center),
        TableHeader(label: t['student_name'] ?? 'Full Name', flex: 3, onSort: () => _sortBy('name'), isSorted: _sortColumn == 'name', sortAscending: _sortAscending),
        TableHeader(label: t['gender'] ?? 'Gender', flex: 2, onSort: () => _sortBy('gender'), isSorted: _sortColumn == 'gender', sortAscending: _sortAscending),
        TableHeader(label: t['class_name'] ?? 'Class', flex: 2, onSort: () => _sortBy('class'), isSorted: _sortColumn == 'class', sortAscending: _sortAscending),
        TableHeader(label: t['date_of_birth'] ?? 'DOB', flex: 2, onSort: () => _sortBy('dob'), isSorted: _sortColumn == 'dob', sortAscending: _sortAscending, textAlign: TextAlign.center),
        TableHeader(label: t['email'] ?? 'Email', flex: 3, onSort: () => _sortBy('email'), isSorted: _sortColumn == 'email', sortAscending: _sortAscending),
        TableHeader(label: t['status'] ?? 'Status', flex: 2, onSort: () => _sortBy('status'), isSorted: _sortColumn == 'status', sortAscending: _sortAscending, textAlign: TextAlign.center),
      ]);
      buildCells = (s, idx) {
        final name = '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
        return [
          rowCheckbox(s),
          Expanded(flex: 1, child: Text('$idx', style: AppTextStyles.body.copyWith(color: textColor), textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text(name.isEmpty ? '—' : name, style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(s['gender']?.toString() ?? '—', style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(s['className'] ?? '—', style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(dob(s), style: AppTextStyles.body.copyWith(color: textColor), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(s['email'] ?? '—', style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Center(child: _StatusBadge(status: s['status'] ?? 'Active'))),
        ];
      };
    } else {
      tableHeader = Row(children: [
        headerCheckbox,
        const TableHeader(label: '#', flex: 1, textAlign: TextAlign.center),
        TableHeader(label: t['code'] ?? 'Code', flex: 2, onSort: () => _sortBy('code'), isSorted: _sortColumn == 'code', sortAscending: _sortAscending),
        TableHeader(label: t['student_name'] ?? 'Full Name', flex: 3, onSort: () => _sortBy('name'), isSorted: _sortColumn == 'name', sortAscending: _sortAscending),
        TableHeader(label: t['gender'] ?? 'Gender', flex: 2, onSort: () => _sortBy('gender'), isSorted: _sortColumn == 'gender', sortAscending: _sortAscending),
        TableHeader(label: t['class_name'] ?? 'Class', flex: 2, onSort: () => _sortBy('class'), isSorted: _sortColumn == 'class', sortAscending: _sortAscending),
        TableHeader(label: t['date_of_birth'] ?? 'Date of Birth', flex: 3, onSort: () => _sortBy('dob'), isSorted: _sortColumn == 'dob', sortAscending: _sortAscending, textAlign: TextAlign.center),
        TableHeader(label: t['email'] ?? 'Email', flex: 3, onSort: () => _sortBy('email'), isSorted: _sortColumn == 'email', sortAscending: _sortAscending),
        TableHeader(label: t['address'] ?? 'Address', flex: 4, onSort: () => _sortBy('address'), isSorted: _sortColumn == 'address', sortAscending: _sortAscending),
        TableHeader(label: t['status'] ?? 'Status', flex: 2, onSort: () => _sortBy('status'), isSorted: _sortColumn == 'status', sortAscending: _sortAscending, textAlign: TextAlign.center),
      ]);
      buildCells = (s, idx) {
        final name = '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
        return [
          rowCheckbox(s),
          Expanded(flex: 1, child: Text('$idx', style: AppTextStyles.body.copyWith(color: textColor), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(s['code'] ?? s['studentCode'] ?? s['id']?.toString() ?? '—', style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(name.isEmpty ? '—' : name, style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(s['gender']?.toString() ?? '—', style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(s['className'] ?? '—', style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(dob(s), style: AppTextStyles.body.copyWith(color: textColor), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(s['email'] ?? '—', style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 4, child: Text(s['address'] ?? '—', style: AppTextStyles.body.copyWith(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Center(child: _StatusBadge(status: s['status'] ?? 'Active'))),
        ];
      };
    }

    return Padding(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          toolbar,
          const SizedBox(height: 12),
          Expanded(
            child: _TableCard(
              loading: _loading,
              empty: _filtered.isEmpty,
              emptyIcon: Icons.school_outlined,
              emptyLabel: t['no_data'] ?? 'No students found',
              header: tableHeader,
              body: ListView.builder(
                itemCount: _paginated.length,
                itemBuilder: (_, i) {
                  final s = _paginated[i];
                  final globalIdx = (_currentPage - 1) * _pageSize + i + 1;
                  return _TableRow(
                    index: i,
                    isSelected: (_selectedStudent != null &&
                        _selectedStudent!['id'] == s['id']) ||
                        _checkedIds.contains(s['id']),
                    onTap: () => _openStudentDetail(s),
                    onDoubleTap: () => _openDetail(s),
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
            selectedCount: _checkedIds.length,
            translations: t,
            onPageChanged: (p) => setState(() => _currentPage = p),
            onPageSizeChanged: (s) => setState(() {
              _pageSize = s;
              _currentPage = 1;
            }),
          ),
        ],
      ),
    );
  }
}

// ── Shared local helpers (not exported) ──────────────────────────────────────

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool fullWidth;
  final VoidCallback? onFilter;
  final int filterCount;

  const _SearchBox({
    required this.controller,
    required this.hint,
    this.fullWidth = false,
    this.onFilter,
    this.filterCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white70 : AppColors.textMuted;
    final hasFilter = onFilter != null;
    final activeFilter = filterCount > 0;

    return SizedBox(
      width: fullWidth ? double.infinity : 240,
      height: 42,
      child: TextField(
        controller: controller,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(color: mutedColor),
          prefixIcon: Icon(Icons.search, size: 18, color: mutedColor),
          suffixIcon: hasFilter
              ? _FilterIconSuffix(
                  onTap: onFilter!,
                  activeFilter: activeFilter,
                  filterCount: filterCount,
                  mutedColor: mutedColor,
                  isDark: isDark,
                )
              : null,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary)),
          filled: true,
          fillColor: bgColor,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        side: BorderSide(color: borderColor, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _EditButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        side: BorderSide(color: borderColor, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _DeleteButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.delete_outline, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        side: BorderSide(color: borderColor, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final bool exporting;
  final VoidCallback? onTap;
  final bool isDark;

  const _ExportButton({
    required this.label,
    required this.exporting,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    return OutlinedButton(
      onPressed: exporting ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        side: BorderSide(color: borderColor, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        overlayColor: AppColors.primaryLight.withValues(alpha: 0.08),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        exporting
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryLight))
            : const Icon(Icons.download_rounded, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ]),
    );
  }
}

class _FilterIconSuffix extends StatefulWidget {
  final VoidCallback onTap;
  final bool activeFilter;
  final int filterCount;
  final Color mutedColor;
  final bool isDark;

  const _FilterIconSuffix({
    required this.onTap,
    required this.activeFilter,
    required this.filterCount,
    required this.mutedColor,
    required this.isDark,
  });

  @override
  State<_FilterIconSuffix> createState() => _FilterIconSuffixState();
}

class _FilterIconSuffixState extends State<_FilterIconSuffix> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final hoverBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.0)
        : AppColors.primarySurface;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => WidgetsBinding.instance.addPostFrameCallback(
          (_) { if (mounted) setState(() => _hovering = true); }),
      onExit: (_) => WidgetsBinding.instance.addPostFrameCallback(
          (_) { if (mounted) setState(() => _hovering = false); }),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 0),
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: widget.activeFilter
                    ? AppColors.primary.withValues(alpha: 0.0)
                    : _hovering
                        ? hoverBg
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 18,
                color: widget.activeFilter
                    ? AppColors.primary
                    : _hovering
                        ? AppColors.primary
                        : widget.mutedColor,
              ),
            ),
            if (widget.activeFilter)
              Positioned(
                top: 6,
                right: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.filterCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final bool loading;
  final bool empty;
  final IconData emptyIcon;
  final String emptyLabel;
  final Widget header;
  final Widget body;
  const _TableCard({
    required this.loading,
    required this.empty,
    required this.emptyIcon,
    required this.emptyLabel,
    required this.header,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final mutedColor = isDark ? Colors.white70 : AppColors.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: header,
              ),
              if (empty)
                Expanded(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(emptyIcon, size: 48, color: mutedColor),
                      const SizedBox(height: 12),
                      Text(emptyLabel,
                          style: AppTextStyles.body.copyWith(color: mutedColor)),
                    ]),
                  ),
                )
              else
                Expanded(child: body),
            ]),
    );
  }
}

class _TableRow extends StatefulWidget {
  final List<Widget> children;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final bool isSelected;
  final int index;
  const _TableRow({
    required this.children,
    required this.index,
    this.onTap,
    this.onDoubleTap,
    this.isSelected = false,
  });

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEven = widget.index % 2 == 0;

    final baseColor = widget.isSelected
        ? AppColors.primary.withValues(alpha: 0.10)
        : isDark
            ? (isEven ? const Color(0xFF16213E) : const Color(0xFF1C2A4A))
            : (isEven ? Colors.white : const Color(0xFFF5F7FA));

    final hoverColor = AppColors.primary.withValues(alpha: 0.10);

    return Material(
      color: baseColor,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        borderRadius: BorderRadius.circular(4),
        hoverColor: hoverColor,
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(children: widget.children),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final dynamic status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = status is bool
        ? status as bool
        : status.toString().toLowerCase() == 'active';
    final statusStr = isActive ? (t['active'] ?? 'Active') : (t['inactive'] ?? 'Inactive');
    final color = isActive ? AppColors.primaryLight : AppColors.error;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      width: 88,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        statusStr,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.body.copyWith(color: color, fontSize: 14),
      ),
    );
  }
}

// ── Filter panel dialog ───────────────────────────────────────────────────────
class _FilterPanel extends StatefulWidget {
  final String genderFilter;
  final String classFilter;
  final String statusFilter;
  final List<String> availableClasses;
  final Map<String, String> t;
  final bool isDark;
  final void Function(String gender, String cls, String status) onApply;

  const _FilterPanel({
    required this.genderFilter,
    required this.classFilter,
    required this.statusFilter,
    required this.availableClasses,
    required this.t,
    required this.isDark,
    required this.onApply,
  });

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late String _gender;
  late String _cls;
  late String _status;

  @override
  void initState() {
    super.initState();
    _gender = widget.genderFilter;
    _cls = widget.classFilter;
    _status = widget.statusFilter;
  }

  Widget _section(String title, List<Widget> chips) {
    final isDark = widget.isDark;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTextStyles.label.copyWith(
                color: mutedColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget _chip(String label, String value, String current,
      void Function(String) onSelect) {
    final isDark = widget.isDark;
    final selected = current == value;
    return GestureDetector(
      onTap: () => setState(() => onSelect(value)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1C2A4A) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle_rounded,
                size: 14, color: AppColors.primary),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final t = widget.t;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final dividerColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;

    final genderChips = [
      _chip(t['all_genders'] ?? 'All', 'all', _gender, (v) => _gender = v),
      _chip(t['male'] ?? 'Male', 'Male', _gender, (v) => _gender = v),
      _chip(t['female'] ?? 'Female', 'Female', _gender, (v) => _gender = v),
    ];

    final classChips = [
      _chip(t['all_classes'] ?? 'All', 'all', _cls, (v) => _cls = v),
      ...widget.availableClasses
          .where((c) => c.isNotEmpty)
          .map((c) => _chip(c, c, _cls, (v) => _cls = v)),
    ];

    final statusChips = [
      _chip(t['all_status'] ?? 'All', 'all', _status, (v) => _status = v),
      _chip(t['active'] ?? 'Active', 'active', _status,
          (v) => _status = v),
      _chip(t['inactive'] ?? 'Inactive', 'inactive', _status,
          (v) => _status = v),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(children: [
              const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t['filter'] ?? 'Filter',
                    style: AppTextStyles.label.copyWith(
                        color: textColor, fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () => setState(
                    () { _gender = 'all'; _cls = 'all'; _status = 'all'; }),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero),
                child: Text(t['delete'] ?? 'Reset',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ]),
          ),
          Divider(height: 1, color: dividerColor),

          // Filter sections
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section(t['gender'] ?? 'Gender', genderChips),
                const SizedBox(height: 16),
                if (widget.availableClasses.isNotEmpty) ...[
                  _section(t['class_name'] ?? 'Class', classChips),
                  const SizedBox(height: 16),
                ],
                _section(t['status'] ?? 'Status', statusChips),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => widget.onApply(_gender, _cls, _status),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(t['confirm'] ?? 'Apply',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToastNotification extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isWarning;
  final VoidCallback onDismiss;
  const _ToastNotification({
    required this.message,
    required this.isError,
    required this.onDismiss,
    this.isWarning = false,
  });

  @override
  State<_ToastNotification> createState() => _ToastNotificationState();
}

class _ToastNotificationState extends State<_ToastNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.isError
        ? AppColors.error
        : widget.isWarning
            ? const Color(0xFFF59E0B)
            : AppColors.primary;
    final icon = widget.isError
        ? Icons.close
        : widget.isWarning
            ? Icons.warning_amber_rounded
            : Icons.check;
    final title = widget.isError
        ? (t['error'] ?? 'Error')
        : widget.isWarning
            ? (t['warning'] ?? 'Warning')
            : (t['success'] ?? 'Success');
    final bgColor = isDark ? const Color(0xFF1C2A4A) : AppColors.white;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final msgColor = isDark ? Colors.white60 : AppColors.textSecondary;
    final closeColor = isDark ? Colors.white54 : AppColors.textSecondary;

    return Positioned(
      top: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: color),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: AppTextStyles.heading3
                                  .copyWith(color: titleColor)),
                          const SizedBox(height: 2),
                          Text(widget.message,
                              style: AppTextStyles.body
                                  .copyWith(color: msgColor)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Icon(Icons.close, size: 20, color: closeColor),
                    ),
                  ]),
                ),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (_, __) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 1.0 - _progress.value,
                      child: Container(height: 4, color: color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaginationRow extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final int selectedCount;
  final Map<String, String> translations;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  const _PaginationRow({
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.selectedCount,
    required this.translations,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;

    final btnStyle = OutlinedButton.styleFrom(
      foregroundColor: textColor,
      backgroundColor: Colors.transparent,
      elevation: 0,
      minimumSize: const Size(44, 44),
      padding: EdgeInsets.zero,
      side: BorderSide(color: borderColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );

    final navRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(onPressed: currentPage > 1 ? () => onPageChanged(1) : null, style: btnStyle, child: const Icon(Icons.first_page, size: 18)),
        const SizedBox(width: 4),
        OutlinedButton(onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null, style: btnStyle, child: const Icon(Icons.chevron_left, size: 18)),
        const SizedBox(width: 8),
        Text('$currentPage ${translations['of'] ?? 'of'} $totalPages', style: AppTextStyles.body.copyWith(color: textColor)),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null, style: btnStyle, child: const Icon(Icons.chevron_right, size: 18)),
        const SizedBox(width: 4),
        OutlinedButton(onPressed: currentPage < totalPages ? () => onPageChanged(totalPages) : null, style: btnStyle, child: const Icon(Icons.last_page, size: 18)),
      ],
    );

    final showRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(translations['show'] ?? 'Show', style: AppTextStyles.body.copyWith(color: textColor)),
        const SizedBox(width: 8),
        Container(
          height: 38,
          width: 84,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(6)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: pageSize,
              isDense: true,
              style: AppTextStyles.body.copyWith(color: textColor),
              dropdownColor: bgColor,
              items: [25, 50, 100].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
              onChanged: (v) => onPageSizeChanged(v!),
            ),
          ),
        ),
      ],
    );

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
                Text(
                  '$selectedCount ${translations['selected'] ?? 'selected'}',
                  style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ]),
            ),
          ])
        : const SizedBox.shrink();

    return LayoutBuilder(
      builder: (_, constraints) {
        final fits = constraints.maxWidth >= 380;
        if (fits) {
          return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            navRow,
            const Spacer(),
            if (selectedCount > 0) ...[selectedBadge, const SizedBox(width: 16)],
            showRow,
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: navRow),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            selectedBadge,
            showRow,
          ]),
        ]);
      },
    );
  }
}

