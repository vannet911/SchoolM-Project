// lib/screens/class_subject.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/services/api_service.dart';
import 'package:schoolms_portal/utils/app_constants.dart';
import 'package:schoolms_portal/widgets/table_widgets.dart';

class ClassSubjectScreen extends StatefulWidget {
  const ClassSubjectScreen({super.key});

  @override
  State<ClassSubjectScreen> createState() => _ClassSubjectScreenState();
}

class _ClassSubjectScreenState extends State<ClassSubjectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final ApiService _api = ApiService();

  // ── Classes state ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _filteredClasses = [];
  bool _classLoading = true;
  final _classSearchCtrl = TextEditingController();
  Map<String, dynamic>? _selectedClass;
  Map<String, dynamic>? _detailClass;
  bool _showClassForm = false;
  Map<String, dynamic>? _formClass;
  String? _classSortColumn;
  bool _classSortAscending = true;
  int _classCurrentPage = 1;
  int _classPageSize = 25;

  int get _classTotalPages =>
      (_filteredClasses.length / _classPageSize).ceil().clamp(1, 999);
  List<Map<String, dynamic>> get _classPaginated {
    final start = (_classCurrentPage - 1) * _classPageSize;
    return _filteredClasses.skip(start).take(_classPageSize).toList();
  }

  // ── Subjects state ───────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _filteredSubjects = [];
  bool _subjectLoading = true;
  final _subjectSearchCtrl = TextEditingController();
  Map<String, dynamic>? _selectedSubject;
  Map<String, dynamic>? _detailSubject;
  bool _showSubjectForm = false;
  Map<String, dynamic>? _formSubject;
  String? _subjectSortColumn;
  bool _subjectSortAscending = true;
  int _subjectCurrentPage = 1;
  int _subjectPageSize = 25;

  int get _subjectTotalPages =>
      (_filteredSubjects.length / _subjectPageSize).ceil().clamp(1, 999);
  List<Map<String, dynamic>> get _subjectPaginated {
    final start = (_subjectCurrentPage - 1) * _subjectPageSize;
    return _filteredSubjects.skip(start).take(_subjectPageSize).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadClasses();
    _loadSubjects();
    _classSearchCtrl.addListener(_filterClasses);
    _subjectSearchCtrl.addListener(_filterSubjects);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _classSearchCtrl.removeListener(_filterClasses);
    _classSearchCtrl.dispose();
    _subjectSearchCtrl.removeListener(_filterSubjects);
    _subjectSearchCtrl.dispose();
    super.dispose();
  }

  // ── Classes data ─────────────────────────────────────────────────────────────

  Future<void> _loadClasses() async {
    setState(() => _classLoading = true);
    try {
      final data = await _api.getClasses();
      if (!mounted) return;
      setState(() {
        _classes = data.cast<Map<String, dynamic>>();
        _classLoading = false;
      });
      _filterClasses();
    } catch (e) {
      if (!mounted) return;
      setState(() => _classLoading = false);
      _showSnack('Failed to load classes', isError: true);
    }
  }

  void _filterClasses({bool resetPage = true}) {
    final q = _classSearchCtrl.text.toLowerCase();
    var list = q.isEmpty
        ? List<Map<String, dynamic>>.from(_classes)
        : _classes
            .where((c) =>
                '${c['code']} ${c['name']} ${c['description'] ?? ''}'
                    .toLowerCase()
                    .contains(q))
            .toList();
    if (_classSortColumn != null) {
      list.sort((a, b) {
        final av = _classSortValue(a, _classSortColumn!);
        final bv = _classSortValue(b, _classSortColumn!);
        return _classSortAscending ? av.compareTo(bv) : bv.compareTo(av);
      });
    }
    setState(() {
      _filteredClasses = list;
      if (resetPage) _classCurrentPage = 1;
    });
  }

  String _classSortValue(Map<String, dynamic> c, String col) {
    switch (col) {
      case 'code':
        return c['code']?.toString().toLowerCase() ?? '';
      case 'name':
        return c['name']?.toString().toLowerCase() ?? '';
      case 'description':
        return c['description']?.toString().toLowerCase() ?? '';
      case 'status':
        final st = c['status'];
        return st is bool
            ? (st ? 'active' : 'inactive')
            : (st?.toString().toLowerCase() ?? '');
      default:
        return '';
    }
  }

  void _sortClasses(String col) {
    if (_classSortColumn == col) {
      _classSortAscending = !_classSortAscending;
    } else {
      _classSortColumn = col;
      _classSortAscending = true;
    }
    _filterClasses(resetPage: false);
  }

  Future<void> _deleteClass(Map<String, dynamic> c) async {
    final t = AppTranslations.translations[
            context.read<LocaleProvider>().locale] ??
        AppTranslations.translations['en']!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t['confirm_delete'] ?? 'Confirm Delete'),
        content: Text('${c['code'] ?? ''} - ${c['name'] ?? ''}?'),
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
        await _api.deleteClass(c['id']);
        _showSnack('Class deleted');
        _loadClasses();
      } catch (_) {
        _showSnack(t['delete_failed'] ?? 'Delete failed', isError: true);
      }
    }
  }

  void _openClassDetail(Map<String, dynamic> c) =>
      setState(() => _selectedClass = c);

  void _openClassDetailPanel(Map<String, dynamic> c) =>
      setState(() { _selectedClass = c; _detailClass = c; });

  void _closeClassDetail() => setState(() => _detailClass = null);

  void _openClassForm({Map<String, dynamic>? item}) => setState(() {
        _showClassForm = true;
        _formClass = item;
        _detailClass = null;
      });

  void _closeClassForm() =>
      setState(() { _showClassForm = false; _formClass = null; });

  // ── Subjects data ─────────────────────────────────────────────────────────────

  Future<void> _loadSubjects() async {
    setState(() => _subjectLoading = true);
    try {
      final data = await _api.getSubjects();
      if (!mounted) return;
      setState(() {
        _subjects = data.cast<Map<String, dynamic>>();
        _subjectLoading = false;
      });
      _filterSubjects();
    } catch (e) {
      if (!mounted) return;
      setState(() => _subjectLoading = false);
      _showSnack('Failed to load subjects', isError: true);
    }
  }

  void _filterSubjects({bool resetPage = true}) {
    final q = _subjectSearchCtrl.text.toLowerCase();
    var list = q.isEmpty
        ? List<Map<String, dynamic>>.from(_subjects)
        : _subjects
            .where((s) =>
                '${s['code']} ${s['name']} ${s['description'] ?? ''}'
                    .toLowerCase()
                    .contains(q))
            .toList();
    if (_subjectSortColumn != null) {
      list.sort((a, b) {
        final av = _subjectSortValue(a, _subjectSortColumn!);
        final bv = _subjectSortValue(b, _subjectSortColumn!);
        return _subjectSortAscending ? av.compareTo(bv) : bv.compareTo(av);
      });
    }
    setState(() {
      _filteredSubjects = list;
      if (resetPage) _subjectCurrentPage = 1;
    });
  }

  String _subjectSortValue(Map<String, dynamic> s, String col) {
    switch (col) {
      case 'code':
        return s['code']?.toString().toLowerCase() ?? '';
      case 'name':
        return s['name']?.toString().toLowerCase() ?? '';
      case 'description':
        return s['description']?.toString().toLowerCase() ?? '';
      case 'status':
        final st = s['status'];
        return st is bool
            ? (st ? 'active' : 'inactive')
            : (st?.toString().toLowerCase() ?? '');
      default:
        return '';
    }
  }

  void _sortSubjects(String col) {
    if (_subjectSortColumn == col) {
      _subjectSortAscending = !_subjectSortAscending;
    } else {
      _subjectSortColumn = col;
      _subjectSortAscending = true;
    }
    _filterSubjects(resetPage: false);
  }

  Future<void> _deleteSubject(Map<String, dynamic> s) async {
    final t = AppTranslations.translations[
            context.read<LocaleProvider>().locale] ??
        AppTranslations.translations['en']!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t['confirm_delete'] ?? 'Confirm Delete'),
        content: Text('${s['code'] ?? ''} - ${s['name'] ?? ''}?'),
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
        await _api.deleteSubject(s['id']);
        _showSnack('Subject deleted');
        _loadSubjects();
      } catch (_) {
        _showSnack(t['delete_failed'] ?? 'Delete failed', isError: true);
      }
    }
  }

  void _openSubjectDetail(Map<String, dynamic> s) =>
      setState(() => _selectedSubject = s);

  void _openSubjectDetailPanel(Map<String, dynamic> s) =>
      setState(() { _selectedSubject = s; _detailSubject = s; });

  void _closeSubjectDetail() => setState(() => _detailSubject = null);

  void _openSubjectForm({Map<String, dynamic>? item}) => setState(() {
        _showSubjectForm = true;
        _formSubject = item;
        _detailSubject = null;
      });

  void _closeSubjectForm() =>
      setState(() { _showSubjectForm = false; _formSubject = null; });

  // ── Toast ─────────────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false, bool isWarning = false}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastNotification(
        message: msg,
        isError: isError,
        isWarning: isWarning,
        onDismiss: () { if (entry.mounted) entry.remove(); },
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;

    if (_showClassForm) {
      return _ClassFormPanel(
        item: _formClass,
        onCancel: _closeClassForm,
        onSave: (data) async {
          try {
            if (_formClass == null) {
              await _api.createClass(data);
              _showSnack('Class created!');
            } else {
              await _api.updateClass(_formClass!['id'], data);
              _showSnack('Class updated!');
            }
            _closeClassForm();
            _loadClasses();
          } catch (_) {
            _showSnack(t['save_failed'] ?? 'Save failed', isError: true);
          }
        },
      );
    }

    if (_detailClass != null) {
      return _ClassDetailPanel(
        item: _detailClass!,
        onBack: _closeClassDetail,
        onEdit: () => _openClassForm(item: _detailClass),
        onDelete: () async {
          try {
            await _api.deleteClass(_detailClass!['id']);
            _showSnack('Class deleted');
            _closeClassDetail();
            _loadClasses();
          } catch (_) {
            _showSnack(t['delete_failed'] ?? 'Delete failed', isError: true);
          }
        },
      );
    }

    if (_showSubjectForm) {
      return _SubjectFormPanel(
        item: _formSubject,
        onCancel: _closeSubjectForm,
        onSave: (data) async {
          try {
            if (_formSubject == null) {
              await _api.createSubject(data);
              _showSnack('Subject created!');
            } else {
              await _api.updateSubject(_formSubject!['id'], data);
              _showSnack('Subject updated!');
            }
            _closeSubjectForm();
            _loadSubjects();
          } catch (_) {
            _showSnack(t['save_failed'] ?? 'Save failed', isError: true);
          }
        },
      );
    }

    if (_detailSubject != null) {
      return _SubjectDetailPanel(
        item: _detailSubject!,
        onBack: _closeSubjectDetail,
        onEdit: () => _openSubjectForm(item: _detailSubject),
        onDelete: () async {
          try {
            await _api.deleteSubject(_detailSubject!['id']);
            _showSnack('Subject deleted');
            _closeSubjectDetail();
            _loadSubjects();
          } catch (_) {
            _showSnack(t['delete_failed'] ?? 'Delete failed', isError: true);
          }
        },
      );
    }

    return _buildTabView(t);
  }

  Widget _buildTabView(Map<String, String> t) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle:
                AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: t['classes'] ?? 'Classes'),
              Tab(text: t['subjects'] ?? 'Subjects'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildClassesTab(t),
                _buildSubjectsTab(t),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesTab(Map<String, String> t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : AppColors.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _SearchBox(
              controller: _classSearchCtrl,
              hint: t['search'] ?? 'Search...'),
          const Spacer(),
          _AddButton(label: t['add'] ?? 'Add', onTap: () => _openClassForm()),
          const SizedBox(width: 8),
          _EditButton(
            label: t['edit'] ?? 'Edit',
            onTap: () {
              if (_selectedClass != null) {
                _openClassForm(item: _selectedClass);
              } else {
                _showSnack(
                    t['select_row_first'] ?? 'Please select a row first',
                    isWarning: true);
              }
            },
          ),
          const SizedBox(width: 8),
          _DeleteButton(
            label: t['delete'] ?? 'Delete',
            onTap: () {
              if (_selectedClass != null) {
                _deleteClass(_selectedClass!);
              } else {
                _showSnack(
                    t['select_row_first'] ?? 'Please select a row first',
                    isWarning: true);
              }
            },
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: _TableCard(
            loading: _classLoading,
            empty: _filteredClasses.isEmpty,
            emptyIcon: Icons.class_outlined,
            emptyLabel: t['no_data'] ?? 'No classes found',
            header: Row(children: [
              const TableHeader(label: '#', flex: 1),
              TableHeader(
                label: t['code'] ?? 'Code',
                flex: 2,
                onSort: () => _sortClasses('code'),
                isSorted: _classSortColumn == 'code',
                sortAscending: _classSortAscending,
              ),
              TableHeader(
                label: t['class_name'] ?? 'Class Name',
                flex: 3,
                onSort: () => _sortClasses('name'),
                isSorted: _classSortColumn == 'name',
                sortAscending: _classSortAscending,
              ),
              TableHeader(
                label: t['description'] ?? 'Description',
                flex: 4,
                onSort: () => _sortClasses('description'),
                isSorted: _classSortColumn == 'description',
                sortAscending: _classSortAscending,
              ),
              TableHeader(
                label: t['status'] ?? 'Status',
                flex: 1,
                onSort: () => _sortClasses('status'),
                isSorted: _classSortColumn == 'status',
                sortAscending: _classSortAscending,
                textAlign: TextAlign.center,
              ),
            ]),
            body: ListView.builder(
              itemCount: _classPaginated.length,
              itemBuilder: (_, i) {
                final c = _classPaginated[i];
                final globalIndex =
                    (_classCurrentPage - 1) * _classPageSize + i;
                return _TableRow(
                  index: i,
                  isSelected: _selectedClass != null &&
                      _selectedClass!['id'] == c['id'],
                  onTap: () => _openClassDetail(c),
                  onDoubleTap: () => _openClassDetailPanel(c),
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        (globalIndex + 1).toString(),
                        style: AppTextStyles.body.copyWith(color: textColor),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        c['code'] ?? '—',
                        style: AppTextStyles.body.copyWith(color: textColor),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        c['name'] ?? '—',
                        style: AppTextStyles.body.copyWith(color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        c['description'] ?? '—',
                        style: AppTextStyles.body.copyWith(color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: _StatusBadge(status: c['status'] ?? true),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _PaginationRow(
          currentPage: _classCurrentPage,
          totalPages: _classTotalPages,
          pageSize: _classPageSize,
          translations: t,
          onPageChanged: (p) => setState(() => _classCurrentPage = p),
          onPageSizeChanged: (s) => setState(() {
            _classPageSize = s;
            _classCurrentPage = 1;
          }),
        ),
      ],
    );
  }

  Widget _buildSubjectsTab(Map<String, String> t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : AppColors.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _SearchBox(
              controller: _subjectSearchCtrl,
              hint: t['search'] ?? 'Search...'),
          const Spacer(),
          _AddButton(
              label: t['add'] ?? 'Add', onTap: () => _openSubjectForm()),
          const SizedBox(width: 8),
          _EditButton(
            label: t['edit'] ?? 'Edit',
            onTap: () {
              if (_selectedSubject != null) {
                _openSubjectForm(item: _selectedSubject);
              } else {
                _showSnack(
                    t['select_row_first'] ?? 'Please select a row first',
                    isWarning: true);
              }
            },
          ),
          const SizedBox(width: 8),
          _DeleteButton(
            label: t['delete'] ?? 'Delete',
            onTap: () {
              if (_selectedSubject != null) {
                _deleteSubject(_selectedSubject!);
              } else {
                _showSnack(
                    t['select_row_first'] ?? 'Please select a row first',
                    isWarning: true);
              }
            },
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: _TableCard(
            loading: _subjectLoading,
            empty: _filteredSubjects.isEmpty,
            emptyIcon: Icons.book_outlined,
            emptyLabel: t['no_data'] ?? 'No subjects found',
            header: Row(children: [
              const TableHeader(label: '#', flex: 1),
              TableHeader(
                label: t['code'] ?? 'Code',
                flex: 2,
                onSort: () => _sortSubjects('code'),
                isSorted: _subjectSortColumn == 'code',
                sortAscending: _subjectSortAscending,
              ),
              TableHeader(
                label: t['subject_name'] ?? 'Subject Name',
                flex: 3,
                onSort: () => _sortSubjects('name'),
                isSorted: _subjectSortColumn == 'name',
                sortAscending: _subjectSortAscending,
              ),
              TableHeader(
                label: t['description'] ?? 'Description',
                flex: 4,
                onSort: () => _sortSubjects('description'),
                isSorted: _subjectSortColumn == 'description',
                sortAscending: _subjectSortAscending,
              ),
              TableHeader(
                label: t['status'] ?? 'Status',
                flex: 1,
                onSort: () => _sortSubjects('status'),
                isSorted: _subjectSortColumn == 'status',
                sortAscending: _subjectSortAscending,
                textAlign: TextAlign.center,
              ),
            ]),
            body: ListView.builder(
              itemCount: _subjectPaginated.length,
              itemBuilder: (_, i) {
                final s = _subjectPaginated[i];
                final globalIndex =
                    (_subjectCurrentPage - 1) * _subjectPageSize + i;
                return _TableRow(
                  index: i,
                  isSelected: _selectedSubject != null &&
                      _selectedSubject!['id'] == s['id'],
                  onTap: () => _openSubjectDetail(s),
                  onDoubleTap: () => _openSubjectDetailPanel(s),
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        (globalIndex + 1).toString(),
                        style: AppTextStyles.body.copyWith(color: textColor),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        s['code'] ?? '—',
                        style: AppTextStyles.body.copyWith(color: textColor),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        s['name'] ?? '—',
                        style: AppTextStyles.body.copyWith(color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        s['description'] ?? '—',
                        style: AppTextStyles.body.copyWith(color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: _StatusBadge(status: s['status'] ?? true),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _PaginationRow(
          currentPage: _subjectCurrentPage,
          totalPages: _subjectTotalPages,
          pageSize: _subjectPageSize,
          translations: t,
          onPageChanged: (p) => setState(() => _subjectCurrentPage = p),
          onPageSizeChanged: (s) => setState(() {
            _subjectPageSize = s;
            _subjectCurrentPage = 1;
          }),
        ),
      ],
    );
  }
}

// ── Shared local helpers ──────────────────────────────────────────────────────

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _SearchBox({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white70 : AppColors.textMuted;

    return SizedBox(
      width: 240,
      height: 42,
      child: TextField(
        controller: controller,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(color: mutedColor),
          prefixIcon: Icon(Icons.search, size: 18, color: mutedColor),
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
                    horizontal: 16, vertical: 12),
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
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEven = widget.index % 2 == 0;
    Color rowColor;
    if (widget.isSelected) {
      rowColor = AppColors.primary.withValues(alpha: 0.10);
    } else if (_isHovering) {
      rowColor =
          isDark ? const Color(0xFF1E2D50) : AppColors.primarySurface;
    } else if (isDark) {
      rowColor = isEven
          ? const Color(0xFF16213E)
          : const Color(0xFF1C2A4A);
    } else {
      rowColor = isEven ? Colors.white : const Color(0xFFF5F7FA);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: rowColor,
            borderRadius: BorderRadius.circular(4),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        statusStr,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(color: color),
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
  final Map<String, String> translations;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  const _PaginationRow({
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
          style: btnStyle,
          child: const Icon(Icons.first_page, size: 18),
        ),
        const SizedBox(width: 4),
        OutlinedButton(
          onPressed:
              currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          style: btnStyle,
          child: const Icon(Icons.chevron_left, size: 18),
        ),
        const SizedBox(width: 8),
        Text(
          '$currentPage ${translations['of'] ?? 'of'} $totalPages',
          style: AppTextStyles.body.copyWith(color: textColor),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
          style: btnStyle,
          child: const Icon(Icons.chevron_right, size: 18),
        ),
        const SizedBox(width: 4),
        OutlinedButton(
          onPressed: currentPage < totalPages
              ? () => onPageChanged(totalPages)
              : null,
          style: btnStyle,
          child: const Icon(Icons.last_page, size: 18),
        ),
        const Spacer(),
        Text(translations['show'] ?? 'Show',
            style: AppTextStyles.body.copyWith(color: textColor)),
        const SizedBox(width: 8),
        Container(
          height: 38,
          width: 84,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: pageSize,
              isDense: true,
              style: AppTextStyles.body.copyWith(color: textColor),
              dropdownColor: bgColor,
              items: [25, 50, 100]
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (v) => onPageSizeChanged(v!),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Class form panel ──────────────────────────────────────────────────────────

class _ClassFormPanel extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;
  const _ClassFormPanel(
      {this.item, required this.onSave, required this.onCancel});

  @override
  State<_ClassFormPanel> createState() => _ClassFormPanelState();
}

class _ClassFormPanelState extends State<_ClassFormPanel> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  bool _status = true;
  bool _saving = false;
  bool _codeError = false;
  bool _nameError = false;
  List<int> _selectedSubjectIds = [];
  List<Map<String, dynamic>> _availableSubjects = [];
  bool _loadingSubjects = false;

  @override
  void initState() {
    super.initState();
    final s = widget.item;
    if (s != null) {
      _codeCtrl.text = s['code'] ?? '';
      _nameCtrl.text = s['name'] ?? '';
      _descCtrl.text = s['description'] ?? '';
      _gradeCtrl.text = s['gradeLevel']?.toString() ?? '';
      final st = s['status'];
      _status = st is bool ? st : true;
      final existing = s['subjects'] as List?;
      if (existing != null) {
        _selectedSubjectIds = existing.map<int>((sub) => sub['id'] as int).toList();
      }
    }
    _loadSubjects();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _gradeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() => _loadingSubjects = true);
    try {
      final data = await ApiService().getSubjects();
      if (!mounted) return;
      setState(() {
        _availableSubjects = data.cast<Map<String, dynamic>>();
        _loadingSubjects = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSubjects = false);
    }
  }

  Future<void> _showSubjectPicker() async {
    final picked = List<int>.from(_selectedSubjectIds);
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Select Subjects'),
          content: SizedBox(
            width: 320,
            child: _availableSubjects.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    shrinkWrap: true,
                    children: _availableSubjects.map((sub) {
                      final id = sub['id'] as int;
                      return CheckboxListTile(
                        value: picked.contains(id),
                        title: Text('${sub['code']} - ${sub['name']}'),
                        onChanged: (v) => setDialogState(() {
                          v == true ? picked.add(id) : picked.remove(id);
                        }),
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedSubjectIds = picked);
                Navigator.pop(ctx);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final codeEmpty = _codeCtrl.text.trim().isEmpty;
    final nameEmpty = _nameCtrl.text.trim().isEmpty;
    if (codeEmpty || nameEmpty) {
      setState(() { _codeError = codeEmpty; _nameError = nameEmpty; });
      return;
    }
    setState(() { _saving = true; _codeError = false; _nameError = false; });
    try {
      await widget.onSave({
        'code': _codeCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'gradeLevel': int.tryParse(_gradeCtrl.text.trim()),
        'status': _status,
        'subjectIds': _selectedSubjectIds,
        'createDate': DateTime.now().toUtc().toIso8601String(),
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDecoration(
      {String? hint,
      bool multiline = false,
      bool isDark = false,
      bool hasError = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body
          .copyWith(color: isDark ? Colors.white70 : AppColors.textMuted),
      enabledBorder: hasError
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error))
          : null,
      focusedBorder: hasError
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.5))
          : null,
      contentPadding: EdgeInsets.symmetric(
          horizontal: 12, vertical: multiline ? 16 : 0),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _requiredLabeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text: label,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
            TextSpan(
                text: ' *',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.error)),
          ]),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ??
        AppTranslations.translations['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final isEdit = widget.item != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Row(children: [
            SizedBox(
              width: 38,
              height: 38,
              child: InkWell(
                onTap: widget.onCancel,
                borderRadius: BorderRadius.circular(18),
                child: const Center(
                  child: Icon(Icons.chevron_left,
                      size: 24, color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEdit
                  ? (t['edit_class'] ?? 'Edit Class')
                  : (t['add_class'] ?? 'Add Class'),
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check, size: 18),
              label: Text(t['save'] ?? 'Save'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 18),
                side: BorderSide(
                    color: isDark
                        ? const Color(0xFF2A2A4A)
                        : AppColors.border,
                    width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _requiredLabeled(
                              '${t['code'] ?? 'Code'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _codeCtrl,
                                  style: AppTextStyles.body
                                      .copyWith(color: textColor),
                                  decoration: _inputDecoration(
                                      hint: 'Code',
                                      isDark: isDark,
                                      hasError: _codeError),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _requiredLabeled(
                              '${t['class_name'] ?? 'Class Name'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _nameCtrl,
                                  style: AppTextStyles.body
                                      .copyWith(color: textColor),
                                  decoration: _inputDecoration(
                                      hint: t['class_name'] ?? 'Class name',
                                      isDark: isDark,
                                      hasError: _nameError),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['description'] ?? 'Description'}:',
                              TextField(
                                controller: _descCtrl,
                                maxLines: 4,
                                style: AppTextStyles.body
                                    .copyWith(color: textColor),
                                decoration: _inputDecoration(
                                    hint: 'Enter description',
                                    multiline: true,
                                    isDark: isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labeled(
                              '${t['grade_level'] ?? 'Grade Level'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _gradeCtrl,
                                  keyboardType: TextInputType.number,
                                  style: AppTextStyles.body
                                      .copyWith(color: textColor),
                                  decoration: _inputDecoration(
                                      hint: 'e.g. 10',
                                      isDark: isDark),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['subjects'] ?? 'Subjects'}:',
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _loadingSubjects ? null : _showSubjectPicker,
                                    icon: const Icon(Icons.book_outlined, size: 16),
                                    label: Text(_selectedSubjectIds.isEmpty
                                        ? 'Select subjects'
                                        : '${_selectedSubjectIds.length} selected'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryLight,
                                      side: BorderSide(
                                          color: isDark ? const Color(0xFF2A2A4A) : AppColors.border),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  if (_selectedSubjectIds.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: _availableSubjects
                                          .where((sub) => _selectedSubjectIds.contains(sub['id']))
                                          .map((sub) => Chip(
                                                label: Text(sub['name'] as String,
                                                    style: AppTextStyles.bodySmall),
                                                deleteIcon: const Icon(Icons.close, size: 14),
                                                onDeleted: () => setState(() =>
                                                    _selectedSubjectIds.remove(sub['id'] as int)),
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize.shrinkWrap,
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['status'] ?? 'Status'}:',
                              Row(children: [
                                Switch(
                                  value: _status,
                                  onChanged: (v) =>
                                      setState(() => _status = v),
                                  activeThumbColor: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _status
                                      ? (t['active'] ?? 'Active')
                                      : (t['inactive'] ?? 'Inactive'),
                                  style: AppTextStyles.bodySmall,
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Class detail panel ────────────────────────────────────────────────────────

class _ClassDetailPanel extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _ClassDetailPanel(
      {required this.item,
      required this.onBack,
      this.onEdit,
      this.onDelete});

  InputDecoration _inputDecoration(
      {String? hint, bool multiline = false, bool isDark = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body
          .copyWith(color: isDark ? Colors.white70 : AppColors.textMuted),
      contentPadding: EdgeInsets.symmetric(
          horizontal: 12, vertical: multiline ? 16 : 0),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _readField(String label, String? value,
      {bool isDark = false}) {
    return _labeled(
      label,
      SizedBox(
        height: 44,
        child: TextField(
          readOnly: true,
          controller: TextEditingController(text: value ?? ''),
          style: AppTextStyles.body.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: _inputDecoration(hint: '—', isDark: isDark),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ??
        AppTranslations.translations['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusRaw = item['status'];
    final isActive = statusRaw is bool
        ? statusRaw
        : (statusRaw?.toString().toLowerCase() == 'active');
    final statusLabel =
        isActive ? (t['active'] ?? 'Active') : (t['inactive'] ?? 'Inactive');
    final statusColor = isActive ? AppColors.success : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Row(children: [
            SizedBox(
              width: 38,
              height: 38,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(18),
                child: const Center(
                  child: Icon(Icons.chevron_left,
                      size: 24, color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              item['code']?.toString() ?? 'CL000',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(t['edit'] ?? 'Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 18),
                side: BorderSide(
                    color: isDark
                        ? const Color(0xFF2A2A4A)
                        : AppColors.border,
                    width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onDelete == null
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(
                              t['confirm_delete'] ?? 'Confirm Delete'),
                          content: Text(
                              '${item['code'] ?? ''} - ${item['name'] ?? ''}?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: Text(t['cancel'] ?? 'Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white),
                              child: Text(t['delete'] ?? 'Delete'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) onDelete!();
                    },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(t['delete'] ?? 'Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 18),
                side: BorderSide(
                    color: isDark
                        ? const Color(0xFF2A2A4A)
                        : AppColors.border,
                    width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _readField('${t['code'] ?? 'Code'}:',
                                item['code']?.toString(),
                                isDark: isDark),
                            const SizedBox(height: 16),
                            _readField(
                                '${t['class_name'] ?? 'Class Name'}:',
                                item['name']?.toString(),
                                isDark: isDark),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['description'] ?? 'Description'}:',
                              TextField(
                                readOnly: true,
                                controller: TextEditingController(
                                    text:
                                        item['description']?.toString() ??
                                            ''),
                                maxLines: 4,
                                style: AppTextStyles.body.copyWith(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary),
                                decoration: _inputDecoration(
                                    hint: '—',
                                    multiline: true,
                                    isDark: isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _readField(
                                '${t['grade_level'] ?? 'Grade Level'}:',
                                item['gradeLevel']?.toString(),
                                isDark: isDark),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['subjects'] ?? 'Subjects'}:',
                              Builder(builder: (_) {
                                final subjects = item['subjects'] as List?;
                                if (subjects == null || subjects.isEmpty) {
                                  return Text('—',
                                      style: AppTextStyles.body.copyWith(
                                          color: isDark ? Colors.white70 : AppColors.textMuted));
                                }
                                return Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: subjects
                                      .map((sub) => Chip(
                                            label: Text(sub['name'] as String,
                                                style: AppTextStyles.bodySmall),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ))
                                      .toList(),
                                );
                              }),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['status'] ?? 'Status'}:',
                              Row(children: [
                                Switch(
                                  value: isActive,
                                  onChanged: null,
                                  activeThumbColor: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(statusLabel,
                                    style: AppTextStyles.body
                                        .copyWith(color: statusColor)),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Subject form panel ────────────────────────────────────────────────────────

class _SubjectFormPanel extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;
  const _SubjectFormPanel(
      {this.item, required this.onSave, required this.onCancel});

  @override
  State<_SubjectFormPanel> createState() => _SubjectFormPanelState();
}

class _SubjectFormPanelState extends State<_SubjectFormPanel> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _status = true;
  bool _saving = false;
  bool _codeError = false;
  bool _nameError = false;

  @override
  void initState() {
    super.initState();
    final s = widget.item;
    if (s != null) {
      _codeCtrl.text = s['code'] ?? '';
      _nameCtrl.text = s['name'] ?? '';
      _descCtrl.text = s['description'] ?? '';
      final st = s['status'];
      _status = st is bool ? st : true;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final codeEmpty = _codeCtrl.text.trim().isEmpty;
    final nameEmpty = _nameCtrl.text.trim().isEmpty;
    if (codeEmpty || nameEmpty) {
      setState(() { _codeError = codeEmpty; _nameError = nameEmpty; });
      return;
    }
    setState(() { _saving = true; _codeError = false; _nameError = false; });
    try {
      await widget.onSave({
        'code': _codeCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'status': _status,
        'createDate': DateTime.now().toUtc().toIso8601String(),
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDecoration(
      {String? hint,
      bool multiline = false,
      bool isDark = false,
      bool hasError = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body
          .copyWith(color: isDark ? Colors.white70 : AppColors.textMuted),
      enabledBorder: hasError
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error))
          : null,
      focusedBorder: hasError
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.5))
          : null,
      contentPadding: EdgeInsets.symmetric(
          horizontal: 12, vertical: multiline ? 16 : 0),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _requiredLabeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text: label,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
            TextSpan(
                text: ' *',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.error)),
          ]),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ??
        AppTranslations.translations['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final isEdit = widget.item != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Row(children: [
            SizedBox(
              width: 38,
              height: 38,
              child: InkWell(
                onTap: widget.onCancel,
                borderRadius: BorderRadius.circular(18),
                child: const Center(
                  child: Icon(Icons.chevron_left,
                      size: 24, color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEdit
                  ? (t['edit_subject'] ?? 'Edit Subject')
                  : (t['add_subject'] ?? 'Add Subject'),
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check, size: 18),
              label: Text(t['save'] ?? 'Save'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 18),
                side: BorderSide(
                    color: isDark
                        ? const Color(0xFF2A2A4A)
                        : AppColors.border,
                    width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _requiredLabeled(
                              '${t['code'] ?? 'Code'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _codeCtrl,
                                  style: AppTextStyles.body
                                      .copyWith(color: textColor),
                                  decoration: _inputDecoration(
                                      hint: 'Code',
                                      isDark: isDark,
                                      hasError: _codeError),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _requiredLabeled(
                              '${t['subject_name'] ?? 'Subject Name'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _nameCtrl,
                                  style: AppTextStyles.body
                                      .copyWith(color: textColor),
                                  decoration: _inputDecoration(
                                      hint: t['subject_name'] ??
                                          'Subject name',
                                      isDark: isDark,
                                      hasError: _nameError),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labeled(
                              '${t['description'] ?? 'Description'}:',
                              TextField(
                                controller: _descCtrl,
                                maxLines: 4,
                                style: AppTextStyles.body
                                    .copyWith(color: textColor),
                                decoration: _inputDecoration(
                                    hint: 'Enter description',
                                    multiline: true,
                                    isDark: isDark),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['status'] ?? 'Status'}:',
                              Row(children: [
                                Switch(
                                  value: _status,
                                  onChanged: (v) =>
                                      setState(() => _status = v),
                                  activeThumbColor: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _status
                                      ? (t['active'] ?? 'Active')
                                      : (t['inactive'] ?? 'Inactive'),
                                  style: AppTextStyles.bodySmall,
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Subject detail panel ──────────────────────────────────────────────────────

class _SubjectDetailPanel extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _SubjectDetailPanel(
      {required this.item,
      required this.onBack,
      this.onEdit,
      this.onDelete});

  InputDecoration _inputDecoration(
      {String? hint, bool multiline = false, bool isDark = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body
          .copyWith(color: isDark ? Colors.white70 : AppColors.textMuted),
      contentPadding: EdgeInsets.symmetric(
          horizontal: 12, vertical: multiline ? 16 : 0),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _readField(String label, String? value,
      {bool isDark = false}) {
    return _labeled(
      label,
      SizedBox(
        height: 44,
        child: TextField(
          readOnly: true,
          controller: TextEditingController(text: value ?? ''),
          style: AppTextStyles.body.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: _inputDecoration(hint: '—', isDark: isDark),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ??
        AppTranslations.translations['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusRaw = item['status'];
    final isActive = statusRaw is bool
        ? statusRaw
        : (statusRaw?.toString().toLowerCase() == 'active');
    final statusLabel =
        isActive ? (t['active'] ?? 'Active') : (t['inactive'] ?? 'Inactive');
    final statusColor = isActive ? AppColors.success : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Row(children: [
            SizedBox(
              width: 38,
              height: 38,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(18),
                child: const Center(
                  child: Icon(Icons.chevron_left,
                      size: 24, color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              item['code']?.toString() ?? 'SB000',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(t['edit'] ?? 'Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 18),
                side: BorderSide(
                    color: isDark
                        ? const Color(0xFF2A2A4A)
                        : AppColors.border,
                    width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onDelete == null
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(
                              t['confirm_delete'] ?? 'Confirm Delete'),
                          content: Text(
                              '${item['code'] ?? ''} - ${item['name'] ?? ''}?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: Text(t['cancel'] ?? 'Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white),
                              child: Text(t['delete'] ?? 'Delete'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) onDelete!();
                    },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(t['delete'] ?? 'Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 18),
                side: BorderSide(
                    color: isDark
                        ? const Color(0xFF2A2A4A)
                        : AppColors.border,
                    width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _readField('${t['code'] ?? 'Code'}:',
                                item['code']?.toString(),
                                isDark: isDark),
                            const SizedBox(height: 16),
                            _readField(
                                '${t['subject_name'] ?? 'Subject Name'}:',
                                item['name']?.toString(),
                                isDark: isDark),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labeled(
                              '${t['description'] ?? 'Description'}:',
                              TextField(
                                readOnly: true,
                                controller: TextEditingController(
                                    text:
                                        item['description']?.toString() ??
                                            ''),
                                maxLines: 4,
                                style: AppTextStyles.body.copyWith(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary),
                                decoration: _inputDecoration(
                                    hint: '—',
                                    multiline: true,
                                    isDark: isDark),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['status'] ?? 'Status'}:',
                              Row(children: [
                                Switch(
                                  value: isActive,
                                  onChanged: null,
                                  activeThumbColor: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(statusLabel,
                                    style: AppTextStyles.body
                                        .copyWith(color: statusColor)),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
