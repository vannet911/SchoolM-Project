// lib/screens/timetable.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/services/api_service.dart';
import 'package:schoolms_portal/utils/app_constants.dart';

// ── Data definitions ───────────────────────────────────────────────────────────

class _PeriodRow {
  final String label;
  final String time;
  final int period; // -1 = break, -2 = lunch, 1–8 = normal
  const _PeriodRow(this.label, this.time, this.period);
}

const _kPeriods = [
  _PeriodRow('07 AM', '07:00 – 08:00', 1),
  _PeriodRow('08 AM', '08:00 – 09:00', 2),
  _PeriodRow('09 AM', '09:00 – 10:00', 3),
  _PeriodRow('10 AM', '10:00 – 11:00', 4),
  _PeriodRow('11 AM', '11:00 – 12:00', 5),
  _PeriodRow('Lunch', '12:00 – 01:00 PM', -1),
  _PeriodRow('01 PM', '01:00 – 02:00 PM', 6),
  _PeriodRow('02 PM', '02:00 – 03:00 PM', 7),
  _PeriodRow('03 PM', '03:00 – 04:00 PM', 8),
  _PeriodRow('04 PM', '04:00 – 05:00 PM', 9),
  _PeriodRow('05 PM', '05:00 – 06:00 PM', 10),
];

const _kDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _kDayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _kWeekendDays = {'Saturday', 'Sunday'};

const _kSubjectColors = [
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFF9C27B0),
  Color(0xFFF44336),
  Color(0xFF00BCD4),
  Color(0xFFFF5722),
  Color(0xFF3F51B5),
  Color(0xFF009688),
  Color(0xFFE91E63),
];

