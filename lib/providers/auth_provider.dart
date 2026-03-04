import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?['role'] == 'admin';

  Future<bool> tryAutoLogin() async {
    final token = await _api.getToken();
    if (token == null) return false;
    try {
      _user = await _api.getMe();
      notifyListeners();
      return true;
    } catch (_) {
      await _api.deleteToken();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.login(email, password);
      await _api.saveToken(res['token']);
      _user = res['user'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
      String name, String email, String password, String department) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.register(name, email, password, department);
      await _api.saveToken(res['token']);
      _user = res['user'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.deleteToken();
    _user = null;
    notifyListeners();
  }

  void updateUser(Map<String, dynamic> updated) {
    _user = {...?_user, ...updated};
    notifyListeners();
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('401')) return 'Credenziali non valide';
      if (msg.contains('409')) return 'Email già registrata';
      if (msg.contains('400')) return 'Dati non validi';
    }
    return 'Errore di connessione';
  }
}
