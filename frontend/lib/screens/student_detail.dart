// // lib/screens/student_detail.dart
// import 'package:flutter/material.dart';
// import 'package:schoolms_portal/services/api_service.dart';
// import 'package:schoolms_portal/utils/app_constants.dart';

// class StudentDetailScreen extends StatefulWidget {
//   final Map<String, dynamic> student;
//   const StudentDetailScreen({super.key, required this.student});

//   @override
//   State<StudentDetailScreen> createState() => _StudentDetailScreenState();
// }

// class _StudentDetailScreenState extends State<StudentDetailScreen> {
//   final ApiService _api = ApiService();
//   Map<String, dynamic>? _student;
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadStudent();
//   }

//   Future<void> _loadStudent() async {
//     setState(() => _loading = true);
//     try {
//       final studentId = widget.student['id'];
//       if (studentId == null) {
//         setState(() => _loading = false);
//         if (mounted) Navigator.pop(context);
//         return;
//       }
//       final data = await _api.getStudent(studentId);
//       if (mounted) setState(() { _student = data; _loading = false; });
//     } catch (_) {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _confirmDelete() async {
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: Text(
//             'Delete ${_student?['firstName']} ${_student?['lastName']}?'),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.error,
//                 foregroundColor: Colors.white),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//     if (ok == true && mounted) {
//       try {
//         await _api.deleteStudent(_student!['id']);
//         if (mounted) Navigator.pop(context, {'action': 'deleted'});
//       } catch (_) {}
//     }
//   }

//   static String _fmtDate(dynamic v) {
//     if (v == null) return '—';
//     final s = v.toString();
//     return s.length >= 10 ? s.substring(0, 10).replaceAll('-', '/') : s;
//   }

//   // ── field helpers ──────────────────────────────────────────────────────────

//   Widget _field(String label, String? value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: AppTextStyles.bodySmall.copyWith(
//             color: AppColors.textSecondary)),
//         const SizedBox(height: 6),
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           decoration: BoxDecoration(
//             color: AppColors.white,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: AppColors.border),
//           ),
//           child: Text(value?.isNotEmpty == true ? value! : '—',
//               style: AppTextStyles.body),
//         ),
//       ],
//     );
//   }

//   Widget _dropdownField(String label, String? value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: AppTextStyles.bodySmall.copyWith(
//             color: AppColors.textSecondary)),
//         const SizedBox(height: 6),
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           decoration: BoxDecoration(
//             color: AppColors.white,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: AppColors.border),
//           ),
//           child: Row(children: [
//             Expanded(
//                 child: Text(value?.isNotEmpty == true ? value! : '—',
//                     style: AppTextStyles.body)),
//             const Icon(Icons.keyboard_arrow_down,
//                 size: 18, color: AppColors.textSecondary),
//           ]),
//         ),
//       ],
//     );
//   }

//   Widget _dateField(String label, dynamic value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: AppTextStyles.bodySmall.copyWith(
//             color: AppColors.textSecondary)),
//         const SizedBox(height: 6),
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           decoration: BoxDecoration(
//             color: AppColors.white,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: AppColors.border),
//           ),
//           child: Row(children: [
//             Expanded(child: Text(_fmtDate(value), style: AppTextStyles.body)),
//             const Icon(Icons.calendar_today_outlined,
//                 size: 16, color: AppColors.textSecondary),
//           ]),
//         ),
//       ],
//     );
//   }

//   Widget _addressField(String label, String? value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: AppTextStyles.bodySmall.copyWith(
//             color: AppColors.textSecondary)),
//         const SizedBox(height: 6),
//         Container(
//           width: double.infinity,
//           height: 148,
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           decoration: BoxDecoration(
//             color: AppColors.white,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: AppColors.border),
//           ),
//           child: Text(value?.isNotEmpty == true ? value! : '—',
//               style: AppTextStyles.body),
//         ),
//       ],
//     );
//   }

//   // ── build ──────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         backgroundColor: AppColors.background,
//         body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
//       );
//     }

//     if (_student == null) {
//       return Scaffold(
//         backgroundColor: AppColors.background,
//         body: Center(
//           child: Column(mainAxisSize: MainAxisSize.min, children: [
//             const Icon(Icons.error_outline, size: 48, color: AppColors.error),
//             const SizedBox(height: 12),
//             const Text('Error loading student details',
//                 style: AppTextStyles.body),
//             const SizedBox(height: 16),
//             TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Go Back')),
//           ]),
//         ),
//       );
//     }

//     final s = _student!;
//     final name =
//         '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ── header ────────────────────────────────────────────────
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//               child: Row(children: [
//                 InkWell(
//                   onTap: () => Navigator.pop(context),
//                   borderRadius: BorderRadius.circular(6),
//                   child: const Icon(Icons.chevron_left,
//                       size: 24, color: AppColors.textSecondary),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   s['code']?.toString() ?? 'ST000',
//                   style: AppTextStyles.body.copyWith(
//                     color: AppColors.primary,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const Spacer(),
//                 OutlinedButton.icon(
//                   onPressed: () => Navigator.pop(
//                       context, {'action': 'edit', 'student': s}),
//                   icon: const Icon(Icons.person_outline, size: 16),
//                   label: const Text('Update'),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: AppColors.textPrimary,
//                     side: const BorderSide(color: AppColors.border),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 14, vertical: 10),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 OutlinedButton.icon(
//                   onPressed: _confirmDelete,
//                   icon: const Icon(Icons.delete_outline, size: 16),
//                   label: const Text('Delete'),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: AppColors.textPrimary,
//                     side: const BorderSide(color: AppColors.border),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 14, vertical: 10),
//                   ),
//                 ),
//               ]),
//             ),

//             // ── content ───────────────────────────────────────────────
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 20, vertical: 8),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Left column
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(children: [
//                             Expanded(
//                                 child: _field('Code:',
//                                     s['code']?.toString())),
//                             const SizedBox(width: 12),
//                             Expanded(
//                                 child: _dropdownField('Gender:',
//                                     s['gender']?.toString())),
//                           ]),
//                           const SizedBox(height: 16),
//                           _field('Full Name:', name.isEmpty ? null : name),
//                           const SizedBox(height: 16),
//                           _dateField('Date of Birth:', s['dateOfBirth']),
//                           const SizedBox(height: 16),
//                           _dateField('Created Date:',
//                               s['createDate'] ?? s['createdAt']),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     // Right column
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           _field('Email:', s['email']?.toString()),
//                           const SizedBox(height: 16),
//                           _field('Phone:', s['phoneNumber']?.toString()),
//                           const SizedBox(height: 16),
//                           _addressField('Address:', s['address']?.toString()),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
