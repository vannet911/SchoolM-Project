// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/auth_provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/providers/theme_provider.dart';
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
  String? _emailError;
  String? _passwordError;
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'km', 'name': 'Khmer', 'flag': '🇰🇭'},
  ];

  void _showLanguageMenu(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 50, 0, 0),
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor),
      ),
      items: _languages.map((lang) {
        return PopupMenuItem<String>(
          value: lang['code'],
          child: Row(
            children: [
              Text(lang['flag']!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                lang['name']!,
                style: AppTextStyles.body.copyWith(color: textColor),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        localeProvider.setLocale(value);
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _validateAndLogin() {
    final locale = context.read<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    setState(() {
      _emailError =
          email.isEmpty ? (t['email_required'] ?? 'Email is required') : null;
      _passwordError = password.isEmpty
          ? (t['password_required'] ?? 'Password is required')
          : null;
    });

    if (email.isEmpty || password.isEmpty) {
      return;
    }

    context.read<AuthProvider>().login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final locale = localeProvider.locale;
    final t = AppTranslations.translations[locale]!;
    final isLoading = auth.status == AuthStatus.loading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── Top bar ───────────────────────────────────────────────
          Container(
            height: AppConstants.topBarHeight,
            decoration: BoxDecoration(
              color: bgColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Spacer(),
                const _TopIconBtn(icon: Icons.info_outline),
                const SizedBox(width: 8),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return _TopIconBtn(
                      icon: themeProvider.isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      onTap: () => themeProvider.toggleTheme(),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Consumer<LocaleProvider>(
                  builder: (context, localeProvider, _) {
                    final currentLocale = localeProvider.locale;
                    final currentLang = _languages.firstWhere(
                      (l) => l['code'] == currentLocale,
                      orElse: () => _languages[0],
                    );
                    return InkWell(
                      onTap: () => _showLanguageMenu(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                          color: bgColor,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentLang['flag']!,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(currentLang['name']!,
                                style: AppTextStyles.body
                                    .copyWith(color: textColor)),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_up,
                                size: 16, color: mutedColor),
                          ],
                        ),
                      ),
                    );
                  },
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
                              border: Border.all(color: mutedColor, width: 1.5),
                            ),
                            child: Center(
                              child: Icon(Icons.school,
                                  size: 28, color: textColor),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 52,
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            color: borderColor,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t['app_name'] ?? 'KOMPONG PHNOM',
                                style: AppTextStyles.heading2
                                    .copyWith(fontSize: 18, color: textColor),
                              ),
                              Text(
                                t['app_subtitle'] ?? 'School Management System',
                                style: AppTextStyles.body
                                    .copyWith(color: mutedColor, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Divider(color: borderColor),
                      const SizedBox(height: 20),

                      // Error message
                      if (auth.status == AuthStatus.error &&
                          auth.errorMessage != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Text(
                            auth.errorMessage!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error),
                          ),
                        ),

                      // Email field
                      _LoginField(
                        controller: _emailCtrl,
                        hint: t['email'] ?? 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onSubmitted: (_) => _validateAndLogin(),
                        onChanged: (_) => setState(() => _emailError = null),
                      ),
                      const SizedBox(height: 14),

                      // Password field
                      _LoginField(
                        controller: _passwordCtrl,
                        hint: t['password'] ?? 'Password',
                        prefixIcon: Icons.lock_outlined,
                        obscureText: _obscurePassword,
                        errorText: _passwordError,
                        suffixIcon: InkWell(
                          onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                        onSubmitted: (_) => _validateAndLogin(),
                        onChanged: (_) => setState(() => _passwordError = null),
                      ),
                      const SizedBox(height: 8),
                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 8),
                          ),
                          child: Text(
                            t['forgot_password'] ?? 'Forgot Password?',
                            style: AppTextStyles.body.copyWith(
                              color: isDark
                                  ? AppColors.textLink.withOpacity(0.8)
                                  : AppColors.textLink,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _validateAndLogin,
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
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  t['login'] ?? 'Log In',
                                  style: const TextStyle(
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
              t['developer'] ?? AppConstants.developerTag,
              style: AppTextStyles.caption.copyWith(color: mutedColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _TopIconBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final iconColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
          color: bgColor,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
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
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const _LoginField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.onSubmitted,
    this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white70 : AppColors.textMuted;
    final iconColor = isDark ? Colors.white70 : AppColors.textSecondary;
    const errorColor = AppColors.error;

    final hasError = errorText != null;
    final currentBorderColor = hasError ? errorColor : borderColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: currentBorderColor),
            color: bgColor,
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onSubmitted: onSubmitted,
            onChanged: onChanged,
            style: AppTextStyles.body.copyWith(color: textColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.body.copyWith(color: mutedColor),
              prefixIcon: Icon(prefixIcon, size: 20, color: iconColor),
              suffixIcon: suffixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: suffixIcon)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText!,
              style: AppTextStyles.bodySmall.copyWith(color: errorColor),
            ),
          ),
      ],
    );
  }
}
