import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

class ApiService {
  static String get baseUrl {
    // Emulatore Android usa 10.0.2.2
    // Dispositivo fisico e iOS usano l'IP del PC
    const localIp = '192.168.1.7'; // <-- metti qui il tuo IP
    if (const bool.fromEnvironment('dart.vm.product')) {
      return 'http://$localIp:3001/api';
    }
    try {
      if (Platform.isAndroid) return 'http://$localIp:3001/api';
      if (Platform.isIOS) return 'http://$localIp:3001/api';
    } catch (_) {}
    return 'http://localhost:3001/api';
  }

  static const _storage = FlutterSecureStorage();
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'bs_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  // AUTH
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio
        .post('/auth/login', data: {'email': email, 'password': password});
    return res.data;
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password, String department) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'department': department
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data;
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  // RESOURCES
  Future<List<dynamic>> getResources() async {
    final res = await _dio.get('/resources');
    return res.data;
  }

  // BOOKINGS
  Future<List<dynamic>> getBookings(
      {bool upcoming = false, bool my = false}) async {
    final params = <String, dynamic>{};
    if (upcoming) params['upcoming'] = 'true';
    if (my) params['my'] = 'true';
    final res = await _dio.get('/bookings', queryParameters: params);
    return res.data;
  }

  Future<List<dynamic>> getCalendarBookings(String start, String end) async {
    final res = await _dio.get('/bookings/calendar',
        queryParameters: {'start': start, 'end': end});
    return res.data;
  }

  Future<Map<String, dynamic>> createBooking({
    required String resourceId,
    required String title,
    required String startTime,
    required String endTime,
    String? notes,
    bool recurring = false,
    int weeks = 1,
  }) async {
    final res = await _dio.post('/bookings', data: {
      'resource_id': resourceId,
      'title': title,
      'start_time': startTime,
      'end_time': endTime,
      if (notes != null) 'notes': notes,
      'recurring': recurring,
      'weeks': weeks,
    });
    return res.data;
  }

  Future<void> cancelBooking(String id) async {
    await _dio.delete('/bookings/$id');
  }

  // USERS
  Future<List<dynamic>> getUsers() async {
    final res = await _dio.get('/users');
    return res.data;
  }

  Future<Map<String, dynamic>> updateProfile(
      String name, String department) async {
    final res = await _dio
        .put('/users/me', data: {'name': name, 'department': department});
    return res.data;
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    await _dio.put('/users/me/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _dio.put('/users/$userId/role', data: {'role': role});
  }

  // LOGS
  Future<List<dynamic>> getLogs() async {
    final res = await _dio.get('/logs');
    return res.data;
  }

  // TOKEN
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'bs_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'bs_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'bs_token');
  }

  Future<void> toggleResource(String id, bool activate) async {
    await _dio.put('/resources/$id', data: {'is_active': activate});
  }
}
