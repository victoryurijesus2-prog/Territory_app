// lib/core/config.dart
class AppConfig {
  static const String supabaseUrl = 'https://imwpfkpnovgvsyjzehga.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imltd3Bma3Bub3ZndnN5anplaGdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExMTcxNDAsImV4cCI6MjA5NjY5MzE0MH0.HzCEs8LsYvY0AxpvHVAhfeDU0r_zEvzNS0byvCRfcqE';
  static const String appName = 'TerritoryApp';
  static const int freeTerritoryLimit = 20;
  static const double maxRunSpeedKmh = 20.0;
  static const double closingThresholdMeters = 30.0;
  static const int minGpsPoints = 8;
  static const double minPathLengthMeters = 50.0;
}
