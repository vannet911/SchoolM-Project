// lib/screens/students_screen.dart
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
  final _searchCtrl = TextEditingController();
  Map<String, dynamic>? _selectedStudent;
  Map<String, dynamic>? _detailStudent;
  bool _showForm = false;
  Map<String, dynamic>? _formStudent;

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
      final data = await _api.getStudents();
      setState(() {
        _students = data.cast<Map<String, dynamic>>();
        _filtered = _students;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Failed to load students', isError: true);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _students
          : _students
              .where((s) => '${s['firstName']} ${s['lastName']} ${s['email']}'
                  .toLowerCase()
                  .contains(q))
              .toList();
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(top: 16, right: 16),
      width: 320,
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _delete(Map<String, dynamic> s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text("Delete ${s['firstName']} ${s['lastName']}?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _api.deleteStudent(s['id']);
        _showSnack('Student deleted');
        _load();
      } catch (_) {
        _showSnack('Delete failed', isError: true);
      }
    }
  }

  void _openStudentDetail(Map<String, dynamic> student) {
    setState(() => _selectedStudent = student);
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
              _showSnack('Student created!');
            } else {
              await _api.updateStudent(_formStudent!['id'], data);
              _showSnack('Student updated!');
            }
            _closeForm();
            _load();
          } catch (_) {
            _showSnack('Save failed', isError: true);
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
          await _api.deleteStudent(_detailStudent!['id']);
          _closeDetail();
          _load();
        },
      );
    }

    return _buildTableView(t);
  }

  Widget _buildTableView(Map<String, String> t) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _SearchBox(
                controller: _searchCtrl,
                hint: t['search'] ?? 'Searching...'),
            const Spacer(),
            _AddButton(label: t['add'] ?? 'Add', onTap: () => _openForm()),
            const SizedBox(width: 8),
            _EditButton(onTap: () {
              if (_filtered.isNotEmpty) _openForm(student: _filtered[0]);
            }),
            const SizedBox(width: 8),
            _DeleteButton(onTap: () {
              if (_filtered.isNotEmpty) _delete(_filtered[0]);
            }),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: _TableCard(
              loading: _loading,
              empty: _filtered.isEmpty,
              emptyIcon: Icons.school_outlined,
              emptyLabel: t['no_data'] ?? 'No students found',
              header: Row(children: [
                const TableHeader(label: '#', flex: 1),
                const _HeaderDivider(),
                TableHeader(label: t['code'] ?? 'Code', flex: 2),
                const _HeaderDivider(),
                TableHeader(label: t['student_name'] ?? 'Full Name', flex: 3),
                const _HeaderDivider(),
                TableHeader(
                    label: t['date_of_birth'] ?? 'Date of Birth', flex: 2),
                const _HeaderDivider(),
                TableHeader(label: t['email'] ?? 'Email', flex: 3),
                const _HeaderDivider(),
                TableHeader(label: t['address'] ?? 'Address', flex: 3),
                const _HeaderDivider(),
                TableHeader(label: t['status'] ?? 'Status', flex: 2),
              ]),
              body: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final s = _filtered[i];
                  final name =
                      '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
                  return _TableRow(
                      isSelected: _selectedStudent != null &&
                          _selectedStudent!['id'] == s['id'],
                      onTap: () => _openStudentDetail(s),
                      onDoubleTap: () => _openDetail(s),
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            (i + 1).toString(),
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            s['code'] ??
                                s['studentCode'] ??
                                s['id']?.toString() ??
                                '—',
                            style: AppTextStyles.bodySmall
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            name.isEmpty ? '—' : name,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            s['dateOfBirth'] != null
                                ? (s['dateOfBirth'] as String)
                                    .substring(0, 10)
                                    .replaceAll('-', '/')
                                : '—',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(s['email'] ?? '—',
                              style: AppTextStyles.bodySmall),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(s['address'] ?? '—',
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Expanded(
                          flex: 2,
                          child: _StatusBadge(status: s['status'] ?? 'Active'),
                        ),
                      ]);
                },
              ),
            ),
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
      height: 44,
      child: TextField(
        controller: controller,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodySmall.copyWith(color: mutedColor),
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
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        side: const BorderSide(color: AppColors.primarySurface, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text('Update'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        side: const BorderSide(color: AppColors.primarySurface, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DeleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.delete_outline, size: 18),
      label: const Text('Delete'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        side: const BorderSide(color: AppColors.background, width: 1),
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
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final mutedColor = isDark ? Colors.white70 : AppColors.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: borderColor),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppConstants.cardRadius)),
                      border:
                          Border(bottom: BorderSide(color: AppColors.border)),
                    ),
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
  const _TableRow({required this.children, this.onTap, this.onDoubleTap, this.isSelected = false});

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    Color rowColor;
    if (widget.isSelected) {
      rowColor = AppColors.primary.withOpacity(0.10);
    } else if (_isHovering) {
      rowColor = AppColors.primarySurface;
    } else {
      rowColor = Colors.transparent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: rowColor,
            border: Border(
              left: widget.isSelected
                  ? const BorderSide(color: AppColors.primary, width: 3)
                  : BorderSide.none,
              bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
            ),
          ),
          child: Row(children: widget.children),
        ),
      ),
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final dynamic status; // Can be bool or String
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    // Handle both boolean and string status
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
        statusStr.replaceFirstMapped(
            RegExp(r'^.'), (m) => m.group(0)!.toUpperCase()),
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
