// lib/screens/class_subject_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/services/api_service.dart';
import 'package:schoolms_portal/utils/app_constants.dart';
import 'package:schoolms_portal/widgets/table_widgets.dart';

class ClassSubjectScreen extends StatefulWidget {
  const ClassSubjectScreen({super.key});

  @override
  State<ClassSubjectScreen> createState() => _ClassSubjectScreenState();
}

class _ClassSubjectScreenState extends State<ClassSubjectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t['classes'] ?? 'Class & Subject',
              style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle:
                AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: t['classes'] ?? 'Classes'),
              Tab(text: t['subjects'] ?? 'Subjects'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _GenericCrudList(
                  endpoint: 'classes',
                  label: t['class_name'] ?? 'Class',
                  fields: ['name', 'description'],
                  badgeColor: const Color(0xFF3A6B35),
                ),
                _GenericCrudList(
                  endpoint: 'subjects',
                  label: t['subject_name'] ?? 'Subject',
                  fields: ['name', 'code', 'description'],
                  badgeColor: const Color(0xFF1565C0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generic CRUD list ─────────────────────────────────────────────────────────
class _GenericCrudList extends StatefulWidget {
  final String endpoint;
  final String label;
  final List<String> fields;
  final Color badgeColor;

  const _GenericCrudList({
    required this.endpoint,
    required this.label,
    required this.fields,
    required this.badgeColor,
  });

  @override
  State<_GenericCrudList> createState() => _GenericCrudListState();
}

class _GenericCrudListState extends State<_GenericCrudList> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await _api.get('/${widget.endpoint}');
      setState(() {
        _items = (d as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final name = item[widget.fields[0]]?.toString() ?? 'item';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete $name?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _api.delete('/${widget.endpoint}/${item['id']}');
        _showSnack('${widget.label} deleted');
        _load();
      } catch (_) {
        _showSnack('Delete failed', isError: true);
      }
    }
  }

  void _openForm({Map<String, dynamic>? item}) {
    showDialog(
      context: context,
      builder: (_) => _GenericFormDialog(
        item: item,
        label: widget.label,
        fields: widget.fields,
        onSave: (data) async {
          try {
            if (item == null) {
              await _api.post('/${widget.endpoint}', data);
              _showSnack('${widget.label} created!');
            } else {
              await _api.put('/${widget.endpoint}/${item['id']}',
                  {...data, 'id': item['id']});
              _showSnack('${widget.label} updated!');
            }
            _load();
          } catch (_) {
            _showSnack('Save failed', isError: true);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        // Table header + add button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppConstants.cardRadius)),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            ...widget.fields.map((f) =>
                Expanded(flex: 2, child: TableHeader(label: f, flex: 1))),
            Expanded(flex: 1, child: TableHeader(label: 'Actions', flex: 1)),
            ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 16),
              label: Text('Add ${widget.label}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7)),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ]),
        ),

        // Body
        if (_loading)
          const Expanded(
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)))
        else if (_items.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No ${widget.label.toLowerCase()}s yet',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: AppColors.border.withOpacity(0.5)))),
                  child: Row(children: [
                    ...widget.fields.asMap().entries.map((e) {
                      final idx = e.key;
                      final field = e.value;
                      final value = item[field]?.toString() ?? '—';
                      return Expanded(
                        flex: 2,
                        child: idx == 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: widget.badgeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  value,
                                  style: AppTextStyles.caption.copyWith(
                                    color: widget.badgeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : Text(value, style: AppTextStyles.bodySmall),
                      );
                    }),
                    Expanded(
                      flex: 1,
                      child: Row(children: [
                        ActionBtn(
                            icon: Icons.edit_outlined,
                            color: AppColors.primary,
                            onTap: () => _openForm(item: item)),
                        const SizedBox(width: 4),
                        ActionBtn(
                            icon: Icons.delete_outline,
                            color: AppColors.error,
                            onTap: () => _delete(item)),
                      ]),
                    ),
                  ]),
                );
              },
            ),
          ),
      ]),
    );
  }
}

// ── Generic Form Dialog ───────────────────────────────────────────────────────
class _GenericFormDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final String label;
  final List<String> fields;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _GenericFormDialog({
    this.item,
    required this.label,
    required this.fields,
    required this.onSave,
  });

  @override
  State<_GenericFormDialog> createState() => _GenericFormDialogState();
}

class _GenericFormDialogState extends State<_GenericFormDialog> {
  late final Map<String, TextEditingController> _ctrls;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final f in widget.fields)
        f: TextEditingController(text: widget.item?[f]?.toString() ?? '')
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget
        .onSave({for (final f in widget.fields) f: _ctrls[f]!.text.trim()});
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(
                widget.item == null
                    ? 'Add ${widget.label}'
                    : 'Edit ${widget.label}',
                style: AppTextStyles.heading3,
              ),
              const Spacer(),
              InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      size: 20, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 20),
            ...widget.fields.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FormFieldInput(
                      label: f, controller: _ctrls[f]!, hint: 'Enter $f'),
                )),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
