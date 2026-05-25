import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';

// ── Auth Provider ─────────────────────────────────────────────────────────────

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? userName;
  final String? plan;
  final String? error;
  final bool isNewUser;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.userName,
    this.plan,
    this.error,
    this.isNewUser = false,
  });

  AuthState copyWith({bool? isLoading, bool? isAuthenticated, String? userName, String? plan, String? error, bool? isNewUser}) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        userName: userName ?? this.userName,
        plan: plan ?? this.plan,
        error: error,
        isNewUser: isNewUser ?? this.isNewUser,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final loggedIn = await ApiService.instance.isLoggedIn;
      if (loggedIn) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userName: await ApiService.instance.savedName,
          plan: await ApiService.instance.savedPlan,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('Auth init error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await ApiService.instance.signUp(email, password, name);
      state = state.copyWith(isLoading: false, isAuthenticated: true, userName: token.name, plan: token.plan, isNewUser: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiError(e));
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await ApiService.instance.signIn(email, password);
      state = state.copyWith(isLoading: false, isAuthenticated: true, userName: token.name, plan: token.plan);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiError(e));
      return false;
    }
  }

  Future<void> signOut() async {
    await ApiService.instance.clearToken();
    state = const AuthState();
  }

  void clearNewUserFlag() {
    state = state.copyWith(isNewUser: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

// ── Profile Provider ──────────────────────────────────────────────────────────

class ProfileNotifier extends StateNotifier<AsyncValue<HealthProfile?>> {
  ProfileNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final profile = await ApiService.instance.getProfile();
      state = AsyncValue.data(profile);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<bool> save(HealthProfile profile) async {
    try {
      final saved = await ApiService.instance.saveProfile(profile);
      state = AsyncValue.data(saved);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<HealthProfile?>>((ref) => ProfileNotifier());

// ── Chat Provider ─────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isSending;
  final String? sessionId;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isSending = false,
    this.sessionId,
    this.error,
  });

  ChatState copyWith({List<ChatMessage>? messages, bool? isSending, String? sessionId, String? error}) =>
      ChatState(
        messages: messages ?? this.messages,
        isSending: isSending ?? this.isSending,
        sessionId: sessionId ?? this.sessionId,
        error: error,
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState());

  void setSession(String sessionId, List<ChatMessage> messages) {
    state = ChatState(sessionId: sessionId, messages: messages);
  }

  void newSession() {
    state = const ChatState();
  }

  Future<void> send(String message, {String? imageUrl}) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: message,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isSending: true,
      error: null,
    );

    try {
      final response = await ApiService.instance.sendMessage(
        sessionId: state.sessionId,
        message: message,
        imageUrl: imageUrl,
      );

      final aiMsg = ChatMessage(
        id: response.messageId,
        role: MessageRole.assistant,
        content: response.reply,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isSending: false,
        sessionId: response.sessionId,
      );
    } catch (e) {
      state = state.copyWith(isSending: false, error: apiError(e));
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) => ChatNotifier());

// ── History Provider ──────────────────────────────────────────────────────────

final historyProvider = FutureProvider.autoDispose<List<ConversationSummary>>((ref) async {
  return ApiService.instance.getHistory();
});
