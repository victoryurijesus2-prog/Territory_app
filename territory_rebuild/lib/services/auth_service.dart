import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player.dart';

class AuthService {
  static final _client = Supabase.instance.client;
  static final _googleSignIn = GoogleSignIn();

  static User? get currentUser => _client.auth.currentUser;
  static String get userId => currentUser?.id ?? '';
  static bool get isLoggedIn => currentUser != null;
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final response = await _client.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: googleAuth.idToken!, accessToken: googleAuth.accessToken!);
      await _upsertProfile(userId: response.user!.id, nickname: googleUser.displayName ?? 'Jogador', avatarUrl: googleUser.photoUrl);
      return response;
    } catch (e) { debugPrint('Google sign in error: $e'); rethrow; }
  }

  static Future<AuthResponse?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await SignInWithApple.getAppleIDCredential(scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName], nonce: hashedNonce);
      final response = await _client.auth.signInWithIdToken(provider: OAuthProvider.apple, idToken: credential.identityToken!, nonce: rawNonce);
      final name = [credential.givenName, credential.familyName].where((e) => e != null).join(' ');
      await _upsertProfile(userId: response.user!.id, nickname: name.isNotEmpty ? name : 'Jogador Apple', avatarUrl: null);
      return response;
    } catch (e) { debugPrint('Apple sign in error: $e'); rethrow; }
  }

  static Future<AuthResponse> signUpWithEmail({required String email, required String password, required String nickname}) async {
    final response = await _client.auth.signUp(email: email, password: password);
    if (response.user != null) await _upsertProfile(userId: response.user!.id, nickname: nickname, avatarUrl: null);
    return response;
  }

  static Future<AuthResponse> signInWithEmail({required String email, required String password}) async => _client.auth.signInWithPassword(email: email, password: password);

  static Future<void> signOut() async { await _googleSignIn.signOut(); await _client.auth.signOut(); }

  static Future<Player?> getProfile(String userId) async {
    final data = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return data != null ? Player.fromMap(data) : null;
  }

  static Future<void> updateProfile({String? nickname, String? avatarUrl}) async {
    if (currentUser == null) return;
    final updates = <String, dynamic>{};
    if (nickname != null) updates['nickname'] = nickname;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (updates.isEmpty) return;
    await _client.from('profiles').update(updates).eq('id', currentUser!.id);
  }

  static Future<void> _upsertProfile({required String userId, required String nickname, String? avatarUrl}) async => _client.from('profiles').upsert({'id': userId, 'nickname': nickname, 'avatar_url': avatarUrl}, onConflict: 'id');

  static String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }
}
