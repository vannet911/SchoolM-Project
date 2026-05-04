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

    final name =
        '${_student!['firstName'] ?? ''} ${_student!['lastName'] ?? ''}'.trim();
    final c = _avatarColor(name);

    return Scaffold(
      appBar: AppBar(
        title: Text(t['student_detail'] ?? 'Student Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _openEditForm(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: c.withOpacity(0.15),
                    child: Text(
                      _initials(_student!['firstName'], _student!['lastName']),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: c,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? '—' : name,
                          style: AppTextStyles.heading2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${_student!['id']}',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _student!['email'] ?? '—',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Details Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DetailCard(
                    title: t['personal_info'] ?? 'Personal Information',
                    children: [
                      _DetailRow(
                        label: t['first_name'] ?? 'First Name',
                        value: _student!['firstName'] ?? '—',
                      ),
                      _DetailRow(
                        label: t['last_name'] ?? 'Last Name',
                        value: _student!['lastName'] ?? '—',
                      ),
                      _DetailRow(
                        label: t['email'] ?? 'Email',
                        value: _student!['email'] ?? '—',
                      ),
                      _DetailRow(
                        label: t['date_of_birth'] ?? 'Date of Birth',
                        value: _student!['dateOfBirth'] != null
                            ? (_student!['dateOfBirth'] as String)
                                .substring(0, 10)
                            : '—',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _DetailCard(
                    title: t['academic_info'] ?? 'Academic Information',
                    children: [
                      _DetailRow(
                        label: t['enrollment_date'] ?? 'Enrollment Date',
                        value: _student!['enrollmentDate'] != null
                            ? (_student!['enrollmentDate'] as String)
                                .substring(0, 10)
                            : '—',
                      ),
                      _DetailRow(
                        label: t['student_status'] ?? 'Status',
                        value:
                            'Active', // You can add status field to your model
                      ),
                      _DetailRow(
                        label: t['grade_level'] ?? 'Grade Level',
                        value: '—', // You can add grade field to your model
                      ),
                      _DetailRow(
                        label: t['gpa'] ?? 'GPA',
                        value: '—', // You can add GPA field to your model
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Additional Information Card
            _DetailCard(
              title: t['additional_info'] ?? 'Additional Information',
              children: [
                _DetailRow(
                  label: t['created_at'] ?? 'Created At',
                  value: _student!['createdAt'] != null
                      ? (_student!['createdAt'] as String).substring(0, 10)
                      : '—',
                ),
                _DetailRow(
                  label: t['updated_at'] ?? 'Updated At',
                  value: _student!['updatedAt'] != null
                      ? (_student!['updatedAt'] as String).substring(0, 10)
                      : '—',
                ),
              ],
            ),
          ],
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
