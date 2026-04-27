// lib/screens/teachers_screen.dart
import 'package:flutter/material.dart';
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
    } catch (_) {
      setState(() => _loading = false);
      _showSnack('Failed to load teachers', isError: true);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _teachers
          : _teachers
              .where((t) => '${t['firstName']} ${t['lastName']} ${t['email']}'
                  .toLowerCase()
                  .contains(q))
              .toList();
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _delete(Map<String, dynamic> t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text("Delete ${t['firstName']} ${t['lastName']}?"),
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
        await _api.deleteTeacher(t['id']);
        _showSnack('Teacher deleted');
        _load();
      } catch (_) {
        _showSnack('Delete failed', isError: true);
      }
    }
  }

  void _openForm({Map<String, dynamic>? teacher}) {
    showDialog(
      context: context,
      builder: (_) => TeacherFormDialog(
        teacher: teacher,
        onSave: (data) async {
          try {
            if (teacher == null) {
              await _api.createTeacher(data);
              _showSnack('Teacher created!');
            } else {
              await _api.updateTeacher(teacher['id'], data);
              _showSnack('Teacher updated!');
            }
            _load();
          } catch (_) {
            _showSnack('Save failed', isError: true);
          }
        },
      ),
    );
  }

  String _initials(String? first, String? last) {
    final f = (first ?? '').isNotEmpty ? first![0].toUpperCase() : '';
    final l = (last ?? '').isNotEmpty ? last![0].toUpperCase() : '';
    return '$f$l'.isEmpty ? '?' : '$f$l';
  }

  static const List<Color> _avatarColors = [
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
    Color(0xFFE65100),
  ];
  Color _avatarColor(String name) =>
      _avatarColors[name.hashCode.abs() % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _TeacherSearchBox(controller: _searchCtrl),
            const Spacer(),
            _AddButton(label: 'Add', onTap: () => _openForm()),
            const SizedBox(width: 8),
            _EditButton(onTap: () {
              if (_filtered.length == 1) {
                _openForm(teacher: _filtered[0]);
              } else {
                _showSnack(
                    'Please search and narrow down to a single teacher to edit',
                    isError: true);
              }
            }),
            const SizedBox(width: 8),
            _DeleteButton(onTap: () {
              if (_filtered.length == 1) {
                _delete(_filtered[0]);
              } else {
                _showSnack(
                    'Please search and narrow down to a single teacher to delete',
                    isError: true);
              }
            }),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : _filtered.isEmpty
                      ? Center(
                          child: Text('No teachers found',
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.textMuted)))
                      : Column(children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.vertical(
                                  top:
                                      Radius.circular(AppConstants.cardRadius)),
                              border: Border(
                                  bottom: BorderSide(color: AppColors.border)),
                            ),
                            child: Row(children: [
                              TableHeader(label: 'Name', flex: 3),
                              TableHeader(label: 'Email', flex: 3),
                              TableHeader(label: 'Subject', flex: 2),
                              TableHeader(label: 'Hire Date', flex: 2),
                              TableHeader(label: 'Actions', flex: 1),
                            ]),
                          ),
                          // Rows
                          Expanded(
                            child: ListView.builder(
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) {
                                final t = _filtered[i];
                                final name =
                                    '${t['firstName'] ?? ''} ${t['lastName'] ?? ''}'
                                        .trim();
                                final c = _avatarColor(name);
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: AppColors.border
                                                .withOpacity(0.5))),
                                  ),
                                  child: Row(children: [
                                    Expanded(
                                      flex: 3,
                                      child: Row(children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: c.withOpacity(0.15),
                                          child: Text(
                                              _initials(t['firstName'],
                                                  t['lastName']),
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: c)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(name.isEmpty ? '—' : name,
                                              style: AppTextStyles.body
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w500),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ]),
                                    ),
                                    Expanded(
                                        flex: 3,
                                        child: Text(t['email'] ?? '—',
                                            style: AppTextStyles.bodySmall)),
                                    Expanded(
                                      flex: 2,
                                      child: t['subject'] != null
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6A1B9A)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(t['subject'],
                                                  style: AppTextStyles.caption
                                                      .copyWith(
                                                    color:
                                                        const Color(0xFF6A1B9A),
                                                    fontWeight: FontWeight.w600,
                                                  )))
                                          : Text('—',
                                              style: AppTextStyles.bodySmall),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                          t['hireDate'] != null
                                              ? (t['hireDate'] as String)
                                                  .substring(0, 10)
                                              : '—',
                                          style: AppTextStyles.bodySmall),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Row(children: [
                                        ActionBtn(
                                            icon: Icons.edit_outlined,
                                            color: AppColors.primary,
                                            onTap: () => _openForm(teacher: t)),
                                        const SizedBox(width: 4),
                                        ActionBtn(
                                            icon: Icons.delete_outline,
                                            color: AppColors.error,
                                            onTap: () => _delete(t)),
                                      ]),
                                    ),
                                  ]),
                                );
                              },
                            ),
                          ),
                        ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Teacher Form Dialog ───────────────────────────────────────────────────────
class TeacherFormDialog extends StatefulWidget {
  final Map<String, dynamic>? teacher;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const TeacherFormDialog({super.key, this.teacher, required this.onSave});

  @override
  State<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends State<TeacherFormDialog> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _hireDate = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.teacher;
    if (t != null) {
      _first.text = t['firstName'] ?? '';
      _last.text = t['lastName'] ?? '';
      _email.text = t['email'] ?? '';
      _subject.text = t['subject'] ?? '';
      _hireDate.text = t['hireDate'] != null
          ? (t['hireDate'] as String).substring(0, 10)
          : '';
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _subject.dispose();
    _hireDate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave({
      'firstName': _first.text.trim(),
      'lastName': _last.text.trim(),
      'email': _email.text.trim(),
      'subject': _subject.text.trim(),
      'hireDate': _hireDate.text.isNotEmpty ? _hireDate.text : null,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(widget.teacher == null ? 'Add Teacher' : 'Edit Teacher',
                  style: AppTextStyles.heading3),
              const Spacer(),
              InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      size: 20, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: FormFieldInput(
                      label: 'First Name',
                      controller: _first,
                      hint: 'First name')),
              const SizedBox(width: 12),
              Expanded(
                  child: FormFieldInput(
                      label: 'Last Name',
                      controller: _last,
                      hint: 'Last name')),
            ]),
            const SizedBox(height: 14),
            FormFieldInput(
                label: 'Email',
                controller: _email,
                hint: 'teacher@school.edu',
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: FormFieldInput(
                      label: 'Subject',
                      controller: _subject,
                      hint: 'e.g. Mathematics')),
              const SizedBox(width: 12),
              Expanded(
                  child: FormFieldInput(
                      label: 'Hire Date',
                      controller: _hireDate,
                      hint: 'YYYY-MM-DD')),
            ]),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _TeacherSearchBox extends StatelessWidget {
  final TextEditingController controller;
  const _TeacherSearchBox({required this.controller});

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
          hintText: 'Search teachers...',
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
        foregroundColor: AppColors.primary,
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
        foregroundColor: AppColors.primary,
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
      icon: const Icon(Icons.delete_outlined, size: 18),
      label: const Text('Delete'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        side: const BorderSide(color: AppColors.primarySurface, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilterButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.filter_list, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        side: const BorderSide(color: AppColors.primary, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
