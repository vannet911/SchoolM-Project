// lib/providers/locale_provider.dart
import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  String _locale = 'en';

  String get locale => _locale;

  void setLocale(String locale) {
    if (_locale != locale) {
      _locale = locale;
      notifyListeners();
    }
  }

  void toggleLocale() {
    _locale = _locale == 'en' ? 'km' : 'en';
    notifyListeners();
  }
}

// Translation strings
class AppTranslations {
  static const Map<String, Map<String, String>> translations = {
    'en': {
      // Common
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'filter': 'Filter',
      'actions': 'Actions',
      'loading': 'Loading...',
      'no_data': 'No data available',
      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',
      'of': 'of',
      'show': 'Show',
      'other': 'Other',
      'confirm_delete': 'Confirm Delete',
      'select_row_first': 'Please select a row first',
      'failed_load': 'Failed to load',
      'success': 'Success',
      'error': 'Error',

      // Messages
      'student_created': 'Student created!',
      'student_updated': 'Student updated!',
      'student_deleted': 'Student deleted',
      'teacher_created': 'Teacher created!',
      'teacher_updated': 'Teacher updated!',
      'teacher_deleted': 'Teacher deleted',
      'delete_failed': 'Delete failed',
      'save_failed': 'Save failed',

      // Login
      'email': 'Email',
      'password': 'Password',
      'login': 'Login',
      'forgot_password': 'Forgot Password?',
      'email_required': 'Email is required',
      'password_required': 'Password is required',
      'email_not_found': 'Email is incorrect',
      'wrong_password': 'Password is incorrect',

      // Navigation
      'dashboard': 'Dashboard',
      'students': 'Students',
      'teachers': 'Teachers',
      'classes': 'Classes',
      'class & subject': 'Class & Subject',
      'subjects': 'Subjects',
      'users': 'Users',
      'roles': 'Roles',
      'logout': 'Logout',
      'settings': 'Settings',
      'reports': 'Reports',
      'profile': 'Profile',

      // Dashboard
      'welcome': 'Welcome',
      'good_morning': 'Good Morning',
      'good_afternoon': 'Good Afternoon',
      'good_evening': 'Good Evening',
      'welcome_back': 'Welcome back to School Management Portal.',
      'students_by_gender': 'Students by Gender',
      'students_by_class': 'Students per Class',
      'school_overview': 'School Overview',
      'total_students': 'Total Students',
      'total_teachers': 'Total Teachers',
      'total_classes': 'Total Classes',
      'total_subjects': 'Total Subjects',
      'subject_information': 'Subject Information',
      'notifications_about_subject': 'Notifications about subject Info',
      'data_this_month': 'Data this month',
      'chart_coming_soon': 'Chart / Data coming soon',
      'learn_today': 'Learn Today!',

      // Students
      'student_list': 'Student List',
      'add_student': 'Add Student',
      'edit_student': 'Edit Student',
      'code': 'Code',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'student_name': 'Full Name',
      'gender': 'Gender',
      'date_of_birth': 'Date of Birth',
      'phone': 'Phone',
      'address': 'Address',
      'male': 'Male',
      'female': 'Female',

      // Teachers
      'teacher_list': 'Teacher List',
      'add_teacher': 'Add Teacher',
      'edit_teacher': 'Edit Teacher',
      'full_name': 'Full Name',
      'subject': 'Subject',
      'qualification': 'Qualification',

      // Classes
      'class_list': 'Class List',
      'add_class': 'Add Class',
      'edit_class': 'Edit Class',
      'class_name': 'Class Name',
      'grade_level': 'Grade Level',
      'academic_year': 'Academic Year',
      'description': 'Description',
      'class_teacher': 'Class Teacher',
      'teacher_name': 'Teacher Name',

      // Subjects
      'subject_list': 'Subject List',
      'add_subject': 'Add Subject',
      'edit_subject': 'Edit Subject',
      'subject_name': 'Subject Name',
      'subject_code': 'Subject Code',
      'credit_hours': 'Credit Hours',

      // Users
      'user_list': 'User List',
      'add_user': 'Add User',
      'edit_user': 'Edit User',
      'username': 'Username',
      'user_name': 'Full Name',
      'role': 'Role',
      'status': 'Status',
      'active': 'Active',
      'inactive': 'Inactive',

      // Profile
      'back': 'Back',
      'profile_information': 'Profile Information',
      'display_name': 'Display Name',
      'enter_display_name': 'Enter display name',
      'save_profile': 'Save Profile',
      'change_password': 'Change Password',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_new_password': 'Confirm New Password',
      'passwords_not_match': 'Passwords do not match',
      'profile_updated': 'Profile updated!',
      'cannot_connect_server': 'Cannot connect to server',
      'password_changed': 'Password changed!',
      'current_password_incorrect': 'Current password is incorrect',
      'failed_change_password': 'Failed to change password',

      // App
      'version': 'Version',
      'app_name': 'KOMPONG PHNOM',
      'app_subtitle': 'School Management System',
      'developer': '@vannet.developer',
    },
    'km': {
      // Common
      'save': 'រក្សាទុក',
      'cancel': 'បោះបង់',
      'delete': 'លុប',
      'edit': 'កែប្រែ',
      'add': 'បន្ថែម',
      'search': 'ស្វែងរក',
      'filter': 'តម្រង',
      'actions': 'សកម្មភាព',
      'loading': 'កំពុងផ្ទុក...',
      'no_data': 'គ្មានទិន្ន័យ',
      'confirm': 'បញ្ជាក់',
      'yes': 'បាទ/ចាស',
      'no': 'ទេ',
      'of': 'នៃ',
      'show': 'បង្ហាញ',
      'other': 'ផ្សេងទៀត',
      'confirm_delete': 'បញ្ជាក់ការលុប',
      'select_row_first': 'សូមជ្រើសរើសជួរមុន',
      'failed_load': 'បរាជ័យក្នុងការផ្ទុក',
      'success': 'ជោគជ័យ',
      'error': 'កំហុស',

      // Messages
      'student_created': 'បន្ថែមសិស្សបានជោគជ័យ!',
      'student_updated': 'កែប្រែសិស្សបានជោគជ័យ!',
      'student_deleted': 'លុបសិស្សបានជោគជ័យ',
      'teacher_created': 'បន្ថែមគ្រូបានជោគជ័យ!',
      'teacher_updated': 'កែប្រែគ្រូបានជោគជ័យ!',
      'teacher_deleted': 'លុបគ្រូបានជោគជ័យ',
      'delete_failed': 'លុបមិនបានជោគជ័យ',
      'save_failed': 'រក្សាទុកមិនបានជោគជ័យ',

      // Login
      'email': 'អ៊ីមែល',
      'password': 'ពាក្យសម្ងាត់',
      'login': 'ចូល',
      'forgot_password': 'ភ្លេចពាក្យសម្ងាត់?',
      'email_required': 'ត្រូវបំពេញអ៊ីមែល',
      'password_required': 'ត្រូវបំពេញពាក្យសម្ងាត់',
      'email_not_found': 'រកមិនឃើញអ៊ីមែល',
      'wrong_password': 'ពាក្យសម្ងាត់មិនត្រឹមត្រូវ',

      // Navigation
      'dashboard': 'ផ្ទាំងគ្រប់គ្រង',
      'students': 'សិស្ស',
      'teachers': 'គ្រូបង្រៀន',
      'class & subject': 'ថ្នាក់ & មុខវិជ្ជា',
      'classes': 'ថ្នាក់',
      'subjects': 'មុខវិជ្ជា',
      'users': 'អ្នកប្រើប្រាស់',
      'roles': 'តួនាទី',
      'logout': 'ចេញ',
      'settings': 'ការកំណត់',
      'reports': 'របាយការណ៍',
      'profile': 'ប្រវត្តិ',
      // Dashboard
      'welcome': 'សូមស្វាគមន៍',
      'good_morning': 'អរុណសួស្តី',
      'good_afternoon': 'ទិវាសួស្តី',
      'good_evening': 'សាយណ្ហសួស្តី',
      'welcome_back': 'សូមស្វាគមន៍មកកាន់ប្រព័ន្ធគ្រប់គ្រងសាលា!',
      'students_by_gender': 'សិស្សតាមភេទ',
      'students_by_class': 'សិស្សតាមថ្នាក់',
      'school_overview': 'ទិដ្ឋភាពរួមសាលា',
      'total_students': 'ចំនួនសិស្ស',
      'total_teachers': 'ចំនួនគ្រូ',
      'total_classes': 'ចំនួនថ្នាក់',
      'total_subjects': 'ចំនួនមុខវិជ្ជា',
      'subject_information': 'ព័ត៌មានមុខវិជ្ជា',
      'notifications_about_subject': 'ការជូនដំណឹងអំពីមុខវិជ្ជា',
      'data_this_month': 'ទិន្ន័យខែនេះ',
      'chart_coming_soon': 'តារាង / ទិន្ន័យនឹងមកដល់',
      'learn_today': 'រៀនថ្ងៃនេះ!',

      // Students
      'student_list': 'បញ្ជីសិស្ស',
      'add_student': 'បន្ថែមសិស្ស',
      'edit_student': 'កែប្រែសិស្ស',
      'code': 'កូដ',
      'first_name': 'នាមខ្លួន',
      'last_name': 'នាមត្រកូល',
      'student_name': 'ឈ្មោះសិស្ស',
      'gender': 'ភេទ',
      'date_of_birth': 'ថ្ងៃខែឆ្នាំកំណើត',
      'phone': 'លេខទូរស័ព្ទ',
      'address': 'អាស័យដ្ឋាន',
      'male': 'ប្រុស',
      'female': 'ស្រី',

      // Teachers
      'teacher_list': 'បញ្ជីគ្រូ',
      'add_teacher': 'បន្ថែមគ្រូ',
      'edit_teacher': 'កែប្រែគ្រូ',
      'full_name': 'ឈ្មោះពេញ',
      'subject': 'មុខវិជ្ជា',
      'qualification': 'សញ្ញាបត្រ',

      // Classes
      'class_list': 'បញ្ជីថ្នាក់',
      'add_class': 'បន្ថែមថ្នាក់',
      'edit_class': 'កែប្រែថ្នាក់',
      'class_name': 'ឈ្មោះថ្នាក់',
      'grade_level': 'កម្រិតថ្នាក់',
      'academic_year': 'ឆ្នាំសិក្សា',
      'description': 'ការពិពណ៌នា',
      'class_teacher': 'គ្រូប្រចាំថ្នាក់',
      'teacher_name': 'ឈ្មោះគ្រូ',

      // Subjects
      'subject_list': 'បញ្ជីមុខវិជ្ជា',
      'add_subject': 'បន្ថែមមុខវិជ្ជា',
      'edit_subject': 'កែប្រែមុខវិជ្ជា',
      'subject_name': 'ឈ្មោះមុខវិជ្ជា',
      'subject_code': 'កូដមុខវិជ្ជា',
      'credit_hours': 'ម៉ោងកredit',

      // Users
      'user_list': 'បញ្ជីអ្នកប្រើប្រាស់',
      'add_user': 'បន្ថែមអ្នកប្រើប្រាស់',
      'edit_user': 'កែប្រែអ្នកប្រើប្រាស់',
      'username': 'ឈ្មោះអ្នកប្រើ',
      'user_name': 'ឈ្មោះពេញ',
      'role': 'តួនាទី',
      'status': 'ស្ថានភាព',
      'active': 'សកម្ម',
      'inactive': 'មិនសកម្ម',

      // Profile
      'back': 'ត្រឡប់',
      'profile_information': 'ព័ត៌មានប្រវត្តិ',
      'display_name': 'ឈ្មោះបង្ហាញ',
      'enter_display_name': 'បញ្ចូលឈ្មោះបង្ហាញ',
      'save_profile': 'រក្សាប្រវត្តិ',
      'change_password': 'ប្តូរពាក្យសម្ងាត់',
      'current_password': 'ពាក្យសម្ងាត់បច្ចុប្បន្ន',
      'new_password': 'ពាក្យសម្ងាត់ថ្មី',
      'confirm_new_password': 'បញ្ជាក់ពាក្យសម្ងាត់ថ្មី',
      'passwords_not_match': 'ពាក្យសម្ងាត់មិនត្រូវគ្នា',
      'profile_updated': 'ប្រវត្តិបានអាប់ដេត!',
      'cannot_connect_server': 'មិនអាចភ្ជាប់ម៉ាស៊ីនបម្រើ',
      'password_changed': 'ពាក្យសម្ងាត់បានប្តូរ!',
      'current_password_incorrect': 'ពាក្យសម្ងាត់បច្ចុប្បន្នមិនត្រឹមត្រូវ',
      'failed_change_password': 'ការប្តូរពាក្យសម្ងាត់បរាជ័យ',

      // App
      'version': 'បច្ចុប្បន្នភាព',
      'app_name': 'កំពង់ភ្នំ',
      'app_subtitle': 'ប្រព័ន្ធគ្រប់គ្រងសាលា',
      'developer': '@វ៉ាន់នេត.អ្នកអភិវឌ្ឍន៍',
    },
  };

  static String translate(String key, {String? locale}) {
    final currentLocale = locale ?? 'en';
    return translations[currentLocale]?[key] ?? translations['en']?[key] ?? key;
  }

  static String get(String key, String locale) {
    return translations[locale]?[key] ?? translations['en']?[key] ?? key;
  }
}
