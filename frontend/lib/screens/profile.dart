// lib/screens/profile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/auth_provider.dart';
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

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _savingProfile = true);
    try {
      final auth = context.read<AuthProvider>();
      final id = auth.currentUser?['id'];
      if (id != null) {
        await _api.updateUser(id, {
          'username': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
        });
      }
      _showSnack('Profile updated!');
    } catch (e) {
      _showSnack(
        e.toString().contains('Network error') || e.toString().contains('Connection')
            ? 'Cannot connect to server'
            : 'Save failed',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final newPwd = _newPwdCtrl.text;
    final newEmpty = newPwd.isEmpty;
    final mismatch = newPwd != _confirmPwdCtrl.text;
    if (newEmpty || mismatch) {
      setState(() { _newPwdError = newEmpty; _confirmPwdError = mismatch; });
      return;
    }
    setState(() { _changingPassword = true; _newPwdError = false; _confirmPwdError = false; });
    try {
      await _api.post('/auth/change-password', {
        'currentPassword': _currentPwdCtrl.text,
        'newPassword': newPwd,
      });
      _currentPwdCtrl.clear();
      _newPwdCtrl.clear();
      _confirmPwdCtrl.clear();
      _showSnack('Password changed!');
    } catch (e) {
      _showSnack(
        e.toString().contains('Network error') || e.toString().contains('Connection')
            ? 'Cannot connect to server'
            : e.toString().contains('401')
                ? 'Current password is incorrect'
                : 'Failed to change password',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;
    final borderColor =
        isDark ? const Color(0xFF2A2A4A) : AppColors.border;

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
                    color: isDark
                        ? const Color(0xFF16213E)
                        : AppColors.white,
                    borderRadius:
                        BorderRadius.circular(AppConstants.cardRadius),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(children: [
                    Container(
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
                        child: Image.network(
                          'https://www.shutterstock.com/image-vector/default-avatar-photo-placeholder-grey-600nw-2007531536.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 36,
                              color: AppColors.primary),
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
                      label: const Text('Back'),
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
                        title: 'Profile Information',
                        icon: Icons.person_outline,
                        isDark: isDark,
                        children: [
                          _labeled(
                            'Display Name:',
                            SizedBox(
                              height: 44,
                              child: TextField(
                                controller: _nameCtrl,
                                style: AppTextStyles.body
                                    .copyWith(color: textColor),
                                decoration: _inputDecoration(
                                    hint: 'Enter display name',
                                    isDark: isDark),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _labeled(
                            'Email:',
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
                            'Username:',
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
                                  _savingProfile ? null : _saveProfile,
                              icon: _savingProfile
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : const Icon(Icons.save_outlined,
                                      size: 18),
                              label: const Text('Save Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
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
                        title: 'Change Password',
                        icon: Icons.lock_outline,
                        isDark: isDark,
                        children: [
                          _labeled(
                            'Current Password:',
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
                            'New Password:',
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
                            'Confirm New Password:',
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
                              'Passwords do not match',
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
                                  : _changePassword,
                              icon: _changingPassword
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : const Icon(Icons.lock_reset_outlined,
                                      size: 18),
                              label: const Text('Change Password'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
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

class _Toast extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;
  const _Toast(
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
                offset: const Offset(0, 4),
              ),
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
