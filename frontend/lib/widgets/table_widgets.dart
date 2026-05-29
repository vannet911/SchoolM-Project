// lib/widgets/table_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/services/api_service.dart';
import 'package:schoolms_portal/utils/app_constants.dart';

/// Inline student detail panel
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

    final s = student;
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
                child: const Center(child: Icon(Icons.chevron_left, size: 24, color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              s['code']?.toString() ?? 'ST000',
              style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(t['edit'] ?? 'Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                side: BorderSide(color: isDark ? const Color(0xFF2A2A4A) : AppColors.border, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onDelete == null ? null : () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(t['confirm_delete'] ?? 'Confirm Delete'),
                    content: Text('${student['code'] ?? ''} - ${student['firstName'] ?? ''} ${student['lastName'] ?? ''}?'),
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
                if (ok == true) onDelete!();
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(t['delete'] ?? 'Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight, elevation: 0,
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
                              Expanded(child: _readField('${t['code'] ?? 'Code'}:', s['code']?.toString(), isDark: isDark)),
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
                                      decoration: _inputDecoration(isDark: isDark, suffix: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary)),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _readField('${t['first_name'] ?? 'First Name'}:', s['firstName']?.toString(), isDark: isDark),
                            const SizedBox(height: 16),
                            _readField('${t['last_name'] ?? 'Last Name'}:', s['lastName']?.toString(), isDark: isDark),
                            const SizedBox(height: 16),
                            _readField(
                              '${t['date_of_birth'] ?? 'Date of Birth'}:',
                              _fmtDate(s['dateOfBirth']),
                              suffix: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                              isDark: isDark,
                            ),
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
                            _readField('${t['classes'] ?? 'Class'}:', s['className']?.toString(), isDark: isDark),
                            const SizedBox(height: 16),
                            _labeled(
                              '${t['address'] ?? 'Address'}:',
                              TextField(
                                readOnly: true,
                                controller: TextEditingController(text: s['address']?.toString() ?? ''),
                                maxLines: 4,
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

/// Inline add / edit student form panel
class StudentFormPanel extends StatefulWidget {
  final Map<String, dynamic>? student;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const StudentFormPanel({super.key, this.student, required this.onSave, required this.onCancel});

  @override
  State<StudentFormPanel> createState() => _StudentFormPanelState();
}

class _StudentFormPanelState extends State<StudentFormPanel> {
  final _api = ApiService();
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
  bool _codeError = false;
  bool _firstError = false;
  int? _selectedClassId;
  List<Map<String, dynamic>> _availableClasses = [];
  bool _loadingClasses = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
    final s = widget.student;
    if (s != null) {
      _codeCtrl.text = s['code'] ?? '';
      _firstCtrl.text = s['firstName'] ?? '';
      _lastCtrl.text = s['lastName'] ?? '';
      _emailCtrl.text = s['email'] ?? '';
      _phoneCtrl.text = s['phoneNumber'] ?? '';
      final dob = s['dateOfBirth']?.toString() ?? '';
      _dobCtrl.text = dob.length >= 10 ? dob.substring(0, 10).replaceAll('-', '/') : dob;
      _addressCtrl.text = s['address'] ?? '';
      final g = s['gender']?.toString() ?? '';
      _gender = ['Male', 'Female'].contains(g) ? g : 'Male';
      final st = s['status'];
      _status = st is bool ? st : true;
      _selectedClassId = s['classId'] as int?;
    }
  }

  Future<void> _loadClasses() async {
    setState(() => _loadingClasses = true);
    try {
      final data = await _api.getClasses();
      if (!mounted) return;
      setState(() {
        _availableClasses = data.cast<Map<String, dynamic>>();
        _loadingClasses = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingClasses = false);
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
    final codeEmpty = _codeCtrl.text.trim().isEmpty;
    final firstEmpty = _firstCtrl.text.trim().isEmpty;
    if (codeEmpty || firstEmpty) {
      setState(() { _codeError = codeEmpty; _firstError = firstEmpty; });
      return;
    }
    setState(() { _saving = true; _codeError = false; _firstError = false; });
    try {
      await widget.onSave({
        'code': _codeCtrl.text.trim(),
        'firstName': _firstCtrl.text.trim(),
        'lastName': _lastCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'gender': _gender,
        'dateOfBirth': _dobCtrl.text.isNotEmpty ? _dobCtrl.text.replaceAll('/', '-') : null,
        'address': _addressCtrl.text.trim(),
        'classId': _selectedClassId,
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
        _dobCtrl.text = '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffix, bool multiline = false, bool isDark = false, bool hasError = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: isDark ? Colors.white70 : AppColors.textMuted),
      suffixIcon: suffix,
      enabledBorder: hasError ? OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.error)) : null,
      focusedBorder: hasError ? OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.error, width: 1.5)) : null,
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

  Widget _requiredLabeled(String label, Widget child) {
    return Column(
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
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ?? AppTranslations.translations['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final isEdit = widget.student != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Row(children: [
            SizedBox(
              width: 38, height: 38,
              child: InkWell(
                onTap: widget.onCancel,
                borderRadius: BorderRadius.circular(18),
                child: const Center(child: Icon(Icons.chevron_left, size: 24, color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEdit ? (t['edit_student'] ?? 'Edit Student') : (t['add_student'] ?? 'Add Student'),
              style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check, size: 18),
              label: Text(t['save'] ?? 'Save'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight, elevation: 0,
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
                                child: _requiredLabeled('${t['code'] ?? 'Code'}:',
                                  SizedBox(height: 44, child: TextField(controller: _codeCtrl, style: AppTextStyles.body.copyWith(color: textColor), decoration: _inputDecoration(hint: 'Code', isDark: isDark, hasError: _codeError)))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _labeled('${t['gender'] ?? 'Gender'}:',
                                  _StyledDropdown<String>(
                                    value: _gender,
                                    items: const ['Male', 'Female'],
                                    labels: [t['male'] ?? 'Male', t['female'] ?? 'Female'],
                                    hint: t['gender'] ?? 'Gender',
                                    isDark: isDark,
                                    onChanged: (v) => setState(() => _gender = v),
                                  )),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _requiredLabeled('${t['first_name'] ?? 'First Name'}:',
                              SizedBox(height: 44, child: TextField(controller: _firstCtrl, style: AppTextStyles.body.copyWith(color: textColor), decoration: _inputDecoration(hint: t['first_name'] ?? 'First name', isDark: isDark, hasError: _firstError)))),
                            const SizedBox(height: 16),
                            _labeled('${t['last_name'] ?? 'Last Name'}:',
                              SizedBox(height: 44, child: TextField(controller: _lastCtrl, style: AppTextStyles.body.copyWith(color: textColor), decoration: _inputDecoration(hint: t['last_name'] ?? 'Last name', isDark: isDark)))),
                            const SizedBox(height: 16),
                            _labeled('${t['date_of_birth'] ?? 'Date of Birth'}:',
                              SizedBox(height: 44, child: TextField(
                                controller: _dobCtrl, readOnly: true, onTap: _pickDate,
                                style: AppTextStyles.body.copyWith(color: textColor),
                                decoration: _inputDecoration(hint: 'YYYY/MM/DD', isDark: isDark, suffix: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary)),
                              ))),
                            const SizedBox(height: 16),
                            _labeled('${t['status'] ?? 'Status'}:',
                              Row(children: [
                                Switch(value: _status, onChanged: (v) => setState(() => _status = v), activeThumbColor: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(_status ? (t['active'] ?? 'Active') : (t['inactive'] ?? 'Inactive'), style: AppTextStyles.bodySmall),
                              ])),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labeled('${t['email'] ?? 'Email'}:',
                              SizedBox(height: 44, child: TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: AppTextStyles.body.copyWith(color: textColor), decoration: _inputDecoration(hint: 'student@school.edu', isDark: isDark)))),
                            const SizedBox(height: 16),
                            _labeled('${t['phone'] ?? 'Phone'}:',
                              SizedBox(height: 44, child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, style: AppTextStyles.body.copyWith(color: textColor), decoration: _inputDecoration(hint: '+855 XX XXX XXX', isDark: isDark)))),
                            const SizedBox(height: 16),
                            _labeled('${t['classes'] ?? 'Class'}:',
                              SizedBox(
                                height: 44,
                                child: _loadingClasses
                                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                                  : _StyledDropdown<int?>(
                                      value: _selectedClassId,
                                      items: [null, ..._availableClasses.map((c) => c['id'] as int?)],
                                      labels: [t['select_class'] ?? 'Select Class', ..._availableClasses.map((c) => c['name']?.toString() ?? '')],
                                      hint: t['select_class'] ?? 'Select Class',
                                      isDark: isDark,
                                      onChanged: (v) => setState(() => _selectedClassId = v),
                                    ),
                              )),
                            const SizedBox(height: 16),
                            _labeled('${t['address'] ?? 'Address'}:',
                              TextField(controller: _addressCtrl, maxLines: 5, style: AppTextStyles.body.copyWith(color: textColor), decoration: _inputDecoration(hint: t['address'] ?? 'Enter address', multiline: true, isDark: isDark))),
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
    final textColor = isSorted ? AppColors.primary : (isDark ? Colors.white70 : AppColors.textSecondary);
    final mainAxis = textAlign == TextAlign.center ? MainAxisAlignment.center : MainAxisAlignment.start;

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onSort,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: mainAxis,
          children: [
            Text(label, textAlign: textAlign, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: textColor)),
            if (onSort != null) ...[
              const SizedBox(width: 4),
              //const Spacer(),
              Icon(
                isSorted ? (sortAscending ? Icons.arrow_upward : Icons.arrow_downward) : Icons.unfold_more,
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

  const TeacherDetailPanel({super.key, required this.teacher, required this.onBack, this.onEdit, this.onDelete});

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
    return _labeled(label, SizedBox(height: 44, child: TextField(
      readOnly: true,
      controller: TextEditingController(text: value ?? ''),
      style: AppTextStyles.body.copyWith(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: _inputDecoration(hint: '—', suffix: suffix, isDark: isDark),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ?? AppTranslations.translations['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final chipBg = isDark ? const Color(0xFF1C2A4A) : AppColors.primarySurface;

    final s = teacher;
    final statusRaw = s['status'];
    final isActive = statusRaw is bool ? statusRaw : (statusRaw?.toString().toLowerCase() == 'active');
    final statusLabel = isActive ? (t['active'] ?? 'Active') : (t['inactive'] ?? 'Inactive');
    final statusColor = isActive ? AppColors.success : AppColors.error;

    // Extract subjects list
    final subjectsList = s['subjects'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Row(children: [
            SizedBox(width: 38, height: 38,
              child: InkWell(onTap: onBack, borderRadius: BorderRadius.circular(18),
                child: const Center(child: Icon(Icons.chevron_left, size: 24, color: AppColors.textSecondary)))),
            const SizedBox(width: 12),
            Text(s['code']?.toString() ?? 'TC000', style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(t['edit'] ?? 'Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                side: BorderSide(color: isDark ? const Color(0xFF2A2A4A) : AppColors.border, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onDelete == null ? null : () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(t['confirm_delete'] ?? 'Confirm Delete'),
                    content: Text('${teacher['code'] ?? ''} - ${teacher['name'] ?? ''}?'),
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
                if (ok == true) onDelete!();
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(t['delete'] ?? 'Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight, elevation: 0,
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
                              Expanded(child: _readField('${t['code'] ?? 'Code'}:', s['code']?.toString(), isDark: isDark)),
                              const SizedBox(width: 12),
                              Expanded(child: _labeled('${t['gender'] ?? 'Gender'}:', SizedBox(height: 44, child: TextField(
                                readOnly: true,
                                controller: TextEditingController(text: s['gender']?.toString() ?? ''),
                                style: AppTextStyles.body.copyWith(color: textColor),
                                decoration: _inputDecoration(isDark: isDark, suffix: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary)),
                              )))),
                            ]),
                            const SizedBox(height: 16),
                            _readField('${t['full_name'] ?? 'Full Name'}:', s['name']?.toString(), isDark: isDark),
                            const SizedBox(height: 16),
                            _readField('${t['date_of_birth'] ?? 'Date of Birth'}:', _fmtDate(s['dateOfBirth']),
                              suffix: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary), isDark: isDark),
                            const SizedBox(height: 16),
                            _labeled('${t['subject'] ?? 'Subjects'}:',
                              Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(minHeight: 44),
                                decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: subjectsList.isEmpty
                                  ? Text('—', style: AppTextStyles.body.copyWith(color: isDark ? Colors.white70 : AppColors.textMuted))
                                  : Wrap(
                                      spacing: 6, runSpacing: 4,
                                      children: subjectsList.map((sub) {
                                        final name = (sub is Map) ? (sub['name']?.toString() ?? '') : sub.toString();
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                                          child: Text(name, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                                        );
                                      }).toList(),
                                    ),
                              )),
                            const SizedBox(height: 16),
                            _labeled('${t['status'] ?? 'Status'}:',
                              Row(children: [
                                Switch(value: isActive, onChanged: null, activeThumbColor: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(statusLabel, style: AppTextStyles.body.copyWith(color: statusColor)),
                              ])),
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
                            _labeled('${t['address'] ?? 'Address'}:',
                              TextField(
                                readOnly: true,
                                controller: TextEditingController(text: s['address']?.toString() ?? ''),
                                maxLines: 5,
                                style: AppTextStyles.body.copyWith(color: textColor),
                                decoration: _inputDecoration(hint: '—', multiline: true, isDark: isDark),
                              )),
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

  const TeacherFormPanel({super.key, this.teacher, required this.onSave, required this.onCancel});

  @override
  State<TeacherFormPanel> createState() => _TeacherFormPanelState();
}

class _TeacherFormPanelState extends State<TeacherFormPanel> {
  final _api = ApiService();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _gender = 'Male';
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
    _loadSubjects();
    final s = widget.teacher;
    if (s != null) {
      _codeCtrl.text = s['code'] ?? '';
      _nameCtrl.text = s['name'] ?? '';
      _emailCtrl.text = s['email'] ?? '';
      _phoneCtrl.text = s['phoneNumber'] ?? '';
      final dob = s['dateOfBirth']?.toString() ?? '';
      _dobCtrl.text = dob.length >= 10 ? dob.substring(0, 10).replaceAll('-', '/') : dob;
      _addressCtrl.text = s['address'] ?? '';
      final g = s['gender']?.toString() ?? '';
      _gender = ['Male', 'Female'].contains(g) ? g : 'Male';
      final st = s['status'];
      _status = st is bool ? st : true;
      // Parse existing subject IDs
      final subjects = s['subjects'] as List<dynamic>? ?? [];
      _selectedSubjectIds = subjects.map((sub) => (sub is Map ? sub['id'] : sub) as int).toList();
    }
  }

  Future<void> _loadSubjects() async {
    setState(() => _loadingSubjects = true);
    try {
      final data = await _api.getSubjects();
      if (!mounted) return;
      setState(() {
        _availableSubjects = data.cast<Map<String, dynamic>>();
        _loadingSubjects = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSubjects = false);
    }
  }

  void _showSubjectPicker(BuildContext context, bool isDark, Map<String, String> t) {
    final tempSelected = List<int>.from(_selectedSubjectIds);
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text(t['subject'] ?? 'Subjects', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 300,
            child: _availableSubjects.isEmpty
              ? Text(t['no_data'] ?? 'No subjects available')
              : ListView(
                  shrinkWrap: true,
                  children: _availableSubjects.map((sub) {
                    final id = sub['id'] as int;
                    return CheckboxListTile(
                      dense: true,
                      title: Text('${sub['code']} — ${sub['name']}', style: AppTextStyles.body),
                      value: tempSelected.contains(id),
                      activeColor: AppColors.primary,
                      onChanged: (v) => setDState(() {
                        if (v == true) tempSelected.add(id);
                        else tempSelected.remove(id);
                      }),
                    );
                  }).toList(),
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t['cancel'] ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedSubjectIds = List.from(tempSelected));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: Text(t['confirm'] ?? 'OK'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
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
        'email': _emailCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'gender': _gender,
        'dateOfBirth': _dobCtrl.text.isNotEmpty ? _dobCtrl.text.replaceAll('/', '-') : null,
        'subjectIds': _selectedSubjectIds,
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
        _dobCtrl.text = '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffix, bool multiline = false, bool isDark = false, bool hasError = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: isDark ? Colors.white70 : AppColors.textMuted),
      suffixIcon: suffix,
      enabledBorder: hasError ? OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.error)) : null,
      focusedBorder: hasError ? OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.error, width: 1.5)) : null,
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

  Widget _requiredLabeled(String label, Widget child) {
    return Column(
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
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ?? AppTranslations.translations['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : AppColors.white;
    final chipBg = isDark ? const Color(0xFF1C2A4A) : AppColors.primarySurface;
    final isEdit = widget.teacher != null;

    final selectedSubjects = _availableSubjects.where((s) => _selectedSubjectIds.contains(s['id'])).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Row(children: [
            SizedBox(width: 38, height: 38,
              child: InkWell(onTap: widget.onCancel, borderRadius: BorderRadius.circular(18),
                child: const Center(child: Icon(Icons.chevron_left, size: 24, color: AppColors.textSecondary)))),
            const SizedBox(width: 12),
            Text(
              isEdit ? (t['edit_teacher'] ?? 'Edit Teacher') : (t['add_teacher'] ?? 'Add Teacher'),
              style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check, size: 18),
              label: Text(t['save'] ?? 'Save'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight, elevation: 0,
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
                                child: _requiredLabeled('${t['code'] ?? 'Code'}:',
                                  SizedBox(height: 44, child: TextField(controller: _codeCtrl, style: AppTextStyles.body.copyWith(color: textColor), decoration: _inputDecoration(hint: 'Code', isDark: isDark, hasError: _codeError)))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _labeled('${t['gender'] ?? 'Gender'}:',
                                  _StyledDropdown<String>(
                                    value: _gender,
                                    items: const ['Male', 'Female'],
                                    labels: [t['male'] ?? 'Male', t['female'] ?? 'Female'],
                                    hint: t['gender'] ?? 'Gender',
                                    isDark: isDark,
                                    onChanged: (v) => setState(() => _gender = v),
                                  )),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _requiredLabeled('${t['full_name'] ?? 'Full Name'}:',
                              SizedBox(height: 44, child: TextField(controller: _nameCtrl, style: AppTextStyles.body.copyWith(color: textColor), decoration: _inputDecoration(hint: t['full_name'] ?? 'Full name', isDark: isDark, hasError: _nameError)))),
                            const SizedBox(height: 16),
                            _labeled('${t['date_of_birth'] ?? 'Date of Birth'}:',
                              SizedBox(height: 44, child: TextField(
                                controller: _dobCtrl, readOnly: true, onTap: _pickDate,
                                style: AppTextStyles.body.copyWith(color: textColor),
                                decoration: _inputDecoration(hint: 'YYYY/MM/DD', isDark: isDark, suffix: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary)),
                              ))),
                            const SizedBox(height: 16),
                            _labeled('${t['subject'] ?? 'Subjects'}:',
                              InkWell(
                                onTap: _loadingSubjects ? null : () => _showSubjectPicker(context, isDark, t),
                                child: Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(minHeight: 44),
                                  decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: _loadingSubjects
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : selectedSubjects.isEmpty
                                      ? Row(children: [
                                          Text(t['subject'] ?? 'Select subjects...', style: AppTextStyles.body.copyWith(color: isDark ? Colors.white70 : AppColors.textMuted)),
                                          const Spacer(),
                                          Icon(Icons.add_circle_outline, size: 18, color: isDark ? Colors.white70 : AppColors.textSecondary),
                                        ])
                                      : Wrap(
                                          spacing: 6, runSpacing: 4,
                                          children: [
                                            ...selectedSubjects.map((sub) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                                              child: Text(sub['name']?.toString() ?? '', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                                            )),
                                            Icon(Icons.edit_outlined, size: 16, color: isDark ? Colors.white54 : AppColors.textMuted),
                                          ],
                                        ),
                                ),
                              )),
                            const SizedBox(height: 16),
                            _labeled('${t['status'] ?? 'Status'}:',
                              Row(children: [
                                Switch(value: _status, onChanged: (v) => setState(() => _status = v), activeThumbColor: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(_status ? (t['active'] ?? 'Active') : (t['inactive'] ?? 'Inactive'), style: AppTextStyles.bodySmall),
                              ])),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labeled('${t['email'] ?? 'Email'}:',
                              SizedBox(height: 44, child: TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: AppTextStyles.body.copyWith(color: textColor), decoration: _inputDecoration(hint: 'teacher@school.edu', isDark: isDark)))),
                            const SizedBox(height: 16),
                            _labeled('${t['phone'] ?? 'Phone'}:',
                              SizedBox(height: 44, child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, style: AppTextStyles.body.copyWith(color: textColor), decoration: _inputDecoration(hint: '+855 XX XXX XXX', isDark: isDark)))),
                            const SizedBox(height: 16),
                            _labeled('${t['address'] ?? 'Address'}:',
                              TextField(controller: _addressCtrl, maxLines: 5, style: AppTextStyles.body.copyWith(color: textColor), decoration: _inputDecoration(hint: t['address'] ?? 'Enter address', multiline: true, isDark: isDark))),
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
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.06)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              filled: true,
              fillColor: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Styled dropdown — matches language selector style ─────────────────────────
class _Option<T> {
  final T value;
  const _Option(this.value);
}

class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final List<String> labels;
  final String hint;
  final bool isDark;
  final ValueChanged<T> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.labels,
    required this.hint,
    required this.isDark,
    required this.onChanged,
  });

  void _open(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final activeColor = isDark ? const Color(0xFF6DBF67) : AppColors.primary;

    final renderBox = context.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final rect = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(
            Offset(0, renderBox.size.height), ancestor: overlay),
        renderBox.localToGlobal(
            renderBox.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final buttonWidth = renderBox.size.width;

    showMenu<_Option<T>>(
      context: context,
      position: rect,
      elevation: 4,
      color: bgColor,
      constraints: BoxConstraints(minWidth: buttonWidth, maxWidth: buttonWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor),
      ),
      items: items.asMap().entries.map((e) {
        final isSelected = e.value == value;
        return PopupMenuItem<_Option<T>>(
          value: _Option<T>(e.value),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Row(children: [
            Expanded(
              child: Text(
                labels[e.key],
                style: AppTextStyles.body.copyWith(
                  color: isSelected ? activeColor : textColor,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, size: 15, color: activeColor),
          ]),
        );
      }).toList(),
    ).then((opt) {
      if (opt != null) onChanged(opt.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white70 : AppColors.textMuted;
    final iconColor = isDark ? Colors.white70 : AppColors.textSecondary;

    final idx = items.indexOf(value);
    final display = idx >= 0 ? labels[idx] : null;

    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              display ?? hint,
              style: AppTextStyles.body.copyWith(
                color: display != null ? textColor : mutedColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: iconColor),
        ]),
      ),
    );
  }
}
