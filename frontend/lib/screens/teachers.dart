// lib/screens/teachers_screen.dart
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
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getTeachers();
      setState(() {
        _teachers = data.cast<Map<String, dynamic>>();
        _filtered = _teachers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      final t = AppTranslations.translations[
              context.read<LocaleProvider>().locale] ??
          AppTranslations.translations['en']!;
      _showSnack(t['failed_load'] ?? 'Failed to load teachers', isError: true);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    var list = q.isEmpty
        ? List<Map<String, dynamic>>.from(_teachers)
        : _teachers
            .where((s) =>
                '${s['name']} ${s['code']} ${s['email']} ${s['subject']}'
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
      _currentPage = 1;
    });
  }

  String _sortValue(Map<String, dynamic> s, String col) {
    switch (col) {
      case 'code':
        return s['code']?.toString().toLowerCase() ?? '';
      case 'name':
        return s['name']?.toString().toLowerCase() ?? '';
      case 'subject':
        return s['subject']?.toString().toLowerCase() ?? '';
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
    setState(() {
      if (_sortColumn == col) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = col;
        _sortAscending = true;
      }
    });
    _filter();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastNotification(
        message: msg,
        isError: isError,
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
            _load();
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

    return _buildTableView(t);
  }

  Widget _buildTableView(Map<String, String> t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _SearchBox(
                controller: _searchCtrl,
                hint: t['search'] ?? 'Search...'),
            const Spacer(),
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
                      isError: true);
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
                      isError: true);
                }
              },
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: _TableCard(
              loading: _loading,
              empty: _filtered.isEmpty,
              emptyIcon: Icons.person_outline,
              emptyLabel: t['no_data'] ?? 'No teachers found',
              header: Row(children: [
                const TableHeader(label: '#', flex: 1),
                TableHeader(
                  label: t['code'] ?? 'Code',
                  flex: 2,
                  onSort: () => _sortBy('code'),
                  isSorted: _sortColumn == 'code',
                  sortAscending: _sortAscending,
                ),
                TableHeader(
                  label: t['teacher_name'] ?? 'Name',
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
                  flex: 1,
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
                          s['subject'] ?? '—',
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
                        flex: 1,
                        child: _StatusBadge(status: s['status'] ?? 'Active'),
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
          : empty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(emptyIcon, size: 48, color: mutedColor),
                    const SizedBox(height: 12),
                    Text(emptyLabel,
                        style: AppTextStyles.body.copyWith(color: mutedColor)),
                  ]),
                )
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: header,
                  ),
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
      rowColor = isDark ? const Color(0xFF1E2D50) : AppColors.primarySurface;
    } else if (isDark) {
      rowColor =
          isEven ? const Color(0xFF16213E) : const Color(0xFF1C2A4A);
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
          decoration: BoxDecoration(color: rowColor),
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
    final statusStr =
        status is bool ? (status ? 'Active' : 'Inactive') : status.toString();
    final isActive = statusStr.toLowerCase() == 'active';
    final color = isActive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        textAlign: TextAlign.center,
        statusStr.replaceFirstMapped(
            RegExp(r'^.'), (m) => m.group(0)!.toUpperCase()),
        style: AppTextStyles.body.copyWith(color: color),
      ),
    );
  }
}

class _ToastNotification extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;
  const _ToastNotification(
      {required this.message,
      required this.isError,
      required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.success;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Positioned(
      top: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textPrimary))),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close,
                  size: 16, color: AppColors.textSecondary),
            ),
          ]),
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
