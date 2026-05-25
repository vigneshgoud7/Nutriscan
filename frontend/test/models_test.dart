import 'package:flutter_test/flutter_test.dart';
import 'package:nutriscan/models/models.dart';

void main() {
  group('AuthToken', () {
    test('fromJson and properties', () {
      final json = {
        'access_token': 'test_token',
        'user_id': 'user123',
        'name': 'Test User',
        'plan': 'free',
      };
      final token = AuthToken.fromJson(json);
      expect(token.accessToken, 'test_token');
      expect(token.userId, 'user123');
      expect(token.name, 'Test User');
      expect(token.plan, 'free');
      expect(token.isPremium, false);
    });
  });

  group('HealthProfile', () {
    test('fromJson and toJson', () {
      final json = {
        'age': 30,
        'sex': 'male',
        'weight_kg': 70.5,
        'height_cm': 175.0,
        'goal': 'weight loss',
        'diseases': ['none'],
        'allergies': ['peanuts'],
        'diet_type': 'keto',
      };
      final profile = HealthProfile.fromJson(json);
      expect(profile.age, 30);
      expect(profile.sex, 'male');
      expect(profile.weightKg, 70.5);
      
      final outJson = profile.toJson();
      expect(outJson['age'], 30);
      expect(outJson['sex'], 'male');
      expect(outJson['allergies'], ['peanuts']);
      expect(profile.isEmpty, false);
    });

    test('isEmpty is true when empty', () {
      final profile = HealthProfile();
      expect(profile.isEmpty, true);
    });
  });

  group('ChatMessage', () {
    test('fromJson', () {
      final json = {
        'id': 'msg1',
        'role': 'user',
        'content': 'Hello',
        'timestamp': '2023-01-01T12:00:00.000Z',
      };
      final msg = ChatMessage.fromJson(json);
      expect(msg.id, 'msg1');
      expect(msg.role, MessageRole.user);
      expect(msg.content, 'Hello');
      expect(msg.timestamp.year, 2023);
    });
  });
}
