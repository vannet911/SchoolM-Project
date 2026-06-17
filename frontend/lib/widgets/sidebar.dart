// lib/widgets/sidebar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/auth_provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/providers/nav_provider.dart';
import 'package:schoolms_portal/utils/app_constants.dart';

const double _collapsedWidth = 90;

class Sidebar extends StatefulWidget {
  final bool? forceCollapsed;
  const Sidebar({super.key, this.forceCollapsed});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _showSkeleton = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showSkeleton = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    final isCollapsed = widget.forceCollapsed ?? nav.sidebarCollapsed;

    if (_showSkeleton) return SidebarSkeleton(collapsed: isCollapsed);

    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.sidebarBg;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final mutedColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 0),
      curve: Curves.easeInOut,
      width: isCollapsed ? _collapsedWidth : AppConstants.sidebarWidth,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: ClipRect(
        child: isCollapsed
            ? _CollapsedSidebar(
                auth: auth,
                nav: nav,
                t: t,
                isDark: isDark,
                borderColor: borderColor,
                mutedColor: mutedColor,
              )
            : _ExpandedSidebar(
                auth: auth,
                nav: nav,
                t: t,
                isDark: isDark,
                borderColor: borderColor,
                mutedColor: mutedColor,
              ),
      ),
    );
  }
}

// ── Collapsed sidebar (90px) ──────────────────────────────────────────────────

class _CollapsedSidebar extends StatelessWidget {
  final AuthProvider auth;
  final NavProvider nav;
  final Map<String, String> t;
  final bool isDark;
  final Color borderColor;
  final Color mutedColor;

  const _CollapsedSidebar({
    required this.auth,
    required this.nav,
    required this.t,
    required this.isDark,
    required this.borderColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
        // Avatar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: isDark ? const Color(0xFF1A1A2E) : AppColors.background,
          alignment: Alignment.center,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySurface,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: ClipOval(
              child: Image.network(
                auth.photoUrl ?? AuthProvider.defaultPhotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person,
                  size: 28,
                  color: mutedColor,
                ),
              ),
            ),
          ),
        ),

        //Divider(color: borderColor, height: 1),

        // Nav items
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CollapsedNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: t['dashboard'] ?? 'Dashboard',
                  isActive: nav.currentPage == NavPage.dashboard,
                  onTap: () => nav.navigate(NavPage.dashboard),
                ),
                _CollapsedNavItem(
                  icon: Icons.school_outlined,
                  activeIcon: Icons.school,
                  label: t['students'] ?? 'Students',
                  isActive: nav.currentPage == NavPage.students,
                  onTap: () => nav.navigate(NavPage.students),
                ),
                _CollapsedNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: t['teachers'] ?? 'Teachers',
                  isActive: nav.currentPage == NavPage.teachers,
                  onTap: () => nav.navigate(NavPage.teachers),
                ),
                _CollapsedNavItem(
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book,
                  label: t['class & subject'] ?? 'Class & Subject',
                  isActive: nav.currentPage == NavPage.classSubject,
                  onTap: () => nav.navigate(NavPage.classSubject),
                ),
                _CollapsedNavItem(
                  icon: Icons.calendar_view_week_outlined,
                  activeIcon: Icons.calendar_view_week,
                  label: t['timetable'] ?? 'Timetable',
                  isActive: nav.currentPage == NavPage.timetable,
                  onTap: () => nav.navigate(NavPage.timetable),
                ),
                _CollapsedNavItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  label: t['reports'] ?? 'Reports',
                  isActive: nav.currentPage == NavPage.reports,
                  onTap: () => nav.navigate(NavPage.reports),
                ),
              ],
            ),
          ),
        ),

        // Version refresh icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.refresh, size: 20, color: mutedColor),
        ),
        ],
      ),
    );
  }
}

class _CollapsedNavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CollapsedNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_CollapsedNavItem> createState() => _CollapsedNavItemState();
}

