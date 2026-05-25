import 'package:flutter/foundation.dart';

// ── Auth ──────────────────────────────────────────────────────────────────────

class AuthToken {
  final String accessToken;
  final String userId;
  final String name;
  final String plan;

  const AuthToken({
    required this.accessToken,
    required this.userId,
    required this.name,
    required this.plan,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) => AuthToken(
        accessToken: json['access_token'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        plan: json['plan'] as String,
      );

  bool get isPremium => plan == 'premium';
}

// ── Health Profile ────────────────────────────────────────────────────────────

class HealthProfile {
  final int? age;
  final String? sex;
  final double? weightKg;
  final double? heightCm;
  final String? goal;
  final List<String> diseases;
  final List<String> allergies;
  final String? dietType;

  const HealthProfile({
    this.age,
    this.sex,
    this.weightKg,
    this.heightCm,
    this.goal,
    this.diseases = const [],
    this.allergies = const [],
    this.dietType,
  });

  factory HealthProfile.fromJson(Map<String, dynamic> json) => HealthProfile(
        age: json['age'] as int?,
        sex: json['sex'] as String?,
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        goal: json['goal'] as String?,
        diseases: List<String>.from(json['diseases'] ?? []),
        allergies: List<String>.from(json['allergies'] ?? []),
        dietType: json['diet_type'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'age': age,
        'sex': sex,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'goal': goal,
        'diseases': diseases,
        'allergies': allergies,
        'diet_type': dietType,
      };

  bool get isEmpty =>
      age == null && sex == null && weightKg == null && diseases.isEmpty && allergies.isEmpty;
}

// ── Chat ──────────────────────────────────────────────────────────────────────

enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.imageUrl,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
        content: json['content'] as String,
        imageUrl: json['image_url'] as String?,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
      );
}

class ChatResponse {
  final String sessionId;
  final String sessionTitle;
  final String reply;
  final String messageId;

  const ChatResponse({
    required this.sessionId,
    required this.sessionTitle,
    required this.reply,
    required this.messageId,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
        sessionId: json['session_id'] as String,
        sessionTitle: json['session_title'] as String,
        reply: json['reply'] as String,
        messageId: json['message_id'] as String,
      );
}

// ── History ───────────────────────────────────────────────────────────────────

class ConversationSummary {
  final String sessionId;
  final String title;
  final DateTime createdAt;
  final int messageCount;
  final DateTime lastMessageAt;

  const ConversationSummary({
    required this.sessionId,
    required this.title,
    required this.createdAt,
    required this.messageCount,
    required this.lastMessageAt,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) => ConversationSummary(
        sessionId: json['session_id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        messageCount: json['message_count'] as int,
        lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      );
}

// ── Compare ───────────────────────────────────────────────────────────────────

class CompareResult {
  final String comparisonText;
  final String? winner;
  final String sessionId;

  const CompareResult({
    required this.comparisonText,
    this.winner,
    required this.sessionId,
  });

  factory CompareResult.fromJson(Map<String, dynamic> json) => CompareResult(
        comparisonText: json['comparison_text'] as String,
        winner: json['winner'] as String?,
        sessionId: json['session_id'] as String,
      );
}
