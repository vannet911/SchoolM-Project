// lib/screens/dashboard_screen.dart
import 'dart:math' as math;
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
  int _maleCount = 0;
  int _femaleCount = 0;
  Map<String, int> _studentsByClass = {};
  int _subjectCount = 0;
  List<Map<String, dynamic>> _subjects = [];
  Map<String, double> _attendanceRateByClass = {};
  int _weekSessions = 0;
  int _timetableCount = 0;
  Map<String, int> _timetableByDay = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getStudents(),
        _api.getTeachers(),
        _api.getClasses(),
        _api.getSubjects(),
        _api.getAttendance(),
        _api.getTimetableEntries(),
      ]);

      final students = results[0].cast<Map<String, dynamic>>();
      final teachers = results[1];
      final classes = results[2];
      final subjects = results[3];
      final attendanceList = results[4].cast<Map<String, dynamic>>();
      final timetableList = results[5].cast<Map<String, dynamic>>();

      int male = 0, female = 0;
      final Map<String, int> byClass = {};
      for (final s in students) {
        final g = (s['gender'] as String?)?.toLowerCase() ?? '';
        if (g == 'male') {
          male++;
        } else {
          female++;
        }
        final cls = (s['className'] as String?) ?? 'Unassigned';
        byClass[cls] = (byClass[cls] ?? 0) + 1;
      }

      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      int weekSessions = 0;
      final Map<String, int> attPresent = {};
      for (final a in attendanceList) {
        final cls = (a['className'] as String?) ?? 'Unassigned';
        final present = (a['present'] as num?)?.toInt() ?? 0;
        final dateStr = (a['date'] as String?) ?? '';
        bool inWeek = false;
        if (dateStr.isNotEmpty) {
          final recordDate = DateTime.tryParse(
              dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr);
          if (recordDate != null) {
            final d =
                DateTime(recordDate.year, recordDate.month, recordDate.day);
            inWeek = !d.isBefore(weekStart) && !d.isAfter(weekEnd);
          }
        }
        if (inWeek) {
          weekSessions++;
          attPresent[cls] = (attPresent[cls] ?? 0) + present;
        }
      }
      final maxPresent =
          attPresent.values.isEmpty ? 1 : attPresent.values.reduce(math.max);
      final Map<String, double> rateByClass = {
        for (final cls in attPresent.keys)
          cls: maxPresent == 0 ? 0.0 : attPresent[cls]! / maxPresent * 100.0,
      };

      const dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final Map<String, int> byDay = {};
      for (final entry in timetableList) {
        final day = (entry['day'] as String?) ?? 'Other';
        byDay[day] = (byDay[day] ?? 0) + 1;
      }

      setState(() {
        _stats = {
          'students': students.length,
          'teachers': teachers.length,
          'classes': classes.length,
        };
        _maleCount = male;
        _femaleCount = female;
        _studentsByClass = byClass;
        _subjectCount = subjects.length;
        _subjects = subjects.cast<Map<String, dynamic>>();
        _attendanceRateByClass = rateByClass;
        _weekSessions = weekSessions;
        _timetableCount = timetableList.length;
        _timetableByDay = Map.fromEntries(
          dayOrder.where((d) => byDay.containsKey(d)).map((d) => MapEntry(d, byDay[d]!)),
        );
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _stats = {'students': 40, 'teachers': 5, 'classes': 5};
        _maleCount = 24;
        _femaleCount = 16;
        _studentsByClass = {
          'Class A': 12,
          'Class B': 15,
          'Class C': 8,
          'Unassigned': 5,
        };
        _subjectCount = 8;
        _subjects = [];
        _attendanceRateByClass = {
          'Class A': 82.0,
          'Class B': 68.0,
          'Class C': 91.0,
          'Unassigned': 55.0,
        };
        _weekSessions = 0;
        _timetableCount = 18;
        _timetableByDay = {
          'Monday': 4,
          'Tuesday': 3,
          'Wednesday': 4,
          'Thursday': 3,
          'Friday': 2,
          'Saturday': 2,
        };
        _loading = false;
      });
    }
  }

  String _greeting(Map<String, String> t) {
    final hour = DateTime.now().hour;
    if (hour < 12) return t['good_morning'] ?? 'Good Morning';
    if (hour < 17) return t['good_afternoon'] ?? 'Good Afternoon';
    return t['good_evening'] ?? 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _DashboardSkeleton();

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isDesktop = width >= 1024;

    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;

    // ── Stat cards ─────────────────────────────────────────────
    Widget statCards;
    if (isMobile) {
      // Mobile: 2x2 grid
      statCards = Column(children: [
        Row(children: [
          Expanded(child: _StatCard(title: t['total_students'] ?? 'Total Students', value: _stats['students']!.toString().padLeft(2, '0'), subtitle: t['all_data'] ?? 'All Data', iconWidget: const _StudentIcon())),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(title: t['total_teachers'] ?? 'Total Teachers', value: _stats['teachers']!.toString().padLeft(2, '0'), subtitle: t['all_data'] ?? 'All Data', iconWidget: const _TeacherIcon())),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatCard(title: t['total_classes'] ?? 'Total Classes', value: _stats['classes']!.toString().padLeft(2, '0'), subtitle: t['all_data'] ?? 'All Data', iconWidget: const _ClassIcon())),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(title: t['total_subjects'] ?? 'Total Subjects', value: _subjectCount.toString().padLeft(2, '0'), subtitle: t['all_data'] ?? 'All Data', iconWidget: const _SubjectIcon())),
        ]),
      ]);
    } else {
      // Tablet + Desktop: 4 in a row
      statCards = Row(children: [
        Expanded(child: _StatCard(title: t['total_students'] ?? 'Total Students', value: _stats['students']!.toString().padLeft(2, '0'), subtitle: t['all_data'] ?? 'All Data', iconWidget: const _StudentIcon())),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(title: t['total_teachers'] ?? 'Total Teachers', value: _stats['teachers']!.toString().padLeft(2, '0'), subtitle: t['all_data'] ?? 'All Data', iconWidget: const _TeacherIcon())),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(title: t['total_classes'] ?? 'Total Classes', value: _stats['classes']!.toString().padLeft(2, '0'), subtitle: t['all_data'] ?? 'All Data', iconWidget: const _ClassIcon())),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(title: t['total_subjects'] ?? 'Total Subjects', value: _subjectCount.toString().padLeft(2, '0'), subtitle: t['all_data'] ?? 'All Data', iconWidget: const _SubjectIcon())),
      ]);
    }

    // ── Charts row 1 ───────────────────────────────────────────
    Widget chartsRow1;
    if (isMobile) {
      chartsRow1 = Column(children: [
        _GenderDonutChart(male: _maleCount, female: _femaleCount, total: _stats['students'] ?? 0, t: t),
        const SizedBox(height: 16),
        _StudentsPerClassChart(data: _studentsByClass, t: t),
      ]);
    } else {
      // Tablet + Desktop: side by side
      chartsRow1 = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _GenderDonutChart(male: _maleCount, female: _femaleCount, total: _stats['students'] ?? 0, t: t)),
          const SizedBox(width: 16),
          Expanded(child: _StudentsPerClassChart(data: _studentsByClass, t: t)),
        ],
      );
    }

    // ── Scrollable main content ────────────────────────────────
    final mainScroll = SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome + Logo header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(t),
                        style: AppTextStyles.heading1.copyWith(
                            fontSize: isMobile ? 22 : 28, color: textColor)),
                    const SizedBox(height: 4),
                    Text(
                      t['welcome_back'] ??
                          'Welcome back to School Management Portal.',
                      style: AppTextStyles.body.copyWith(color: mutedColor),
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.school, size: 36, color: AppColors.primaryLight),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(t['app_name'] ?? 'KOMPONG PHNOM',
                        style: AppTextStyles.heading2.copyWith(fontSize: 18, color: textColor)),
                    Text(t['app_subtitle'] ?? AppConstants.appSubtitle,
                        style: AppTextStyles.body.copyWith(color: mutedColor)),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          statCards,
          const SizedBox(height: 16),

          chartsRow1,
          const SizedBox(height: 16),

          _SchoolOverviewChart(
            students: _stats['students'] ?? 0,
            teachers: _stats['teachers'] ?? 0,
            classes: _stats['classes'] ?? 0,
            subjects: _subjectCount,
            t: t,
          ),
          const SizedBox(height: 16),

          if (isMobile)
            Column(children: [
              _TimetableSummaryCard(
                total: _timetableCount,
                byDay: _timetableByDay,
                t: t,
              ),
              const SizedBox(height: 16),
              _AttendancePerClassChart(
                data: _attendanceRateByClass,
                t: t,
                weekSessions: _weekSessions,
              ),
            ])
          else
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: _TimetableSummaryCard(
                  total: _timetableCount,
                  byDay: _timetableByDay,
                  t: t,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _AttendancePerClassChart(
                  data: _attendanceRateByClass,
                  t: t,
                  weekSessions: _weekSessions,
                ),
              ),
            ]),

          // Inline subject panel on mobile/tablet
          if (!isDesktop) ...[
            const SizedBox(height: 16),
            _CourseInfoPanel(
                subjects: _subjects, loading: _loading, inline: true),
          ],
        ],
      ),
    );

    // ── Desktop: main + right panel side-by-side ──────────────
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: mainScroll),
          _CourseInfoPanel(subjects: _subjects, loading: _loading),
        ],
      );
    }

    // ── Tablet / Mobile: full-width scroll ────────────────────
    return mainScroll;
  }
}