class _CollapsedNavItemState extends State<_CollapsedNavItem> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hoverColor = isDark
        ? Colors.white.withValues(alpha: 0.00)
        : Colors.black.withValues(alpha: 0.00);
    final activeBg = isDark
        ? AppColors.primaryLight.withValues(alpha: 0.0)
        : AppColors.primaryLight.withValues(alpha: 0.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (v) => WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => isHovering = v); }),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isHovering
                ? hoverColor
                : widget.isActive
                    ? activeBg
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isActive ? widget.activeIcon : widget.icon,
                size: 22,
                color: widget.isActive
                    ? AppColors.primaryLight
                    : isDark
                        ? Colors.white70
                        : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: AppTextStyles.caption.copyWith(
                  color: widget.isActive
                      ? AppColors.primaryLight
                      : isDark
                          ? Colors.white70
                          : AppColors.textSecondary,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Expanded sidebar (250px) ──────────────────────────────────────────────────

class _ExpandedSidebar extends StatelessWidget {
  final AuthProvider auth;
  final NavProvider nav;
  final Map<String, String> t;
  final bool isDark;
  final Color borderColor;
  final Color mutedColor;

  const _ExpandedSidebar({
    required this.auth,
    required this.nav,
    required this.t,
    required this.isDark,
    required this.borderColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          color: isDark ? const Color(0xFF1A1A2E) : AppColors.background,
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySurface,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    auth.photoUrl ?? AuthProvider.defaultPhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      size: 40,
                      color: mutedColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Text(
                      auth.displayName,
                      style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.w600, color: textColor),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auth.displayEmail,
                      style: AppTextStyles.body.copyWith(color: mutedColor),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Divider(
                  color: isDark ? const Color(0xFF2A2A4A) : AppColors.divider),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _SidebarActionButton(
                      icon: Icons.edit_outlined,
                      onTap: () =>
                          context.read<NavProvider>().navigateToProfile(),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 38, color: borderColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SidebarActionButton(
                      icon: Icons.logout,
                      color: AppColors.error,
                      onTap: () {
                        context.read<AuthProvider>().logout();
                      },
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: t['dashboard'] ?? 'Dashboard',
                  isActive: nav.currentPage == NavPage.dashboard,
                  onTap: () => nav.navigate(NavPage.dashboard),
                ),
                _NavItem(
                  icon: Icons.school_outlined,
                  activeIcon: Icons.school,
                  label: t['students'] ?? 'Students',
                  isActive: nav.currentPage == NavPage.students,
                  onTap: () => nav.navigate(NavPage.students),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: t['teachers'] ?? 'Teachers',
                  isActive: nav.currentPage == NavPage.teachers,
                  onTap: () => nav.navigate(NavPage.teachers),
                ),
                _NavItem(
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book,
                  label: t['class & subject'] ?? 'Class & Subject',
                  isActive: nav.currentPage == NavPage.classSubject,
                  onTap: () => nav.navigate(NavPage.classSubject),
                ),
                _NavItem(
                  icon: Icons.calendar_view_week_outlined,
                  activeIcon: Icons.calendar_view_week,
                  label: t['timetable'] ?? 'Timetable',
                  isActive: nav.currentPage == NavPage.timetable,
                  onTap: () => nav.navigate(NavPage.timetable),
                ),
                _NavItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  label: t['reports'] ?? 'Reports',
                  isActive: nav.currentPage == NavPage.reports,
                  onTap: () => nav.navigate(NavPage.reports),
                ),
              ],
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: Row(
            children: [
              Icon(Icons.refresh, size: 18, color: mutedColor),
              const SizedBox(width: 8),
              Text(
                '${t['version'] ?? 'Version'} ${AppConstants.appVersion}',
                style: AppTextStyles.body.copyWith(color: mutedColor),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}

class _SidebarActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _SidebarActionButton({
    required this.icon,
    this.color = AppColors.textSecondary,
    required this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: borderRadius,
            color: bgColor,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hoverColor = isDark
        ? Colors.white.withValues(alpha: 0.0)
        : Colors.black.withValues(alpha: 0.0);
    final activeBg = isDark ? const Color(0xFF1A1A2E) : AppColors.background;
    final textColor = isDark ? Colors.white : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovering) {
          setState(() => isHovering = hovering);
        },
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 0),
          height: 44,
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: isHovering
                ? hoverColor
                : widget.isActive
                    ? activeBg
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 30,
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? AppColors.primaryLight
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Icon(
                widget.isActive ? widget.activeIcon : widget.icon,
                size: 20,
                color: widget.isActive ? AppColors.primaryLight : textColor,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: AppTextStyles.body.copyWith(
                  color: widget.isActive ? AppColors.primaryLight : textColor,
                  fontWeight:
                      widget.isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sidebar skeleton loader ───────────────────────────────────────────────────

class SidebarSkeleton extends StatefulWidget {
  final bool collapsed;
  const SidebarSkeleton({super.key, this.collapsed = false});

  @override
  State<SidebarSkeleton> createState() => _SidebarSkeletonState();
}

class _SidebarSkeletonState extends State<SidebarSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _block(Color base, double w, double h, {double r = 6}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(r),
        ),
      );

  Widget _circle(Color base, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: base, shape: BoxShape.circle),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.sidebarBg;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final base = isDark ? const Color(0xFF1C2A4A) : const Color(0xFFE8EBF2);
    final shimmer = isDark ? const Color(0xFF2A3D60) : const Color(0xFFF5F6FA);

    return Container(
      width: widget.collapsed ? _collapsedWidth : AppConstants.sidebarWidth,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value;
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(-3.0 + t * 6.0, 0),
                end: Alignment(-1.0 + t * 6.0, 0),
                colors: [base, shimmer, base],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: widget.collapsed
                  ? _buildCollapsed(base, borderColor)
                  : _buildExpanded(base, borderColor),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCollapsed(Color base, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: _circle(base, 52),
          ),
          // 5 nav items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                  6,
                  (_) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _circle(base, 22),
                        const SizedBox(height: 5),
                        Center(child: _block(base, 40, 9)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            alignment: Alignment.center,
            child: _circle(base, 20),
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded(Color base, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile section
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: [
                // Avatar 90×90
                Center(child: _circle(base, 90)),
                const SizedBox(height: 10),
                // Name + email blocks
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Center(child: _block(base, 120, 16)),
                      const SizedBox(height: 6),
                      Center(child: _block(base, 150, 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Divider(color: borderColor),
                const SizedBox(height: 4),
                // Action buttons row
                Row(
                  children: [
                    Expanded(child: _block(base, double.infinity, 38, r: 24)),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 38, color: borderColor),
                    const SizedBox(width: 8),
                    Expanded(child: _block(base, double.infinity, 38, r: 24)),
                  ],
                ),
              ],
            ),
          ),
          // 5 nav items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: List.generate(
                  6,
                  (_) => SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        _block(base, 4, 30, r: 4),
                        const SizedBox(width: 13),
                        _circle(base, 20),
                        const SizedBox(width: 12),
                        _block(base, 90, 13),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                _circle(base, 18),
                const SizedBox(width: 8),
                _block(base, 80, 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
