// lib/widgets/table_widgets.dart
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/auth_provider.dart';
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

  static Color _readFill(bool isDark) =>
      isDark ? const Color(0xFF0D0D1C) : const Color(0xFFF2F3F7);

  InputDecoration _inputDecoration({String? hint, Widget? suffix, bool multiline = false, bool isDark = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: isDark ? Colors.white70 : AppColors.textMuted),
      suffixIcon: suffix,
      filled: true,
      fillColor: _readFill(isDark),
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
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(
              width: 38,
              height: 38,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(18),
                child: const Center(child: Icon(Icons.arrow_back_rounded, size: 22, color: AppColors.textSecondary)),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: _StudentAvatar(
                          photoUrl: s['photoUrl']?.toString(),
                          firstName: s['firstName']?.toString() ?? '',
                          lastName: s['lastName']?.toString() ?? '',
                          size: 104,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
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

/// Circular avatar — matches user profile style (bordered circle, cover image, initials fallback)
class _StudentAvatar extends StatelessWidget {
  final String? photoUrl;
  final String firstName;
  final String lastName;
  final double size;
  final bool isDark;
  final bool showCamera;
  final VoidCallback? onTap;

  const _StudentAvatar({
    this.photoUrl,
    required this.firstName,
    required this.lastName,
    this.size = 80,
    this.isDark = false,
    this.showCamera = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.primary.withValues(alpha: 0.3);
    final bg = isDark ? const Color(0xFF1C2A4A) : AppColors.primarySurface;
    final effectiveUrl = (photoUrl != null && photoUrl!.isNotEmpty)
        ? photoUrl!
        : AuthProvider.defaultPhotoUrl;

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              effectiveUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(Icons.person_rounded, size: size * 0.55, color: AppColors.primary.withValues(alpha: 0.7)),
              ),
            ),
            if (showCamera)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: size * 0.28,
                  color: Colors.black.withValues(alpha: 0.45),
                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: avatar),
      );
    }
    return avatar;
  }
}

