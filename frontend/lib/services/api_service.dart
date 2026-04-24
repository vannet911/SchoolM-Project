// lib/services/api_service.dart
import 'dart:convert';
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
  String? _token;
  void setToken(String token) {
    _token = token;
    _headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _token = null;
    _headers.remove('Authorization');
  }

  // ── Generic request ─────────────────────────────────────────────
  Future<dynamic> _request(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_base$path');
    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
          break;
        case 'POST':
          response = await http.post(uri, headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await http.put(uri, headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: _headers).timeout(const Duration(seconds: 15));
          break;
        default:
          throw ApiException('Unknown method');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }

    if (response.statusCode == 204 || response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    throw ApiException(decoded['message'] ?? 'Request failed', statusCode: response.statusCode);
  }

  Future<dynamic> get(String path) => _request('GET', path);
  Future<dynamic> post(String path, Map<String, dynamic> body) => _request('POST', path, body: body);
  Future<dynamic> put(String path, Map<String, dynamic> body) => _request('PUT', path, body: body);
  Future<dynamic> delete(String path) => _request('DELETE', path);

  // ── Auth ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await post('/auth/login', {'email': email, 'password': password});
    return result as Map<String, dynamic>;
  }

  // ── Students ─────────────────────────────────────────────────────
  Future<List<dynamic>> getStudents() async => (await get('/students')) as List;
  Future<Map<String, dynamic>> getStudent(int id) async => (await get('/students/$id')) as Map<String, dynamic>;
  Future<dynamic> createStudent(Map<String, dynamic> data) => post('/students', data);
  Future<dynamic> updateStudent(int id, Map<String, dynamic> data) => put('/students/$id', {...data, 'id': id});
  Future<void> deleteStudent(int id) async => await delete('/students/$id');

  // ── Teachers ─────────────────────────────────────────────────────
  Future<List<dynamic>> getTeachers() async => (await get('/teachers')) as List;
  Future<dynamic> createTeacher(Map<String, dynamic> data) => post('/teachers', data);
  Future<dynamic> updateTeacher(int id, Map<String, dynamic> data) => put('/teachers/$id', {...data, 'id': id});
  Future<void> deleteTeacher(int id) async => await delete('/teachers/$id');

  // ── Classes ──────────────────────────────────────────────────────
  Future<List<dynamic>> getClasses() async => (await get('/classes')) as List;
  Future<dynamic> createClass(Map<String, dynamic> data) => post('/classes', data);
  Future<dynamic> updateClass(int id, Map<String, dynamic> data) => put('/classes/$id', {...data, 'id': id});
  Future<void> deleteClass(int id) async => await delete('/classes/$id');

  // ── Subjects ─────────────────────────────────────────────────────
  Future<List<dynamic>> getSubjects() async => (await get('/subjects')) as List;
  Future<dynamic> createSubject(Map<String, dynamic> data) => post('/subjects', data);
  Future<dynamic> updateSubject(int id, Map<String, dynamic> data) => put('/subjects/$id', {...data, 'id': id});
  Future<void> deleteSubject(int id) async => await delete('/subjects/$id');

  // ── Users ────────────────────────────────────────────────────────
  Future<List<dynamic>> getUsers() async => (await get('/users')) as List;
  Future<dynamic> createUser(Map<String, dynamic> data) => post('/users', data);
  Future<dynamic> updateUser(int id, Map<String, dynamic> data) => put('/users/$id', {...data, 'id': id});
  Future<void> deleteUser(int id) async => await delete('/users/$id');

  // ── Roles ────────────────────────────────────────────────────────
  Future<List<dynamic>> getRoles() async => (await get('/roles')) as List;
  Future<dynamic> createRole(Map<String, dynamic> data) => post('/roles', data);
  Future<dynamic> updateRole(int id, Map<String, dynamic> data) => put('/roles/$id', {...data, 'id': id});
  Future<void> deleteRole(int id) async => await delete('/roles/$id');

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
