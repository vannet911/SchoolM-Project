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

  InputDecoration _inputDecoration({String? hint, Widget? suffix, bool multiline = false, bool isDark = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: isDark ? Colors.white70 : AppColors.textMuted),
      suffixIcon: suffix,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: multiline ? 16 : 0),
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

  Widget _readField(String label, String? value, {Widget? suffix, bool isDark = false}) {
    return _labeled(
      label,
      SizedBox(
        height: 44,
        child: TextField(
          readOnly: true,
          controller: TextEditingController(text: value ?? ''),
          style: AppTextStyles.body.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: _inputDecoration(hint: '—', suffix: suffix, isDark: isDark),
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
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    final s = student;
    final statusRaw = s['status'];
    final isActive = statusRaw is bool
        ? statusRaw
        : (statusRaw?.toString().toLowerCase() == 'active');
    final statusLabel =
        isActive ? (t['active'] ?? 'Active') : (t['inactive'] ?? 'Inactive');
    final statusColor = isActive ? AppColors.success : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── header ──────────────────────────────────────────────────
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
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(t['edit'] ?? 'Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                side:
                    BorderSide(color: isDark ? const Color(0xFF2A2A4A) : AppColors.border, width: 1),
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
                          content: Text('${student['code'] ?? ''} -'
                              ' ${student['firstName'] ?? ''}'
                              ' ${student['lastName'] ?? ''}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(t['cancel'] ?? 'Cancel'),
                            ),
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
                      if (ok == true) onDelete!();
                    },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(t['delete'] ?? 'Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                side:
                    BorderSide(color: isDark ? const Color(0xFF2A2A4A) : AppColors.border, width: 1),
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
                                child: _readField('${t['code'] ?? 'Code'}:',
                                    s['code']?.toString(), isDark: isDark),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _labeled(
                                  '${t['gender'] ?? 'Gender'}:',
                                  SizedBox(
                                    height: 44,
                                    child: TextField(
                                      readOnly: true,
                                      controller: TextEditingController(
                                          text: s['gender']?.toString() ?? ''),
                                      style: AppTextStyles.body.copyWith(color: textColor),
                                      decoration: _inputDecoration(
                                        isDark: isDark,
                                        suffix: const Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 18,
                                            color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _readField('${t['first_name'] ?? 'First Name'}:',
                                s['firstName']?.toString(), isDark: isDark),
                            const SizedBox(height: 16),
                            _readField('${t['last_name'] ?? 'Last Name'}:',
                                s['lastName']?.toString(), isDark: isDark),
                            const SizedBox(height: 16),
                            _readField(
                              '${t['date_of_birth'] ?? 'Date of Birth'}:',
                              _fmtDate(s['dateOfBirth']),
                              suffix: const Icon(Icons.calendar_today_outlined,
                                  size: 16, color: AppColors.textSecondary),
                              isDark: isDark,
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
                      const SizedBox(width: 16),
                      // Right column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _readField('${t['email'] ?? 'Email'}:',
                                s['email']?.toString(), isDark: isDark),
                            const SizedBox(height: 16),
                            _readField('${t['phone'] ?? 'Phone'}:',
                                s['phoneNumber']?.toString(), isDark: isDark),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['address'] ?? 'Address'}:',
                              TextField(
                                readOnly: true,
                                controller: TextEditingController(
                                    text: s['address']?.toString() ?? ''),
                                maxLines: 5,
                                style: AppTextStyles.body.copyWith(color: textColor),
                                decoration: _inputDecoration(hint: '—', multiline: true, isDark: isDark),
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

  InputDecoration _inputDecoration({String? hint, Widget? suffix, bool multiline = false, bool isDark = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: isDark ? Colors.white70 : AppColors.textMuted),
      suffixIcon: suffix,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: multiline ? 16 : 0),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
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
    final isEdit = widget.student != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── header ────────────────────────────────────────────────
        Padding(
          //padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                  ? (t['edit_student'] ?? 'Edit Student')
                  : (t['add_student'] ?? 'Add Student'),
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
                  : const Icon(Icons.check, size: 18),
              label: Text(t['save'] ?? 'Save'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                side:
                    BorderSide(color: isDark ? const Color(0xFF2A2A4A) : AppColors.border, width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ]),
        ),
        //const Divider(height: 1),
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
                                  SizedBox(
                                    height: 44,
                                    child: TextField(
                                      controller: _codeCtrl,
                                      style: AppTextStyles.body.copyWith(color: textColor),
                                      decoration: _inputDecoration(
                                          hint: 'Enter code', isDark: isDark),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _labeled(
                                  '${t['gender'] ?? 'Gender'}:',
                                  SizedBox(
                                    height: 44,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _gender,
                                      style: AppTextStyles.body.copyWith(color: textColor),
                                      decoration: _inputDecoration(isDark: isDark),
                                      items: [
                                        DropdownMenuItem(
                                            value: 'Male',
                                            child: Text(t['male'] ?? 'Male',
                                                style: AppTextStyles.body.copyWith(color: textColor))),
                                        DropdownMenuItem(
                                            value: 'Female',
                                            child: Text(
                                                t['female'] ?? 'Female',
                                                style: AppTextStyles.body.copyWith(color: textColor))),
                                        DropdownMenuItem(
                                            value: 'Other',
                                            child: Text(t['other'] ?? 'Other',
                                                style: AppTextStyles.body.copyWith(color: textColor))),
                                      ],
                                      onChanged: (v) => setState(
                                          () => _gender = v ?? 'Male'),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['first_name'] ?? 'First Name'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _firstCtrl,
                                  style: AppTextStyles.body.copyWith(color: textColor),
                                  decoration: _inputDecoration(
                                      hint: t['first_name'] ?? 'First name', isDark: isDark),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['last_name'] ?? 'Last Name'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _lastCtrl,
                                  style: AppTextStyles.body.copyWith(color: textColor),
                                  decoration: _inputDecoration(
                                      hint: t['last_name'] ?? 'Last name', isDark: isDark),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['date_of_birth'] ?? 'Date of Birth'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _dobCtrl,
                                  readOnly: true,
                                  onTap: _pickDate,
                                  style: AppTextStyles.body.copyWith(color: textColor),
                                  decoration: _inputDecoration(
                                    hint: 'YYYY/MM/DD',
                                    isDark: isDark,
                                    suffix: const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['status'] ?? 'Status'}:',
                              Row(children: [
                                Switch(
                                  value: _status,
                                  onChanged: (v) => setState(() => _status = v),
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
                      const SizedBox(width: 16),
                      // Right column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labeled(
                              '${t['email'] ?? 'Email'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  style: AppTextStyles.body.copyWith(color: textColor),
                                  decoration: _inputDecoration(
                                      hint: 'student@school.edu', isDark: isDark),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['phone'] ?? 'Phone'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  style: AppTextStyles.body.copyWith(color: textColor),
                                  decoration: _inputDecoration(
                                      hint: '+855 XX XXX XXX', isDark: isDark),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['address'] ?? 'Address'}:',
                              TextField(
                                controller: _addressCtrl,
                                maxLines: 5,
                                style: AppTextStyles.body.copyWith(color: textColor),
                                decoration: _inputDecoration(
                                    hint: t['address'] ?? 'Enter address',
                                    multiline: true,
                                    isDark: isDark),
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

/// Inline teacher detail panel
class TeacherDetailPanel extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TeacherDetailPanel({
    super.key,
    required this.teacher,
    required this.onBack,
    this.onEdit,
    this.onDelete,
  });

  static String _fmtDate(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10).replaceAll('-', '/') : s;
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffix, bool multiline = false, bool isDark = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: isDark ? Colors.white70 : AppColors.textMuted),
      suffixIcon: suffix,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: multiline ? 16 : 0),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _readField(String label, String? value, {Widget? suffix, bool isDark = false}) {
    return _labeled(
      label,
      SizedBox(
        height: 44,
        child: TextField(
          readOnly: true,
          controller: TextEditingController(text: value ?? ''),
          style: AppTextStyles.body.copyWith(color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: _inputDecoration(hint: '—', suffix: suffix, isDark: isDark),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ?? AppTranslations.translations['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    final s = teacher;
    final statusRaw = s['status'];
    final isActive = statusRaw is bool ? statusRaw : (statusRaw?.toString().toLowerCase() == 'active');
    final statusLabel = isActive ? (t['active'] ?? 'Active') : (t['inactive'] ?? 'Inactive');
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
                  child: Icon(Icons.chevron_left, size: 24, color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              s['code']?.toString() ?? 'TC000',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                side: BorderSide(color: isDark ? const Color(0xFF2A2A4A) : AppColors.border, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                          content: Text('${teacher['code'] ?? ''} - ${teacher['name'] ?? ''}?'),
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
                      if (ok == true) onDelete!();
                    },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(t['delete'] ?? 'Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                side: BorderSide(color: isDark ? const Color(0xFF2A2A4A) : AppColors.border, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                            Row(children: [
                              Expanded(
                                child: _readField('${t['code'] ?? 'Code'}:', s['code']?.toString(), isDark: isDark),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _labeled(
                                  '${t['gender'] ?? 'Gender'}:',
                                  SizedBox(
                                    height: 44,
                                    child: TextField(
                                      readOnly: true,
                                      controller: TextEditingController(text: s['gender']?.toString() ?? ''),
                                      style: AppTextStyles.body.copyWith(color: textColor),
                                      decoration: _inputDecoration(
                                        isDark: isDark,
                                        suffix: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _readField('${t['teacher_name'] ?? 'Teacher Name'}:', s['name']?.toString(), isDark: isDark),
                            const SizedBox(height: 16),
                            _readField(
                              '${t['date_of_birth'] ?? 'Date of Birth'}:',
                              _fmtDate(s['dateOfBirth']),
                              suffix: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),
                            _readField('${t['subject'] ?? 'Subject'}:', s['subject']?.toString(), isDark: isDark),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['status'] ?? 'Status'}:',
                              Row(children: [
                                Switch(value: isActive, onChanged: null, activeThumbColor: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(statusLabel, style: AppTextStyles.body.copyWith(color: statusColor)),
                              ]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _readField('${t['email'] ?? 'Email'}:', s['email']?.toString(), isDark: isDark),
                            const SizedBox(height: 16),
                            _readField('${t['phone'] ?? 'Phone'}:', s['phoneNumber']?.toString(), isDark: isDark),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['address'] ?? 'Address'}:',
                              TextField(
                                readOnly: true,
                                controller: TextEditingController(text: s['address']?.toString() ?? ''),
                                maxLines: 5,
                                style: AppTextStyles.body.copyWith(color: textColor),
                                decoration: _inputDecoration(hint: '—', multiline: true, isDark: isDark),
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

/// Inline add / edit teacher form panel
class TeacherFormPanel extends StatefulWidget {
  final Map<String, dynamic>? teacher;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const TeacherFormPanel({
    super.key,
    this.teacher,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<TeacherFormPanel> createState() => _TeacherFormPanelState();
}

class _TeacherFormPanelState extends State<TeacherFormPanel> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _gender = 'Male';
  bool _status = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.teacher;
    if (s != null) {
      _codeCtrl.text = s['code'] ?? '';
      _nameCtrl.text = s['name'] ?? '';
      _emailCtrl.text = s['email'] ?? '';
      _phoneCtrl.text = s['phoneNumber'] ?? '';
      final dob = s['dateOfBirth']?.toString() ?? '';
      _dobCtrl.text = dob.length >= 10 ? dob.substring(0, 10).replaceAll('-', '/') : dob;
      _subjectCtrl.text = s['subject'] ?? '';
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _subjectCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'code': _codeCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'gender': _gender,
        'dateOfBirth': _dobCtrl.text.isNotEmpty
            ? _dobCtrl.text.replaceAll('/', '-')
            : '1990-01-01',
        'subject': _subjectCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'status': _status,
        'createDate': DateTime.now().toUtc().toIso8601String(),
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final current = DateTime.tryParse(_dobCtrl.text.replaceAll('/', '-'));
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(1990),
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

  InputDecoration _inputDecoration({String? hint, Widget? suffix, bool multiline = false, bool isDark = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: isDark ? Colors.white70 : AppColors.textMuted),
      suffixIcon: suffix,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: multiline ? 16 : 0),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ?? AppTranslations.translations['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final isEdit = widget.teacher != null;

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
                  child: Icon(Icons.chevron_left, size: 24, color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEdit ? (t['edit_teacher'] ?? 'Edit Teacher') : (t['add_teacher'] ?? 'Add Teacher'),
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
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check, size: 18),
              label: Text(t['save'] ?? 'Save'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                side: BorderSide(color: isDark ? const Color(0xFF2A2A4A) : AppColors.border, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                            Row(children: [
                              Expanded(
                                child: _labeled(
                                  '${t['code'] ?? 'Code'}:',
                                  SizedBox(
                                    height: 44,
                                    child: TextField(
                                      controller: _codeCtrl,
                                      style: AppTextStyles.body.copyWith(color: textColor),
                                      decoration: _inputDecoration(hint: 'Enter code', isDark: isDark),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _labeled(
                                  '${t['gender'] ?? 'Gender'}:',
                                  SizedBox(
                                    height: 44,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _gender,
                                      style: AppTextStyles.body.copyWith(color: textColor),
                                      decoration: _inputDecoration(isDark: isDark),
                                      items: [
                                        DropdownMenuItem(value: 'Male', child: Text(t['male'] ?? 'Male', style: AppTextStyles.body.copyWith(color: textColor))),
                                        DropdownMenuItem(value: 'Female', child: Text(t['female'] ?? 'Female', style: AppTextStyles.body.copyWith(color: textColor))),
                                        DropdownMenuItem(value: 'Other', child: Text(t['other'] ?? 'Other', style: AppTextStyles.body.copyWith(color: textColor))),
                                      ],
                                      onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['teacher_name'] ?? 'Teacher Name'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _nameCtrl,
                                  style: AppTextStyles.body.copyWith(color: textColor),
                                  decoration: _inputDecoration(hint: t['teacher_name'] ?? 'Full name', isDark: isDark),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['date_of_birth'] ?? 'Date of Birth'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _dobCtrl,
                                  readOnly: true,
                                  onTap: _pickDate,
                                  style: AppTextStyles.body.copyWith(color: textColor),
                                  decoration: _inputDecoration(
                                    hint: 'YYYY/MM/DD',
                                    isDark: isDark,
                                    suffix: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['subject'] ?? 'Subject'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _subjectCtrl,
                                  style: AppTextStyles.body.copyWith(color: textColor),
                                  decoration: _inputDecoration(
                                      hint: t['subject'] ?? 'Enter subject',
                                      isDark: isDark),
                                ),
                              ),
                            ),                            
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['status'] ?? 'Status'}:',
                              Row(children: [
                                Switch(
                                  value: _status,
                                  onChanged: (v) => setState(() => _status = v),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labeled(
                              '${t['email'] ?? 'Email'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  style: AppTextStyles.body.copyWith(color: textColor),
                                  decoration: _inputDecoration(hint: 'teacher@school.edu', isDark: isDark),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['phone'] ?? 'Phone'}:',
                              SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  style: AppTextStyles.body.copyWith(color: textColor),
                                  decoration: _inputDecoration(hint: '+855 XX XXX XXX', isDark: isDark),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['address'] ?? 'Address'}:',
                              TextField(
                                controller: _addressCtrl,
                                maxLines: 5,
                                style: AppTextStyles.body.copyWith(color: textColor),
                                decoration: _inputDecoration(
                                    hint: t['address'] ?? 'Enter address',
                                    multiline: true,
                                    isDark: isDark),
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
        SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodySmall,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
        ),
      ],
    );
  }
}
