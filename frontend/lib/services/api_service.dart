// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:schoolms_portal/utils/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _base = AppConstants.apiBase;
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Auth token support ──────────────────────────────────────────
  void setToken(String token) => _headers['Authorization'] = 'Bearer $token';
  void clearToken() => _headers.remove('Authorization');

  // ── Generic request ─────────────────────────────────────────────
  Future<dynamic> _request(String method, String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_base$path');
    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: _headers)
              .timeout(const Duration(seconds: 15));
          break;
        case 'POST':
          response = await http
              .post(uri, headers: _headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: _headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: _headers)
              .timeout(const Duration(seconds: 15));
          break;
        default:
          throw ApiException('Unknown method');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }

    if (response.statusCode == 204 || response.body.isEmpty) return null;
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Server error (${response.statusCode})',
          statusCode: response.statusCode);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    // ASP.NET Core returns ProblemDetails with 'title' and 'errors'
    final errors = decoded['errors'] as Map<String, dynamic>?;
    final detail = errors?.entries
        .map((e) => '${e.key}: ${(e.value as List).first}')
        .join(', ');
    throw ApiException(
        detail ?? decoded['message'] ?? decoded['title'] ?? 'Request failed',
        statusCode: response.statusCode);
  }

  Future<dynamic> get(String path) => _request('GET', path);
  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);
  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _request('PUT', path, body: body);
  Future<dynamic> delete(String path) => _request('DELETE', path);

  // ── Auth ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final result =
        await post('/auth/login', {'email': email, 'password': password});
    return result as Map<String, dynamic>;
  }

  // ── Students ─────────────────────────────────────────────────────
  Future<List<dynamic>> getStudents() async => (await get('/students')) as List;
  Future<Map<String, dynamic>> getStudent(int id) async =>
      (await get('/students/$id')) as Map<String, dynamic>;
  Future<dynamic> createStudent(Map<String, dynamic> data) =>
      post('/students', data);
  Future<dynamic> updateStudent(int id, Map<String, dynamic> data) =>
      put('/students/$id', {...data, 'id': id});
  Future<void> deleteStudent(int id) async => await delete('/students/$id');

  // ── Teachers ─────────────────────────────────────────────────────
  Future<List<dynamic>> getTeachers() async => (await get('/teachers')) as List;
  Future<dynamic> createTeacher(Map<String, dynamic> data) =>
      post('/teachers', data);
  Future<dynamic> updateTeacher(int id, Map<String, dynamic> data) =>
      put('/teachers/$id', {...data, 'id': id});
  Future<void> deleteTeacher(int id) async => await delete('/teachers/$id');

  // ── Classes ──────────────────────────────────────────────────────
  Future<List<dynamic>> getClasses() async => (await get('/classes')) as List;
  Future<dynamic> createClass(Map<String, dynamic> data) =>
      post('/classes', data);
  Future<dynamic> updateClass(int id, Map<String, dynamic> data) =>
      put('/classes/$id', {...data, 'id': id});
  Future<void> deleteClass(int id) async => await delete('/classes/$id');

  // ── Subjects ─────────────────────────────────────────────────────
  Future<List<dynamic>> getSubjects() async => (await get('/subjects')) as List;
  Future<dynamic> createSubject(Map<String, dynamic> data) =>
      post('/subjects', data);
  Future<dynamic> updateSubject(int id, Map<String, dynamic> data) =>
      put('/subjects/$id', {...data, 'id': id});
  Future<void> deleteSubject(int id) async => await delete('/subjects/$id');

  // ── Users ────────────────────────────────────────────────────────
  Future<List<dynamic>> getUsers() async => (await get('/users')) as List;
  Future<dynamic> createUser(Map<String, dynamic> data) => post('/users', data);
  Future<dynamic> updateUser(int id, Map<String, dynamic> data) =>
      put('/users/$id', {...data, 'id': id});
  Future<void> deleteUser(int id) async => await delete('/users/$id');

  // ── Roles ────────────────────────────────────────────────────────
  Future<List<dynamic>> getRoles() async => (await get('/roles')) as List;
  Future<dynamic> createRole(Map<String, dynamic> data) => post('/roles', data);
  Future<dynamic> updateRole(int id, Map<String, dynamic> data) =>
      put('/roles/$id', {...data, 'id': id});
  Future<void> deleteRole(int id) async => await delete('/roles/$id');

  // ── Photo upload ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> uploadUserPhoto(int userId, html.File file) async {
    final completer = Completer<Map<String, dynamic>>();
    final formData = html.FormData();
    formData.appendBlob('file', file, file.name);

    final request = html.HttpRequest();
    request.open('POST', '$_base/users/$userId/photo');
    if (_headers.containsKey('Authorization')) {
      request.setRequestHeader('Authorization', _headers['Authorization']!);
    }

    request.onLoad.listen((_) {
      final status = request.status ?? 0;
      final body = request.responseText ?? '';
      if (status >= 200 && status < 300) {
        try {
          completer.complete(jsonDecode(body) as Map<String, dynamic>);
        } catch (_) {
          completer.completeError(ApiException('Invalid server response'));
        }
      } else {
        String message;
        try {
          final decoded = jsonDecode(body) as Map<String, dynamic>;
          message = decoded['message'] as String?
              ?? decoded['title'] as String?
              ?? 'Upload failed (HTTP $status)';
        } catch (_) {
          message = 'Upload failed (HTTP $status)';
        }
        completer.completeError(ApiException(message, statusCode: status));
      }
    });

    request.onError.listen((_) =>
        completer.completeError(ApiException('Network error: upload failed')));

    request.send(formData);
    return completer.future;
  }

  Future<Map<String, dynamic>> uploadStudentPhoto(int studentId, html.File file) async {
    final completer = Completer<Map<String, dynamic>>();
    final formData = html.FormData();
    formData.appendBlob('file', file, file.name);

    final request = html.HttpRequest();
    request.open('POST', '$_base/students/$studentId/photo');
    if (_headers.containsKey('Authorization')) {
      request.setRequestHeader('Authorization', _headers['Authorization']!);
    }

    request.onLoad.listen((_) {
      final status = request.status ?? 0;
      final body = request.responseText ?? '';
      if (status >= 200 && status < 300) {
        try {
          completer.complete(jsonDecode(body) as Map<String, dynamic>);
        } catch (_) {
          completer.completeError(ApiException('Invalid server response'));
        }
      } else {
        String message;
        try {
          final decoded = jsonDecode(body) as Map<String, dynamic>;
          message = decoded['message'] as String?
              ?? decoded['title'] as String?
              ?? 'Upload failed (HTTP $status)';
        } catch (_) {
          message = 'Upload failed (HTTP $status)';
        }
        completer.completeError(ApiException(message, statusCode: status));
      }
    });

    request.onError.listen((_) =>
        completer.completeError(ApiException('Network error: upload failed')));

    request.send(formData);
    return completer.future;
  }

  // ── Dashboard Stats ───────────────────────────────────────────────
  Future<Map<String, int>> getDashboardStats() async {
    final results = await Future.wait([
      getStudents().then((l) => l.length).catchError((_) => 0),
      getTeachers().then((l) => l.length).catchError((_) => 0),
      getClasses().then((l) => l.length).catchError((_) => 0),
    ]);
    return {
      'students': results[0],
      'teachers': results[1],
      'classes': results[2],
    };
  }
}
