// lib/widgets/top_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/providers/theme_provider.dart';
import 'package:schoolms_portal/utils/app_constants.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showMenuIcon;
  final VoidCallback? onMenuTap;

  const TopBar({
    super.key,
    required this.title,
    this.showMenuIcon = true,
    this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppConstants.topBarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return Container(
      height: AppConstants.topBarHeight,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (showMenuIcon) ...[
            _MenuButton(onTap: onMenuTap, isDark: isDark),
            const SizedBox(width: 12),
          ],
          Text(title, style: AppTextStyles.heading3.copyWith(color: textColor)),
          const Spacer(),
          _TopBarIconButton(
            icon: Icons.info_outline,
            tooltip: 'About',
            onTap: () => showAppAboutDialog(context),
          ),
          const SizedBox(width: 8),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return _TopBarIconButton(
                icon: themeProvider.isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                onTap: () => themeProvider.toggleTheme(),
              );
            },
          ),
          const SizedBox(width: 12),
          _LanguageSelector(),
        ],
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isDark;
  const _MenuButton({required this.onTap, required this.isDark});

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverBg = widget.isDark
        ? Colors.white.withValues(alpha: 0)
        : AppColors.primarySurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (v) => WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _hovered = v); }),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 0),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _hovered ? hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(
            child: Icon(Icons.menu_open_outlined,
                size: 24, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _TopBarIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final iconColor = isDark ? Colors.white70 : AppColors.textSecondary;

    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
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

    if (tooltip == null) return button;
    return Tooltip(
      message: tooltip!,
      preferBelow: true,
      child: button,
    );
  }
}

void showAppAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => const _AnalyticsDialog(),
  );
}

class _AnalyticsDialog extends StatelessWidget {
  const _AnalyticsDialog();

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF12172B) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF252D45) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white54 : AppColors.textSecondary;
    final gridBg = isDark ? const Color(0xFF1A2238) : const Color(0xFFF7F9FF);
    final gridBorder = isDark ? const Color(0xFF252D45) : const Color(0xFFE4EAFF);
    final accentColor = isDark ? const Color(0xFF6DBF67) : AppColors.primary;

    final modules = [
      (Icons.home_outlined,      t['dashboard']!),
      (Icons.school_outlined,    t['students']!),
      (Icons.person_outline,     t['teachers']!),
      (Icons.menu_book_outlined, t['class & subject']!),
      (Icons.bar_chart_outlined, t['reports']!),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 500,
          height: 450,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.12),
                blurRadius: 60,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Close button ────────────────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 12),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : const Color(0xFFF1F3F8),
                      ),
                      child: Icon(Icons.close, size: 14, color: mutedColor),
                    ),
                  ),
                ),
              ),

              // ── Centered logo + title ────────────────────────────
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
                  border: Border.all(
                      color: accentColor.withValues(alpha: 0.25), width: 1.5),
                ),
                child: Icon(Icons.school_rounded, color: accentColor, size: 32),
              ),
              const SizedBox(height: 14),
              Text(
                t['app_name'] ?? AppConstants.appName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t['app_subtitle'] ?? AppConstants.appSubtitle,
                style: TextStyle(fontSize: 14, color: mutedColor),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      'v${AppConstants.appVersion}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  t['about_description'] ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: mutedColor,
                    height: 1.65,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Module chips ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (icon, name) in modules)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: gridBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: gridBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 13, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Footer strip ─────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(children: [
                          Icon(Icons.group_outlined,
                              size: 15, color: accentColor),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t['developer_label'] ?? 'Developer',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: mutedColor,
                                    fontWeight: FontWeight.w500,
                                  )),
                              Text(t['developer'] ?? AppConstants.developerTag,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ]),
                      ),
                    ),
                    Container(width: 1, height: 40, color: borderColor),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(children: [
                          Icon(Icons.mail_outline,
                              size: 15, color: accentColor),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t['contact'] ?? 'Contact',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: mutedColor,
                                      fontWeight: FontWeight.w500,
                                    )),
                                Text(t['contact_email'] ?? 'vannet.sony911@gmail.com',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatefulWidget {
  @override
  State<_LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<_LanguageSelector> {
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
      position: const RelativeRect.fromLTRB(100, 50, 12, 0),
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
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final currentLocale = localeProvider.locale;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final iconColor = isDark ? Colors.white70 : AppColors.textSecondary;

    final currentLang = _languages.firstWhere(
      (l) => l['code'] == currentLocale,
      orElse: () => _languages[0],
    );

    return InkWell(
      onTap: () => _showLanguageMenu(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
          color: bgColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentLang['flag']!, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(currentLang['name']!,
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w500, color: textColor)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_up, size: 16, color: iconColor),
          ],
        ),
      ),
    );
  }
}
