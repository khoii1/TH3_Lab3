import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'auth_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _email = '';
  String _password = '';
  String _name = '';

  Future<String?> _getFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    final authState = context.read<AuthState>();
    authState.clearError();

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final token = await _getFcmToken();

    if (_isLogin) {
      await authState.signIn(_email, _password, fcmToken: token);
    } else {
      await authState.signUp(_email, _password, _name, fcmToken: token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, state, _) {
        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isLogin ? 'Đăng nhập' : 'Đăng ký',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          if (!_isLogin)
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Tên hiển thị',
                              ),
                              onSaved: (v) => _name = v!.trim(),
                              validator: (v) {
                                if (!_isLogin && (v == null || v.isEmpty)) {
                                  return 'Nhập tên hiển thị';
                                }
                                return null;
                              },
                            ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onSaved: (v) => _email = v!.trim(),
                            validator: (v) {
                              if (v == null || !v.contains('@')) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Mật khẩu',
                            ),
                            obscureText: true,
                            onSaved: (v) => _password = v!.trim(),
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return 'Mật khẩu tối thiểu 6 ký tự';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (state.error != null)
                            Text(
                              state.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: state.loading ? null : _submit,
                              child: state.loading
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(_isLogin ? 'Đăng nhập' : 'Đăng ký'),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(
                              _isLogin
                                  ? 'Chưa có tài khoản? Đăng ký'
                                  : 'Đã có tài khoản? Đăng nhập',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
