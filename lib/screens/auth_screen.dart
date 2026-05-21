import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _loginForm = GlobalKey<FormState>();
  final _registerForm = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  final _regName = TextEditingController();
  bool _busy = false;
  bool _obscureLogin = true;
  bool _obscureReg = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    _regName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.burntSienna, AppColors.burntSiennaDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.auto_stories_rounded, size: 72, color: AppColors.white),
              const SizedBox(height: 12),
              Text(
                'Книжная полка',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Читай с удовольствием каждый день',
                style: TextStyle(color: AppColors.powderBlue, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabs,
                        labelColor: AppColors.burntSienna,
                        unselectedLabelColor: AppColors.burntSienna.withValues(alpha: 0.5),
                        indicatorColor: AppColors.burntSienna,
                        tabs: const [
                          Tab(text: 'Вход'),
                          Tab(text: 'Регистрация'),
                        ],
                      ),
                      if (state.authError != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            state.authError!,
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            _buildLogin(state),
                            _buildRegister(state),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogin(AppState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginForm,
        child: Column(
          children: [
            TextFormField(
              controller: _loginEmail,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Введите email' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _loginPassword,
              obscureText: _obscureLogin,
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureLogin ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
                ),
              ),
              validator: (v) =>
                  v == null || v.length < 6 ? 'Минимум 6 символов' : null,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : () => _doLogin(state),
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Войти'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegister(AppState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _registerForm,
        child: Column(
          children: [
            TextFormField(
              controller: _regName,
              decoration: const InputDecoration(
                labelText: 'Имя',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Введите имя' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _regEmail,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Введите email' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _regPassword,
              obscureText: _obscureReg,
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureReg ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureReg = !_obscureReg),
                ),
              ),
              validator: (v) =>
                  v == null || v.length < 6 ? 'Минимум 6 символов' : null,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : () => _doRegister(state),
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Создать аккаунт'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doLogin(AppState state) async {
    if (!_loginForm.currentState!.validate()) return;
    setState(() => _busy = true);
    state.clearAuthError();
    await state.login(
      email: _loginEmail.text,
      password: _loginPassword.text,
    );
    setState(() => _busy = false);
  }

  Future<void> _doRegister(AppState state) async {
    if (!_registerForm.currentState!.validate()) return;
    setState(() => _busy = true);
    state.clearAuthError();
    await state.register(
      email: _regEmail.text,
      password: _regPassword.text,
      displayName: _regName.text,
    );
    setState(() => _busy = false);
  }
}
