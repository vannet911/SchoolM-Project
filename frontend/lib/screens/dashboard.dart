// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/services/api_service.dart';
import 'package:schoolms_portal/utils/app_constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();
  Map<String, int> _stats = {'students': 0, 'teachers': 0, 'classes': 0};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final stats = await _api.getDashboardStats();
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      // Show zeros if API offline
      setState(() {
        _stats = {'students': 40, 'teachers': 5, 'classes': 5};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Main content ──────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome + Logo header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['welcome'] ?? 'Welcome',
                            style:
                                AppTextStyles.heading1.copyWith(fontSize: 28)),
                      ],
                    ),
                    const Spacer(),
                    // School logo & name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(Icons.school,
                                size: 36, color: AppColors.primaryLight),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'KOMPONG PHNOM',
                          style: AppTextStyles.heading2.copyWith(fontSize: 18),
                        ),
                        Text(
                          AppConstants.appSubtitle,
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stat cards row
                if (_loading)
                  const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                else
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: t['total_students'] ?? 'Total Students',
                          value: _stats['students']!.toString().padLeft(2, '0'),
                          subtitle: t['data_this_month'] ?? 'Data this month',
                          iconWidget: _StudentIcon(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: t['total_teachers'] ?? 'Total Teachers',
                          value: _stats['teachers']!.toString().padLeft(2, '0'),
                          subtitle: t['data_this_month'] ?? 'Data this month',
                          iconWidget: _TeacherIcon(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: t['total_classes'] ?? 'Total Classes',
                          value: _stats['classes']!.toString().padLeft(2, '0'),
                          subtitle: t['data_this_month'] ?? 'Data this month',
                          iconWidget: _ClassIcon(),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Chart / data rows — placeholder cards matching screenshot
                Row(
                  children: [
                    Expanded(
                      child: _ChartPlaceholder(height: 240),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ChartPlaceholder(height: 240),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ChartPlaceholder(height: 350),
              ],
            ),
          ),
        ),

        // ── Right panel: Course Information ───────────────────────
        _CourseInfoPanel(),
      ],
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Widget iconWidget;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title,
                    style: AppTextStyles.label
                        .copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              iconWidget,
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.statValue),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),
          Text(subtitle, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// Icon widgets for stat cards
class _StudentIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.studentIconBg,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.school, size: 26, color: Color(0xFF2E7D32)),
    );
  }
}

class _TeacherIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.teacherIconBg,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, size: 26, color: Color(0xFF1565C0)),
    );
  }
}

class _ClassIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.classIconBg,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.menu_book, size: 26, color: Color(0xFFF57F17)),
    );
  }
}

// ── Chart Placeholder ────────────────────────────────────────────────────────
class _ChartPlaceholder extends StatelessWidget {
  final double height;
  const _ChartPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Text(t['chart_coming_soon'] ?? 'Chart / Data coming soon',
            style: AppTextStyles.heading3),
      ),
    );
  }
}

// ── Right panel ───────────────────────────────────────────────────────────────
class _CourseInfoPanel extends StatelessWidget {
  final List<_CourseItem> _courses = const [
    _CourseItem(
      label: 'C# Programming',
      color: Color(0xFF6C3FAB),
      icon: Icons.code,
    ),
    _CourseItem(
      label: 'Mathematics',
      color: Color(0xFF1A237E),
      icon: Icons.calculate_outlined,
    ),
    _CourseItem(
      label: 'Graphic Design',
      color: Color(0xFFAD1457),
      icon: Icons.brush_outlined,
    ),
    _CourseItem(
      label: 'Web Design',
      color: Color(0xFF1B5E20),
      icon: Icons.web_outlined,
    ),
    _CourseItem(
        label: 'Flutter Framework', color: Color(0xFF00897B), icon: Icons.code),
  ];

  const _CourseInfoPanel();

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;

    return Container(
      width: AppConstants.rightPanelWidth,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(left: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            // decoration: const BoxDecoration(
            //   border: Border(bottom: BorderSide(color: AppColors.border)),
            // ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['subject_information'] ?? 'Subject Information',
                    style: AppTextStyles.heading3),
                const SizedBox(height: 2),
                Text(
                    t['notifications_about_subject'] ??
                        'Notifications about subject Info',
                    style: AppTextStyles.body),
              ],
            ),
          ),

          // Course cards list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _courses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _courses[i].buildCard(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseItem {
  final String label;
  final Color color;
  final IconData icon;

  const _CourseItem(
      {required this.label, required this.color, required this.icon});

  Widget buildCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(icon, size: 90, color: Colors.white.withOpacity(0.12)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(icon, size: 28, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Learn Today!',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
