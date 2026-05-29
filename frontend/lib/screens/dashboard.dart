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
      ]);

      final students = results[0].cast<Map<String, dynamic>>();
      final teachers = results[1];
      final classes = results[2];
      final subjects = results[3];

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
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(t),
                            style: AppTextStyles.heading1.copyWith(
                                fontSize: 28, color: textColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t['welcome_back'] ??
                                'Welcome back to School Management Portal.',
                            style:
                                AppTextStyles.body.copyWith(color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: borderColor, width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(Icons.school,
                                size: 36, color: AppColors.primaryLight),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t['app_name'] ?? 'KOMPONG PHNOM',
                          style: AppTextStyles.heading2
                              .copyWith(fontSize: 18, color: textColor),
                        ),
                        Text(
                          t['app_subtitle'] ?? AppConstants.appSubtitle,
                          style: AppTextStyles.body.copyWith(color: mutedColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stat cards
                if (_loading)
                  const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                else
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title:
                              t['total_students'] ?? 'Total Students',
                          value: _stats['students']!
                              .toString()
                              .padLeft(2, '0'),
                          subtitle:
                              t['all_data'] ?? 'All Data',
                          iconWidget: const _StudentIcon(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title:
                              t['total_teachers'] ?? 'Total Teachers',
                          value: _stats['teachers']!
                              .toString()
                              .padLeft(2, '0'),
                          subtitle:
                              t['all_data'] ?? 'All Data',
                          iconWidget: const _TeacherIcon(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: t['total_classes'] ?? 'Total Classes',
                          value: _stats['classes']!
                              .toString()
                              .padLeft(2, '0'),
                          subtitle:
                              t['all_data'] ?? 'All Data',
                          iconWidget: const _ClassIcon(),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Charts row 1: Donut + Horizontal bars
                if (!_loading)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _GenderDonutChart(
                          male: _maleCount,
                          female: _femaleCount,
                          total: _stats['students'] ?? 0,
                          t: t,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StudentsPerClassChart(
                          data: _studentsByClass,
                          t: t,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Chart row 2: School overview vertical bars
                if (!_loading)
                  _SchoolOverviewChart(
                    students: _stats['students'] ?? 0,
                    teachers: _stats['teachers'] ?? 0,
                    classes: _stats['classes'] ?? 0,
                    subjects: _subjectCount,
                    t: t,
                  ),
              ],
            ),
          ),
        ),

        // ── Right panel ───────────────────────────────────────────
        _CourseInfoPanel(subjects: _subjects, loading: _loading),
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
class _CourseInfoPanel extends StatelessWidget {
  final List<Map<String, dynamic>> subjects;
  final bool loading;

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

  const _CourseInfoPanel({required this.subjects, required this.loading});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return Container(
      width: AppConstants.rightPanelWidth,
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(left: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t['subject_information'] ?? 'Subject Information',
                  style: AppTextStyles.heading3.copyWith(color: textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  t['notifications_about_subject'] ??
                      'Notifications about subject Info',
                  style: AppTextStyles.body.copyWith(color: mutedColor),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : subjects.isEmpty
                    ? Center(
                        child: Text(t['no_data'] ?? 'No data',
                            style: AppTextStyles.body
                                .copyWith(color: mutedColor)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: subjects.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final s = subjects[i];
                          final name =
                              (s['name'] as String?) ?? 'Subject ${i + 1}';
                          final color =
                              _palette[i % _palette.length];
                          final icon = _icons[i % _icons.length];
                          return _CourseItem(
                              label: name, color: color, icon: icon);
                        },
                      ),
          ),
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
