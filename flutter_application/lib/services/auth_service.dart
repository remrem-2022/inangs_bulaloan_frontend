import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  static UserModel? _currentUser;

  static UserModel? get currentUser => _currentUser;

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await ApiService.post(
      ApiConfig.login,
      {
        'username': username,
        'password': password,
      },
      includeAuth: false,
    );

    if (response['success'] == true) {
      final token = response['token'] as String;
      final userData = response['user'] as Map<String, dynamic>;

      await _saveToken(token);
      await _saveUser(userData);

      ApiService.setToken(token);
      _currentUser = UserModel.fromJson(userData);
    }

    return response;
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String storeName,
    required String storeAddress,
    String? contactNumber,
  }) async {
    final response = await ApiService.post(
      ApiConfig.register,
      {
        'username': username,
        'password': password,
        'storeName': storeName,
        'storeAddress': storeAddress,
        if (contactNumber != null) 'contactNumber': contactNumber,
      },
      includeAuth: false,
    );

    if (response['success'] == true) {
      final token = response['token'] as String;
      final userData = response['user'] as Map<String, dynamic>;

      await _saveToken(token);
      await _saveUser(userData);

      ApiService.setToken(token);
      _currentUser = UserModel.fromJson(userData);
    }

    return response;
  }

  static Future<bool> loadSavedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);

      if (token != null && userJson != null) {
        // Check if token is expired
        if (JwtDecoder.isExpired(token)) {
          await logout();
          return false;
        }

        ApiService.setToken(token);
        _currentUser = UserModel.fromJson(Map<String, dynamic>.from(
          const {},
        ));

        return true;
      }
    } catch (e) {
      // Error loading saved auth
    }

    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    ApiService.setToken(null);
    _currentUser = null;
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> _saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userData.toString());
  }

  static bool get isLoggedIn => _currentUser != null;
}
