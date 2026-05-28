// lib/screens/profile.dart
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/auth_provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/providers/nav_provider.dart';
import 'package:schoolms_portal/services/api_service.dart';
import 'package:schoolms_portal/utils/app_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _savingProfile = false;
  bool _uploadingPhoto = false;

  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _changingPassword = false;
  bool _showCurrentPwd = false;
  bool _showNewPwd = false;
  bool _showConfirmPwd = false;
  bool _newPwdError = false;
  bool _confirmPwdError = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl.text = auth.displayName;
    _emailCtrl.text = auth.displayEmail;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Toast(
        message: msg,
        isError: isError,
        onDismiss: () { if (entry.mounted) entry.remove(); },
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  void _pickAndUploadPhoto() {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.onChange.listen((_) async {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final file = files.first;
      if (!mounted) return;
      setState(() => _uploadingPhoto = true);
      try {
        final auth = context.read<AuthProvider>();
        final id = auth.currentUser?['id'];
        if (id == null) {
          _showSnack('User ID not found', isError: true);
          return;
        }
        final data = await _api.uploadUserPhoto(id, file);
        auth.updateCurrentUser({'photoUrl': data['photoUrl'] as String?});
        _showSnack('Photo updated successfully');
      } catch (e) {
        _showSnack(
          e.toString().contains('Network error') || e.toString().contains('Connection')
              ? 'Cannot connect to server'
              : e.toString(),
          isError: true,
        );
      } finally {
        if (mounted) setState(() => _uploadingPhoto = false);
      }
    });
    input.click();
  }

  Future<void> _saveProfile(Map<String, String> t) async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _savingProfile = true);
    try {
      final auth = context.read<AuthProvider>();
      final newName = _nameCtrl.text.trim();
      final id = auth.currentUser?['id'];
      if (id != null) {
        await _api.updateUser(id, {
          'username': newName,
          'email': _emailCtrl.text.trim(),
        });
      }
      auth.updateCurrentUser({'username': newName});
      _showSnack(t['profile_updated']!);
    } catch (e) {
      _showSnack(
        e.toString().contains('Network error') || e.toString().contains('Connection')
            ? t['cannot_connect_server']!
            : t['save_failed']!,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword(Map<String, String> t) async {
    final newPwd = _newPwdCtrl.text;
    final newEmpty = newPwd.isEmpty;
    final mismatch = newPwd != _confirmPwdCtrl.text;
    if (newEmpty || mismatch) {
      setState(() { _newPwdError = newEmpty; _confirmPwdError = mismatch; });
      return;
    }
    setState(() { _changingPassword = true; _newPwdError = false; _confirmPwdError = false; });
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?['id'];
      if (userId == null) {
        _showSnack(t['failed_change_password']!, isError: true);
        return;
      }
      await _api.post('/auth/change-password', {
        'userId': userId,
        'currentPassword': _currentPwdCtrl.text,
        'newPassword': newPwd,
      });
      _currentPwdCtrl.clear();
      _newPwdCtrl.clear();
      _confirmPwdCtrl.clear();
      _showSnack(t['password_changed']!);
    } catch (e) {
      final msg = e.toString();
      _showSnack(
        msg.contains('Network error') || msg.contains('Connection')
            ? t['cannot_connect_server']!
            : msg.contains('401') || msg.contains('incorrect')
                ? t['current_password_incorrect']!
                : t['failed_change_password']!,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  InputDecoration _inputDecoration({
    String? hint,
    Widget? suffix,
    bool isDark = false,
    bool hasError = false,
    bool readOnly = false,
  }) {
    final normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
          color: isDark ? const Color(0xFF2A2A4A) : AppColors.border),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body
          .copyWith(color: isDark ? Colors.white38 : AppColors.textMuted),
      suffixIcon: suffix,
      filled: true,
      fillColor: readOnly
          ? (isDark ? const Color(0xFF0F1729) : const Color(0xFFF9FAFB))
          : (isDark ? const Color(0xFF1C2A4A) : AppColors.white),
      border: hasError ? errorBorder : normalBorder,
      enabledBorder: hasError ? errorBorder : normalBorder,
      focusedBorder: hasError
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5))
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
            color: isDark ? const Color(0xFF2A2A4A) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title,
                style: AppTextStyles.heading3
                    .copyWith(color: AppColors.primary)),
          ]),
          const SizedBox(height: 16),
          Divider(
              color: isDark ? const Color(0xFF2A2A4A) : AppColors.border,
              height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar card
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16213E) : AppColors.white,
                    borderRadius:
                        BorderRadius.circular(AppConstants.cardRadius),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primarySurface,
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 2),
                          ),
                          child: ClipOval(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (_uploadingPhoto)
                                  Container(
                                    color: AppColors.primarySurface,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary),
                                      ),
                                    ),
                                  )
                                else
                                  Image.network(
                                    auth.photoUrl ?? AuthProvider.defaultPhotoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person,
                                        size: 36,
                                        color: AppColors.primary),
                                  ),
                                if (!_uploadingPhoto)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 22,
                                      color: Colors.black.withValues(alpha: 0.45),
                                      child: const Icon(Icons.camera_alt,
                                          size: 13, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(auth.displayName,
                              style: AppTextStyles.heading3
                                  .copyWith(color: textColor)),
                          const SizedBox(height: 4),
                          Text(auth.displayEmail,
                              style: AppTextStyles.body
                                  .copyWith(color: mutedColor)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.read<NavProvider>().goBack(),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: Text(t['back'] ?? 'Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryLight,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                        side: BorderSide(color: borderColor, width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile info
                    Expanded(
                      child: _card(
                        title: t['profile_information'] ?? 'Profile Information',
                        icon: Icons.person_outline,
                        isDark: isDark,
                        children: [
                          _labeled(
                            '${t['display_name'] ?? 'Display Name'}:',
                            SizedBox(
                              height: 44,
                              child: TextField(
                                controller: _nameCtrl,
                                style: AppTextStyles.body
                                    .copyWith(color: textColor),
                                decoration: _inputDecoration(
                                    hint: t['enter_display_name'],
                                    isDark: isDark),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _labeled(
                            '${t['email'] ?? 'Email'}:',
                            SizedBox(
                              height: 44,
                              child: TextField(
                                controller: _emailCtrl,
                                readOnly: true,
                                style: AppTextStyles.body
                                    .copyWith(color: mutedColor),
                                decoration: _inputDecoration(
                                    isDark: isDark, readOnly: true),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _labeled(
                            '${t['username'] ?? 'Username'}:',
                            SizedBox(
                              height: 44,
                              child: TextField(
                                readOnly: true,
                                controller: TextEditingController(
                                    text: auth.currentUser?['username'] ??
                                        auth.displayName),
                                style: AppTextStyles.body
                                    .copyWith(color: mutedColor),
                                decoration: _inputDecoration(
                                    isDark: isDark, readOnly: true),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _savingProfile ? null : () => _saveProfile(t),
                              icon: _savingProfile
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : const Icon(Icons.save_outlined, size: 18),
                              label: Text(t['save_profile'] ?? 'Save Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Change password
                    Expanded(
                      child: _card(
                        title: t['change_password'] ?? 'Change Password',
                        icon: Icons.lock_outline,
                        isDark: isDark,
                        children: [
                          _labeled(
                            '${t['current_password'] ?? 'Current Password'}:',
                            SizedBox(
                              height: 44,
                              child: TextField(
                                controller: _currentPwdCtrl,
                                obscureText: !_showCurrentPwd,
                                style: AppTextStyles.body
                                    .copyWith(color: textColor),
                                decoration: _inputDecoration(
                                  hint: '••••••••',
                                  isDark: isDark,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _showCurrentPwd
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () => setState(() =>
                                        _showCurrentPwd = !_showCurrentPwd),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _labeled(
                            '${t['new_password'] ?? 'New Password'}:',
                            SizedBox(
                              height: 44,
                              child: TextField(
                                controller: _newPwdCtrl,
                                obscureText: !_showNewPwd,
                                onChanged: (_) => setState(() {
                                  _newPwdError = false;
                                  _confirmPwdError = false;
                                }),
                                style: AppTextStyles.body
                                    .copyWith(color: textColor),
                                decoration: _inputDecoration(
                                  hint: '••••••••',
                                  isDark: isDark,
                                  hasError: _newPwdError,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _showNewPwd
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () => setState(
                                        () => _showNewPwd = !_showNewPwd),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _labeled(
                            '${t['confirm_new_password'] ?? 'Confirm New Password'}:',
                            SizedBox(
                              height: 44,
                              child: TextField(
                                controller: _confirmPwdCtrl,
                                obscureText: !_showConfirmPwd,
                                onChanged: (_) => setState(
                                    () => _confirmPwdError = false),
                                style: AppTextStyles.body
                                    .copyWith(color: textColor),
                                decoration: _inputDecoration(
                                  hint: '••••••••',
                                  isDark: isDark,
                                  hasError: _confirmPwdError,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _showConfirmPwd
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () => setState(() =>
                                        _showConfirmPwd = !_showConfirmPwd),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_confirmPwdError) ...[
                            const SizedBox(height: 4),
                            Text(
                              t['passwords_not_match'] ?? 'Passwords do not match',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.error),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _changingPassword
                                  ? null
                                  : () => _changePassword(t),
                              icon: _changingPassword
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : const Icon(Icons.lock_reset_outlined, size: 18),
                              label: Text(t['change_password'] ?? 'Change Password'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                              ),
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
    );
  }
}

class _Toast extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;
  const _Toast({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
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
    final color = widget.isError ? AppColors.error : AppColors.primary;
    final icon = widget.isError ? Icons.close : Icons.check;
    final title = widget.isError ? (t['error'] ?? 'Error') : (t['success'] ?? 'Success');
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
