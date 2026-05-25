import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../theme/constants.dart';

class ApiService {
  late final Dio _dio;
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();
  static final ApiService instance = ApiService._();

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await _prefs;
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          clearToken();
        }
        handler.next(error);
      },
    ));
  }

  Future<void> saveToken(AuthToken token) async {
    final prefs = await _prefs;
    await prefs.setString('access_token', token.accessToken);
    await prefs.setString('user_id', token.userId);
    await prefs.setString('user_name', token.name);
    await prefs.setString('user_plan', token.plan ?? '');
  }

  Future<void> clearToken() async {
    final prefs = await _prefs;
    await prefs.remove('access_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_plan');
  }

  Future<String?> get savedName async => (await _prefs).getString('user_name');
  Future<String?> get savedPlan async => (await _prefs).getString('user_plan');
  Future<bool> get isLoggedIn async => (await _prefs).getString('access_token') != null;

  // ── Auth ──────────────────────────────────────────────────────

  Future<AuthToken> signUp(String email, String password, String name) async {
    final r = await _dio.post(AppConstants.signUp, data: {
      'email': email, 'password': password, 'name': name,
    });
    final token = AuthToken.fromJson(r.data);
    await saveToken(token);
    return token;
  }

  Future<AuthToken> signIn(String email, String password) async {
    final r = await _dio.post(AppConstants.signIn, data: {
      'email': email, 'password': password,
    });
    final token = AuthToken.fromJson(r.data);
    await saveToken(token);
    return token;
  }

  Future<AuthToken> socialAuth(String providerToken, String provider) async {
    final r = await _dio.post(AppConstants.socialAuth, data: {
      'provider_token': providerToken, 'provider': provider,
    });
    final token = AuthToken.fromJson(r.data);
    await saveToken(token);
    return token;
  }

  // ── Profile ───────────────────────────────────────────────────

  Future<HealthProfile> getProfile() async {
    final r = await _dio.get(AppConstants.profile);
    return HealthProfile.fromJson(r.data);
  }

  Future<HealthProfile> saveProfile(HealthProfile profile) async {
    final r = await _dio.post(AppConstants.profile, data: profile.toJson());
    return HealthProfile.fromJson(r.data);
  }

  // ── Image Upload ──────────────────────────────────────────────

  Future<String> uploadImage(XFile imageFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final bytes = await imageFile.readAsBytes();
    
    final prefs = await _prefs;
    final token = prefs.getString('access_token');
    final uploadUrl = '${AppConstants.supabaseUrl}/storage/v1/object/${AppConstants.storageBucket}/$fileName';

    final dio = Dio();
    await dio.post(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'apikey': AppConstants.supabaseAnonKey,
          'Content-Type': 'image/jpeg',
        },
      ),
    );

    return '${AppConstants.supabaseUrl}/storage/v1/object/public/${AppConstants.storageBucket}/$fileName';
  }

  // ── Chat ──────────────────────────────────────────────────────

  Future<ChatResponse> sendMessage({
    String? sessionId,
    required String message,
    String? imageUrl,
  }) async {
    final r = await _dio.post(AppConstants.chat, data: {
      'session_id': sessionId,
      'message': message,
      'image_url': imageUrl,
    });
    return ChatResponse.fromJson(r.data);
  }

  // ── Compare ───────────────────────────────────────────────────

  Future<CompareResult> compareProducts(List<Map<String, String>> products) async {
    final r = await _dio.post(AppConstants.compare, data: {'products': products});
    return CompareResult.fromJson(r.data);
  }

  // ── History ───────────────────────────────────────────────────

  Future<List<ConversationSummary>> getHistory({int limit = 20, int offset = 0}) async {
    final r = await _dio.get(
      AppConstants.historyList,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return (r.data as List).map((e) => ConversationSummary.fromJson(e)).toList();
  }

  Future<List<ChatMessage>> getConversation(String sessionId) async {
    final r = await _dio.get('${AppConstants.historyDetail}$sessionId');
    return (r.data['messages'] as List).map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<void> deleteConversation(String sessionId) async {
    await _dio.delete('${AppConstants.historyDetail}$sessionId');
  }
}

// Helper: extract user-friendly error message from DioException
String apiError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      if (data.containsKey('detail')) {
        final detail = data['detail'].toString();
        final normalized = detail.toLowerCase();
        if (normalized.contains('email rate limit exceeded')) {
          return 'Email rate limit exceeded. Wait a few minutes before trying again.';
        }
        if (normalized.contains('invalid login credentials')) {
          return 'Invalid email or password. If you just signed up, confirm your email first.';
        }
        return detail;
      }
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
      if (data.containsKey('error') && data['error'] is String) {
        return data['error'].toString();
      }
    }
    if (e.type == DioExceptionType.connectionTimeout) return 'Connection timed out.';
    if (e.type == DioExceptionType.receiveTimeout) return 'Server took too long to respond.';
    if (e.response?.statusCode == 429) return 'Too many requests. Please slow down.';
    if (e.response?.statusCode == 401) return 'Session expired. Please sign in again.';
  }
  if (e is StorageException) {
    return e.message;
  }
  return 'Something went wrong. Please try again.';
}
