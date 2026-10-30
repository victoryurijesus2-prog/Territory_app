import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  SyncService.instance.startMonitoring();
  runApp(const TerritoryApp());
}

class TerritoryApp extends StatelessWidget {
  const TerritoryApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: AppConfig.appName, debugShowCheckedModeBanner: false, theme: AppTheme.light(), darkTheme: AppTheme.dark(), themeMode: ThemeMode.dark, home: const AuthGate());
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: Supabase.instance.client.auth.onAuthStateChange,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
      final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
      return session != null ? const HomeScreen() : const LoginScreen();
    },
  );
}
