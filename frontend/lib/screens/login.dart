// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/auth_provider.dart';
import 'package:schoolms_portal/utils/app_constants.dart';
//import 'package:schoolms_portal/widgets/top_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }
    await context.read<AuthProvider>().login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // ── Top bar ───────────────────────────────────────────────
          Container(
            height: AppConstants.topBarHeight,
            decoration: const BoxDecoration(
              color: AppColors.white,
              //border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Spacer(),
                _TopIconBtn(icon: Icons.info_outline),
                const SizedBox(width: 8),
                _TopIconBtn(icon: Icons.dark_mode_outlined),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('🇬🇧', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text('English', style: AppTextStyles.body),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_up, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Login form centered ───────────────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo + Name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Circular logo
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.textSecondary, width: 1.5),
                            ),
                            child: const Center(
                              child: Icon(Icons.school, size: 28, color: AppColors.textPrimary),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 52,
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            color: AppColors.border,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'KOMPONG PHNOM',
                                style: AppTextStyles.heading2.copyWith(fontSize: 18),
                              ),
                              Text(
                                AppConstants.appSubtitle,
                                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 20),

                      // Error message
                      if (auth.status == AuthStatus.error && auth.errorMessage != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Text(
                            auth.errorMessage!,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                          ),
                        ),

                      // Email field
                      _LoginField(
                        controller: _emailCtrl,
                        hint: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 14),

                      // Password field
                      _LoginField(
                        controller: _passwordCtrl,
                        hint: 'Password',
                        prefixIcon: Icons.lock_outlined,
                        obscureText: _obscurePassword,
                        suffixIcon: InkWell(
                          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 8),
                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLink),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Footer ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              AppConstants.developerTag,
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconBtn extends StatelessWidget {
  final IconData icon;
  const _TopIconBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 18, color: AppColors.textSecondary),
    );
  }
}

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final ValueChanged<String>? onSubmitted;

  const _LoginField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        color: AppColors.white,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.textSecondary),
          suffixIcon: suffixIcon != null
              ? Padding(padding: const EdgeInsets.only(right: 8), child: suffixIcon)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
