// lib/screens/student_detail.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schoolms_portal/providers/locale_provider.dart';
import 'package:schoolms_portal/services/api_service.dart';
import 'package:schoolms_portal/utils/app_constants.dart';

class StudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _student;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getStudent(widget.student['id']);
      setState(() {
        _student = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Failed to load student details', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  String _initials(String? first, String? last) {
    final f = (first ?? '').isNotEmpty ? first![0].toUpperCase() : '';
    final l = (last ?? '').isNotEmpty ? last![0].toUpperCase() : '';
    return '$f$l'.isEmpty ? '?' : '$f$l';
  }

  static const List<Color> _avatarColors = [
    Color(0xFF3A6B35),
    Color(0xFF1565C0),
    Color(0xFFC62828),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFF00695C),
  ];
  Color _avatarColor(String name) =>
      _avatarColors[name.hashCode.abs() % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final t = AppTranslations.translations[locale]!;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t['student_detail'] ?? 'Student Details'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_student == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t['student_detail'] ?? 'Student Details'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              SizedBox(height: 12),
              Text('Error loading student details', style: AppTextStyles.body),
            ],
          ),
        ),
      );
    }

    final student = _student!;
    final name =
        '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'.trim();
    final c = _avatarColor(name);

    String formatDate(dynamic value) {
      if (value == null) return '—';
      final text = value is String ? value : value.toString();
      return text.length >= 10 ? text.substring(0, 10) : text;
    }

    String formatStatus(dynamic value) {
      if (value == null) return 'Inactive';
      if (value is bool) return value ? 'Active' : 'Inactive';
      return value.toString();
    }

    Widget field(String label, String value, {int maxLines = 1}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              value,
              style: AppTextStyles.body,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.arrow_back, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(student['code'] ?? 'ST000',
                      style: AppTextStyles.heading2.copyWith(
                          fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Update'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: c.withOpacity(0.18),
                          child: Text(
                            _initials(
                                student['firstName'], student['lastName']),
                            style: TextStyle(
                              color: c,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name.isEmpty ? '—' : name,
                                  style: AppTextStyles.heading3
                                      .copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text('ID: ${student['id']}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(student['email'] ?? '—',
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            formatStatus(student['status']),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              field('Code', student['code'] ?? '—'),
                              const SizedBox(height: 18),
                              field('Full Name', name.isEmpty ? '—' : name),
                              const SizedBox(height: 18),
                              field('Date of Birth',
                                  formatDate(student['dateOfBirth'])),
                              const SizedBox(height: 18),
                              field(
                                  'Created Date',
                                  formatDate(student['createDate'] ??
                                      student['createdAt'])),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: [
                              field('Gender', student['gender'] ?? '—'),
                              const SizedBox(height: 18),
                              field('Email', student['email'] ?? '—'),
                              const SizedBox(height: 18),
                              field('Phone', student['phoneNumber'] ?? '—'),
                              const SizedBox(height: 18),
                              field('Address', student['address'] ?? '—',
                                  maxLines: 5),
                            ],
                          ),
                        ),
                      ],
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

  void _openEditForm() {
    // Navigate back to students screen with edit mode
    Navigator.pop(context, {'action': 'edit', 'student': _student});
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
