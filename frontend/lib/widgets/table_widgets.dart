// lib/widgets/table_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/utils/app_constants.dart';

/// Inline student detail panel — same visual style as StudentFormPanel.
class StudentDetailPanel extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StudentDetailPanel({
    super.key,
    required this.student,
    required this.onBack,
    this.onEdit,
    this.onDelete,
  });

  static String _fmtDate(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10).replaceAll('-', '/') : s;
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      suffixIcon: suffix,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _readField(String label, String? value, {Widget? suffix}) {
    return _labeled(
      label,
      TextField(
        readOnly: true,
        controller: TextEditingController(text: value ?? ''),
        style: AppTextStyles.body,
        decoration: _inputDecoration(hint: '—', suffix: suffix),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ?? AppTranslations.translations['en']!;

    final s = student;
    final statusRaw = s['status'];
    final isActive = statusRaw is bool
        ? statusRaw
        : (statusRaw?.toString().toLowerCase() == 'active');
    final statusLabel = isActive ? (t['active'] ?? 'Active') : (t['inactive'] ?? 'Inactive');
    final statusColor = isActive ? AppColors.success : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── header ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(children: [
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(24),
              child: const Icon(Icons.chevron_left,
                  size: 24, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              s['code']?.toString() ?? 'ST000',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(t['edit'] ?? 'Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 18),
                side: const BorderSide(
                    color: AppColors.primarySurface, width: 1),
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
                          title: Text(t['confirm_delete'] ?? 'Confirm Delete'),
                          content: Text(
                              '${student['code'] ?? ''} -'
                              ' ${student['firstName'] ?? ''}'
                              ' ${student['lastName'] ?? ''}?'),
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
              icon: const Icon(Icons.delete_outline, size: 16),
              label: Text(t['delete'] ?? 'Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 18),
                side: const BorderSide(
                    color: AppColors.primarySurface, width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ]),
        ),
        // ── content ─────────────────────────────────────────────────
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
                      // Left column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: _readField(
                                    '${t['code'] ?? 'Code'}:', s['code']?.toString()),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _labeled(
                                  '${t['gender'] ?? 'Gender'}:',
                                  TextField(
                                    readOnly: true,
                                    controller: TextEditingController(
                                        text: s['gender']?.toString() ?? ''),
                                    style: AppTextStyles.body,
                                    decoration: _inputDecoration(
                                      suffix: const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 18,
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _readField(
                                '${t['first_name'] ?? 'First Name'}:', s['firstName']?.toString()),
                            const SizedBox(height: 16),
                            _readField(
                                '${t['last_name'] ?? 'Last Name'}:', s['lastName']?.toString()),
                            const SizedBox(height: 16),
                            _readField(
                              '${t['date_of_birth'] ?? 'Date of Birth'}:',
                              _fmtDate(s['dateOfBirth']),
                              suffix: const Icon(Icons.calendar_today_outlined,
                                  size: 16, color: AppColors.textSecondary),
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
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: statusColor)),
                              ]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _readField('${t['email'] ?? 'Email'}:', s['email']?.toString()),
                            const SizedBox(height: 16),
                            _readField(
                                '${t['phone'] ?? 'Phone'}:', s['phoneNumber']?.toString()),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['address'] ?? 'Address'}:',
                              TextField(
                                readOnly: true,
                                controller: TextEditingController(
                                    text: s['address']?.toString() ?? ''),
                                maxLines: 6,
                                style: AppTextStyles.body,
                                decoration:
                                    _inputDecoration(hint: '—'),
                              ),
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

/// Inline add / edit student form panel.
class StudentFormPanel extends StatefulWidget {
  final Map<String, dynamic>? student; // null = add mode
  final Future<void> Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const StudentFormPanel({
    super.key,
    this.student,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<StudentFormPanel> createState() => _StudentFormPanelState();
}

class _StudentFormPanelState extends State<StudentFormPanel> {
  final _codeCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _gender = 'Male';
  bool _status = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    if (s != null) {
      _codeCtrl.text = s['code'] ?? '';
      _firstCtrl.text = s['firstName'] ?? '';
      _lastCtrl.text = s['lastName'] ?? '';
      _emailCtrl.text = s['email'] ?? '';
      _phoneCtrl.text = s['phoneNumber'] ?? '';
      final dob = s['dateOfBirth']?.toString() ?? '';
      _dobCtrl.text =
          dob.length >= 10 ? dob.substring(0, 10).replaceAll('-', '/') : dob;
      _addressCtrl.text = s['address'] ?? '';
      final g = s['gender']?.toString() ?? '';
      _gender = ['Male', 'Female', 'Other'].contains(g) ? g : 'Male';
      final st = s['status'];
      _status = st is bool ? st : true;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'code': _codeCtrl.text.trim(),
        'firstName': _firstCtrl.text.trim(),
        'lastName': _lastCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'gender': _gender,
        'dateOfBirth': _dobCtrl.text.isNotEmpty
            ? _dobCtrl.text.replaceAll('/', '-')
            : null,
        'address': _addressCtrl.text.trim(),
        'status': _status,
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final current = DateTime.tryParse(_dobCtrl.text.replaceAll('/', '-'));
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text =
            '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      suffixIcon: suffix,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5)),
      filled: true,
      fillColor: AppColors.white,
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ?? AppTranslations.translations['en']!;
    final isEdit = widget.student != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── header ────────────────────────────────────────────────
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            InkWell(
              onTap: widget.onCancel,
              borderRadius: BorderRadius.circular(6),
              child: const Icon(Icons.chevron_left,
                  size: 24, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              isEdit ? (t['edit_student'] ?? 'Edit Student') : (t['add_student'] ?? 'Add Student'),
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
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check, size: 16),
              label: Text(t['save'] ?? 'Save'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 18),
                side: const BorderSide(
                    color: AppColors.primarySurface, width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ]),
        ),
        const Divider(height: 1),
        // ── form ──────────────────────────────────────────────────
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
                      // Left column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: _labeled(
                                  '${t['code'] ?? 'Code'}:',
                                  TextField(
                                    controller: _codeCtrl,
                                    style: AppTextStyles.body,
                                    decoration:
                                        _inputDecoration(hint: 'ST001'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _labeled(
                                  '${t['gender'] ?? 'Gender'}:',
                                  DropdownButtonFormField<String>(
                                    initialValue: _gender,
                                    style: AppTextStyles.body,
                                    decoration: _inputDecoration(),
                                    items: [
                                      DropdownMenuItem(value: 'Male', child: Text(t['male'] ?? 'Male', style: AppTextStyles.body)),
                                      DropdownMenuItem(value: 'Female', child: Text(t['female'] ?? 'Female', style: AppTextStyles.body)),
                                      DropdownMenuItem(value: 'Other', child: Text(t['other'] ?? 'Other', style: AppTextStyles.body)),
                                    ],
                                    onChanged: (v) => setState(
                                        () => _gender = v ?? 'Male'),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['first_name'] ?? 'First Name'}:',
                              TextField(
                                controller: _firstCtrl,
                                style: AppTextStyles.body,
                                decoration: _inputDecoration(
                                    hint: t['first_name'] ?? 'First name'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['last_name'] ?? 'Last Name'}:',
                              TextField(
                                controller: _lastCtrl,
                                style: AppTextStyles.body,
                                decoration: _inputDecoration(
                                    hint: t['last_name'] ?? 'Last name'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['date_of_birth'] ?? 'Date of Birth'}:',
                              TextField(
                                controller: _dobCtrl,
                                readOnly: true,
                                onTap: _pickDate,
                                style: AppTextStyles.body,
                                decoration: _inputDecoration(
                                  hint: 'YYYY/MM/DD',
                                  suffix: const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                      color: AppColors.textSecondary),
                                ),
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
                                  _status ? (t['active'] ?? 'Active') : (t['inactive'] ?? 'Inactive'),
                                  style: AppTextStyles.bodySmall,
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labeled(
                              '${t['email'] ?? 'Email'}:',
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: AppTextStyles.body,
                                decoration: _inputDecoration(
                                    hint: 'student@school.edu'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['phone'] ?? 'Phone'}:',
                              TextField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                style: AppTextStyles.body,
                                decoration: _inputDecoration(
                                    hint: '+855 XX XXX XXX'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['address'] ?? 'Address'}:',
                              TextField(
                                controller: _addressCtrl,
                                maxLines: 6,
                                style: AppTextStyles.body,
                                decoration:
                                    _inputDecoration(hint: t['address'] ?? 'Enter address'),
                              ),
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

/// Column header for data tables
class TableHeader extends StatelessWidget {
  final String label;
  final int flex;
  final VoidCallback? onSort;
  final bool isSorted;
  final bool sortAscending;
  final TextAlign textAlign;

  const TableHeader({
    super.key,
    required this.label,
    required this.flex,
    this.onSort,
    this.isSorted = false,
    this.sortAscending = true,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isSorted
        ? AppColors.primary
        : (isDark ? Colors.white70 : AppColors.textSecondary);
    final mainAxis = textAlign == TextAlign.center
        ? MainAxisAlignment.center
        : MainAxisAlignment.start;

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onSort,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: mainAxis,
          children: [
            Text(
              label,
              textAlign: textAlign,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (onSort != null) ...[
              const SizedBox(width: 4),
              Icon(
                isSorted
                    ? (sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                    : Icons.unfold_more,
                size: 14,
                color: isSorted ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Labelled text input used in form dialogs
class FormFieldInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;

  const FormFieldInput({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.06,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodySmall,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.white,
          ),
        ),
      ],
    );
  }
}
