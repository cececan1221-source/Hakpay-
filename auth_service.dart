import '../config/app_config.dart';
import '../core/result.dart';
import 'api_client.dart';

class UserSession {
  final String userId;
  final String email;
  final String displayName;
  final String? token;

  const UserSession({
    required this.userId,
    required this.email,
    required this.displayName,
    this.token,
  });

  factory UserSession.fromJson(Map<String, dynamic> j) => UserSession(
        userId: j['user_id']?.toString() ?? j['id']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        displayName: j['display_name']?.toString() ??
            j['name']?.toString() ??
            'Kullanıcı',
        token: j['token']?.toString(),
      );
}

/// Auth sınırı. Demo modda yerel sahte oturum.
abstract class AuthService {
  Future<Result<UserSession>> login(String email, String password);
  Future<Result<UserSession>> register(String email, String password, String name);
  Future<Result<UserSession?>> currentSession();
  Future<void> logout();
}

class DemoAuthService implements AuthService {
  UserSession? _session;

  @override
  Future<Result<UserSession>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (email.isEmpty || password.length < 4) {
      return const Err('E-posta veya şifre hatalı');
    }
    _session = UserSession(
      userId: 'demo_${email.hashCode.abs()}',
      email: email,
      displayName: email.split('@').first,
      token: 'demo_token',
    );
    return Ok(_session!);
  }

  @override
  Future<Result<UserSession>> register(
      String email, String password, String name) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (email.isEmpty || password.length < 6) {
      return const Err('Geçersiz kayıt bilgisi');
    }
    _session = UserSession(
      userId: 'demo_${email.hashCode.abs()}',
      email: email,
      displayName: name.isEmpty ? email.split('@').first : name,
      token: 'demo_token',
    );
    return Ok(_session!);
  }

  @override
  Future<Result<UserSession?>> currentSession() async => Ok(_session);

  @override
  Future<void> logout() async => _session = null;
}

class RemoteAuthService implements AuthService {
  RemoteAuthService(this._api);
  final ApiClient _api;

  @override
  Future<Result<UserSession>> login(String email, String password) async {
    final res = await _api.post(
      '/v1/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
    return res.when(
      ok: (data) async {
        final session = UserSession.fromJson(data);
        if (session.token != null) await _api.setToken(session.token);
        return Ok(session);
      },
      err: (m) => Err(m),
    );
  }

  @override
  Future<Result<UserSession>> register(
      String email, String password, String name) async {
    final res = await _api.post(
      '/v1/auth/register',
      body: {'email': email, 'password': password, 'name': name},
      auth: false,
    );
    return res.when(
      ok: (data) async {
        final session = UserSession.fromJson(data);
        if (session.token != null) await _api.setToken(session.token);
        return Ok(session);
      },
      err: (m) => Err(m),
    );
  }

  @override
  Future<Result<UserSession?>> currentSession() async {
    final token = await _api.getToken();
    if (token == null) return const Ok(null);
    final res = await _api.get('/v1/auth/me');
    return res.when(
      ok: (data) => Ok(UserSession.fromJson(data)),
      err: (_) async {
        await _api.setToken(null);
        return const Ok(null);
      },
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _api.post('/v1/auth/logout');
    } catch (_) {}
    await _api.setToken(null);
  }
}

AuthService createAuthService(ApiClient? api) {
  if (AppConfig.isRemote && api != null) return RemoteAuthService(api);
  return DemoAuthService();
}