// ── Dashboard Skeleton ────────────────────────────────────────────────────
class _DashboardSkeleton extends StatefulWidget {
  const _DashboardSkeleton();
  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton>
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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isDesktop = width >= 1024;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1C2A4A) : const Color(0xFFE8EBF2);
    final shimmer = isDark ? const Color(0xFF2A3D60) : const Color(0xFFF5F6FA);
    final cardColor = isDark ? const Color(0xFF16213E) : AppColors.cardBg;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;

    Widget block({double? w, double h = 14, double r = 7}) => Container(
          width: w,
          height: h,
          decoration:
              BoxDecoration(color: base, borderRadius: BorderRadius.circular(r)),
        );

    // ── Stat card — mirrors _StatCard exactly ──────────────────
    Widget statCard() => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: borderColor),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: block(w: 110, h: 14)),
              Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(color: base, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 12),
            block(w: 48, h: 28, r: 6),
            const SizedBox(height: 12),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 10),
            block(w: 72, h: 12),
          ]),
        );

    // ── Donut chart — mirrors _GenderDonutChart ────────────────
    Widget legendRow() => Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: base, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(w: 48, h: 11),
                const SizedBox(height: 4),
                block(w: 68, h: 14),
              ],
            ),
          ),
        ]);

    Widget donutChartCard() => Container(
          height: 240,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: borderColor),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            block(w: 170, h: 14),
            Expanded(
              child: Row(children: [
                // Donut — flex 3 (matches actual)
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Stack(alignment: Alignment.center, children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                            color: base, shape: BoxShape.circle),
                      ),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                            color: cardColor, shape: BoxShape.circle),
                      ),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        block(w: 36, h: 26, r: 6),
                        const SizedBox(height: 4),
                        block(w: 44, h: 12),
                      ]),
                    ]),
                  ),
                ),
                // Legend — flex 2 (matches actual)
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      legendRow(),
                      const SizedBox(height: 16),
                      legendRow(),
                    ],
                  ),
                ),
              ]),
            ),
          ]),
        );

    // ── Bar chart — mirrors _StudentsPerClassChart ─────────────
    Widget barChartCard() {
      const ratios = [0.80, 0.55, 0.90, 0.65, 0.40];
      return Container(
        height: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: borderColor),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          block(w: 170, h: 14),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ratios.map((pct) {
                return Row(children: [
                  // Label — 72px wide (matches actual)
                  Container(
                      width: 72,
                      height: 12,
                      decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6))),
                  const SizedBox(width: 8),
                  // Bar — Expanded (matches actual)
                  Expanded(
                    child: Stack(children: [
                      Container(
                          height: 18,
                          decoration: BoxDecoration(
                              color: base.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4))),
                      FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(
                            height: 18,
                            decoration: BoxDecoration(
                                color: base,
                                borderRadius: BorderRadius.circular(4))),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  // Count — 24px wide (matches actual)
                  Container(
                      width: 24,
                      height: 12,
                      decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6))),
                ]);
              }).toList(),
            ),
          ),
        ]),
      );
    }

    // ── Area chart — mirrors _SchoolOverviewChart ──────────────
    Widget areaChartCard() => Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: borderColor),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            block(w: 150, h: 14),
            const SizedBox(height: 8),
            Expanded(
              child: CustomPaint(
                painter: _SkeletonCurvePainter(base: base),
                size: Size.infinite,
              ),
            ),
          ]),
        );

    // ── Subject item — mirrors _CourseItem ─────────────────────
    Widget subjectItem() => Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: base, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.all(16),
          child: Stack(children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle)),
                const SizedBox(height: 8),
                block(w: 100, h: 14),
                const SizedBox(height: 2),
                block(w: 72, h: 12),
              ],
            ),
          ]),
        );

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        Shader shader(Rect bounds) => LinearGradient(
              begin: Alignment(-3.0 + t * 6.0, 0),
              end: Alignment(-1.0 + t * 6.0, 0),
              colors: [base, shimmer, base],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);

        Widget mainContent = ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: shader,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome row
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        block(w: 200, h: isMobile ? 22 : 28, r: 8),
                        const SizedBox(height: 8),
                        block(w: 280, h: 14),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 16),
                    Column(children: [
                      Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                              color: base,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor))),
                      const SizedBox(height: 8),
                      block(w: 140, h: 14),
                      const SizedBox(height: 6),
                      block(w: 180, h: 12),
                    ]),
                  ],
                ]),
                const SizedBox(height: 24),

                // Stat cards
                if (isMobile)
                  Column(children: [
                    Row(children: [
                      Expanded(child: statCard()),
                      const SizedBox(width: 12),
                      Expanded(child: statCard()),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: statCard()),
                      const SizedBox(width: 12),
                      Expanded(child: statCard()),
                    ]),
                  ])
                else
                  Row(children: [
                    Expanded(child: statCard()),
                    const SizedBox(width: 16),
                    Expanded(child: statCard()),
                    const SizedBox(width: 16),
                    Expanded(child: statCard()),
                    const SizedBox(width: 16),
                    Expanded(child: statCard()),
                  ]),
                const SizedBox(height: 16),

                // Charts row 1 (donut + students/class)
                if (isMobile)
                  Column(children: [
                    donutChartCard(),
                    const SizedBox(height: 16),
                    barChartCard(),
                  ])
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: donutChartCard()),
                      const SizedBox(width: 16),
                      Expanded(child: barChartCard()),
                    ],
                  ),
                const SizedBox(height: 16),

                // Wide chart
                areaChartCard(),
                const SizedBox(height: 16),

                // Timetable (day tiles) + Attendance per class (ranked bars)
                Builder(builder: (context) {
                  Widget timetableCard() => Container(
                        height: 320,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius:
                              BorderRadius.circular(AppConstants.cardRadius),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row: title + badge
                            Row(children: [
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  block(w: 160, h: 13),
                                  const SizedBox(height: 4),
                                  block(w: 120, h: 10),
                                ],
                              )),
                              block(w: 52, h: 26, r: 20),
                            ]),
                            const SizedBox(height: 12),
                            // 3 stat tiles
                            Row(children: [
                              Expanded(child: block(h: 54, r: 10)),
                              const SizedBox(width: 8),
                              Expanded(child: block(h: 54, r: 10)),
                              const SizedBox(width: 8),
                              Expanded(child: block(h: 54, r: 10)),
                            ]),
                            const SizedBox(height: 12),
                            block(h: 1),
                            const SizedBox(height: 10),
                            // Horizontal bar rows
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(5, (_) => Row(children: [
                                  block(w: 34, h: 12),
                                  const SizedBox(width: 8),
                                  Expanded(child: block(h: 10, r: 5)),
                                  const SizedBox(width: 8),
                                  block(w: 20, h: 12),
                                ])),
                              ),
                            ),
                          ],
                        ),
                      );

                  Widget attendanceCard() => Container(
                        height: 270,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius:
                              BorderRadius.circular(AppConstants.cardRadius),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: title + Today chip
                            Row(children: [
                              Expanded(child: block(w: 160, h: 13)),
                              block(w: 48, h: 24, r: 16),
                            ]),
                            const SizedBox(height: 10),
                            // Chart: y-axis + vertical bars
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Y-axis shimmer labels
                                  SizedBox(
                                    width: 36,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        block(w: 32, h: 10),
                                        block(w: 28, h: 10),
                                        block(w: 20, h: 10),
                                        const SizedBox(height: 22),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Bar columns
                                  Expanded(
                                    child: Column(children: [
                                      Expanded(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: List.generate(4, (i) {
                                            const factors = [0.92, 0.78, 0.38, 0.70];
                                            return Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 5),
                                                child: FractionallySizedBox(
                                                  heightFactor: factors[i],
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: base,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .vertical(
                                                                  top: Radius
                                                                      .circular(
                                                                          4)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                      // X-axis labels
                                      const SizedBox(height: 4),
                                      Row(
                                        children: List.generate(
                                          4,
                                          (_) => Expanded(
                                              child: Center(
                                                  child: block(w: 36, h: 10))),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );

                  if (isMobile) {
                    return Column(children: [
                      timetableCard(),
                      const SizedBox(height: 16),
                      attendanceCard(),
                    ]);
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: timetableCard()),
                      const SizedBox(width: 16),
                      Expanded(child: attendanceCard()),
                    ],
                  );
                }),

                // Inline subject panel (mobile/tablet)
                if (!isDesktop) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius:
                          BorderRadius.circular(AppConstants.cardRadius),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        block(w: 160, h: 16),
                        const SizedBox(height: 8),
                        block(w: 220, h: 12),
                        const SizedBox(height: 16),
                        subjectItem(),
                        subjectItem(),
                        subjectItem(),
                        subjectItem(),
                        subjectItem(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

        if (!isDesktop) return mainContent;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: mainContent),
            ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: shader,
              child: Container(
                width: AppConstants.rightPanelWidth,
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(left: BorderSide(color: borderColor)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          block(w: 160, h: 16),
                          const SizedBox(height: 8),
                          block(w: 220, h: 12),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          subjectItem(),
                          subjectItem(),
                          subjectItem(),
                          subjectItem(),
                          subjectItem(),
                          subjectItem(),
                          subjectItem(),
                          subjectItem(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Skeleton curve painter ────────────────────────────────────────────────
class _SkeletonCurvePainter extends CustomPainter {
  final Color base;
  const _SkeletonCurvePainter({required this.base});

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 24.0;
    const bottomPad = 30.0;
    const hPad = 20.0;
    final chartW = size.width - hPad * 2;
    final chartH = size.height - topPad - bottomPad;

    // Horizontal grid lines
    final gridPaint = Paint()
      ..color = base.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = topPad + chartH * i / 4;
      canvas.drawLine(Offset(hPad, y), Offset(hPad + chartW, y), gridPaint);
    }

    // Data points
    const ratios = [0.85, 0.28, 0.52, 0.72];
    final n = ratios.length;
    final xStep = chartW / (n - 1);
    final points = List.generate(
        n,
        (i) => Offset(
              hPad + i * xStep,
              topPad + chartH * (1.0 - ratios[i]),
            ));

    // Smooth bezier path
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < n; i++) {
      final mid = (points[i - 1].dx + points[i].dx) / 2;
      path.cubicTo(
          mid, points[i - 1].dy, mid, points[i].dy, points[i].dx, points[i].dy);
    }

    // Filled area under curve
    final fill = Path.from(path)
      ..lineTo(points.last.dx, topPad + chartH)
      ..lineTo(points.first.dx, topPad + chartH)
      ..close();
    canvas.drawPath(fill, Paint()..color = base.withValues(alpha: 0.35));

    // Curve line
    canvas.drawPath(
      path,
      Paint()
        ..color = base
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Value labels above dots
    for (final p in points) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(p.dx, p.dy - 16), width: 28, height: 12),
          const Radius.circular(4),
        ),
        Paint()..color = base,
      );
    }

    // Dots (ring + fill)
    for (final p in points) {
      canvas.drawCircle(p, 6, Paint()..color = base.withValues(alpha: 0.4));
      canvas.drawCircle(p, 4, Paint()..color = base);
    }

    // X-axis labels
    for (int i = 0; i < n; i++) {
      final x = hPad + i * xStep;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(x, topPad + chartH + 16), width: 52, height: 10),
          const Radius.circular(5),
        ),
        Paint()..color = base,
      );
    }
  }

  @override
  bool shouldRepaint(_SkeletonCurvePainter old) => old.base != base;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF16213E) : AppColors.cardBg;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white54 : AppColors.textMuted;
    final dividerColor =
        isDark ? const Color(0xFF2A2A4A) : AppColors.divider;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                    style: AppTextStyles.label.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
              ),
              iconWidget,
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: AppTextStyles.statValue.copyWith(color: textColor)),
          const SizedBox(height: 12),
          Divider(color: dividerColor, height: 1),
          const SizedBox(height: 10),
          Text(subtitle,
              style: AppTextStyles.caption.copyWith(color: mutedColor)),
        ],
      ),
    );
  }
}

