// lib/screens/teachers.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/services/api_service.dart';
import 'package:schoolms_portal/utils/app_constants.dart';
import 'package:schoolms_portal/widgets/table_widgets.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  Map<String, dynamic>? _selectedTeacher;
  Map<String, dynamic>? _detailTeacher;
  bool _showForm = false;
  Map<String, dynamic>? _formTeacher;
  String? _sortColumn;
  bool _sortAscending = true;
  int _currentPage = 1;
  int _pageSize = 25;

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
      final data = await _api.getTeachers();
      if (!mounted) return;
      setState(() {
        _teachers = data.cast<Map<String, dynamic>>();
        _loading = false;
      });
      _filter();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final t = AppTranslations.translations[
              context.read<LocaleProvider>().locale] ??
          AppTranslations.translations['en']!;
      _showSnack(t['failed_load'] ?? 'Failed to load teachers', isError: true);
    }
  }

  void _filter({bool resetPage = true}) {
    final q = _searchCtrl.text.toLowerCase();
    var list = q.isEmpty
        ? List<Map<String, dynamic>>.from(_teachers)
        : _teachers
            .where((s) =>
                '${s['name']} ${s['code']} ${s['email']} ${(s['subjects'] as List?)?.map((sub) => sub['name']).join(' ') ?? ''}'
                    .toLowerCase()
                    .contains(q))
            .toList();
    if (_sortColumn != null) {
      list.sort((a, b) {
        final av = _sortValue(a, _sortColumn!);
        final bv = _sortValue(b, _sortColumn!);
        return _sortAscending ? av.compareTo(bv) : bv.compareTo(av);
      });
    }
    setState(() {
      _filtered = list;
      if (resetPage) _currentPage = 1;
    });
  }

  String _sortValue(Map<String, dynamic> s, String col) {
    switch (col) {
      case 'code':
        return s['code']?.toString().toLowerCase() ?? '';
      case 'name':
        return s['name']?.toString().toLowerCase() ?? '';
      case 'subject':
        return (s['subjects'] as List?)?.map((sub) => sub['name'] as String).join(', ').toLowerCase() ?? '';
      case 'email':
        return s['email']?.toString().toLowerCase() ?? '';
      case 'address':
        return s['address']?.toString().toLowerCase() ?? '';
      case 'status':
        final st = s['status'];
        return st is bool
            ? (st ? 'active' : 'inactive')
            : (st?.toString().toLowerCase() ?? '');
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
            context.read<LocaleProvider>().locale] ??
        AppTranslations.translations['en']!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t['confirm_delete'] ?? 'Confirm Delete'),
        content: Text("${s['code'] ?? ''} - ${s['name'] ?? ''}?"),
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
        await _api.deleteTeacher(s['id']);
        _showSnack(t['teacher_deleted'] ?? 'Teacher deleted');
        _load();
      } catch (_) {
        _showSnack(t['delete_failed'] ?? 'Delete failed', isError: true);
      }
    }
  }

  void _openTeacherDetail(Map<String, dynamic> teacher) {
    setState(() => _selectedTeacher = teacher);
  }

  void _openDetail(Map<String, dynamic> teacher) {
    setState(() {
      _selectedTeacher = teacher;
      _detailTeacher = teacher;
    });
  }

  void _closeDetail() {
    setState(() => _detailTeacher = null);
  }

  void _openForm({Map<String, dynamic>? teacher}) {
    setState(() {
      _showForm = true;
      _formTeacher = teacher;
      _detailTeacher = null;
    });
  }

  void _closeForm() {
    setState(() {
      _showForm = false;
      _formTeacher = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;

    if (_showForm) {
      return TeacherFormPanel(
        teacher: _formTeacher,
        onCancel: _closeForm,
        onSave: (data) async {
          try {
            if (_formTeacher == null) {
              await _api.createTeacher(data);
              _showSnack(t['teacher_created'] ?? 'Teacher created!');
            } else {
              await _api.updateTeacher(_formTeacher!['id'], data);
              _showSnack(t['teacher_updated'] ?? 'Teacher updated!');
            }
            _closeForm();
            await _load();
          } catch (_) {
            _showSnack(t['save_failed'] ?? 'Save failed', isError: true);
          }
        },
      );
    }

    if (_detailTeacher != null) {
      return TeacherDetailPanel(
        teacher: _detailTeacher!,
        onBack: _closeDetail,
        onEdit: () => _openForm(teacher: _detailTeacher),
        onDelete: () async {
          try {
            await _api.deleteTeacher(_detailTeacher!['id']);
            _showSnack(t['teacher_deleted'] ?? 'Teacher deleted');
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

  Widget _buildTableView(Map<String, String> t, {bool isMobile = false, bool isTablet = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _SearchBox(
                  controller: _searchCtrl,
                  hint: t['search'] ?? 'Search...',
                  fullWidth: true),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                _AddButton(label: t['add'] ?? 'Add', onTap: () => _openForm()),
                const SizedBox(width: 8),
                _EditButton(
                  label: t['edit'] ?? 'Edit',
                  onTap: () {
                    if (_selectedTeacher != null) {
                      _openForm(teacher: _selectedTeacher);
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
                    if (_selectedTeacher != null) {
                      _delete(_selectedTeacher!);
                    } else {
                      _showSnack(
                          t['select_row_first'] ?? 'Please select a row first',
                          isWarning: true);
                    }
                  },
                ),
              ]),
            ])
          else
            LayoutBuilder(builder: (_, constraints) {
              final btns = [
                _AddButton(label: t['add'] ?? 'Add', onTap: () => _openForm()),
                const SizedBox(width: 8),
                _EditButton(
                  label: t['edit'] ?? 'Edit',
                  onTap: () {
                    if (_selectedTeacher != null) {
                      _openForm(teacher: _selectedTeacher);
                    } else {
                      _showSnack(t['select_row_first'] ?? 'Please select a row first', isWarning: true);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _DeleteButton(
                  label: t['delete'] ?? 'Delete',
                  onTap: () {
                    if (_selectedTeacher != null) {
                      _delete(_selectedTeacher!);
                    } else {
                      _showSnack(t['select_row_first'] ?? 'Please select a row first', isWarning: true);
                    }
                  },
                ),
              ];
              if (constraints.maxWidth > 550) {
                return Row(children: [
                  _SearchBox(controller: _searchCtrl, hint: t['search'] ?? 'Search...'),
                  const Spacer(),
                  ...btns,
                ]);
              }
              return Row(children: [
                Expanded(child: _SearchBox(controller: _searchCtrl, hint: t['search'] ?? 'Search...', fullWidth: true)),
                const SizedBox(width: 10),
                ...btns,
              ]);
            }),
          const SizedBox(height: 12),
          Expanded(
            child: _TableCard(
              loading: _loading,
              empty: _filtered.isEmpty,
              emptyIcon: Icons.person_outline,
              emptyLabel: t['no_data'] ?? 'No teachers found',
              header: isMobile
                ? Row(children: [
                    const TableHeader(label: '#', flex: 1),
                    TableHeader(
                      label: t['full_name'] ?? 'Name',
                      flex: 4,
                      onSort: () => _sortBy('name'),
                      isSorted: _sortColumn == 'name',
                      sortAscending: _sortAscending,
                    ),
                    TableHeader(
                      label: t['subject'] ?? 'Subject',
                      flex: 4,
                      onSort: () => _sortBy('subject'),
                      isSorted: _sortColumn == 'subject',
                      sortAscending: _sortAscending,
                    ),
                    TableHeader(
                      label: t['status'] ?? 'Status',
                      flex: 2,
                      onSort: () => _sortBy('status'),
                      isSorted: _sortColumn == 'status',
                      sortAscending: _sortAscending,
                      textAlign: TextAlign.center,
                    ),
                  ])
                : isTablet
                ? Row(children: [
                    const TableHeader(label: '#', flex: 1),
                    TableHeader(
                      label: t['full_name'] ?? 'Full Name',
                      flex: 3,
                      onSort: () => _sortBy('name'),
                      isSorted: _sortColumn == 'name',
                      sortAscending: _sortAscending,
                    ),
                    TableHeader(
                      label: t['subject'] ?? 'Subject',
                      flex: 3,
                      onSort: () => _sortBy('subject'),
                      isSorted: _sortColumn == 'subject',
                      sortAscending: _sortAscending,
                    ),
                    TableHeader(
                      label: t['email'] ?? 'Email',
                      flex: 3,
                      onSort: () => _sortBy('email'),
                      isSorted: _sortColumn == 'email',
                      sortAscending: _sortAscending,
                    ),
                    TableHeader(
                      label: t['status'] ?? 'Status',
                      flex: 2,
                      onSort: () => _sortBy('status'),
                      isSorted: _sortColumn == 'status',
                      sortAscending: _sortAscending,
                      textAlign: TextAlign.center,
                    ),
                  ])
                : Row(children: [
                    const TableHeader(label: '#', flex: 1),
                    TableHeader(
                      label: t['code'] ?? 'Code',
                      flex: 2,
                      onSort: () => _sortBy('code'),
                      isSorted: _sortColumn == 'code',
                      sortAscending: _sortAscending,
                    ),
                    TableHeader(
                      label: t['full_name'] ?? 'Full Name',
                      flex: 3,
                      onSort: () => _sortBy('name'),
                      isSorted: _sortColumn == 'name',
                      sortAscending: _sortAscending,
                    ),
                    TableHeader(
                      label: t['subject'] ?? 'Subject',
                      flex: 3,
                      onSort: () => _sortBy('subject'),
                      isSorted: _sortColumn == 'subject',
                      sortAscending: _sortAscending,
                    ),
                    TableHeader(
                      label: t['email'] ?? 'Email',
                      flex: 3,
                      onSort: () => _sortBy('email'),
                      isSorted: _sortColumn == 'email',
                      sortAscending: _sortAscending,
                    ),
                    TableHeader(
                      label: t['address'] ?? 'Address',
                      flex: 4,
                      onSort: () => _sortBy('address'),
                      isSorted: _sortColumn == 'address',
                      sortAscending: _sortAscending,
                    ),
                    TableHeader(
                      label: t['status'] ?? 'Status',
                      flex: 2,
                      onSort: () => _sortBy('status'),
                      isSorted: _sortColumn == 'status',
                      sortAscending: _sortAscending,
                      textAlign: TextAlign.center,
                    ),
                  ]),
              body: ListView.builder(
                itemCount: _paginated.length,
                itemBuilder: (_, i) {
                  final s = _paginated[i];
                  final globalIndex = (_currentPage - 1) * _pageSize + i;
                  return _TableRow(
                    index: i,
                    isSelected: _selectedTeacher != null &&
                        _selectedTeacher!['id'] == s['id'],
                    onTap: () => _openTeacherDetail(s),
                    onDoubleTap: () => _openDetail(s),
                    children: isMobile
                        ? [
                            Expanded(
                              flex: 1,
                              child: Text(
                                (globalIndex + 1).toString(),
                                style: AppTextStyles.body.copyWith(color: textColor),
                              ),
                            ),
                            Expanded(
                              flex: 4,
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
                                (s['subjects'] as List?)?.isNotEmpty == true
                                    ? (s['subjects'] as List).map((sub) => sub['name']).join(', ')
                                    : '—',
                                style: AppTextStyles.body.copyWith(color: textColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(child: _StatusBadge(status: s['status'] ?? 'Active')),
                            ),
                          ]
                        : isTablet
                        ? [
                            Expanded(
                              flex: 1,
                              child: Text(
                                (globalIndex + 1).toString(),
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
                              flex: 3,
                              child: Text(
                                (s['subjects'] as List?)?.isNotEmpty == true
                                    ? (s['subjects'] as List).map((sub) => sub['name']).join(', ')
                                    : '—',
                                style: AppTextStyles.body.copyWith(color: textColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                s['email'] ?? '—',
                                style: AppTextStyles.body.copyWith(color: textColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(child: _StatusBadge(status: s['status'] ?? 'Active')),
                            ),
                          ]
                        : [
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
                                s['code'] ?? s['id']?.toString() ?? '—',
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
                              flex: 3,
                              child: Text(
                                (s['subjects'] as List?)?.isNotEmpty == true
                                    ? (s['subjects'] as List).map((sub) => sub['name']).join(', ')
                                    : '—',
                                style: AppTextStyles.body.copyWith(color: textColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                s['email'] ?? '—',
                                style: AppTextStyles.body.copyWith(color: textColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                s['address'] ?? '—',
                                style: AppTextStyles.body.copyWith(color: textColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(child: _StatusBadge(status: s['status'] ?? 'Active')),
                            ),
                          ],
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

// ── Local helpers ─────────────────────────────────────────────────────────────

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool fullWidth;
  const _SearchBox({required this.controller, required this.hint, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white70 : AppColors.textMuted;

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
  void deactivate() {
    _isHovering = false;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEven = widget.index % 2 == 0;
    Color rowColor;
    if (widget.isSelected) {
      rowColor = AppColors.primary.withValues(alpha: 0.10);
    } else if (_isHovering) {
      rowColor = isDark ? const Color(0xFF1E2D50) : AppColors.primarySurface;
    } else if (isDark) {
      rowColor =
          isEven ? const Color(0xFF16213E) : const Color(0xFF1C2A4A);
    } else {
      rowColor = isEven ? Colors.white : const Color(0xFFF5F7FA);
    }

    return MouseRegion(
      onEnter: (_) => WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _isHovering = true); }),
      onExit: (_) => WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _isHovering = false); }),
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
        style: AppTextStyles.body.copyWith(color: color, fontSize: 12),
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
