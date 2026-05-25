class AppConstants {
  // ── Replace these with your actual values ─────────────────────
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';

  static const String supabaseUrl = 'https://uqclehpajfqghakxafln.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVxY2xlaHBhamZxZ2hha3hhZmxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzNzYxMDYsImV4cCI6MjA5NDk1MjEwNn0.7nu4qXHar7q8-8m-bC7FoMpQMznulQGVVpYmJ4n4rIY';

  static const String storageBucket = 'food-images';

  // ── API endpoints ──────────────────────────────────────────────
  static const String signUp         = '/auth/signup';
  static const String signIn         = '/auth/signin';
  static const String socialAuth     = '/auth/social';
  static const String profile        = '/profile/me';
  static const String chat           = '/chat/';
  static const String compare        = '/compare/';
  static const String historyList    = '/history/';
  static const String historyDetail  = '/history/';

  // ── UI constants ───────────────────────────────────────────────
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const double maxCompressQuality = 80.0;
  static const int maxCompareProducts = 5;
}