class _StudentIcon extends StatelessWidget {
  const _StudentIcon();
  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
            color: AppColors.studentIconBg, shape: BoxShape.circle),
        child:
            const Icon(Icons.school, size: 26, color: Color(0xFF2E7D32)),
      );
}

class _TeacherIcon extends StatelessWidget {
  const _TeacherIcon();
  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
            color: AppColors.teacherIconBg, shape: BoxShape.circle),
        child:
            const Icon(Icons.person, size: 26, color: Color(0xFF1565C0)),
      );
}

class _ClassIcon extends StatelessWidget {
  const _ClassIcon();
  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
            color: AppColors.classIconBg, shape: BoxShape.circle),
        child: const Icon(Icons.menu_book,
            size: 26, color: Color(0xFFF57F17)),
      );
}

class _SubjectIcon extends StatelessWidget {
  const _SubjectIcon();
  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
            color: Color(0xFFF3E5F5), shape: BoxShape.circle),
        child: const Icon(Icons.library_books,
            size: 26, color: Color(0xFF7B1FA2)),
      );
}

// ── Chart helpers ─────────────────────────────────────────────────────────

Widget _chartCard({
  required BuildContext context,
  required double height,
  required Widget child,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    height: height,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF16213E) : AppColors.cardBg,
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      border: Border.all(
          color: isDark ? const Color(0xFF2A2A4A) : AppColors.border),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2)),
      ],
    ),
    child: child,
  );
}

