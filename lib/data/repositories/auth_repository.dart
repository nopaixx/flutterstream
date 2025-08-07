import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie_model.dart';

abstract class AuthRepository {
  Future<UserModel?> login(String email, String password);
  Future<bool> logout();
  Future<UserModel?> getCurrentUser();
  Future<bool> saveUser(UserModel user);
}

class MockAuthRepository implements AuthRepository {
  static const String _userKey = 'current_user';

  // Usuarios mock para testing
  static final List<Map<String, String>> _mockUsers = [
    {
      'email': 'test@netflix.com',
      'password': '123456',
      'name': 'Usuario Test',
      'id': '1',
    },
    {
      'email': 'demo@netflix.com',
      'password': 'demo123',
      'name': 'Usuario Demo',
      'id': '2',
    },
  ];

  @override
  Future<UserModel?> login(String email, String password) async {
    // Simular delay de red
    await Future.delayed(Duration(seconds: 1));

    // Buscar usuario en la lista mock
    final userData = _mockUsers.firstWhere(
          (user) => user['email'] == email && user['password'] == password,
      orElse: () => {},
    );

    if (userData.isEmpty) {
      return null; // Credenciales inválidas
    }

    final user = UserModel(
      id: userData['id']!,
      email: userData['email']!,
      name: userData['name']!,
      profileImageUrl: 'https://via.placeholder.com/150',
    );

    // Guardar usuario en SharedPreferences
    await saveUser(user);

    return user;
  }

  @override
  Future<bool> logout() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_userKey);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    }

    return null;
  }

  @override
  Future<bool> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    return await prefs.setString(_userKey, userJson);
  }
}