// ── Main screen ────────────────────────────────────────────────────────────────

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _api = ApiService();

  List<dynamic> _entries = [];
  List<dynamic> _classes = [];
  List<dynamic> _teachers = [];
  List<dynamic> _subjects = [];
  bool _isLoading = true;

  String _filterClass = 'all';
  String _filterTeacher = 'all';
  String _filterDay = 'all';
  Map<String, dynamic>? _selectedEntry;
  bool _isClassView = false;

  final _searchCtrl = TextEditingController();
  final GlobalKey _searchBoxKey = GlobalKey();
  OverlayEntry? _filterOverlay;

  int get _activeFilterCount => [
        _filterClass != 'all',
        _filterTeacher != 'all',
        _filterDay != 'all',
      ].where((v) => v).length;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _filterOverlay?.remove();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final api = _api;

      // Phase 1: load reference data (fast — these endpoints exist)
      final ref = await Future.wait<List<dynamic>>([
        api.getClasses().catchError((_) => <dynamic>[]),
        api.getTeachers().catchError((_) => <dynamic>[]),
        api.getSubjects().catchError((_) => <dynamic>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _classes = ref[0];
        _teachers = ref[1];
        _subjects = ref[2];
        _isLoading = false; // show grid immediately
      });

      // Phase 2: load timetable entries separately (may fail gracefully)
      final entries = await api
          .getTimetableEntries()
          .catchError((_) => <dynamic>[]);
      if (mounted) setState(() => _entries = entries);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredEntries {
    final q = _searchCtrl.text.toLowerCase().trim();
    return _entries.where((e) {
      // Search across subject, class, teacher, room
      if (q.isNotEmpty) {
        final hay = [
          e['subjectName'], e['subjectCode'],
          e['className'], e['teacherName'], e['room'],
        ].whereType<String>().join(' ').toLowerCase();
        if (!hay.contains(q)) return false;
      }
      // Class filter
      if (_filterClass != 'all') {
        if ((e['className']?.toString() ?? '') != _filterClass) return false;
      }
      // Teacher filter
      if (_filterTeacher != 'all') {
        if ((e['teacherName']?.toString() ?? '') != _filterTeacher) return false;
      }
      // Day filter
      if (_filterDay != 'all') {
        if ((e['day']?.toString() ?? '') != _filterDay) return false;
      }
      return true;
    }).toList();
  }

  List<dynamic> _entriesAt(String day, int period) {
    return _filteredEntries.where((e) {
      final d = e['day']?.toString() ?? '';
      final p = e['period'];
      final pInt = p is int ? p : int.tryParse(p?.toString() ?? '');
      return d == day && pInt == period;
    }).toList();
  }

  Color _colorForSubject(dynamic subjectId) {
    if (subjectId == null) return AppColors.primary;
    final id = subjectId is int ? subjectId : int.tryParse(subjectId.toString()) ?? 0;
    return _kSubjectColors[(id - 1).abs() % _kSubjectColors.length];
  }

  String _getTodayName() {
    const names = {
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };
    return names[DateTime.now().weekday] ?? '';
  }

  void _toggleFilter() {
    if (_filterOverlay != null) {
      _filterOverlay!.remove();
      _filterOverlay = null;
      return;
    }
    final keyCtx = _searchBoxKey.currentContext;
    if (keyCtx == null) return;
    final box = keyCtx.findRenderObject() as RenderBox;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero, ancestor: overlayBox);

    final locale = context.read<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build unique class and teacher name lists from loaded data
    final classNames = _classes
        .map((c) => c['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final teacherNames = _teachers.map((tc) {
      final n =
          '${tc['firstName'] ?? tc['first_name'] ?? ''} ${tc['lastName'] ?? tc['last_name'] ?? ''}'
              .trim();
      return n.isEmpty ? (tc['name']?.toString() ?? '') : n;
    }).where((s) => s.isNotEmpty).toSet().toList()
      ..sort();

    _filterOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _filterOverlay?.remove();
                _filterOverlay = null;
              },
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: pos.dx,
            top: pos.dy + box.size.height + 6,
            width: box.size.width,
            child: GestureDetector(
              onTap: () {},
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: _TimetableFilterPanel(
                  filterClass: _filterClass,
                  filterTeacher: _filterTeacher,
                  filterDay: _filterDay,
                  classNames: classNames,
                  teacherNames: teacherNames,
                  t: t,
                  isDark: isDark,
                  onApply: (cls, teacher, day) {
                    _filterOverlay?.remove();
                    _filterOverlay = null;
                    setState(() {
                      _filterClass = cls;
                      _filterTeacher = teacher;
                      _filterDay = day;
                      _selectedEntry = null;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_filterOverlay!);
  }

  void _openForm({Map<String, dynamic>? entry}) async {
    final locale = context.read<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _TimetableFormDialog(
        entry: entry,
        classes: _classes,
        teachers: _teachers,
        subjects: _subjects,
        t: t,
        isDark: isDark,
      ),
    );

    if (result != null && mounted) {
      final api = _api;
      try {
        if (entry != null) {
          await api.updateTimetableEntry(entry['id'] as int, result);
        } else {
          await api.createTimetableEntry(result);
        }
        setState(() => _selectedEntry = null);
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t['save_failed'] ?? 'Save failed'}: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedEntry == null) return;
    final locale = context.read<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dlgBg = isDark ? const Color(0xFF1C2A4A) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final bodyColor = isDark ? Colors.white70 : AppColors.textPrimary;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dlgBg,
        title: Text(t['confirm_delete'] ?? 'Confirm Delete',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: titleColor)),
        content: Text(t['confirm_delete_timetable'] ?? 'Delete this timetable entry?',
            style: AppTextStyles.body.copyWith(color: bodyColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t['cancel'] ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(t['delete'] ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final api = _api;
      try {
        await api.deleteTimetableEntry(_selectedEntry!['id'] as int);
        setState(() => _selectedEntry = null);
        await _load();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppTranslations.translations[
                            context.read<LocaleProvider>().locale]!['delete_failed'] ??
                        'Delete failed')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    final surfaceBg = isDark ? const Color(0xFF16213E) : AppColors.white;
    final bgColor = isDark ? const Color(0xFF1C2A4A) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A3A5A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white54 : AppColors.textSecondary;

    return Container(
      color: surfaceBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolbar(t, isDark, isMobile, borderColor, bgColor, textColor, mutedColor),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : isMobile
                    ? _buildMobileList(t, isDark, bgColor, borderColor, textColor, mutedColor)
                    : _isClassView
                        ? _buildClassView(
                            t, isDark, bgColor, borderColor, surfaceBg, textColor, mutedColor)
                        : _buildWeeklyGrid(
                            t, isDark, bgColor, borderColor, surfaceBg, textColor, mutedColor),
          ),
        ],
      ),
    );
  }

  // ── Toolbar ──────────────────────────────────────────────────────────────────

  Widget _buildToolbar(Map<String, String> t, bool isDark, bool isMobile,
      Color borderColor, Color bgColor, Color textColor, Color mutedColor) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600 && w < 1024;
    final searchBg = isDark ? const Color(0xFF16213E) : AppColors.white;
    final hasFilters = _activeFilterCount > 0;

    final searchBox = KeyedSubtree(
      key: _searchBoxKey,
      child: SizedBox(
        height: 42,
        child: TextField(
          controller: _searchCtrl,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: t['search'] ?? 'Search...',
            hintStyle: AppTextStyles.body.copyWith(color: mutedColor),
            prefixIcon: Icon(Icons.search, size: 18, color: mutedColor),
            suffixIcon: _FilterIconSuffix(
              onTap: _toggleFilter,
              activeFilter: hasFilters,
              filterCount: _activeFilterCount,
              mutedColor: mutedColor,
              isDark: isDark,
            ),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary)),
            filled: true,
            fillColor: searchBg,
          ),
        ),
      ),
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 12, AppConstants.pagePadding, 8),
        child: Row(
          children: [
            Expanded(child: searchBox),
            const SizedBox(width: 8),
            _ViewToggleButton(
              isClassView: _isClassView,
              onToggle: () => setState(() => _isClassView = !_isClassView),
            ),
            const SizedBox(width: 8),
            _IconBtn(
              icon: Icons.add,
              onTap: () => _openForm(),
            ),
          ],
        ),
      );
    }

    final List<Widget> actionBtns = [
      const SizedBox(width: 8),
      _TblBtn(
        icon: Icons.add,
        label: t['add'] ?? 'Add',
        iconOnly: isTablet,
        onTap: () => _openForm(),
      ),
      const SizedBox(width: 6),
      _TblBtn(
        icon: Icons.edit_outlined,
        label: t['edit'] ?? 'Edit',
        iconOnly: isTablet,
        enabled: _selectedEntry != null,
        onTap: _selectedEntry != null ? () => _openForm(entry: _selectedEntry) : null,
      ),
      const SizedBox(width: 6),
      _TblBtn(
        icon: Icons.delete_outline,
        label: t['delete'] ?? 'Delete',
        iconOnly: isTablet,
        enabled: _selectedEntry != null,
        onTap: _selectedEntry != null ? _deleteSelected : null,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppConstants.pagePaddingDesktop, 12, AppConstants.pagePaddingDesktop, 8),
      child: Row(
        children: [
          if (isTablet)
            Expanded(child: searchBox)
          else
            SizedBox(width: 320, child: searchBox),
          const SizedBox(width: 8),
          _ViewToggleButton(
            isClassView: _isClassView,
            onToggle: () => setState(() => _isClassView = !_isClassView),
          ),
          if (!isTablet) const Spacer(),
          ...actionBtns,
        ],
      ),
    );
  }

  List<dynamic> _classEntriesAt(String className, int period) {
    return _filteredEntries.where((e) {
      final cls = e['className']?.toString() ?? '';
      final p = e['period'];
      final pInt = p is int ? p : int.tryParse(p?.toString() ?? '');
      return cls == className && pInt == period;
    }).toList();
  }

  String _dayAbbr(String day) {
    final idx = _kDays.indexOf(day);
    return idx >= 0 ? _kDayAbbr[idx] : (day.length >= 3 ? day.substring(0, 3) : day);
  }

  // ── Weekly grid (desktop / tablet) ───────────────────────────────────────────

  Widget _buildWeeklyGrid(Map<String, String> t, bool isDark, Color bgColor,
      Color borderColor, Color surfaceBg, Color textColor, Color mutedColor) {
    const timeColW = 150.0;
    const minDayColW = 118.0;
    const rowH = 74.0;
    const breakH = 48.0;
    const headerH = 48.0;
    final headerBg = isDark ? const Color(0xFF1C2A4A) : AppColors.sidebarBg;
    final breakBg = isDark ? const Color(0xFF141E30) : const Color(0xFFF5F7FA);
    final todayName = _getTodayName();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppConstants.pagePaddingDesktop, 4, AppConstants.pagePaddingDesktop, AppConstants.pagePaddingDesktop),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final rawDayColW =
              (constraints.maxWidth - timeColW - _kDays.length) /
                  _kDays.length;
          // Expand to fill full width; scroll only when screen is too narrow
          final dayColW = rawDayColW.clamp(minDayColW, double.infinity);
          final gridW = timeColW + (dayColW + 1) * _kDays.length;

          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: gridW,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: [
                        // Day header row
                        Container(
                          height: headerH,
                          color: headerBg,
                          child: Row(
                            children: [
                              SizedBox(
                                width: timeColW,
                                child: Center(
                                  child: Text(
                                    t['period'] ?? 'Period',
                                    style: AppTextStyles.body.copyWith(
                                        color: mutedColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              for (int i = 0; i < _kDays.length; i++) ...[
                                Container(
                                    width: 1,
                                    height: headerH,
                                    color: borderColor),
                                _buildDayHeader(
                                  abbr: _kDayAbbr[i],
                                  dayName: _kDays[i],
                                  width: dayColW,
                                  height: headerH,
                                  isToday: _kDays[i] == todayName,
                                  isWeekend:
                                      _kWeekendDays.contains(_kDays[i]),
                                  isDark: isDark,
                                  textColor: textColor,
                                  mutedColor: mutedColor,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(height: 1, color: borderColor),
                        // Period rows
                        for (int ri = 0; ri < _kPeriods.length; ri++) ...[
                          _buildGridRow(
                            period: _kPeriods[ri],
                            timeColW: timeColW,
                            dayColW: dayColW,
                            rowH: rowH,
                            breakH: breakH,
                            isDark: isDark,
                            bgColor: bgColor,
                            breakBg: breakBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            mutedColor: mutedColor,
                          ),
                          if (ri < _kPeriods.length - 1)
                            Container(height: 1, color: borderColor),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayHeader({
    required String abbr,
    required String dayName,
    required double width,
    required double height,
    required bool isToday,
    required bool isWeekend,
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
  }) {
    final weekendBg =
        isDark ? const Color(0xFF131D35) : const Color(0xFFF2F4FA);
    return Container(
      width: width,
      height: height,
      color: isWeekend ? weekendBg : null,
      child: Center(
        child: isToday
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : Text(
                dayName,
                style: AppTextStyles.body.copyWith(
                  color: isWeekend ? mutedColor : textColor,
                  fontSize: 14,
                  fontWeight: isWeekend ? FontWeight.w500 : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }

  Widget _buildGridRow({
    required _PeriodRow period,
    required double timeColW,
    required double dayColW,
    required double rowH,
    required double breakH,
    required bool isDark,
    required Color bgColor,
    required Color breakBg,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    final isBreak = period.period < 0;

    final weekendCellBg =
        isDark ? const Color(0xFF131D35) : const Color(0xFFF2F4FA);

    if (isBreak) {
      return Container(
        height: breakH,
        color: breakBg,
        child: Row(
          children: [
            SizedBox(
              width: timeColW,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.restaurant_outlined,
                      size: 18,
                      color: mutedColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${period.label}  ${period.time}',
                        style:
                            AppTextStyles.body.copyWith(color: mutedColor, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (int di = 0; di < _kDays.length; di++) ...[
              Container(width: 1, height: breakH, color: borderColor),
              SizedBox(
                width: dayColW,
                child: Container(
                  color: _kWeekendDays.contains(_kDays[di])
                      ? weekendCellBg
                      : breakBg,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      height: rowH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: timeColW,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(period.label,
                      style: AppTextStyles.body.copyWith(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  Text(period.time,
                      style: AppTextStyles.body
                          .copyWith(color: mutedColor, fontSize: 14),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          for (int di = 0; di < _kDays.length; di++) ...[
            Container(width: 1, color: borderColor),
            Container(
              width: dayColW,
              height: rowH,
              color: _kWeekendDays.contains(_kDays[di])
                  ? weekendCellBg.withValues(alpha: isDark ? 0.6 : 0.5)
                  : null,
              child: _buildCell(
                _kDays[di],
                period.period,
                isDark,
                bgColor,
                textColor,
                mutedColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCell(String day, int period, bool isDark, Color bgColor,
      Color textColor, Color mutedColor) {
    final entries = _entriesAt(day, period);
    if (entries.isEmpty) {
      return GestureDetector(
        onTap: () => setState(() => _selectedEntry = null),
        child: Container(color: Colors.transparent),
      );
    }

    final entry = entries.first as Map<String, dynamic>;
    final isSelected = _selectedEntry?['id'] == entry['id'];
    final color = _colorForSubject(entry['subjectId']);
    final subjectName = entry['subjectName']?.toString() ??
        entry['subjectCode']?.toString() ?? '';
    final className = entry['className']?.toString() ?? '';
    final teacherName = entry['teacherName']?.toString() ?? '';

    return GestureDetector(
      onTap: () => setState(() => _selectedEntry = isSelected ? null : entry),
      onDoubleTap: () {
        setState(() => _selectedEntry = entry);
        _openForm(entry: entry);
      },
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    subjectName,
                    style: AppTextStyles.body.copyWith(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (entries.length > 1) ...[
                  const SizedBox(width: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text('!${entries.length}',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.error, fontSize: 14)),
                  ),
                ],
              ],
            ),
            if (className.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(className,
                  style:
                      AppTextStyles.caption.copyWith(color: mutedColor, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
            ],
            if (teacherName.isNotEmpty)
              Text(teacherName,
                  style:
                      AppTextStyles.caption.copyWith(color: mutedColor, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Class view (desktop / tablet) ────────────────────────────────────────────

  Widget _buildClassView(Map<String, String> t, bool isDark, Color bgColor,
      Color borderColor, Color surfaceBg, Color textColor, Color mutedColor) {
    const classColW = 150.0;
    const minPeriodColW = 100.0;
    const rowH = 70.0;
    const headerH = 48.0;
    final headerBg = isDark ? const Color(0xFF1C2A4A) : AppColors.sidebarBg;
    final activePeriods = _kPeriods.where((p) => p.period > 0).toList();
    final classNames = _classes
        .map((c) => c['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppConstants.pagePaddingDesktop, 4,
          AppConstants.pagePaddingDesktop, AppConstants.pagePaddingDesktop),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final rawPeriodColW =
              (constraints.maxWidth - classColW - activePeriods.length) /
                  activePeriods.length;
          final periodColW = rawPeriodColW.clamp(minPeriodColW, double.infinity);
          final gridW = classColW + (periodColW + 1) * activePeriods.length;

          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: gridW,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: [
                        // Header row
                        Container(
                          height: headerH,
                          color: headerBg,
                          child: Row(
                            children: [
                              SizedBox(
                                width: classColW,
                                child: Center(
                                  child: Text(
                                    t['class_name'] ?? 'Class',
                                    style: AppTextStyles.body.copyWith(
                                      color: mutedColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              for (final p in activePeriods) ...[
                                Container(
                                    width: 1, height: headerH, color: borderColor),
                                SizedBox(
                                  width: periodColW,
                                  height: headerH,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          p.label,
                                          style: AppTextStyles.body.copyWith(
                                            color: textColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          p.time,
                                          style: AppTextStyles.caption.copyWith(
                                            color: mutedColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(height: 1, color: borderColor),
                        // Class rows
                        if (classNames.isEmpty)
                          SizedBox(
                            height: 120,
                            child: Center(
                              child: Text(
                                t['no_classes'] ?? 'No classes',
                                style: AppTextStyles.body.copyWith(color: mutedColor),
                              ),
                            ),
                          )
                        else
                          for (int ri = 0; ri < classNames.length; ri++) ...[
                            SizedBox(
                              height: rowH,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    width: classColW,
                                    color: headerBg,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text(
                                          classNames[ri],
                                          style: AppTextStyles.body.copyWith(
                                            color: textColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  for (final p in activePeriods) ...[
                                    Container(width: 1, color: borderColor),
                                    SizedBox(
                                      width: periodColW,
                                      child: _buildClassCell(
                                        classNames[ri],
                                        p.period,
                                        isDark,
                                        bgColor,
                                        textColor,
                                        mutedColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (ri < classNames.length - 1)
                              Container(height: 1, color: borderColor),
                          ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassCell(String className, int period, bool isDark, Color bgColor,
      Color textColor, Color mutedColor) {
    final entries = _classEntriesAt(className, period);
    if (entries.isEmpty) {
      return GestureDetector(
        onTap: () => setState(() => _selectedEntry = null),
        child: Container(color: Colors.transparent),
      );
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: entries.map((entry) {
            final isSelected = _selectedEntry?['id'] == entry['id'];
            final color = _colorForSubject(entry['subjectId']);
            final subject = entry['subjectName']?.toString() ??
                entry['subjectCode']?.toString() ?? '';
            final dayAbbr = _dayAbbr(entry['day']?.toString() ?? '');
            return GestureDetector(
              onTap: () => setState(() =>
                  _selectedEntry = isSelected ? null : Map<String, dynamic>.from(entry as Map)),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? color : color.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        subject,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected ? Colors.white : color,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        dayAbbr,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected ? Colors.white : color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Mobile list (grouped by day) ─────────────────────────────────────────────

  Widget _buildMobileList(Map<String, String> t, bool isDark, Color bgColor,
      Color borderColor, Color textColor, Color mutedColor) {
    if (_filteredEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 48, color: mutedColor),
            const SizedBox(height: 12),
            Text(t['no_timetable_data'] ?? 'No timetable entries',
                style: AppTextStyles.body.copyWith(color: mutedColor)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 16),
              label: Text(t['add_timetable'] ?? 'Add Entry'),
            ),
          ],
        ),
      );
    }

    final grouped = <String, List<dynamic>>{};
    for (final day in _kDays) {
      final dayEntries = _filteredEntries
          .where((e) => e['day']?.toString() == day)
          .toList()
        ..sort((a, b) {
          final pa = a['period'] is int
              ? a['period'] as int
              : int.tryParse(a['period']?.toString() ?? '') ?? 0;
          final pb = b['period'] is int
              ? b['period'] as int
              : int.tryParse(b['period']?.toString() ?? '') ?? 0;
          return pa.compareTo(pb);
        });
      if (dayEntries.isNotEmpty) grouped[day] = dayEntries;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      children: [
        for (final day in _kDays)
          if (grouped.containsKey(day)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
              child: Text(day,
                  style: AppTextStyles.heading3.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < grouped[day]!.length; i++) ...[
                    _buildMobileCard(grouped[day]![i] as Map<String, dynamic>,
                        isDark, borderColor, textColor, mutedColor, t),
                    if (i < grouped[day]!.length - 1)
                      Divider(height: 1, color: borderColor),
                  ],
                ],
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildMobileCard(
      Map<String, dynamic> entry,
      bool isDark,
      Color borderColor,
      Color textColor,
      Color mutedColor,
      Map<String, String> t) {
    final isSelected = _selectedEntry?['id'] == entry['id'];
    final color = _colorForSubject(entry['subjectId']);
    final periodInt = entry['period'] is int
        ? entry['period'] as int
        : int.tryParse(entry['period']?.toString() ?? '') ?? 0;
    _PeriodRow? periodData;
    try {
      periodData = _kPeriods.firstWhere((p) => p.period == periodInt);
    } catch (_) {}
    final subjectName = entry['subjectName']?.toString() ??
        entry['subjectCode']?.toString() ?? '';
    final className = entry['className']?.toString() ?? '';
    final teacherName = entry['teacherName']?.toString() ?? '';
    final room = entry['room']?.toString() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedEntry = isSelected ? null : entry),
        onLongPress: () {
          setState(() => _selectedEntry = entry);
          _openForm(entry: entry);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      periodData?.label ?? 'P$periodInt',
                      style: AppTextStyles.caption.copyWith(
                          color: color, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subjectName,
                        style: AppTextStyles.body.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (className.isNotEmpty) ...[
                          Icon(Icons.class_outlined, size: 11, color: mutedColor),
                          const SizedBox(width: 3),
                          Text(className,
                              style: AppTextStyles.caption
                                  .copyWith(color: mutedColor, fontSize: 11)),
                          const SizedBox(width: 8),
                        ],
                        if (teacherName.isNotEmpty) ...[
                          Icon(Icons.person_outline, size: 11, color: mutedColor),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(teacherName,
                                style: AppTextStyles.caption
                                    .copyWith(color: mutedColor, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                    if (periodData != null)
                      Text(periodData.time,
                          style: AppTextStyles.caption
                              .copyWith(color: mutedColor, fontSize: 10)),
                  ],
                ),
              ),
              if (room.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A3A5A)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(room,
                      style: AppTextStyles.caption
                          .copyWith(color: mutedColor, fontSize: 10)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Toolbar buttons ────────────────────────────────────────────────────────────

class _TblBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool iconOnly;
  final bool enabled;
  final VoidCallback? onTap;

  const _TblBtn({
    required this.icon,
    required this.label,
    this.iconOnly = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;

    final style = OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryLight,
      elevation: 0,
      padding: iconOnly
          ? const EdgeInsets.all(0)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      side: BorderSide(color: borderColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      minimumSize: iconOnly ? const Size(48, 48) : null,
    );

    if (iconOnly) {
      return OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: style,
        child: Icon(icon, size: 18),
      );
    }
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: style,
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        elevation: 0,
        padding: const EdgeInsets.all(0),
        side: BorderSide(color: borderColor, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        minimumSize: const Size(48, 48),
      ),
      child: Icon(icon, size: 18),
    );
  }
}

// ── Add / Edit form dialog ─────────────────────────────────────────────────────

class _TimetableFormDialog extends StatefulWidget {
  final Map<String, dynamic>? entry;
  final List<dynamic> classes;
  final List<dynamic> teachers;
  final List<dynamic> subjects;
  final Map<String, String> t;
  final bool isDark;

  const _TimetableFormDialog({
    this.entry,
    required this.classes,
    required this.teachers,
    required this.subjects,
    required this.t,
    required this.isDark,
  });

  @override
  State<_TimetableFormDialog> createState() => _TimetableFormDialogState();
}

class _TimetableFormDialogState extends State<_TimetableFormDialog> {
  String? _day;
  int? _period;
  int? _classId;
  int? _subjectId;
  int? _teacherId;
  final _roomCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    if (e != null) {
      _day = e['day']?.toString();
      final p = e['period'];
      _period = p is int ? p : int.tryParse(p?.toString() ?? '');
      _classId = _toInt(e['classId']);
      _subjectId = _toInt(e['subjectId']);
      _teacherId = _toInt(e['teacherId']);
      _roomCtrl.text = e['room']?.toString() ?? '';
      _yearCtrl.text = e['academicYear']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _roomCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  int? _toInt(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  bool get _isValid => _day != null && _period != null && _classId != null && _subjectId != null;

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final isDark = widget.isDark;
    final dlgBg = isDark ? const Color(0xFF1C2A4A) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final labelColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final fieldBg = isDark ? const Color(0xFF162035) : AppColors.background;
    final borderColor = isDark ? const Color(0xFF2A3A5A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final isEditing = widget.entry != null;

    Widget dropRow(
        String label, Widget dd1, String label2, Widget dd2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _fieldWrap(label, dd1, labelColor)),
          const SizedBox(width: 12),
          Expanded(child: _fieldWrap(label2, dd2, labelColor)),
        ],
      );
    }

    Widget dd<T>({
      required T? value,
      required String hint,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged,
    }) {
      return Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: fieldBg,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            hint: Text(hint,
                style: AppTextStyles.body.copyWith(color: labelColor, fontSize: 13)),
            dropdownColor: dlgBg,
            style: AppTextStyles.body.copyWith(color: textColor, fontSize: 13),
            icon: Icon(Icons.keyboard_arrow_down, size: 16, color: labelColor),
            isExpanded: true,
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
    }

    Widget textField(TextEditingController ctrl, String hint) {
      return TextField(
        controller: ctrl,
        style: AppTextStyles.body.copyWith(color: textColor, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTextStyles.body.copyWith(color: labelColor, fontSize: 13),
          filled: true,
          fillColor: fieldBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      );
    }

    final periodItems = _kPeriods
        .where((p) => p.period > 0)
        .map((p) => DropdownMenuItem<int>(
              value: p.period,
              child: Text('${p.label}  ${p.time}',
                  style: AppTextStyles.body.copyWith(color: textColor, fontSize: 13)),
            ))
        .toList();

    return AlertDialog(
      backgroundColor: dlgBg,
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      title: Text(
        isEditing
            ? (t['edit_timetable'] ?? 'Edit Entry')
            : (t['add_timetable'] ?? 'Add Entry'),
        style: AppTextStyles.body
            .copyWith(fontWeight: FontWeight.w700, color: titleColor),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              dropRow(
                t['day'] ?? 'Day',
                dd<String>(
                  value: _day,
                  hint: t['select_day'] ?? 'Select Day',
                  items: _kDays
                      .map((d) => DropdownMenuItem<String>(
                            value: d,
                            child: Text(d,
                                style: AppTextStyles.body
                                    .copyWith(color: textColor, fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _day = v),
                ),
                t['period'] ?? 'Period',
                dd<int>(
                  value: _period,
                  hint: t['select_period'] ?? 'Select Period',
                  items: periodItems,
                  onChanged: (v) => setState(() => _period = v),
                ),
              ),
              _fieldWrap(
                t['select_class'] ?? 'Class',
                dd<int>(
                  value: _classId,
                  hint: t['select_class'] ?? 'Select Class',
                  items: widget.classes
                      .map((c) => DropdownMenuItem<int>(
                            value: c['id'] as int?,
                            child: Text(
                                c['name']?.toString() ?? '',
                                style: AppTextStyles.body
                                    .copyWith(color: textColor, fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _classId = v),
                ),
                labelColor,
              ),
              _fieldWrap(
                t['subject'] ?? 'Subject',
                dd<int>(
                  value: _subjectId,
                  hint: t['subject'] ?? 'Select Subject',
                  items: widget.subjects
                      .map((s) => DropdownMenuItem<int>(
                            value: s['id'] as int?,
                            child: Text(
                                '${s['code'] ?? ''} — ${s['name'] ?? ''}',
                                style: AppTextStyles.body
                                    .copyWith(color: textColor, fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _subjectId = v),
                ),
                labelColor,
              ),
              _fieldWrap(
                t['teachers'] ?? 'Teacher',
                dd<int?>(
                  value: _teacherId,
                  hint: t['select_teacher'] ?? 'Select Teacher',
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(t['none'] ?? 'None',
                          style: AppTextStyles.body
                              .copyWith(color: labelColor, fontSize: 13)),
                    ),
                    ...widget.teachers.map((tc) {
                      final name =
                          '${tc['firstName'] ?? tc['first_name'] ?? ''} ${tc['lastName'] ?? tc['last_name'] ?? ''}'
                              .trim();
                      return DropdownMenuItem<int?>(
                        value: tc['id'] as int?,
                        child: Text(
                            name.isEmpty ? (tc['name']?.toString() ?? '') : name,
                            style: AppTextStyles.body
                                .copyWith(color: textColor, fontSize: 13)),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() => _teacherId = v),
                ),
                labelColor,
              ),
              dropRow(
                t['room'] ?? 'Room',
                textField(_roomCtrl, t['room_hint'] ?? 'e.g. Room 101'),
                t['academic_year'] ?? 'Academic Year',
                textField(_yearCtrl, '2024–2025'),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t['cancel'] ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValid
              ? () => Navigator.pop(context, {
                    'day': _day,
                    'period': _period,
                    'classId': _classId,
                    'subjectId': _subjectId,
                    'teacherId': _teacherId,
                    'room': _roomCtrl.text.trim(),
                    'academicYear': _yearCtrl.text.trim(),
                  })
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppColors.primary.withValues(alpha: 0.4),
          ),
          child: Text(t['save'] ?? 'Save'),
        ),
      ],
    );
  }

  Widget _fieldWrap(String label, Widget child, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: labelColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        child,
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Filter icon suffix (matches students screen) ──────────────────────────────

class _FilterIconSuffix extends StatefulWidget {
  final VoidCallback onTap;
  final bool activeFilter;
  final int filterCount;
  final Color mutedColor;
  final bool isDark;

  const _FilterIconSuffix({
    required this.onTap,
    required this.activeFilter,
    required this.filterCount,
    required this.mutedColor,
    required this.isDark,
  });

  @override
  State<_FilterIconSuffix> createState() => _FilterIconSuffixState();
}

class _FilterIconSuffixState extends State<_FilterIconSuffix> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final hoverBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.0)
        : AppColors.primarySurface;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => WidgetsBinding.instance.addPostFrameCallback(
          (_) { if (mounted) setState(() => _hovering = true); }),
      onExit: (_) => WidgetsBinding.instance.addPostFrameCallback(
          (_) { if (mounted) setState(() => _hovering = false); }),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 0),
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: widget.activeFilter
                    ? AppColors.primary.withValues(alpha: 0.0)
                    : _hovering
                        ? hoverBg
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 18,
                color: widget.activeFilter
                    ? AppColors.primary
                    : _hovering
                        ? AppColors.primary
                        : widget.mutedColor,
              ),
            ),
            if (widget.activeFilter)
              Positioned(
                top: 6,
                right: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.filterCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Timetable filter panel overlay ────────────────────────────────────────────

class _TimetableFilterPanel extends StatefulWidget {
  final String filterClass;
  final String filterTeacher;
  final String filterDay;
  final List<String> classNames;
  final List<String> teacherNames;
  final Map<String, String> t;
  final bool isDark;
  final void Function(String cls, String teacher, String day) onApply;

  const _TimetableFilterPanel({
    required this.filterClass,
    required this.filterTeacher,
    required this.filterDay,
    required this.classNames,
    required this.teacherNames,
    required this.t,
    required this.isDark,
    required this.onApply,
  });

  @override
  State<_TimetableFilterPanel> createState() => _TimetableFilterPanelState();
}

class _TimetableFilterPanelState extends State<_TimetableFilterPanel> {
  late String _cls;
  late String _teacher;
  late String _day;

  @override
  void initState() {
    super.initState();
    _cls = widget.filterClass;
    _teacher = widget.filterTeacher;
    _day = widget.filterDay;
  }

  Widget _section(String title, List<Widget> chips) {
    final isDark = widget.isDark;
    final mutedColor = isDark ? Colors.white60 : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTextStyles.label.copyWith(
                color: mutedColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget _chip(String label, String value, String current,
      void Function(String) onSelect) {
    final isDark = widget.isDark;
    final selected = current == value;
    return GestureDetector(
      onTap: () => setState(() => onSelect(value)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1C2A4A) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle_rounded,
                size: 14, color: AppColors.primary),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final t = widget.t;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final dividerColor = isDark ? const Color(0xFF2A2A4A) : AppColors.border;

    // "all" sentinel → display label mapping
    final clsVal = _cls == 'all' ? 'all' : _cls;
    final teacherVal = _teacher == 'all' ? 'all' : _teacher;
    final dayVal = _day == 'all' ? 'all' : _day;

    final classChips = [
      _chip(t['all_classes'] ?? 'All', 'all', clsVal, (v) => _cls = v),
      ...widget.classNames.where((c) => c.isNotEmpty)
          .map((c) => _chip(c, c, clsVal, (v) => _cls = v)),
    ];

    final teacherChips = [
      _chip(t['all_teachers'] ?? 'All', 'all', teacherVal,
          (v) => _teacher = v),
      ...widget.teacherNames.where((n) => n.isNotEmpty)
          .map((n) => _chip(n, n, teacherVal, (v) => _teacher = v)),
    ];

    final dayChips = [
      _chip(t['all_days'] ?? 'All', 'all', dayVal, (v) => _day = v),
      ..._kDays.map((d) => _chip(d, d, dayVal, (v) => _day = v)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(children: [
              const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t['filter'] ?? 'Filter',
                    style: AppTextStyles.body.copyWith(
                        color: textColor, fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () =>
                    setState(() { _cls = 'all'; _teacher = 'all'; _day = 'all'; }),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero),
                child: Text(t['reset'] ?? 'Reset',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ]),
          ),
          Divider(height: 1, color: dividerColor),
          // Filter sections
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section(t['class_name'] ?? 'Class', classChips),
                const SizedBox(height: 16),
                if (widget.teacherNames.isNotEmpty) ...[
                  _section(t['teacher'] ?? 'Teacher', teacherChips),
                  const SizedBox(height: 16),
                ],
                _section(t['day'] ?? 'Day', dayChips),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => widget.onApply(_cls, _teacher, _day),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(t['confirm'] ?? 'Apply',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
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

// ── View toggle button (matches students screen) ──────────────────────────────

class _ViewToggleButton extends StatelessWidget {
  final bool isClassView;
  final VoidCallback onToggle;
  const _ViewToggleButton({required this.isClassView, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C2A4A) : const Color(0xFFF1F3F8);
    const activeColor = AppColors.primary;
    final inactiveColor = isDark ? Colors.white38 : const Color(0xFFADB5C7);

    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleSeg(
            icon: Icons.view_week_outlined,
            active: !isClassView,
            onTap: isClassView ? onToggle : null,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            isDark: isDark,
          ),
          const SizedBox(width: 2),
          _ToggleSeg(
            icon: Icons.table_chart_outlined,
            active: isClassView,
            onTap: isClassView ? null : onToggle,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ToggleSeg extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  final Color activeColor;
  final Color inactiveColor;
  final bool isDark;
  const _ToggleSeg({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark
        ? activeColor.withValues(alpha: 0.25)
        : Colors.white;
    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.70);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        boxShadow: active
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: isDark ? 0.30 : 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          hoverColor: hoverBg,
          splashColor: activeColor.withValues(alpha: 0.10),
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          mouseCursor: onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: active ? activeColor : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}