// ── Chart 1: Students by Gender — Donut ──────────────────────────────────
class _GenderDonutChart extends StatelessWidget {
  final int male;
  final int female;
  final int total;
  final Map<String, String> t;

  const _GenderDonutChart({
    required this.male,
    required this.female,
    required this.total,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;

    return _chartCard(
      context: context,
      height: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t['students_by_gender'] ?? 'Students by Gender',
            style: AppTextStyles.label
                .copyWith(fontWeight: FontWeight.w600, color: textColor),
          ),
          Expanded(
            child: total == 0
                ? Center(
                    child: Text(t['no_data'] ?? 'No data',
                        style:
                            AppTextStyles.body.copyWith(color: mutedColor)))
                : Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(140, 140),
                              painter: _DonutPainter(
                                  male: male,
                                  female: female,
                                  isDark: isDark),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(total.toString(),
                                    style: AppTextStyles.statValue.copyWith(
                                        fontSize: 26, color: textColor)),
                                Text(t['students'] ?? 'Total',
                                    style: AppTextStyles.caption
                                        .copyWith(color: mutedColor)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LegendDot(
                              color: AppColors.primaryLight,
                              label: t['male'] ?? 'Male',
                              value: male,
                              total: total,
                            ),
                            const SizedBox(height: 16),
                            _LegendDot(
                              color: const Color(0xFFEC4899),
                              label: t['female'] ?? 'Female',
                              value: female,
                              total: total,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int male;
  final int female;
  final bool isDark;

  const _DonutPainter(
      {required this.male, required this.female, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final total = male + female;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const strokeW = 22.0;

    final bgPaint = Paint()
      ..color =
          isDark ? const Color(0xFF2A2A4A) : const Color(0xFFE5E7EB)
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final maleAngle = (male / total) * 2 * math.pi;

    if (male > 0) {
      canvas.drawArc(
          rect,
          startAngle,
          maleAngle,
          false,
          Paint()
            ..color = AppColors.primaryLight
            ..strokeWidth = strokeW
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt);
    }
    if (female > 0) {
      canvas.drawArc(
          rect,
          startAngle + maleAngle,
          2 * math.pi - maleAngle,
          false,
          Paint()
            ..color = const Color(0xFFEC4899)
            ..strokeWidth = strokeW
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.male != male || old.female != female;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final int total;

  const _LegendDot(
      {required this.color,
      required this.label,
      required this.value,
      required this.total});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;
    final pct =
        total == 0 ? 0 : ((value / total) * 100).round();

    return Row(children: [
      Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(color: mutedColor),
              overflow: TextOverflow.ellipsis),
          Text('$value ($pct%)',
              style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600, color: textColor)),
        ]),
      ),
    ]);
  }
}

// ── Chart 2: Students per Class — Horizontal bars ─────────────────────────
class _StudentsPerClassChart extends StatelessWidget {
  final Map<String, int> data;
  final Map<String, String> t;

  const _StudentsPerClassChart(
      {required this.data, required this.t});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;
    final barBg =
        isDark ? const Color(0xFF2A2A4A) : const Color(0xFFE5E7EB);

    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayed = sorted.take(5).toList();
    final maxVal = displayed.isEmpty ? 1 : displayed.first.value;

    return _chartCard(
      context: context,
      height: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t['students_by_class'] ?? 'Students per Class',
            style: AppTextStyles.label
                .copyWith(fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 12),
          displayed.isEmpty
              ? Expanded(
                  child: Center(
                      child: Text(t['no_data'] ?? 'No data',
                          style: AppTextStyles.body
                              .copyWith(color: mutedColor))))
              : Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: displayed.map((entry) {
                      final pct =
                          (entry.value / maxVal).clamp(0.0, 1.0);
                      return Row(children: [
                        SizedBox(
                          width: 72,
                          child: Text(entry.key,
                              style: AppTextStyles.caption
                                  .copyWith(color: mutedColor),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Stack(children: [
                            Container(
                                height: 18,
                                decoration: BoxDecoration(
                                    color: barBg,
                                    borderRadius:
                                        BorderRadius.circular(4))),
                            FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          child: Text(entry.value.toString(),
                              style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: textColor),
                              textAlign: TextAlign.end),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Chart 3: School Overview — Area Chart ─────────────────────────────────
class _BarItem {
  final String label;
  final int value;
  final Color color;
  const _BarItem(this.label, this.value, this.color);
}

class _SchoolOverviewChart extends StatelessWidget {
  final int students;
  final int teachers;
  final int classes;
  final int subjects;
  final Map<String, String> t;

  const _SchoolOverviewChart({
    required this.students,
    required this.teachers,
    required this.classes,
    required this.subjects,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;

    final items = <_BarItem>[
      _BarItem(t['students'] ?? 'Students', students, AppColors.primaryLight),
      _BarItem(t['teachers'] ?? 'Teachers', teachers, const Color(0xFF3B82F6)),
      _BarItem(t['classes'] ?? 'Classes', classes, const Color(0xFFF59E0B)),
      _BarItem(t['subjects'] ?? 'Subjects', subjects, const Color(0xFF8B5CF6)),
    ];

    return _chartCard(
      context: context,
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t['school_overview'] ?? 'School Overview',
            style: AppTextStyles.label
                .copyWith(fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: _AreaChartPainter(
                items: items,
                isDark: isDark,
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<_BarItem> items;
  final bool isDark;
  final Color textColor;
  final Color mutedColor;

  const _AreaChartPainter({
    required this.items,
    required this.isDark,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 28.0;
    const bottomPad = 36.0;
    const hPad = 24.0;

    final chartW = size.width - hPad * 2;
    final chartH = size.height - topPad - bottomPad;
    final n = items.length;

    final maxVal = items.map((e) => e.value).reduce(math.max);
    final safeMax = maxVal == 0 ? 1 : maxVal;

    final xStep = chartW / (n - 1);
    final points = List<Offset>.generate(n, (i) {
      final x = hPad + i * xStep;
      final y = topPad + chartH * (1.0 - items[i].value / safeMax);
      return Offset(x, y);
    });

    // Subtle horizontal grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = topPad + chartH * i / 4;
      canvas.drawLine(Offset(hPad, y), Offset(hPad + chartW, y), gridPaint);
    }

    // Build smooth path (cubic bezier through midpoints)
    Path smoothPath(bool close) {
      final p = Path()..moveTo(points.first.dx, close ? topPad + chartH : points.first.dy);
      if (close) p.lineTo(points.first.dx, points.first.dy);
      for (int i = 1; i < n; i++) {
        final mid = (points[i - 1].dx + points[i].dx) / 2;
        p.cubicTo(mid, points[i - 1].dy, mid, points[i].dy, points[i].dx, points[i].dy);
      }
      if (close) {
        p.lineTo(points.last.dx, topPad + chartH);
        p.close();
      }
      return p;
    }

    // Filled area with gradient
    final gradientRect = Rect.fromLTWH(hPad, topPad, chartW, chartH);
    canvas.drawPath(
      smoothPath(true),
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.primaryLight.withValues(alpha: isDark ? 0.30 : 0.20),
            const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.25 : 0.15),
            const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.25 : 0.15),
            const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.30 : 0.20),
          ],
          stops: const [0.0, 0.33, 0.66, 1.0],
        ).createShader(gradientRect),
    );

    // Line stroke
    canvas.drawPath(
      smoothPath(false),
      Paint()
        ..color = AppColors.primaryLight
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Dots and labels
    final ringColor = isDark ? const Color(0xFF16213E) : Colors.white;
    for (int i = 0; i < n; i++) {
      final p = points[i];
      canvas.drawCircle(p, 6.5, Paint()..color = ringColor);
      canvas.drawCircle(p, 4.5, Paint()..color = items[i].color);
      _paintLabel(canvas, items[i].value.toString(), p.dx, p.dy - 22,
          textColor, 12, FontWeight.w700);
      _paintLabel(canvas, items[i].label, p.dx, topPad + chartH + 10,
          mutedColor, 11, FontWeight.w400);
    }
  }

  void _paintLabel(Canvas canvas, String text, double cx, double y,
      Color color, double fontSize, FontWeight weight) {
    final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(cx - painter.width / 2, y));
  }

  @override
  bool shouldRepaint(_AreaChartPainter old) =>
      old.items != items || old.isDark != isDark;
}

// ── Right panel ───────────────────────────────────────────────────────────────
// ── Subject list skeleton ─────────────────────────────────────────────────
class _SubjectListSkeleton extends StatefulWidget {
  final bool shrink;
  const _SubjectListSkeleton({this.shrink = false});

  @override
  State<_SubjectListSkeleton> createState() => _SubjectListSkeletonState();
}

class _SubjectListSkeletonState extends State<_SubjectListSkeleton>
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
    final cardColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    const nameWidths = [110.0, 90.0, 130.0, 100.0, 80.0, 120.0];

    Widget item(int i) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 120,
            color: base,
            child: Stack(children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle)),
                    const SizedBox(height: 8),
                    Container(
                        width: nameWidths[i % nameWidths.length],
                        height: 14,
                        decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(7))),
                    const SizedBox(height: 4),
                    Container(
                        width: 72,
                        height: 12,
                        decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ]),
          ),
        );

    return AnimatedBuilder(
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
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            shrinkWrap: widget.shrink,
            physics: widget.shrink
                ? const NeverScrollableScrollPhysics()
                : null,
            itemCount: nameWidths.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => item(i),
          ),
        );
      },
    );
  }
}

class _CourseInfoPanel extends StatelessWidget {
  final List<Map<String, dynamic>> subjects;
  final bool loading;
  final bool inline;

  static const List<Color> _palette = [
    Color(0xFF6C3FAB),
    Color(0xFF1A237E),
    Color(0xFFAD1457),
    Color(0xFF1B5E20),
    Color(0xFF00897B),
    Color(0xFFE65100),
    Color(0xFF37474F),
    Color(0xFFC62828),
  ];

  static const List<IconData> _icons = [
    Icons.menu_book_outlined,
    Icons.calculate_outlined,
    Icons.science_outlined,
    Icons.language_outlined,
    Icons.brush_outlined,
    Icons.code,
    Icons.history_edu_outlined,
    Icons.music_note_outlined,
  ];

  const _CourseInfoPanel({
    required this.subjects,
    required this.loading,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white70 : AppColors.textSecondary;

    final header = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t['subject_information'] ?? 'Subject Information',
              style: AppTextStyles.heading3.copyWith(color: textColor)),
          const SizedBox(height: 2),
          Text(
            t['notifications_about_subject'] ??
                'Notifications about subject Info',
            style: AppTextStyles.body.copyWith(color: mutedColor),
          ),
        ],
      ),
    );

