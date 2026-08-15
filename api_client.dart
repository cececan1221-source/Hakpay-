import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../core/result.dart';

/// HTTP + Bearer token istemcisi.
/// Sadece HAKPAY_API_BASE doluysa kullanılır.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _tokenKey = 'hakpay_auth_token';

  String get _base => AppConfig.apiBase.replaceAll(RegExp(r'/$'), '');

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> setToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        h['Authorization'] = 'Bearer $token';
      }
    }
    return h;
  }

  Future<Result<Map<String, dynamic>>> get(String path) async {
    try {
      final res = await _client.get(
        Uri.parse('$_base$path'),
        headers: await _headers(),
      );
      return _parse(res);
    } catch (e) {
      return Err('Ağ hatası: $e');
    }
  }

  Future<Result<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final res = await _client.post(
        Uri.parse('$_base$path'),
        headers: await _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      );
      return _parse(res);
    } catch (e) {
      return Err('Ağ hatası: $e');
    }
  }

  Future<Result<Map<String, dynamic>>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await _client.patch(
        Uri.parse('$_base$path'),
        headers: await _headers(),
        body: body == null ? null : jsonEncode(body),
      );
      return _parse(res);
    } catch (e) {
      return Err('Ağ hatası: $e');
    }
  }

  Result<Map<String, dynamic>> _parse(http.Response res) {
    Map<String, dynamic> data = {};
    try {
      if (res.body.isNotEmpty) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      }
    } catch (_) {}

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Ok(data);
    }
    final msg = data['message']?.toString() ??
        data['error']?.toString() ??
        'HTTP ${res.statusCode}';
    return Err(msg);
  }

  void dispose() => _client.close();
}