/// Inline add / edit student form panel
class StudentFormPanel extends StatefulWidget {
  final Map<String, dynamic>? student;
  final Future<void> Function(Map<String, dynamic> data, html.File? photoFile) onSave;
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
  html.File? _pickedPhoto;
  String? _photoPreviewUrl;
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
      _photoPreviewUrl = s['photoUrl']?.toString();
    }
  }

  void _pickPhoto() {
    final input = html.FileUploadInputElement()
      ..accept = 'image/jpeg,image/png,image/webp,image/gif'
      ..click();
    input.onChange.listen((_) {
      final file = input.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoad.listen((_) {
        if (!mounted) return;
        setState(() {
          _pickedPhoto = file;
          _photoPreviewUrl = reader.result as String?;
        });
      });
    });
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
      await widget.onSave(
        {
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
        },
        _pickedPhoto,
      );
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
                child: const Center(child: Icon(Icons.arrow_back_rounded, size: 22, color: AppColors.textSecondary)),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: _StudentAvatar(
                          photoUrl: _photoPreviewUrl,
                          firstName: _firstCtrl.text,
                          lastName: _lastCtrl.text,
                          size: 104,
                          isDark: isDark,
                          showCamera: true,
                          onTap: _pickPhoto,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column: Code, Gender, First Name, Last Name, DOB, Status
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: _requiredLabeled('${t['code'] ?? 'Code'}:',
                                    SizedBox(height: 44, child: TextField(controller: _codeCtrl, style: AppTextStyles.body.copyWith(color: textColor), decoration: _inputDecoration(hint: 'Code', isDark: isDark, hasError: _codeError))))),
                                  const SizedBox(width: 12),
                                  Expanded(child: _labeled('${t['gender'] ?? 'Gender'}:',
                                    _StyledDropdown<String>(
                                      value: _gender,
                                      items: const ['Male', 'Female'],
                                      labels: [t['male'] ?? 'Male', t['female'] ?? 'Female'],
                                      hint: t['gender'] ?? 'Gender',
                                      isDark: isDark,
                                      onChanged: (v) => setState(() => _gender = v),
                                    ))),
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
                          // Right column: Email, Phone, Class, Address
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
                                  TextField(controller: _addressCtrl, maxLines: 4, style: AppTextStyles.body.copyWith(color: textColor), decoration: _inputDecoration(hint: t['address'] ?? 'Enter address', multiline: true, isDark: isDark))),
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
            Flexible(
              child: Text(
                label,
                textAlign: textAlign,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
            if (onSort != null) ...[
              const SizedBox(width: 4),
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
      filled: true,
      fillColor: StudentDetailPanel._readFill(isDark),
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
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(width: 38, height: 38,
              child: InkWell(onTap: onBack, borderRadius: BorderRadius.circular(18),
                child: const Center(child: Icon(Icons.arrow_back_rounded, size: 22, color: AppColors.textSecondary)))),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: _StudentAvatar(
                          photoUrl: s['photoUrl']?.toString(),
                          firstName: s['name']?.toString() ?? '',
                          lastName: '',
                          size: 104,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
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
                                decoration: BoxDecoration(color: StudentDetailPanel._readFill(isDark), border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
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
  final Future<void> Function(Map<String, dynamic> data, html.File? photoFile) onSave;
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
  html.File? _pickedPhoto;
  String? _photoPreviewUrl;

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
      final subjects = s['subjects'] as List<dynamic>? ?? [];
      _selectedSubjectIds = subjects.map((sub) => (sub is Map ? sub['id'] : sub) as int).toList();
      _photoPreviewUrl = s['photoUrl']?.toString();
    }
  }

  Future<void> _pickPhoto() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return;
    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;
    setState(() {
      _pickedPhoto = file;
      _photoPreviewUrl = reader.result as String?;
    });
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
        builder: (ctx, setDState) {
          final dlgDark = Theme.of(ctx).brightness == Brightness.dark;
          final dlgBg = dlgDark ? const Color(0xFF1C2A4A) : Colors.white;
          final titleColor = dlgDark ? Colors.white : AppColors.textPrimary;
          final itemColor = dlgDark ? Colors.white70 : AppColors.textPrimary;
          final checkBorder = dlgDark ? const Color(0xFF4A5568) : AppColors.border;
          return AlertDialog(
            backgroundColor: dlgBg,
            title: Text(t['subject'] ?? 'Subjects',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: titleColor)),
            content: SizedBox(
              width: 300,
              child: _availableSubjects.isEmpty
                ? Text(t['no_data'] ?? 'No subjects available',
                    style: AppTextStyles.body.copyWith(color: itemColor))
                : ListView(
                    shrinkWrap: true,
                    children: _availableSubjects.map((sub) {
                      final id = sub['id'] as int;
                      return CheckboxListTile(
                        dense: true,
                        title: Text('${sub['code']} — ${sub['name']}',
                            style: AppTextStyles.body.copyWith(color: itemColor)),
                        value: tempSelected.contains(id),
                        activeColor: AppColors.primary,
                        checkColor: Colors.white,
                        side: BorderSide(color: checkBorder, width: 1.5),
                        onChanged: (v) => setDState(() {
                          if (v == true) { tempSelected.add(id); }
                          else { tempSelected.remove(id); }
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
          );
        },
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
      }, _pickedPhoto);
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
                child: const Center(child: Icon(Icons.arrow_back_rounded, size: 22, color: AppColors.textSecondary)))),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: _StudentAvatar(
                          photoUrl: _photoPreviewUrl,
                          firstName: _nameCtrl.text.split(' ').first,
                          lastName: _nameCtrl.text.split(' ').skip(1).join(' '),
                          size: 104,
                          isDark: isDark,
                          showCamera: true,
                          onTap: _pickPhoto,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
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

/// Animated shimmer skeleton loader for data tables
class SkeletonTableLoader extends StatefulWidget {
  final int rowCount;
  const SkeletonTableLoader({super.key, this.rowCount = 9});

  @override
  State<SkeletonTableLoader> createState() => _SkeletonTableLoaderState();
}

class _SkeletonTableLoaderState extends State<SkeletonTableLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1C2A4A) : const Color(0xFFE8EBF2);
    final shimmer = isDark ? const Color(0xFF2A3D60) : const Color(0xFFF5F6FA);
    final divider = isDark ? const Color(0xFF162035) : const Color(0xFFF0F2F5);

    // widths used to stagger row content so rows don't look identical
    final widths = [0.55, 0.70, 0.45, 0.60, 0.50, 0.65, 0.40, 0.55, 0.70];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // single shimmer sweep across the whole column at once
        final t = _ctrl.value;
        final shimmerBegin = Alignment(-3.0 + t * 6.0, 0);
        final shimmerEnd = Alignment(-1.0 + t * 6.0, 0);

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: shimmerBegin,
            end: shimmerEnd,
            colors: [base, shimmer, base],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Column(
            children: List.generate(widget.rowCount, (i) {
              final w = widths[i % widths.length];
              return _SkeletonRow(
                fillRatio: w,
                base: base,
                divider: divider,
              );
            }),
          ),
        );
      },
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  final double fillRatio;
  final Color base;
  final Color divider;

  const _SkeletonRow({
    required this.fillRatio,
    required this.base,
    required this.divider,
  });

  Widget _block({double? w, double h = 12, double r = 5}) =>
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: divider, width: 1)),
      ),
      child: Row(
        children: [
          // Checkbox
          _block(w: 16, h: 16, r: 3),
          const SizedBox(width: 14),
          // Index
          Expanded(flex: 1, child: Center(child: _block(w: 18, h: 11))),
          const SizedBox(width: 8),
          // Col 1 — code
          Expanded(flex: 2, child: _block(w: double.infinity, h: 12)),
          const SizedBox(width: 8),
          // Col 2 — name (longer)
          Expanded(flex: 3, child: FractionallySizedBox(
            widthFactor: fillRatio,
            alignment: Alignment.centerLeft,
            child: _block(w: double.infinity, h: 12),
          )),
          const SizedBox(width: 8),
          // Col 3
          Expanded(flex: 2, child: FractionallySizedBox(
            widthFactor: 0.65,
            alignment: Alignment.centerLeft,
            child: _block(w: double.infinity, h: 12),
          )),
          const SizedBox(width: 8),
          // Col 4
          Expanded(flex: 2, child: FractionallySizedBox(
            widthFactor: 0.55,
            alignment: Alignment.centerLeft,
            child: _block(w: double.infinity, h: 12),
          )),
          const SizedBox(width: 8),
          // Col 5
          Expanded(flex: 3, child: FractionallySizedBox(
            widthFactor: fillRatio * 0.9,
            alignment: Alignment.centerLeft,
            child: _block(w: double.infinity, h: 12),
          )),
          const SizedBox(width: 8),
          // Status pill
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                width: 62,
                height: 22,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ],
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

// ── Attendance Detail Panel ───────────────────────────────────────────────────

class AttendanceDetailPanel extends StatelessWidget {
  final Map<String, dynamic> summary;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AttendanceDetailPanel({
    super.key,
    required this.summary,
    required this.onBack,
    this.onEdit,
    this.onDelete,
  });

  static const _kPeriodLabels = {
    1: '07 AM  07:00 – 08:00', 2: '08 AM  08:00 – 09:00',
    3: '09 AM  09:00 – 10:00', 4: '10 AM  10:00 – 11:00',
    5: '11 AM  11:00 – 12:00', 6: '01 PM  01:00 – 02:00 PM',
    7: '02 PM  02:00 – 03:00 PM', 8: '03 PM  03:00 – 04:00 PM',
    9: '04 PM  04:00 – 05:00 PM', 10: '05 PM  05:00 – 06:00 PM',
  };

  static String _fmtDate(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10).replaceAll('-', '/') : s;
  }

  InputDecoration _inputDeco({bool isDark = false, bool multiline = false}) => InputDecoration(
    hintText: '—',
    hintStyle: AppTextStyles.body.copyWith(color: isDark ? Colors.white70 : AppColors.textMuted),
    filled: true,
    fillColor: StudentDetailPanel._readFill(isDark),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: multiline ? 14 : 0),
  );

  Widget _labeled(String label, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      child,
    ],
  );

  Widget _readField(String label, String? value, {bool isDark = false, Widget? suffix}) =>
      _labeled(label, SizedBox(height: 44, child: TextField(
        readOnly: true,
        controller: TextEditingController(text: value ?? ''),
        style: AppTextStyles.body.copyWith(color: isDark ? Colors.white : AppColors.textPrimary),
        decoration: _inputDeco(isDark: isDark).copyWith(suffixIcon: suffix),
      )));

  Widget _sectionTitle(String label) => Text(label,
      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondary));

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ?? AppTranslations.translations['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white54 : AppColors.textSecondary;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;

    final s = summary;
    final period = (s['period'] as num?)?.toInt();
    final periodStr = period != null ? '${t['period'] ?? 'Period'} $period  ${_kPeriodLabels[period] ?? ''}' : null;
    final records = (s['records'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final total   = s['total']   as int?    ?? records.length;
    final present = s['present'] as int?    ?? 0;
    final absent  = s['absent']  as int?    ?? 0;
    final late    = s['late']    as int?    ?? 0;
    final rate    = s['rate']    as double? ?? 0.0;

    Widget statCard(String label, String value, Color color) => Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: AppTextStyles.body.copyWith(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.body.copyWith(color: mutedColor, fontSize: 12)),
      ]),
    ));

    Color statusColor(String status) => switch (status.toLowerCase()) {
      'present' => const Color(0xFF16A34A),
      'absent'  => AppColors.error,
      'late'    => const Color(0xFFD97706),
      'excused' => const Color(0xFF2196F3),
      _         => mutedColor,
    };

    String statusLabel(String status) => switch (status.toLowerCase()) {
      'present' => t['present'] ?? 'Present',
      'absent'  => t['absent']  ?? 'Absent',
      'late'    => t['late']    ?? 'Late',
      'excused' => t['excused'] ?? 'Excused',
      _         => status,
    };

    final btnStyle = OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryLight, elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      side: BorderSide(color: borderColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 38, height: 38,
            child: InkWell(onTap: onBack, borderRadius: BorderRadius.circular(18),
              child: const Center(child: Icon(Icons.arrow_back_rounded, size: 22, color: AppColors.textSecondary)))),
          const SizedBox(width: 12),
          Text(_fmtDate(s['date']),
            style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(t['edit'] ?? 'Edit'), style: btnStyle),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onDelete == null ? null : () async {
              final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                title: Text(t['confirm_delete'] ?? 'Confirm Delete'),
                content: Text('${_fmtDate(s['date'])} — ${s['className'] ?? ''} / ${s['subjectName'] ?? ''}'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t['cancel'] ?? 'Cancel')),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                    child: Text(t['delete'] ?? 'Delete')),
                ],
              ));
              if (ok == true) onDelete!();
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(t['delete'] ?? 'Delete'),
            style: btnStyle,
          ),
        ]),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionTitle(t['session_info'] ?? 'Session Info'),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _readField('${t['code'] ?? 'Code'}:', s['code']?.toString(), isDark: isDark)),
                const SizedBox(width: 16),
                Expanded(child: _readField('${t['teacher_name'] ?? 'Teacher Name'}:', s['teacherName']?.toString(), isDark: isDark)),
              ]),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _readField('${t['date'] ?? 'Date'}:', _fmtDate(s['date']), isDark: isDark,
                  suffix: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary))),
                const SizedBox(width: 16),
                Expanded(child: _readField('${t['period'] ?? 'Period'}:', periodStr, isDark: isDark)),
              ]),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _readField('${t['class_name'] ?? 'Class'}:', s['className']?.toString(), isDark: isDark)),
                const SizedBox(width: 16),
                Expanded(child: _readField('${t['subject'] ?? 'Subject'}:', s['subjectName']?.toString(), isDark: isDark)),
              ]),
              const SizedBox(height: 16),
              _labeled('${t['remark'] ?? 'Remark'}:',
                TextField(
                  readOnly: true,
                  controller: TextEditingController(text: s['remark']?.toString() ?? ''),
                  maxLines: 3,
                  style: AppTextStyles.body.copyWith(color: isDark ? Colors.white : AppColors.textPrimary),
                  decoration: _inputDeco(isDark: isDark, multiline: true),
                ),
              ),
              const SizedBox(height: 28),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 28),
              _sectionTitle(t['attendance'] ?? 'Attendance'),
              const SizedBox(height: 12),
              Row(children: [
                statCard(t['total_students'] ?? 'Total', '$total',                       AppColors.primary),
                const SizedBox(width: 8),
                statCard(t['present'] ?? 'Present',       '$present',                    const Color(0xFF16A34A)),
                const SizedBox(width: 8),
                statCard(t['absent']  ?? 'Absent',        '$absent',                     AppColors.error),
                const SizedBox(width: 8),
                statCard(t['late']    ?? 'Late',          '$late',                       const Color(0xFFD97706)),
                const SizedBox(width: 8),
                statCard(t['rate']    ?? 'Rate',          '${rate.toStringAsFixed(1)}%', const Color(0xFF2196F3)),
              ]),
              if (records.isNotEmpty) ...[
                const SizedBox(height: 28),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 28),
                _sectionTitle(t['students'] ?? 'Students'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(children: records.asMap().entries.map((entry) {
                    final idx    = entry.key;
                    final r      = entry.value;
                    final name   = r['studentName']?.toString() ?? '—';
                    final code   = r['studentCode']?.toString() ?? '';
                    final status = r['status']?.toString() ?? 'Present';
                    final sColor = statusColor(status);
                    final sLabel = statusLabel(status);
                    final isLast = idx == records.length - 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: idx.isOdd
                            ? (isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF5F7FA))
                            : Colors.transparent,
                        border: isLast ? null : Border(bottom: BorderSide(color: borderColor)),
                        borderRadius: BorderRadius.vertical(
                          top: idx == 0 ? const Radius.circular(10) : Radius.zero,
                          bottom: isLast ? const Radius.circular(10) : Radius.zero,
                        ),
                      ),
                      child: Row(children: [
                        SizedBox(width: 28,
                          child: Text('${idx + 1}', style: AppTextStyles.body.copyWith(color: mutedColor), textAlign: TextAlign.center)),
                        const SizedBox(width: 12),
                        if (code.isNotEmpty) ...[
                          Text(code, style: AppTextStyles.body.copyWith(
                            color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(width: 10),
                        ],
                        Expanded(child: Text(name, style: AppTextStyles.body.copyWith(color: textColor))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: sColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(sLabel,
                            style: AppTextStyles.body.copyWith(color: sColor, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ]),
                    );
                  }).toList()),
                ),
              ],
            ]),
          ),
        )),
      )),
    ]);
  }
}