    Widget buildList({bool shrink = false}) {
      if (loading) {
        return _SubjectListSkeleton(shrink: shrink);
      }
      if (subjects.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(t['no_data'] ?? 'No data',
              style: AppTextStyles.body.copyWith(color: mutedColor))),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        shrinkWrap: shrink,
        physics: shrink ? const NeverScrollableScrollPhysics() : null,
        itemCount: subjects.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final s = subjects[i];
          final name = (s['name'] as String?) ?? 'Subject ${i + 1}';
          return _CourseItem(
            label: name,
            color: _palette[i % _palette.length],
            icon: _icons[i % _icons.length],
          );
        },
      );
    }

    // ── Inline mode (mobile/tablet): inside the scroll column ──
    if (inline) {
      return Container(
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            buildList(shrink: true),
          ],
        ),
      );
    }

    // ── Side panel mode (desktop) ──────────────────────────────
    return Container(
      width: AppConstants.rightPanelWidth,
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(left: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Expanded(child: buildList()),
        ],
      ),
    );
  }
}

class _CourseItem extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _CourseItem(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;

    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child:
                Icon(icon, size: 90, color: Colors.white.withValues(alpha: 0.12)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(icon, size: 28, color: Colors.white),
                const SizedBox(height: 8),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(t['learn_today'] ?? 'Learn Today!',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chart 4: Attendance per Class — Ranked gradient bars ─────────────────
class _AttendancePerClassChart extends StatelessWidget {
  final Map<String, double> data; // class → attendance rate 0–100
  final Map<String, String> t;
  final int weekSessions;

  const _AttendancePerClassChart({
    required this.data,
    required this.t,
    required this.weekSessions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;
    final gridColor = isDark ? const Color(0xFF2A2A4A) : const Color(0xFFE5E7EB);
    final barColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);

    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final displayed = sorted.toList();

    const xLabelH = 22.0;
    const yAxisW = 36.0;

    final yStyle = AppTextStyles.caption
        .copyWith(fontSize: 10, color: mutedColor);

    return _chartCard(
      context: context,
      height: 270,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Row(children: [
            Expanded(
              child: Text(
                t['attendance_per_class'] ?? 'Attendance by class',
                style: AppTextStyles.label
                    .copyWith(fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                    color: barColor.withValues(alpha: 0.55), width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                weekSessions > 0 ? 'This Week' : 'All time',
                style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: barColor),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          // ── Chart ────────────────────────────────────────────
          displayed.isEmpty
              ? Expanded(
                  child: Center(
                      child: Text(t['no_data'] ?? 'No data',
                          style: AppTextStyles.body
                              .copyWith(color: mutedColor))))
              : Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalH = constraints.maxHeight;
                      final barAreaH = totalH - xLabelH;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Y-axis labels
                          SizedBox(
                            width: yAxisW,
                            height: totalH,
                            child: Stack(children: [
                              Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Text('100%', style: yStyle)),
                              Positioned(
                                  top: barAreaH / 2 - 6,
                                  right: 0,
                                  child: Text('50%', style: yStyle)),
                              Positioned(
                                  top: barAreaH - 12,
                                  right: 0,
                                  child: Text('0%', style: yStyle)),
                            ]),
                          ),
                          const SizedBox(width: 4),
                          // Bar chart area
                          Expanded(
                            child: Stack(
                              children: [
                                // Gridlines
                                Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                        height: 1, color: gridColor)),
                                Positioned(
                                    top: barAreaH / 2,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                        height: 1, color: gridColor)),
                                Positioned(
                                    top: barAreaH,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                        height: 1, color: gridColor)),
                                // Bars + x-labels
                                Column(children: [
                                  // Bar row
                                  SizedBox(
                                    height: barAreaH,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: displayed.map((entry) {
                                        final pct =
                                            (entry.value / 100).clamp(0.02, 1.0);
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5),
                                            child: FractionallySizedBox(
                                              heightFactor: pct,
                                              alignment:
                                                  Alignment.bottomCenter,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: barColor,
                                                  borderRadius:
                                                      const BorderRadius
                                                          .vertical(
                                                              top: Radius
                                                                  .circular(4)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  // X-axis labels
                                  SizedBox(
                                    height: xLabelH,
                                    child: Row(
                                      children: displayed.map((entry) {
                                        return Expanded(
                                          child: Text(
                                            entry.key,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    fontSize: 10,
                                                    color: mutedColor),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Timetable Summary Card — Day tiles ────────────────────────────────────
class _TimetableSummaryCard extends StatelessWidget {
  final int total;
  final Map<String, int> byDay;
  final Map<String, String> t;

  const _TimetableSummaryCard({
    required this.total,
    required this.byDay,
    required this.t,
  });

  static const _allDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static const _dayAbbrev = {
    'Monday': 'Mon', 'Tuesday': 'Tue', 'Wednesday': 'Wed',
    'Thursday': 'Thu', 'Friday': 'Fri', 'Saturday': 'Sat', 'Sunday': 'Sun',
  };

  static const _dayColors = [
    Color(0xFF6366F1), // Mon — indigo
    Color(0xFF8B5CF6), // Tue — violet
    Color(0xFF06B6D4), // Wed — cyan
    Color(0xFF10B981), // Thu — emerald
    Color(0xFFF59E0B), // Fri — amber
    Color(0xFFF43F5E), // Sat — rose
    Color(0xFF64748B), // Sun — slate
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;
    final dividerColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;

    final activeDays = _allDays.where((d) => (byDay[d] ?? 0) > 0).toList();
    final maxVal = byDay.values.isEmpty ? 1 : byDay.values.reduce(math.max);
    final busiestEntry = byDay.entries.isEmpty
        ? null
        : byDay.entries.reduce((a, b) => a.value > b.value ? a : b);
    final busiestLabel = busiestEntry == null
        ? '—'
        : '${_dayAbbrev[busiestEntry.key] ?? busiestEntry.key.substring(0, 3)} ${busiestEntry.value}';

    Widget statTile(IconData icon, Color color, String value, String label) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(height: 5),
              Text(value,
                  style: AppTextStyles.heading2.copyWith(
                      fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
              Text(label,
                  style: AppTextStyles.caption.copyWith(fontSize: 10, color: mutedColor)),
            ],
          ),
        ),
      );
    }

    return _chartCard(
      context: context,
      height: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  t['timetable_summary'] ?? 'Timetable Summary',
                  style: AppTextStyles.label
                      .copyWith(fontWeight: FontWeight.w600, color: textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  'Weekly schedule overview',
                  style: AppTextStyles.caption.copyWith(fontSize: 11, color: mutedColor),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_month_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 4),
                Text('$total',
                    style: AppTextStyles.caption.copyWith(
                        fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),

          // ── 3 mini stat tiles ────────────────────────────────
          Row(children: [
            statTile(Icons.event_note_outlined, const Color(0xFF6366F1),
                '$total', 'Total Entries'),
            const SizedBox(width: 8),
            statTile(Icons.event_available_outlined, const Color(0xFF10B981),
                '${activeDays.length}', 'Active Days'),
            const SizedBox(width: 8),
            statTile(Icons.star_outline_rounded, const Color(0xFFF59E0B),
                busiestLabel, 'Busiest Day'),
          ]),
          const SizedBox(height: 12),

          Divider(height: 1, color: dividerColor),
          const SizedBox(height: 10),

          // ── Horizontal bars per day ──────────────────────────
          activeDays.isEmpty
              ? Expanded(
                  child: Center(
                      child: Text(t['no_data'] ?? 'No data',
                          style: AppTextStyles.body.copyWith(color: mutedColor))))
              : Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: activeDays.map((day) {
                      final idx = _allDays.indexOf(day);
                      final color = _dayColors[idx.clamp(0, _dayColors.length - 1)];
                      final count = byDay[day] ?? 0;
                      final abbrev = _dayAbbrev[day] ?? day.substring(0, 3);
                      final pct = (count / maxVal).clamp(0.0, 1.0);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 34,
                            child: Text(abbrev,
                                style: AppTextStyles.caption.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: textColor)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Stack(children: [
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color.withValues(
                                      alpha: isDark ? 0.15 : 0.10),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: pct,
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        colors: [
                                          color.withValues(alpha: 0.75),
                                          color
                                        ]),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 24,
                            child: Text('$count',
                                textAlign: TextAlign.right,
                                style: AppTextStyles.caption.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: color)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }
}
