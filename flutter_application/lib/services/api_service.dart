import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static String? getToken() {
    return _token;
  }

  static Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  static Future<Map<String, dynamic>> get(
    String url, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: includeAuth),
      );

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: includeAuth),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: includeAuth),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> delete(
    String url, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: includeAuth),
      );

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to parse response: ${e.toString()}',
      };
    }
  }
}
