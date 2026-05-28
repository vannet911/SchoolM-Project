// lib/screens/reports.dart
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/services/api_service.dart';
import 'package:schoolms_portal/utils/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _tab = 0;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _classes = [];
  bool _loading = true;
  bool _exporting = false;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _exportReport() async {
    if (_exporting || _loading) return;
    setState(() => _exporting = true);
    try {
      String sheetName;
      String filename;
      List<String> headers;
      List<List<String>> rows;

      if (_tab == 0) {
        sheetName = 'Students';
        filename = 'students_report';
        headers = ['#', 'Name', 'Gender', 'Class', 'Date of Birth', 'Phone'];
        rows = _students.asMap().entries.map((e) {
          final s = e.value;
          final name =
              '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
          final dob = s['dateOfBirth'] != null
              ? (s['dateOfBirth'] as String).split('T').first
              : '—';
          return [
            '${e.key + 1}',
            name.isEmpty ? '—' : name,
            (s['gender'] as String?) ?? '—',
            (s['className'] as String?) ?? '—',
            dob,
            (s['phone'] as String?) ?? '—',
          ];
        }).toList();
      } else if (_tab == 1) {
        sheetName = 'Teachers';
        filename = 'teachers_report';
        headers = ['#', 'Name', 'Qualification', 'Subjects', 'Phone'];
        rows = _teachers.asMap().entries.map((e) {
          final tc = e.value;
          final name =
              '${tc['firstName'] ?? ''} ${tc['lastName'] ?? ''}'.trim();
          final subs = (tc['subjects'] as List?)
                  ?.map((s) => s['name'] as String)
                  .join(', ') ??
              '—';
          return [
            '${e.key + 1}',
            name.isEmpty ? '—' : name,
            (tc['qualification'] as String?) ?? '—',
            subs.isEmpty ? '—' : subs,
            (tc['phone'] as String?) ?? '—',
          ];
        }).toList();
      } else {
        sheetName = 'Classes';
        filename = 'classes_report';
        headers = [
          '#',
          'Class Name',
          'Grade',
          'Teacher',
          'Subjects',
          'Students'
        ];
        final Map<String, int> byClass = {};
        for (final s in _students) {
          final cls = (s['className'] as String?) ?? 'Unassigned';
          byClass[cls] = (byClass[cls] ?? 0) + 1;
        }
        rows = _classes.asMap().entries.map((e) {
          final c = e.value;
          final name = (c['name'] as String?) ?? '—';
          final subs = (c['subjects'] as List?)
                  ?.map((s) => s['name'] as String)
                  .join(', ') ??
              '—';
          return [
            '${e.key + 1}',
            name,
            (c['gradeLevel'] as String?) ?? '—',
            (c['teacherName'] as String?) ?? '—',
            subs.isEmpty ? '—' : subs,
            '${byClass[name] ?? 0}',
          ];
        }).toList();
      }

      final workbook = Excel.createExcel();
      workbook.rename('Sheet1', sheetName);
      final sheet = workbook[sheetName];
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
      for (final row in rows) {
        sheet.appendRow(row.map((c) => TextCellValue(c)).toList());
      }

      final bytes = workbook.encode()!;
      final date = DateTime.now().toIso8601String().split('T').first;
      final downloadFilename = '${filename}_$date.xlsx';
      final blob = html.Blob(
        [Uint8List.fromList(bytes)],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', downloadFilename)
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Exported: $downloadFilename'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getStudents(),
        _api.getTeachers(),
        _api.getClasses(),
      ]);
      setState(() {
        _students = results[0].cast<Map<String, dynamic>>();
        _teachers = results[1].cast<Map<String, dynamic>>();
        _classes = results[2].cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A2E)
                      : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: AppColors.primaryLight, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['school_reports'] ?? 'School Reports',
                        style: AppTextStyles.heading2.copyWith(color: textColor)),
                    Text(
                        t['reports_subtitle'] ??
                            'School data reports and summaries',
                        style: AppTextStyles.body.copyWith(color: mutedColor)),
                  ],
                ),
              ),
              SizedBox(
                width: 38,
                height: 38,
                child: InkWell(
                  onTap: _load,
                  borderRadius: BorderRadius.circular(18),
                  child: const Center(child: Icon(Icons.refresh_rounded, size: 24, color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _exporting || _loading ? null : _exportReport,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryLight,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 18),
                  side: BorderSide(
                      color: isDark
                          ? const Color(0xFF2A2A4A)
                          : AppColors.border,
                      width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryLight),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(t['export'] ?? 'Export',
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Tab bar ───────────────────────────────────────────────
          _IconTabBar(
            tabs: [
              _TabItem(Icons.school_outlined, t['student_report'] ?? 'Students'),
              _TabItem(Icons.person_outlined, t['teacher_report'] ?? 'Teachers'),
              _TabItem(Icons.class_outlined, t['class_report'] ?? 'Classes'),
            ],
            activeIndex: _tab,
            onTap: (i) => setState(() => _tab = i),
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // ── Content ───────────────────────────────────────────────
          if (_loading)
            const SizedBox(
              height: 220,
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_tab == 0)
            _StudentReport(
                students: _students, t: t, isDark: isDark)
          else if (_tab == 1)
            _TeacherReport(
                teachers: _teachers, t: t, isDark: isDark)
          else
            _ClassReport(
                classes: _classes, students: _students, t: t, isDark: isDark),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────────────────────────────────────
class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem(this.icon, this.label);
}

class _IconTabBar extends StatelessWidget {
  final List<_TabItem> tabs;
  final int activeIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  const _IconTabBar({
    required this.tabs,
    required this.activeIndex,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? const Color(0xFF2A2A4A) : AppColors.border),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == activeIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [AppColors.primaryLight, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[i].icon,
                        size: 16,
                        color: active
                            ? Colors.white
                            : (isDark
                                ? Colors.white54
                                : AppColors.textSecondary)),
                    const SizedBox(width: 6),
                    Text(
                      tabs[i].label,
                      style: AppTextStyles.label.copyWith(
                        color: active
                            ? Colors.white
                            : (isDark
                                ? Colors.white54
                                : AppColors.textSecondary),
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Gradient card — top stat metrics
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white54 : AppColors.textMuted;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16213E) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
              color: isDark ? const Color(0xFF2A2A4A) : AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: AppTextStyles.heading2.copyWith(color: textColor)),
                  Text(label,
                      style:
                          AppTextStyles.caption.copyWith(color: mutedColor),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Horizontal split bar (gender)
class _SplitBar extends StatelessWidget {
  final int left;
  final int right;
  final Color leftColor;
  final Color rightColor;
  final String leftLabel;
  final String rightLabel;

  const _SplitBar({
    required this.left,
    required this.right,
    required this.leftColor,
    required this.rightColor,
    required this.leftLabel,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    final total = left + right;
    final leftPct = total == 0 ? 0 : ((left / total) * 100).round();
    final rightPct = 100 - leftPct;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;

    return Column(
      children: [
        Row(children: [
          _Dot(leftColor),
          const SizedBox(width: 6),
          Text(leftLabel,
              style: AppTextStyles.caption.copyWith(color: mutedColor)),
          const SizedBox(width: 4),
          Text('$left ($leftPct%)',
              style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700, color: textColor)),
          const Spacer(),
          Text('$right ($rightPct%)',
              style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(width: 4),
          Text(rightLabel,
              style: AppTextStyles.caption.copyWith(color: mutedColor)),
          const SizedBox(width: 6),
          _Dot(rightColor),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 14,
            child: Row(children: [
              if (left > 0) Flexible(flex: left, child: Container(color: leftColor)),
              if (right > 0)
                Flexible(flex: right, child: Container(color: rightColor)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

// Mini horizontal bar row used in insight panels
class _MiniBarRow extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final bool isDark;
  final Color mutedColor;
  final Color textColor;

  const _MiniBarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.isDark,
    required this.mutedColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    final barBg =
        isDark ? const Color(0xFF2A2A4A) : const Color(0xFFE5E7EB);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style: AppTextStyles.caption.copyWith(color: mutedColor),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(children: [
            Container(
                height: 10,
                decoration: BoxDecoration(
                    color: barBg, borderRadius: BorderRadius.circular(5))),
            FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.75)]),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 22,
          child: Text('$value',
              style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700, color: textColor),
              textAlign: TextAlign.end),
        ),
      ]),
    );
  }
}

// Search field
class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _SearchField(
      {required this.hint, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final inputBg = isDark ? const Color(0xFF1A1A2E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white54 : AppColors.textSecondary;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.body.copyWith(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(color: mutedColor),
          prefixIcon: Icon(Icons.search, size: 18, color: mutedColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// Dropdown filter
class _DropField extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _DropField({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final inputBg = isDark ? const Color(0xFF1A1A2E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: inputBg,
          style: AppTextStyles.body.copyWith(color: textColor),
          icon: Icon(Icons.keyboard_arrow_down, color: textColor, size: 18),
          items: items
              .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(v, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// Status badge (gender)
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

// Modern data table with alternating rows
class _DataTable extends StatelessWidget {
  final List<String> headers;
  final List<int> flexes;
  final List<List<String?>> rows;
  final List<Widget?>? customCells; // per-row custom widget list
  final List<int>? customCellIndexes;
  final bool isDark;

  const _DataTable({
    required this.headers,
    required this.flexes,
    required this.rows,
    required this.isDark,
    this.customCells,
    this.customCellIndexes,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF16213E) : AppColors.cardBg;
    final headerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final altBg = isDark
        ? const Color(0xFF1A1A2E).withValues(alpha: 0.5)
        : const Color(0xFFF9FAFB);
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white54 : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: Column(
          children: [
            // Header
            Container(
              color: headerBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: List.generate(
                  headers.length,
                  (i) => Expanded(
                    flex: flexes[i],
                    child: Text(
                      headers[i],
                      style: AppTextStyles.label.copyWith(
                          color: mutedColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
            Divider(
                height: 1, color: borderColor, thickness: 1),

            // Rows
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(36),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded,
                          size: 36,
                          color: isDark ? Colors.white24 : AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text('No data',
                          style: AppTextStyles.body
                              .copyWith(color: mutedColor)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final cells = rows[i];
                  final customWidget =
                      customCells != null ? customCells![i] : null;
                  final customIdx =
                      customCellIndexes != null ? customCellIndexes![i] : null;

                  return Container(
                    color: i.isOdd ? altBg : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: List.generate(cells.length, (j) {
                        if (j == customIdx && customWidget != null) {
                          return Expanded(
                              flex: flexes[j], child: customWidget);
                        }
                        return Expanded(
                          flex: flexes[j],
                          child: Text(
                            cells[j] ?? '—',
                            style: AppTextStyles.body.copyWith(
                              color: j == 0 ? mutedColor : textColor,
                              fontWeight: j == 0
                                  ? FontWeight.w400
                                  : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report 1 — Student Report
// ─────────────────────────────────────────────────────────────────────────────
class _StudentReport extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final Map<String, String> t;
  final bool isDark;

  const _StudentReport(
      {required this.students, required this.t, required this.isDark});

  @override
  State<_StudentReport> createState() => _StudentReportState();
}

class _StudentReportState extends State<_StudentReport> {
  String _search = '';
  String _genderFilter = 'All';
  String _classFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;

    final male = widget.students
        .where((s) => (s['gender'] as String?)?.toLowerCase() == 'male')
        .length;
    final female = widget.students.length - male;
    final classCount =
        widget.students.map((s) => s['className']).toSet().length;

    // Build class list for filter
    final allClasses = [
      'All',
      ...widget.students
          .map((s) => (s['className'] as String?) ?? 'Unassigned')
          .toSet()
          .toList()
        ..sort(),
    ];

    // Students per class for insight
    final Map<String, int> byClass = {};
    for (final s in widget.students) {
      final cls = (s['className'] as String?) ?? 'Unassigned';
      byClass[cls] = (byClass[cls] ?? 0) + 1;
    }
    final topClasses = (byClass.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(4)
        .toList();
    final maxClassCount =
        topClasses.isEmpty ? 1 : topClasses.first.value;

    // Filtered rows
    final filtered = widget.students.where((s) {
      final name =
          '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.toLowerCase();
      final cls = (s['className'] as String?) ?? '';
      final g = (s['gender'] as String?) ?? '';
      final searchOk = _search.isEmpty ||
          name.contains(_search.toLowerCase()) ||
          cls.toLowerCase().contains(_search.toLowerCase());
      final genderOk = _genderFilter == 'All' || g == _genderFilter;
      final classOk = _classFilter == 'All' || cls == _classFilter;
      return searchOk && genderOk && classOk;
    }).toList();

    // Build table rows
    final tableRows = filtered.map((s) {
      final name =
          '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
      final dob = s['dateOfBirth'] != null
          ? (s['dateOfBirth'] as String).split('T').first
          : '—';
      return [
        '${filtered.indexOf(s) + 1}',
        name.isEmpty ? '—' : name,
        null, // custom gender badge
        (s['className'] as String?) ?? '—',
        dob,
        (s['phone'] as String?) ?? '—',
      ];
    }).toList();

    final badges = filtered.map((s) {
      final isMale = (s['gender'] as String?)?.toLowerCase() == 'male';
      return _Badge(
        label: isMale ? (t['male'] ?? 'Male') : (t['female'] ?? 'Female'),
        color: isMale
            ? const Color(0xFF3B82F6)
            : const Color(0xFFEC4899),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _StatCard(value: '${widget.students.length}', label: t['total_students'] ?? 'Total Students', icon: Icons.school_rounded, color: AppColors.primaryLight, isDark: isDark),
          const SizedBox(width: 12),
          _StatCard(value: '$male', label: t['male'] ?? 'Male', icon: Icons.male, color: const Color(0xFF3B82F6), isDark: isDark),
          const SizedBox(width: 12),
          _StatCard(value: '$female', label: t['female'] ?? 'Female', icon: Icons.female, color: const Color(0xFFEC4899), isDark: isDark),
          const SizedBox(width: 12),
          _StatCard(value: '$classCount', label: t['total_classes'] ?? 'Classes', icon: Icons.class_rounded, color: const Color(0xFFF59E0B), isDark: isDark),
        ]),
        const SizedBox(height: 14),
        // Filter bar
        Row(children: [
          Expanded(
              flex: 3,
              child: _SearchField(
                  hint: t['search'] ?? 'Search',
                  onChanged: (v) => setState(() => _search = v),
                  isDark: isDark)),
          const SizedBox(width: 10),
          Expanded(
              child: _DropField(
                  value: _genderFilter,
                  items: const ['All', 'Male', 'Female'],
                  onChanged: (v) => setState(() => _genderFilter = v!),
                  isDark: isDark)),
          const SizedBox(width: 10),
          Expanded(
              child: _DropField(
                  value: _classFilter,
                  items: allClasses,
                  onChanged: (v) => setState(() => _classFilter = v!),
                  isDark: isDark)),
        ]),
        const SizedBox(height: 12),
        

        // Table
        _DataTable(
          headers: [
            '#',
            t['student_name'] ?? 'Name',
            t['gender'] ?? 'Gender',
            t['class_name'] ?? 'Class',
            t['date_of_birth'] ?? 'Date of Birth',
            t['phone'] ?? 'Phone',
          ],
          flexes: const [1, 3, 2, 2, 2, 2],
          rows: tableRows.cast<List<String?>>(),
          isDark: isDark,
          customCells: badges.cast<Widget?>(),
          customCellIndexes: List.filled(filtered.length, 2),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report 2 — Teacher Report
// ─────────────────────────────────────────────────────────────────────────────
class _TeacherReport extends StatefulWidget {
  final List<Map<String, dynamic>> teachers;
  final Map<String, String> t;
  final bool isDark;

  const _TeacherReport(
      {required this.teachers, required this.t, required this.isDark});

  @override
  State<_TeacherReport> createState() => _TeacherReportState();
}

class _TeacherReportState extends State<_TeacherReport> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;

    final uniqueSubs = widget.teachers
        .expand((tc) => (tc['subjects'] as List?) ?? [])
        .map((s) => s['id'])
        .toSet()
        .length;
    final totalSubCount = widget.teachers.fold<int>(
        0, (sum, tc) => sum + ((tc['subjects'] as List?)?.length ?? 0));
    final avg = widget.teachers.isEmpty
        ? 0.0
        : totalSubCount / widget.teachers.length;

    // Subject frequency for insight
    final Map<String, int> subFreq = {};
    for (final tc in widget.teachers) {
      for (final s in (tc['subjects'] as List?) ?? []) {
        final name = s['name'] as String? ?? 'Unknown';
        subFreq[name] = (subFreq[name] ?? 0) + 1;
      }
    }
    final topSubs = (subFreq.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(4)
        .toList();
    final maxSubFreq = topSubs.isEmpty ? 1 : topSubs.first.value;

    // Teachers with/without subjects for split bar
    final withSubs =
        widget.teachers.where((tc) => ((tc['subjects'] as List?)?.isNotEmpty == true)).length;
    final withoutSubs = widget.teachers.length - withSubs;

    final filtered = widget.teachers.where((tc) {
      final name =
          '${tc['firstName'] ?? ''} ${tc['lastName'] ?? ''}'.toLowerCase();
      final qual = (tc['qualification'] as String? ?? '').toLowerCase();
      return _search.isEmpty ||
          name.contains(_search.toLowerCase()) ||
          qual.contains(_search.toLowerCase());
    }).toList();

    final tableRows = filtered.map((tc) {
      final name =
          '${tc['firstName'] ?? ''} ${tc['lastName'] ?? ''}'.trim();
      final subs = (tc['subjects'] as List?)
              ?.map((s) => s['name'] as String)
              .join(', ') ??
          '';
      return [
        '${filtered.indexOf(tc) + 1}',
        name.isEmpty ? '—' : name,
        (tc['qualification'] as String?) ?? '—',
        subs.isEmpty ? '—' : subs,
        (tc['phone'] as String?) ?? '—',
      ];
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _StatCard(value: '${widget.teachers.length}', label: t['total_teachers'] ?? 'Total Teachers', icon: Icons.person_rounded, color: AppColors.primaryLight, isDark: isDark),
          const SizedBox(width: 12),
          _StatCard(value: '$uniqueSubs', label: t['subjects_taught'] ?? 'Subjects Taught', icon: Icons.menu_book_rounded, color: const Color(0xFF8B5CF6), isDark: isDark),
          const SizedBox(width: 12),
          _StatCard(value: avg.toStringAsFixed(1), label: t['avg_subjects'] ?? 'Avg Subjects', icon: Icons.bar_chart_rounded, color: const Color(0xFFF59E0B), isDark: isDark),
        ]),
        const SizedBox(height: 14),
        _SearchField(
            hint: t['search'] ?? 'Search',
            onChanged: (v) => setState(() => _search = v),
            isDark: isDark),
        const SizedBox(height: 12),

        // Table
        _DataTable(
          headers: [
            '#',
            t['full_name'] ?? 'Name',
            t['qualification'] ?? 'Qualification',
            t['subjects'] ?? 'Subjects',
            t['phone'] ?? 'Phone',
          ],
          flexes: const [1, 3, 2, 4, 2],
          rows: tableRows.cast<List<String?>>(),
          isDark: isDark,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report 3 — Class Summary
// ─────────────────────────────────────────────────────────────────────────────
class _ClassReport extends StatefulWidget {
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> students;
  final Map<String, String> t;
  final bool isDark;

  const _ClassReport(
      {required this.classes,
      required this.students,
      required this.t,
      required this.isDark});

  @override
  State<_ClassReport> createState() => _ClassReportState();
}

class _ClassReportState extends State<_ClassReport> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;

    // Students per class
    final Map<String, int> byClass = {};
    for (final s in widget.students) {
      final cls = (s['className'] as String?) ?? 'Unassigned';
      byClass[cls] = (byClass[cls] ?? 0) + 1;
    }
    final topClasses = (byClass.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(4)
        .toList();
    final maxStudents = topClasses.isEmpty ? 1 : topClasses.first.value;

    // Subjects per class for insight
    final Map<String, int> subsByClass = {};
    for (final c in widget.classes) {
      final name = (c['name'] as String?) ?? '?';
      subsByClass[name] = (c['subjects'] as List?)?.length ?? 0;
    }
    final topSubsClasses = (subsByClass.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(4)
        .toList();
    final maxSubsPerClass =
        topSubsClasses.isEmpty ? 1 : math.max(1, topSubsClasses.first.value);

    final uniqueSubs = widget.classes
        .expand((c) => (c['subjects'] as List?) ?? [])
        .map((s) => s['id'])
        .toSet()
        .length;

    final filtered = widget.classes.where((c) {
      final name = (c['name'] as String? ?? '').toLowerCase();
      final teacher = (c['teacherName'] as String? ?? '').toLowerCase();
      return _search.isEmpty ||
          name.contains(_search.toLowerCase()) ||
          teacher.contains(_search.toLowerCase());
    }).toList();

    final tableRows = filtered.map((c) {
      final name = (c['name'] as String?) ?? '—';
      final subs = (c['subjects'] as List?)
              ?.map((s) => s['name'] as String)
              .join(', ') ??
          '';
      return [
        '${filtered.indexOf(c) + 1}',
        name,
        (c['gradeLevel'] as String?) ?? '—',
        (c['teacherName'] as String?) ?? '—',
        subs.isEmpty ? '—' : subs,
        '${byClass[name] ?? 0}',
      ];
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _StatCard(value: '${widget.classes.length}', label: t['total_classes'] ?? 'Total Classes', icon: Icons.class_rounded, color: const Color(0xFFF59E0B), isDark: isDark),
          const SizedBox(width: 12),
          _StatCard(value: '$uniqueSubs', label: t['total_subjects'] ?? 'Total Subjects', icon: Icons.menu_book_rounded, color: const Color(0xFF8B5CF6), isDark: isDark),
          const SizedBox(width: 12),
          _StatCard(value: '${widget.students.length}', label: t['total_students'] ?? 'Total Students', icon: Icons.school_rounded, color: AppColors.primaryLight, isDark: isDark),
        ]),
        const SizedBox(height: 14),
        _SearchField(
            hint: t['search'] ?? 'Search',
            onChanged: (v) => setState(() => _search = v),
            isDark: isDark),
        const SizedBox(height: 12),

        // Table
        _DataTable(
          headers: [
            '#',
            t['class_name'] ?? 'Class',
            t['grade_level'] ?? 'Grade',
            t['teacher_name'] ?? 'Teacher',
            t['subjects'] ?? 'Subjects',
            t['students'] ?? 'Students',
          ],
          flexes: const [1, 3, 2, 3, 3, 2],
          rows: tableRows.cast<List<String?>>(),
          isDark: isDark,
        ),
      ],
    );
  }
}
