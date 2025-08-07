import 'package:flutter/material.dart';
import '../../data/models/movie_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = MockAuthRepository();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await _authRepository.getCurrentUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await _authRepository.login(email, password);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      } else {
        _error = 'Credenciales inválidas. Intenta con test@netflix.com / 123456';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión. Verifica tu internet.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authRepository.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cerrar sesión';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}