// ── Timetable Detail Panel ─────────────────────────────────────────────────────

class TimetableDetailPanel extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TimetableDetailPanel({
    super.key,
    required this.entry,
    required this.onBack,
    this.onEdit,
    this.onDelete,
  });

  static const _kPeriodLabels = {
    1: '07 AM  07:00 – 08:00', 2: '08 AM  08:00 – 09:00',
    3: '09 AM  09:00 – 10:00', 4: '10 AM  10:00 – 11:00',
    5: '11 AM  11:00 – 12:00', 6: '01 PM  01:00 – 02:00 PM',
    7: '02 PM  02:00 – 03:00 PM', 8: '03 PM  03:00 – 04:00 PM',
    9: '04 PM  04:00 – 05:00 PM', 10: '05 PM  05:00 – 06:00 PM',
    -1: 'Lunch  12:00 – 01:00 PM',
  };

  InputDecoration _inputDeco({bool isDark = false}) => InputDecoration(
    hintText: '—',
    hintStyle: AppTextStyles.body.copyWith(color: isDark ? Colors.white70 : AppColors.textMuted),
    filled: true,
    fillColor: StudentDetailPanel._readFill(isDark),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
  );

  Widget _labeled(String label, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      child,
    ],
  );

  Widget _readField(String label, String? value, {bool isDark = false}) =>
      _labeled(label, SizedBox(height: 44, child: TextField(
        readOnly: true,
        controller: TextEditingController(text: value ?? ''),
        style: AppTextStyles.body.copyWith(color: isDark ? Colors.white : AppColors.textPrimary),
        decoration: _inputDeco(isDark: isDark),
      )));

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale] ?? AppTranslations.translations['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;

    final e = entry;
    final period      = (e['period'] as num?)?.toInt() ?? 0;
    final dayRaw      = e['day']?.toString() ?? '';
    final dayLabel    = t[dayRaw.toLowerCase()] ?? dayRaw;
    final periodLabel = _kPeriodLabels[period] ?? '${t['period'] ?? 'Period'} $period';

    final btnStyle = OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryLight, elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      side: BorderSide(color: borderColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 38, height: 38,
            child: InkWell(onTap: onBack, borderRadius: BorderRadius.circular(18),
              child: const Center(child: Icon(Icons.arrow_back_rounded, size: 22, color: AppColors.textSecondary)))),
          const SizedBox(width: 12),
          Expanded(child: Text('$dayLabel — $periodLabel',
            style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
            overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 12),
          OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(t['edit'] ?? 'Edit'), style: btnStyle),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onDelete == null ? null : () async {
              final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                title: Text(t['confirm_delete'] ?? 'Confirm Delete'),
                content: Text(t['confirm_delete_timetable'] ?? 'Delete this timetable entry?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t['cancel'] ?? 'Cancel')),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                    child: Text(t['delete'] ?? 'Delete')),
                ],
              ));
              if (ok == true) onDelete!();
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(t['delete'] ?? 'Delete'),
            style: btnStyle,
          ),
        ]),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _readField('${t['day'] ?? 'Day'}:', dayLabel, isDark: isDark)),
                const SizedBox(width: 16),
                Expanded(child: _readField('${t['period'] ?? 'Period'}:', periodLabel, isDark: isDark)),
              ]),
              const SizedBox(height: 16),
              _readField('${t['class_name'] ?? 'Class'}:', e['className']?.toString(), isDark: isDark),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _readField('${t['subject'] ?? 'Subject'}:', e['subjectName']?.toString(), isDark: isDark)),
                const SizedBox(width: 16),
                Expanded(child: _readField('${t['teacher_name'] ?? 'Teacher Name'}:', e['teacherName']?.toString(), isDark: isDark)),
              ]),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _readField('${t['room'] ?? 'Room'}:', e['room']?.toString(), isDark: isDark)),
                const SizedBox(width: 16),
                Expanded(child: _readField('${t['academic_year'] ?? 'Academic Year'}:', e['academicYear']?.toString(), isDark: isDark)),
              ]),
            ]),
          ),
        )),
      )),
    ]);
  }
}
