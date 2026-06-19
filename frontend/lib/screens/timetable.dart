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

String _tDay(String day, Map<String, String> t) => t[day.toLowerCase()] ?? day;

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
  bool _showForm = false;
  Map<String, dynamic>? _formEntry;

  final _searchCtrl = TextEditingController();
  final GlobalKey _searchBoxKey = GlobalKey();
  OverlayEntry? _filterOverlay;

  // Weekly grid scroll controllers
  final _weekHScroll = ScrollController();
  final _weekHHeaderScroll = ScrollController();

  // Class view scroll controllers: content drives, header/fixed column follow via listeners
  final _classHScroll = ScrollController();
  final _classHHeaderScroll = ScrollController();
  final _classVScroll = ScrollController();
  final _classVFixedScroll = ScrollController();

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
    _weekHScroll.addListener(() {
      if (_weekHHeaderScroll.hasClients) {
        _weekHHeaderScroll.jumpTo(_weekHScroll.offset);
      }
    });
    _classHScroll.addListener(() {
      if (_classHHeaderScroll.hasClients) {
        _classHHeaderScroll.jumpTo(_classHScroll.offset);
      }
    });
    _classVScroll.addListener(() {
      if (_classVFixedScroll.hasClients) {
        _classVFixedScroll.jumpTo(_classVScroll.offset);
      }
    });
  }

  @override
  void dispose() {
    _filterOverlay?.remove();
    _searchCtrl.dispose();
    _weekHScroll.dispose();
    _weekHHeaderScroll.dispose();
    _classHScroll.dispose();
    _classHHeaderScroll.dispose();
    _classVScroll.dispose();
    _classVFixedScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final api = _api;
      final results = await Future.wait<List<dynamic>>([
        api.getClasses().catchError((_) => <dynamic>[]),
        api.getTeachers().catchError((_) => <dynamic>[]),
        api.getSubjects().catchError((_) => <dynamic>[]),
        api.getTimetableEntries().catchError((_) => <dynamic>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _classes = results[0];
        _teachers = results[1];
        _subjects = results[2];
        _entries = results[3];
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reloadEntries() async {
    if (!mounted) return;
    try {
      final entries = await _api.getTimetableEntries().catchError((_) => <dynamic>[]);
      if (!mounted) return;
      setState(() => _entries = entries);
    } catch (_) {}
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

  void _showSnack(String msg, {bool isError = false, bool isWarning = false}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastNotification(
        message: msg,
        isError: isError,
        isWarning: isWarning,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  void _openForm({Map<String, dynamic>? entry}) {
    setState(() {
      _showForm = true;
      _formEntry = entry;
    });
  }

  void _closeForm() {
    setState(() {
      _showForm = false;
      _formEntry = null;
    });
  }

  Future<void> _saveForm(Map<String, dynamic> data) async {
    final locale = context.read<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isEdit = _formEntry != null;
    try {
      if (isEdit) {
        await _api.updateTimetableEntry(_formEntry!['id'] as int, data);
      } else {
        await _api.createTimetableEntry(data);
      }
      _closeForm();
      setState(() => _selectedEntry = null);
      await _reloadEntries();
      _showSnack(isEdit
          ? (t['timetable_updated'] ?? 'Entry updated!')
          : (t['timetable_created'] ?? 'Entry created!'));
    } catch (e) {
      _showSnack('${t['save_failed'] ?? 'Save failed'}: $e', isError: true);
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
      try {
        await _api.deleteTimetableEntry(_selectedEntry!['id'] as int);
        setState(() => _selectedEntry = null);
        await _reloadEntries();
        _showSnack(t['timetable_deleted'] ?? 'Entry deleted.');
      } catch (_) {
        _showSnack(t['delete_failed'] ?? 'Delete failed', isError: true);
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

    if (_showForm) {
      return _TimetableFormPanel(
        entry: _formEntry,
        classes: _classes,
        teachers: _teachers,
        subjects: _subjects,
        onCancel: _closeForm,
        onSave: _saveForm,
      );
    }

    return Container(
      color: surfaceBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolbar(t, isDark, isMobile, borderColor, bgColor, textColor, mutedColor),
          Expanded(
            child: _isLoading
                ? _TimetableSkeleton(isClassView: !isMobile && _isClassView)
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppConstants.pagePaddingDesktop, 12, AppConstants.pagePaddingDesktop, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final searchW = (constraints.maxWidth * 0.28).clamp(160.0, 400.0);
          final actionBtns = [
            const SizedBox(width: 8),
            _TblBtn(
              icon: Icons.add,
              label: t['add'] ?? 'Add',
              iconOnly: compact,
              onTap: () => _openForm(),
            ),
            const SizedBox(width: 6),
            _TblBtn(
              icon: Icons.edit_outlined,
              label: t['edit'] ?? 'Edit',
              iconOnly: compact,
              onTap: () {
                if (_selectedEntry == null) {
                  _showSnack(t['select_row_first'] ?? 'Please select an entry first',
                      isWarning: true);
                  return;
                }
                _openForm(entry: _selectedEntry);
              },
            ),
            const SizedBox(width: 6),
            _TblBtn(
              icon: Icons.delete_outline,
              label: t['delete'] ?? 'Delete',
              iconOnly: compact,
              onTap: () {
                if (_selectedEntry == null) {
                  _showSnack(t['select_row_first'] ?? 'Please select an entry first',
                      isWarning: true);
                  return;
                }
                _deleteSelected();
              },
            ),
          ];
          return Row(
            children: [
              SizedBox(width: searchW, child: searchBox),
              const SizedBox(width: 8),
              _ViewToggleButton(
                isClassView: _isClassView,
                onToggle: () => setState(() => _isClassView = !_isClassView),
              ),
              const Spacer(),
              ...actionBtns,
            ],
          );
        },
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


  // ── Weekly grid (desktop / tablet) ───────────────────────────────────────────

  Widget _buildWeeklyGrid(Map<String, String> t, bool isDark, Color bgColor,
      Color borderColor, Color surfaceBg, Color textColor, Color mutedColor) {
    const timeColW = 150.0;
    const minDayColW = 118.0;
    const rowH = 78.0;
    const breakH = 48.0;
    const headerH = 52.0;
    final headerBg = isDark ? const Color(0xFF1C2A4A) : AppColors.sidebarBg;
    final breakBg = isDark ? const Color(0xFF141E30) : const Color(0xFFF5F7FA);
    final weekendCellBg = isDark ? const Color(0xFF131D35) : const Color(0xFFF2F4FA);
    final todayName = _getTodayName();
    final now = DateTime.now();
    // Monday of the current week
    final weekMonday = now.subtract(Duration(days: now.weekday - 1));

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
            height: constraints.maxHeight,
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
              borderRadius: BorderRadius.circular(8),
              child: Column(
                children: [
                  // ── Sticky day-header row ─────────────────────────────
                  SizedBox(
                    height: headerH,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _weekHHeaderScroll,
                      physics: const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        width: gridW,
                        child: Row(
                          children: [
                            Container(
                              width: timeColW,
                              height: headerH,
                              color: headerBg,
                              child: Center(
                                child: Text(
                                  t['time_info'] ?? 'Time Info',
                                  style: AppTextStyles.body.copyWith(
                                      color: mutedColor,
                                      fontSize: 13,
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
                                dayName: _tDay(_kDays[i], t),
                                date: weekMonday.add(Duration(days: i)),
                                width: dayColW,
                                height: headerH,
                                isToday: _kDays[i] == todayName,
                                isWeekend: _kWeekendDays.contains(_kDays[i]),
                                isDark: isDark,
                                textColor: textColor,
                                mutedColor: mutedColor,
                                colBg: _kWeekendDays.contains(_kDays[i])
                                    ? weekendCellBg
                                    : headerBg,
                                t: t,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(height: 1, color: borderColor),

                  // ── Scrollable period rows ────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _weekHScroll,
                      child: SizedBox(
                        width: gridW,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            children: [
                              for (int ri = 0;
                                  ri < _kPeriods.length;
                                  ri++) ...[
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
                                  weekendCellBg: weekendCellBg,
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
                ],
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
    required DateTime date,
    required double width,
    required double height,
    required bool isToday,
    required bool isWeekend,
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
    required Color colBg,
    required Map<String, String> t,
  }) {
    const monthKeys = ['jan','feb','mar','apr','may','jun',
                       'jul','aug','sep','oct','nov','dec'];
    const monthsFallback = ['Jan','Feb','Mar','Apr','May','Jun',
                            'Jul','Aug','Sep','Oct','Nov','Dec'];
    final monthLabel = t[monthKeys[date.month - 1]] ?? monthsFallback[date.month - 1];
    final dateLabel = '$monthLabel ${date.day}';

    return Container(
      width: width,
      height: height,
      color: colBg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                dayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Text(
              dayName,
              style: AppTextStyles.body.copyWith(
                color: isWeekend ? mutedColor : textColor,
                fontSize: 13,
                fontWeight: isWeekend ? FontWeight.w500 : FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 3),
          Text(
            dateLabel,
            style: AppTextStyles.body.copyWith(
              color: isToday ? AppColors.primary : mutedColor,
              fontSize: 12,
              fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
              height: 1.2,
            ),
          ),
        ],
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
    required Color weekendCellBg,
  }) {
    final isBreak = period.period < 0;

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
                        fontSize: 12,
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
                      AppTextStyles.body.copyWith(color: mutedColor, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
            ],
            if (teacherName.isNotEmpty)
              Text(teacherName,
                  style:
                      AppTextStyles.body.copyWith(color: mutedColor, fontSize: 12),
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
    const minColW = 130.0;
    const fixedColW = 170.0;
    const rowH = 70.0;
    const headerH = 52.0;
    final headerBg = isDark ? const Color(0xFF1C2A4A) : AppColors.sidebarBg;
    final activePeriods = _kPeriods.where((p) => p.period > 0).toList();
    final classItems = _classes
        .where((c) => c['name']?.toString().isNotEmpty == true)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppConstants.pagePaddingDesktop, 4,
          AppConstants.pagePaddingDesktop, AppConstants.pagePaddingDesktop),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final rawColW =
              (constraints.maxWidth - fixedColW - 1 - activePeriods.length) /
                  activePeriods.length;
          final colW = rawColW.clamp(minColW, double.infinity);
          // Each period: colW wide + 1px right divider
          final periodColsWidth = activePeriods.length * (colW + 1);

          return Container(
            height: constraints.maxHeight,
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
              borderRadius: BorderRadius.circular(8),
              child: Column(
                children: [
                  // ── Sticky header row ─────────────────────────────────────
                  SizedBox(
                    height: headerH,
                    child: ColoredBox(
                      color: headerBg,
                      child: Row(
                        children: [
                          // Fixed "Class Info" cell
                          SizedBox(
                            width: fixedColW,
                            child: Center(
                              child: Text(
                                t['class_info'] ?? 'Class Info',
                                style: AppTextStyles.body.copyWith(
                                  color: mutedColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Container(
                              width: 1, height: headerH, color: borderColor),
                          // Period headers — driven by _classHHeaderScroll
                          // (synced to _classHScroll via listener)
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _classHHeaderScroll,
                              physics: const NeverScrollableScrollPhysics(),
                              child: SizedBox(
                                width: periodColsWidth,
                                child: Row(
                                  children: [
                                    for (final p in activePeriods) ...[
                                      SizedBox(
                                        width: colW,
                                        height: headerH,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 6),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                p.label,
                                                style: AppTextStyles.body
                                                    .copyWith(
                                                  color: textColor,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                p.time,
                                                style: AppTextStyles.body
                                                    .copyWith(
                                                  color: mutedColor,
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                          width: 1,
                                          height: headerH,
                                          color: borderColor),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(height: 1, color: borderColor),

                  // ── Body ─────────────────────────────────────────────────
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Fixed class info column — NeverScrollable, driven by _classVFixedScroll
                        // (synced to _classVScroll via listener)
                        SizedBox(
                          width: fixedColW,
                          child: SingleChildScrollView(
                            controller: _classVFixedScroll,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                if (classItems.isEmpty)
                                  const SizedBox(height: 120)
                                else
                                  for (int ri = 0;
                                      ri < classItems.length;
                                      ri++) ...[
                                    Container(
                                      height: rowH,
                                      width: fixedColW,
                                      clipBehavior: Clip.hardEdge,
                                      decoration:
                                          BoxDecoration(color: headerBg),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          child: _buildClassLabel(
                                              classItems[ri],
                                              textColor,
                                              mutedColor,
                                              isDark),
                                        ),
                                      ),
                                    ),
                                    if (ri < classItems.length - 1)
                                      Container(height: 1, color: borderColor),
                                  ],
                              ],
                            ),
                          ),
                        ),
                        Container(width: 1, color: borderColor),

                        // Scrollable period content
                        Expanded(
                          child: Scrollbar(
                            controller: _classHScroll,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _classHScroll,
                              child: SizedBox(
                                width: periodColsWidth,
                                child: SingleChildScrollView(
                                  controller: _classVScroll,
                                  child: Column(
                                    children: [
                                      if (classItems.isEmpty)
                                        SizedBox(
                                          height: 120,
                                          child: Center(
                                            child: Text(
                                              t['no_classes'] ?? 'No classes',
                                              style: AppTextStyles.body
                                                  .copyWith(color: mutedColor),
                                            ),
                                          ),
                                        )
                                      else
                                        for (int ri = 0;
                                            ri < classItems.length;
                                            ri++) ...[
                                          SizedBox(
                                            height: rowH,
                                            child: Row(
                                              children: [
                                                for (final p
                                                    in activePeriods) ...[
                                                  SizedBox(
                                                    width: colW,
                                                    child: _buildClassCell(
                                                      classItems[ri]['name']
                                                              ?.toString() ??
                                                          '',
                                                      p.period,
                                                      isDark,
                                                      bgColor,
                                                      textColor,
                                                      mutedColor,
                                                      t,
                                                    ),
                                                  ),
                                                  Container(
                                                      width: 1,
                                                      color: borderColor),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (ri < classItems.length - 1)
                                            Container(
                                                height: 1, color: borderColor),
                                        ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassLabel(dynamic cls, Color textColor, Color mutedColor, bool isDark) {
    final code = cls['code']?.toString() ?? '';
    final name = cls['name']?.toString() ?? '';
    final desc = cls['description']?.toString() ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.body.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (code.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  code,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            desc,
            style: AppTextStyles.body.copyWith(
              color: mutedColor,
              fontSize: 12,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildClassCell(String className, int period, bool isDark, Color bgColor,
      Color textColor, Color mutedColor, Map<String, String> t) {
    final entries = _classEntriesAt(className, period);
    if (entries.isEmpty) {
      return GestureDetector(
        onTap: () => setState(() => _selectedEntry = null),
        child: Container(color: Colors.transparent),
      );
    }

    final entry = entries.first as Map<String, dynamic>;
    final isSelected = _selectedEntry?['id'] == entry['id'];
    final color = _colorForSubject(entry['subjectId']);
    final subject = entry['subjectName']?.toString() ??
        entry['subjectCode']?.toString() ?? '';
    final teacher = entry['teacherName']?.toString() ?? '';
    final dayAbbr = _tDay(entry['day']?.toString() ?? '', t);

    return GestureDetector(
      onTap: () => setState(() =>
          _selectedEntry = isSelected ? null : Map<String, dynamic>.from(entry)),
      onDoubleTap: () {
        setState(() => _selectedEntry = Map<String, dynamic>.from(entry));
        _openForm(entry: Map<String, dynamic>.from(entry));
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
                    subject,
                    style: AppTextStyles.body.copyWith(
                        color: textColor,
                        fontSize: 12,
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
                            .copyWith(color: AppColors.error, fontSize: 10)),
                  ),
                ],
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    dayAbbr,
                    style: AppTextStyles.caption.copyWith(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (teacher.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(teacher,
                  style: AppTextStyles.body
                      .copyWith(color: mutedColor, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
            ],
          ],
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
              child: Text(_tDay(day, t),
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
  final VoidCallback? onTap;

  const _TblBtn({
    required this.icon,
    required this.label,
    this.iconOnly = false,
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
        onPressed: onTap,
        style: style,
        child: Icon(icon, size: 18),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
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

// ── Add / Edit form panel (full-page, matches student form style) ──────────────

class _TimetableFormPanel extends StatefulWidget {
  final Map<String, dynamic>? entry;
  final List<dynamic> classes;
  final List<dynamic> teachers;
  final List<dynamic> subjects;
  final VoidCallback onCancel;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _TimetableFormPanel({
    this.entry,
    required this.classes,
    required this.teachers,
    required this.subjects,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<_TimetableFormPanel> createState() => _TimetableFormPanelState();
}

class _TimetableFormPanelState extends State<_TimetableFormPanel> {
  String? _day;
  int? _period;
  int? _classId;
  int? _subjectId;
  int? _teacherId;
  final _roomCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  bool _saving = false;
  bool _backHovering = false;
  bool _dayError = false;
  bool _periodError = false;
  bool _classError = false;
  bool _subjectError = false;

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

  Future<void> _save() async {
    final dayEmpty = _day == null;
    final periodEmpty = _period == null;
    final classEmpty = _classId == null;
    final subjectEmpty = _subjectId == null;
    if (dayEmpty || periodEmpty || classEmpty || subjectEmpty) {
      setState(() {
        _dayError = dayEmpty;
        _periodError = periodEmpty;
        _classError = classEmpty;
        _subjectError = subjectEmpty;
      });
      return;
    }
    setState(() {
      _saving = true;
      _dayError = false;
      _periodError = false;
      _classError = false;
      _subjectError = false;
    });
    try {
      await widget.onSave({
        'day': _day,
        'period': _period,
        'classId': _classId,
        'subjectId': _subjectId,
        'teacherId': _teacherId,
        'room': _roomCtrl.text.trim(),
        'academicYear': _yearCtrl.text.trim(),
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDec(String hint, {bool isDark = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(
          color: isDark ? Colors.white70 : AppColors.textMuted),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _requiredLabeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(
              text: label,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary)),
          TextSpan(
              text: ' *',
              style: AppTextStyles.body.copyWith(color: AppColors.error)),
        ])),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark ? const Color(0xFF16213E) : AppColors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final isEdit = widget.entry != null;

    // ── Dropdown helper (matches _StyledDropdown visual) ──────────────
    Widget drop<T>({
      required T? value,
      required String hint,
      required List<T> items,
      required List<String> labels,
      required ValueChanged<T?> onChanged,
      bool hasError = false,
    }) {
      return _TimetableDropdown<T>(
        value: value,
        hint: hint,
        items: items,
        labels: labels,
        isDark: isDark,
        hasError: hasError,
        onChanged: onChanged,
      );
    }

    final periodItems = _kPeriods.where((p) => p.period > 0).toList();

    return Container(
      color: surfaceBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: Row(children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _backHovering = true),
                onExit: (_) => setState(() => _backHovering = false),
                child: GestureDetector(
                  onTap: widget.onCancel,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _backHovering
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_back_rounded,
                          size: 22, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit
                    ? (t['edit_timetable'] ?? 'Edit Entry')
                    : (t['add_timetable'] ?? 'Add Entry'),
                style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check, size: 18),
                label: Text(t['save'] ?? 'Save'),
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
              ),
            ]),
          ),

          // ── Form body ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row: Day + Period
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _requiredLabeled(
                                '${t['day'] ?? 'Day'}:',
                                drop<String>(
                                  value: _day,
                                  hint: t['select_day'] ?? 'Select Day',
                                  items: _kDays,
                                  labels: _kDays.map((d) => _tDay(d, t)).toList(),
                                  hasError: _dayError,
                                  onChanged: (v) => setState(() {
                                    _day = v;
                                    _dayError = false;
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _requiredLabeled(
                                '${t['period'] ?? 'Period'}:',
                                drop<int>(
                                  value: _period,
                                  hint: t['select_period'] ??
                                      'Select Period',
                                  items: periodItems
                                      .map((p) => p.period)
                                      .toList(),
                                  labels: periodItems
                                      .map((p) => '${p.label}  ${p.time}')
                                      .toList(),
                                  hasError: _periodError,
                                  onChanged: (v) => setState(() {
                                    _period = v;
                                    _periodError = false;
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Class (full width)
                        _requiredLabeled(
                          '${t['select_class'] ?? 'Class'}:',
                          drop<int>(
                            value: _classId,
                            hint: t['select_class'] ?? 'Select Class',
                            items: widget.classes
                                .map((c) => c['id'] as int)
                                .toList(),
                            labels: widget.classes
                                .map((c) => c['name']?.toString() ?? '')
                                .toList(),
                            hasError: _classError,
                            onChanged: (v) => setState(() {
                              _classId = v;
                              _classError = false;
                            }),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Row: Subject + Teacher
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _requiredLabeled(
                                '${t['subject'] ?? 'Subject'}:',
                                drop<int>(
                                  value: _subjectId,
                                  hint: t['subject'] ?? 'Select Subject',
                                  items: widget.subjects
                                      .map((s) => s['id'] as int)
                                      .toList(),
                                  labels: widget.subjects
                                      .map((s) =>
                                          '${s['code'] ?? ''} — ${s['name'] ?? ''}')
                                      .toList(),
                                  hasError: _subjectError,
                                  onChanged: (v) => setState(() {
                                    _subjectId = v;
                                    _subjectError = false;
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _labeled(
                                '${t['teachers'] ?? 'Teacher'}:',
                                drop<int>(
                                  value: _teacherId,
                                  hint: t['select_teacher'] ??
                                      'Select Teacher',
                                  items: [
                                    -1,
                                    ...widget.teachers
                                        .map((tc) => tc['id'] as int)
                                  ],
                                  labels: [
                                    t['none'] ?? 'None',
                                    ...widget.teachers.map((tc) {
                                      final name =
                                          '${tc['firstName'] ?? tc['first_name'] ?? ''} ${tc['lastName'] ?? tc['last_name'] ?? ''}'
                                              .trim();
                                      return name.isEmpty
                                          ? (tc['name']?.toString() ?? '')
                                          : name;
                                    }),
                                  ],
                                  onChanged: (v) => setState(() =>
                                      _teacherId = (v == -1) ? null : v),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row: Room + Academic Year
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _labeled(
                                '${t['room'] ?? 'Room'}:',
                                SizedBox(
                                  height: 44,
                                  child: TextField(
                                    controller: _roomCtrl,
                                    style: AppTextStyles.body
                                        .copyWith(color: textColor),
                                    decoration: _inputDec(
                                        t['room_hint'] ?? 'e.g. Room 101',
                                        isDark: isDark),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _labeled(
                                '${t['academic_year'] ?? 'Academic Year'}:',
                                SizedBox(
                                  height: 44,
                                  child: TextField(
                                    controller: _yearCtrl,
                                    style: AppTextStyles.body
                                        .copyWith(color: textColor),
                                    decoration: _inputDec('2024–2025',
                                        isDark: isDark),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dropdown widget matching _StyledDropdown visual ────────────────────────────

class _TimetableDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final List<String> labels;
  final bool isDark;
  final bool hasError;
  final ValueChanged<T?> onChanged;

  const _TimetableDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.labels,
    required this.isDark,
    required this.onChanged,
    this.hasError = false,
  });

  void _open(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A3A5A) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    const activeColor = AppColors.primary;

    final renderBox = context.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final rect = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset(0, renderBox.size.height),
            ancestor: overlay),
        renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final buttonWidth = renderBox.size.width;

    showMenu<int>(
      context: context,
      position: rect,
      elevation: 4,
      color: bgColor,
      constraints:
          BoxConstraints(minWidth: buttonWidth, maxWidth: buttonWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor),
      ),
      items: items.asMap().entries.map((e) {
        final isSelected = e.value == value;
        return PopupMenuItem<int>(
          value: e.key,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Row(children: [
            Expanded(
              child: Text(labels[e.key],
                  style: AppTextStyles.body.copyWith(
                    color: isSelected ? activeColor : textColor,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  )),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, size: 15, color: activeColor),
          ]),
        );
      }).toList(),
    ).then((idx) {
      if (idx != null) onChanged(items[idx]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.error
        : isDark
            ? const Color(0xFF2A3A5A)
            : AppColors.border;
    final bgColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white38 : AppColors.textMuted;
    final iconColor = isDark ? Colors.white70 : AppColors.textSecondary;

    final idx = value != null ? items.indexOf(value as T) : -1;
    final display = idx >= 0 ? labels[idx] : null;

    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: hasError ? 1.5 : 1),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              display ?? hint,
              style: AppTextStyles.body.copyWith(
                  color: display != null ? textColor : mutedColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: iconColor),
        ]),
      ),
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
      ..._kDays.map((d) => _chip(_tDay(d, t), d, dayVal, (v) => _day = v)),
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

// ── Timetable skeleton loader ─────────────────────────────────────────────────

class _TimetableSkeleton extends StatefulWidget {
  const _TimetableSkeleton({this.isClassView = false});
  final bool isClassView;
  @override
  State<_TimetableSkeleton> createState() => _TimetableSkeletonState();
}

class _TimetableSkeletonState extends State<_TimetableSkeleton>
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
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    final base = isDark ? const Color(0xFF1C2A4A) : const Color(0xFFE8EBF2);
    final shimmer = isDark ? const Color(0xFF2A3D60) : const Color(0xFFF5F6FA);
    final bgColor = isDark ? const Color(0xFF1C2A4A) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF2A3A5A) : AppColors.border;
    final headerBg = isDark ? const Color(0xFF162035) : AppColors.sidebarBg;
    final weekendBg =
        isDark ? const Color(0xFF131D35) : const Color(0xFFF2F4FA);

    Widget block({double? w, double h = 14, double r = 6}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
              color: base, borderRadius: BorderRadius.circular(r)),
        );

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final progress = _ctrl.value;
        Shader shader(Rect bounds) => LinearGradient(
              begin: Alignment(-3.0 + progress * 6.0, 0),
              end: Alignment(-1.0 + progress * 6.0, 0),
              colors: [base, shimmer, base],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: shader,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppConstants.pagePaddingDesktop,
                4,
                AppConstants.pagePaddingDesktop,
                AppConstants.pagePaddingDesktop),
            child: isMobile
                ? _buildMobileSkeleton(block, bgColor, borderColor)
                : widget.isClassView
                    ? _buildClassSkeleton(block, base, bgColor, borderColor, headerBg)
                    : _buildGridSkeleton(block, base, bgColor, borderColor,
                        headerBg, weekendBg),
          ),
        );
      },
    );
  }

  Widget _buildGridSkeleton(
    Widget Function({double? w, double h, double r}) block,
    Color base,
    Color bgColor,
    Color borderColor,
    Color headerBg,
    Color weekendBg,
  ) {
    const timeColW = 150.0;
    const headerH = 52.0;
    const rowH = 78.0;
    const breakH = 48.0;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final dayColW =
              ((constraints.maxWidth - timeColW - _kDays.length) / _kDays.length)
                  .clamp(100.0, double.infinity);

          return Column(
            children: [
              // Header row
              SizedBox(
                height: headerH,
                child: Row(
                  children: [
                    Container(
                      width: timeColW,
                      height: headerH,
                      color: headerBg,
                      child: Center(child: block(w: 64, h: 12)),
                    ),
                    for (int i = 0; i < _kDays.length; i++) ...[
                      Container(
                          width: 1, height: headerH, color: borderColor),
                      Container(
                        width: dayColW,
                        height: headerH,
                        color: _kWeekendDays.contains(_kDays[i])
                            ? weekendBg
                            : headerBg,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            block(w: 52, h: 12),
                            const SizedBox(height: 5),
                            block(w: 38, h: 10),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(height: 1, color: borderColor),
              // Period rows
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      for (int ri = 0; ri < _kPeriods.length; ri++) ...[
                        if (ri > 0) Container(height: 1, color: borderColor),
                        SizedBox(
                          height: _kPeriods[ri].period < 0 ? breakH : rowH,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Time column
                              Container(
                                width: timeColW,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: _kPeriods[ri].period < 0
                                      ? [block(w: 56, h: 12)]
                                      : [
                                          block(w: 30, h: 14),
                                          const SizedBox(height: 5),
                                          block(w: 90, h: 11),
                                        ],
                                ),
                              ),
                              // Day cells
                              for (int di = 0; di < _kDays.length; di++) ...[
                                Container(width: 1, color: borderColor),
                                Container(
                                  width: dayColW,
                                  color: _kWeekendDays.contains(_kDays[di])
                                      ? weekendBg.withValues(alpha: 0.5)
                                      : null,
                                  child: _kPeriods[ri].period > 0
                                      ? Container(
                                          margin: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: base.withValues(alpha: 0.45),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border:
                                                Border.all(color: base),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                          color: base,
                                                          shape:
                                                              BoxShape.circle)),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                      child: block(h: 12)),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              block(
                                                  w: dayColW * 0.55, h: 10),
                                              const SizedBox(height: 3),
                                              block(
                                                  w: dayColW * 0.42, h: 10),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClassSkeleton(
    Widget Function({double? w, double h, double r}) block,
    Color base,
    Color bgColor,
    Color borderColor,
    Color headerBg,
  ) {
    const fixedColW = 170.0;
    const headerH = 52.0;
    const rowH = 70.0;
    const numClasses = 5;
    final activePeriods = _kPeriods.where((p) => p.period > 0).toList();

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final colW = ((constraints.maxWidth - fixedColW - 1 - activePeriods.length) /
                  activePeriods.length)
              .clamp(100.0, double.infinity);

          return Column(
            children: [
              // ── Header row ──────────────────────────────────────────
              SizedBox(
                height: headerH,
                child: Row(
                  children: [
                    // "Class Info" label column
                    Container(
                      width: fixedColW,
                      height: headerH,
                      color: headerBg,
                      child: Center(child: block(w: 72, h: 12)),
                    ),
                    Container(width: 1, height: headerH, color: borderColor),
                    // Period header columns
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: activePeriods.length * (colW + 1),
                          child: Row(
                            children: [
                              for (final _ in activePeriods) ...[
                                Container(
                                  width: colW,
                                  height: headerH,
                                  color: headerBg,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      block(w: 32, h: 13),
                                      const SizedBox(height: 5),
                                      block(w: 72, h: 10),
                                    ],
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: headerH,
                                    color: borderColor),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: borderColor),
              // ── Body ────────────────────────────────────────────────
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Fixed class name column
                    SizedBox(
                      width: fixedColW,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            for (int ri = 0; ri < numClasses; ri++) ...[
                              Container(
                                height: rowH,
                                width: fixedColW,
                                color: headerBg,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    block(w: 100, h: 13),
                                    const SizedBox(height: 6),
                                    block(w: 68, h: 11),
                                  ],
                                ),
                              ),
                              if (ri < numClasses - 1)
                                Container(height: 1, color: borderColor),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, color: borderColor),
                    // Period cells
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: activePeriods.length * (colW + 1),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                for (int ri = 0; ri < numClasses; ri++) ...[
                                  SizedBox(
                                    height: rowH,
                                    child: Row(
                                      children: [
                                        for (int ci = 0;
                                            ci < activePeriods.length;
                                            ci++) ...[
                                          SizedBox(
                                            width: colW,
                                            height: rowH,
                                            child: Container(
                                              margin: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: base.withValues(
                                                    alpha: 0.45),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(color: base),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 6),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                          width: 6,
                                                          height: 6,
                                                          decoration: BoxDecoration(
                                                              color: base,
                                                              shape: BoxShape
                                                                  .circle)),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                          child: block(h: 12)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  block(
                                                      w: colW * 0.55, h: 10),
                                                  const SizedBox(height: 3),
                                                  block(
                                                      w: colW * 0.42, h: 10),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Container(
                                              width: 1,
                                              height: rowH,
                                              color: borderColor),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (ri < numClasses - 1)
                                    Container(height: 1, color: borderColor),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileSkeleton(
    Widget Function({double? w, double h, double r}) block,
    Color bgColor,
    Color borderColor,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(w: 160, h: 14),
                  const SizedBox(height: 8),
                  block(w: 120, h: 12),
                  const SizedBox(height: 8),
                  Row(children: [
                    block(w: 58, h: 20, r: 10),
                    const SizedBox(width: 8),
                    block(w: 50, h: 20, r: 10),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 12),
            block(w: 40, h: 40, r: 8),
          ],
        ),
      ),
    );
  }
}

// ── Toast notification (matches students screen) ──────────────────────────────

class _ToastNotification extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isWarning;
  final VoidCallback onDismiss;

  const _ToastNotification({
    required this.message,
    required this.isError,
    required this.onDismiss,
    this.isWarning = false,
  });

  @override
  State<_ToastNotification> createState() => _ToastNotificationState();
}

class _ToastNotificationState extends State<_ToastNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.isError
        ? AppColors.error
        : widget.isWarning
            ? const Color(0xFFF59E0B)
            : AppColors.primary;
    final icon = widget.isError
        ? Icons.close
        : widget.isWarning
            ? Icons.warning_amber_rounded
            : Icons.check;
    final title = widget.isError
        ? (t['error'] ?? 'Error')
        : widget.isWarning
            ? (t['warning'] ?? 'Warning')
            : (t['success'] ?? 'Success');
    final bgColor = isDark ? const Color(0xFF1C2A4A) : AppColors.white;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final msgColor = isDark ? Colors.white60 : AppColors.textSecondary;
    final closeColor = isDark ? Colors.white54 : AppColors.textSecondary;

    return Positioned(
      top: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: color),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: AppTextStyles.heading3
                                  .copyWith(color: titleColor)),
                          const SizedBox(height: 2),
                          Text(widget.message,
                              style: AppTextStyles.body
                                  .copyWith(color: msgColor)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Icon(Icons.close, size: 20, color: closeColor),
                    ),
                  ]),
                ),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (_, __) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 1.0 - _progress.value,
                      child: Container(height: 4, color: color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
