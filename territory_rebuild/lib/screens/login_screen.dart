import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false;
  bool _loading = false;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();

  @override
  void dispose() { _emailCtrl.dispose(); _passwordCtrl.dispose(); _nicknameCtrl.dispose(); super.dispose(); }

  Future<void> _emailAuth() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) { _showError('Preencha email e senha'); return; }
    if (_isSignUp && _nicknameCtrl.text.isEmpty) { _showError('Escolha um nickname'); return; }
    setState(() => _loading = true);
    try {
      if (_isSignUp) { await AuthService.signUpWithEmail(email: _emailCtrl.text.trim(), password: _passwordCtrl.text, nickname: _nicknameCtrl.text.trim()); }
      else { await AuthService.signInWithEmail(email: _emailCtrl.text.trim(), password: _passwordCtrl.text); }
    } catch (e) { _showError('Erro: ${e.toString()}'); } finally { if (mounted) setState(() => _loading = false); }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A), Color(0xFF0D0D0D)])),
        child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 48),
          Column(children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.3)]), boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 24, spreadRadius: 4)]), child: const Icon(Icons.terrain, color: Colors.white, size: 40)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            const Text('TerritoryApp', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5)).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            const Text('Conquiste a cidade correndo', style: TextStyle(color: Colors.white54, fontSize: 16)).animate().fadeIn(delay: 400.ms),
          ]),
          const SizedBox(height: 48),
          Text(_isSignUp ? 'Criar conta' : 'Entrar', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 24),
          if (_isSignUp) ...[TextField(controller: _nicknameCtrl, decoration: const InputDecoration(labelText: 'Nickname', prefixIcon: Icon(Icons.person_outline, color: Colors.white38)), style: const TextStyle(color: Colors.white)), const SizedBox(height: 12)],
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: Colors.white38)), keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          TextField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline, color: Colors.white38)), obscureText: true, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 24),
          SizedBox(height: 52, child: ElevatedButton(onPressed: _loading ? null : _emailAuth, child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_isSignUp ? 'Criar conta' : 'Entrar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 16),
          TextButton(onPressed: () => setState(() => _isSignUp = !_isSignUp), child: Text(_isSignUp ? 'Já tenho conta — Entrar' : 'Não tenho conta — Criar', style: const TextStyle(color: Colors.white54))),
        ]))),
      ),
    );
  }
}
