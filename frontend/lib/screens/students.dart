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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
    setState(() {
      _selectedStudent = student;
    });
  }

  void _closeStudentDetail() {
    setState(() {
      _selectedStudent = null;
    });
  }

  void _openForm({Map<String, dynamic>? student}) {
    showDialog(
      context: context,
      builder: (_) => StudentFormDialog(
        student: student,
        onSave: (data) async {
          try {
            if (student == null) {
              await _api.createStudent(data);
              _showSnack('Student created!');
            } else {
              await _api.updateStudent(student['id'], data);
              _showSnack('Student updated!');
            }
            _load();
          } catch (_) {
            _showSnack('Save failed', isError: true);
          }
        },
      ),
    );
  }

  static String _initials(String? first, String? last) {
    final f = (first ?? '').isNotEmpty ? first![0].toUpperCase() : '';
    final l = (last ?? '').isNotEmpty ? last![0].toUpperCase() : '';
    return '$f$l'.isEmpty ? '?' : '$f$l';
  }

  static const List<Color> _avatarColors = [
    Color(0xFF3A6B35),
    Color(0xFF1565C0),
    Color(0xFFC62828),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFF00695C),
  ];
  static Color _avatarColor(String name) =>
      _avatarColors[name.hashCode.abs() % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;

    if (_selectedStudent != null) {
      // Detail page: full content area, keep sidebar/topbar visible outside
      return Padding(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: _StudentDetailView(
          student: _selectedStudent!,
          onClose: _closeStudentDetail,
          onEdit: (student) => _openForm(student: student),
        ),
      );
    }

    // Default view: Full table
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
                hint: t['search'] ?? 'Search students...'),
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
                TableHeader(label: t['code'] ?? 'Code', flex: 2),
                TableHeader(label: t['student_name'] ?? 'Name', flex: 3),
                TableHeader(
                    label: t['date_of_birth'] ?? 'Date of Birth', flex: 2),
                TableHeader(label: t['email'] ?? 'Email', flex: 3),
                TableHeader(label: t['address'] ?? 'Address', flex: 3),
                TableHeader(label: t['status'] ?? 'Status', flex: 2),
              ]),
              body: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final s = _filtered[i];
                  final name =
                      '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
                  final c = _avatarColor(name);
                  return _TableRow(
                      onDoubleTap: () => _openStudentDetail(s),
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
                          child: Row(children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: c.withOpacity(0.15),
                              child: Text(
                                  _initials(s['firstName'], s['lastName']),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: c)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name.isEmpty ? '—' : name,
                                      style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text('ID: ${s['id']}',
                                      style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                          ]),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            s['dateOfBirth'] != null
                                ? (s['dateOfBirth'] as String).substring(0, 10)
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

// ── Student Detail View ───────────────────────────────────────────────────────
class _StudentDetailView extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onEdit;

  const _StudentDetailView({
    required this.student,
    required this.onClose,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'.trim();
    final c = _StudentsScreenState._avatarColor(name);

    String formatDate(dynamic value) {
      if (value == null) return '—';
      final text = value is String ? value : value.toString();
      return text.length >= 10 ? text.substring(0, 10) : text;
    }

    String statusLabel(dynamic value) {
      if (value == null) return 'Inactive';
      if (value is bool) return value ? 'Active' : 'Inactive';
      return value.toString();
    }

    Widget field(String label, String value, {int maxLines = 1}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              value,
              style: AppTextStyles.body,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border.withOpacity(0.3)),
            ),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_back, size: 18),
                ),
              ),
              const SizedBox(width: 16),
              Text(student['code'] ?? 'ST000',
                  style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.w700, letterSpacing: 0.4)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => onEdit(student),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Update'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onClose,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: c.withOpacity(0.18),
                        child: Text(
                          _StudentsScreenState._initials(
                              student['firstName'], student['lastName']),
                          style: TextStyle(
                            color: c,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.isEmpty ? '—' : name,
                                style: AppTextStyles.heading3
                                    .copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('ID: ${student['id']}',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            Text(student['email'] ?? '—',
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          statusLabel(student['status']),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            field('Code', student['code'] ?? '—'),
                            const SizedBox(height: 18),
                            field('Full Name', name.isEmpty ? '—' : name),
                            const SizedBox(height: 18),
                            field('Date of Birth',
                                formatDate(student['dateOfBirth'])),
                            const SizedBox(height: 18),
                            field(
                                'Created Date',
                                formatDate(student['createDate'] ??
                                    student['createdAt'])),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            field('Gender', student['gender'] ?? '—'),
                            const SizedBox(height: 18),
                            field('Email', student['email'] ?? '—'),
                            const SizedBox(height: 18),
                            field('Phone', student['phoneNumber'] ?? '—'),
                            const SizedBox(height: 18),
                            field('Address', student['address'] ?? '—',
                                maxLines: 5),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Student Form Dialog ───────────────────────────────────────────────────────
class StudentFormDialog extends StatefulWidget {
  final Map<String, dynamic>? student;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const StudentFormDialog({super.key, this.student, required this.onSave});

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final _code = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _gender = TextEditingController();
  final _dob = TextEditingController();
  final _address = TextEditingController();
  bool _status = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    if (s != null) {
      _code.text = s['code'] ?? '';
      _first.text = s['firstName'] ?? '';
      _last.text = s['lastName'] ?? '';
      _email.text = s['email'] ?? '';
      _phone.text = s['phoneNumber'] ?? '';
      _gender.text = s['gender'] ?? '';
      _dob.text = s['dateOfBirth'] != null
          ? (s['dateOfBirth'] as String).substring(0, 10)
          : '';
      _address.text = s['address'] ?? '';
      _status = s['status'] ?? true;
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    _gender.dispose();
    _dob.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave({
      'code': _code.text.trim(),
      'firstName': _first.text.trim(),
      'lastName': _last.text.trim(),
      'email': _email.text.trim(),
      'phoneNumber': _phone.text.trim(),
      'gender': _gender.text.trim(),
      'dateOfBirth': _dob.text.isNotEmpty ? _dob.text : null,
      'address': _address.text.trim(),
      'status': _status,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;

    return _FormDialog(
      title: widget.student == null
          ? (t['add_student'] ?? 'Add Student')
          : (t['edit_student'] ?? 'Edit Student'),
      saving: _saving,
      onSave: _save,
      children: [
        FormFieldInput(
            label: t['code'] ?? 'Student Code',
            controller: _code,
            hint: 'ST001'),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: FormFieldInput(
                  label: t['student_name'] ?? 'First Name',
                  controller: _first,
                  hint: 'First name')),
          const SizedBox(width: 12),
          Expanded(
              child: FormFieldInput(
                  label: t['student_name'] ?? 'Last Name',
                  controller: _last,
                  hint: 'Last name')),
        ]),
        const SizedBox(height: 14),
        FormFieldInput(
            label: t['email'] ?? 'Email',
            controller: _email,
            hint: 'student@school.edu',
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: FormFieldInput(
                  label: t['phone'] ?? 'Phone',
                  controller: _phone,
                  hint: '+855 12 345 678',
                  keyboardType: TextInputType.phone)),
          const SizedBox(width: 12),
          Expanded(
              child: FormFieldInput(
                  label: t['gender'] ?? 'Gender',
                  controller: _gender,
                  hint: 'M/F/Other')),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: FormFieldInput(
                  label: t['date_of_birth'] ?? 'Date of Birth',
                  controller: _dob,
                  hint: 'YYYY-MM-DD')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATUS',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.06,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Checkbox(
                      value: _status,
                      onChanged: (v) => setState(() => _status = v ?? true),
                    ),
                    Text(_status ? 'Active' : 'Inactive',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 14),
        FormFieldInput(
            label: t['address'] ?? 'Address',
            controller: _address,
            hint: 'Enter address'),
      ],
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

class _TableRow extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback? onDoubleTap;
  const _TableRow({required this.children, this.onDoubleTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.border.withOpacity(0.5)))),
        child: Row(children: children),
      ),
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
    final background = isActive
        ? AppColors.success.withOpacity(0.12)
        : AppColors.error.withOpacity(0.12);
    final color = isActive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
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

class _FormDialog extends StatelessWidget {
  final String title;
  final bool saving;
  final VoidCallback onSave;
  final List<Widget> children;
  const _FormDialog(
      {required this.title,
      required this.saving,
      required this.onSave,
      required this.children});

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
              Text(title, style: AppTextStyles.heading3),
              const Spacer(),
              InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      size: 20, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 20),
            ...children,
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: saving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: saving
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
