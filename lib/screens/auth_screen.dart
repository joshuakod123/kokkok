import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/popup_utils.dart';

final supabase = Supabase.instance.client;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _userIdController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _trySubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    FocusScope.of(context).unfocus();
    if (!isValid) return;
    setState(() { _isLoading = true; });
    try {
      if (_isLoginMode) {
        await _performLogin();
      } else {
        await _performSignUp();
      }
    } on AuthException catch (error) {
      if (mounted) {
        await PopupUtils.showError(
          context: context,
          title: '로그인 실패',
          message: error.message,
        );
      }
    } catch (error) {
      if (mounted) {
        await PopupUtils.showError(
          context: context,
          title: '오류 발생',
          message: '예상치 못한 오류가 발생했습니다.',
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _performLogin() async {
    final loginInput = _loginController.text.trim();
    String email = loginInput;

    if (!loginInput.contains('@')) {
      try {
        final result = await supabase.rpc(
          'get_email_by_userid',
          params: {'input_userid': loginInput},
        );
        if (result != null) {
          email = result as String;
        } else {
          throw Exception('아이디를 찾을 수 없습니다.');
        }
      } catch (e) {
        throw AuthException('아이디를 찾을 수 없습니다.');
      }
    }

    await supabase.auth.signInWithPassword(
      email: email,
      password: _passwordController.text.trim(),
    );
  }

  Future<void> _performSignUp() async {
    final isDuplicateId = await _checkUserIdDuplicate(_userIdController.text.trim());
    if (isDuplicateId) {
      throw Exception('이미 사용 중인 아이디입니다.');
    }

    await supabase.auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      data: {
        'username': _usernameController.text.trim(),
        'user_id': _userIdController.text.trim(),
      },
    );

    if (mounted) {
      await PopupUtils.showSuccess(
        context: context,
        title: '회원가입 완료!',
        message: '성공적으로 가입되었습니다. 이제 로그인해주세요.',
        onPressed: () {
          setState(() {
            _isLoginMode = true;
            _passwordController.clear();
            _confirmPasswordController.clear();
            _loginController.text = _userIdController.text;
          });
        },
      );
    }
  }

  Future<bool> _checkUserIdDuplicate(String userId) async {
    try {
      final result = await supabase.rpc(
        'check_userid_exists',
        params: {'input_userid': userId},
      );
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  Future<void> _forgotPassword() async {
    final loginController = TextEditingController();
    final result = await _showInputDialog(
      title: '비밀번호 찾기',
      label: '아이디 또는 이메일',
      controller: loginController,
    );

    if (result == true && loginController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final tempPassword = await supabase.rpc(
          'reset_password_by_login',
          params: {'login_input': loginController.text.trim()},
        );

        if (mounted) {
          _showTempPasswordDialog(tempPassword, loginController.text.trim());
        }
      } catch (error) {
        debugPrint('Password Reset Error: $error');
        if (mounted) {
          await PopupUtils.showError(
            context: context,
            title: '비밀번호 찾기 실패',
            message: '사용자를 찾을 수 없거나 오류가 발생했습니다.',
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showInputDialog({
    required String title,
    required String label,
    required TextEditingController controller,
  }) {
    return PopupUtils.showCustom(
      context: context,
      title: title,
      titleIcon: Icons.lock_reset,
      titleColor: Colors.orange,
      barrierDismissible: false,
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('취소', style: TextStyle(color: Colors.grey[600])),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('확인'),
        ),
      ],
    );
  }

  void _showTempPasswordDialog(String password, String loginInput) {
    PopupUtils.showCustom(
      context: context,
      title: '임시 비밀번호 발급 완료',
      titleIcon: Icons.key,
      titleColor: Colors.green,
      barrierDismissible: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '임시 비밀번호가 발급되었습니다.\n아래 비밀번호로 로그인 후 즉시 변경해주세요.',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SelectableText(
              password,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: password));
            PopupUtils.showSuccess(
              context: context,
              title: '복사 완료',
              message: '임시 비밀번호가 클립보드에 복사되었습니다.',
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('복사하기'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _loginController.text = loginInput;
            _passwordController.text = password;
            PopupUtils.showInfo(
              context: context,
              title: '로그인 준비 완료',
              message: '임시 비밀번호로 로그인해주세요.',
              color: Colors.blue,
              icon: Icons.login,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('로그인하기'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 120, child: Center(child: Text('콕콕', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)))),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildAuthModeButton('로그인', true), const SizedBox(width: 20), _buildAuthModeButton('회원가입', false)]),
                    const SizedBox(height: 30),

                    if (_isLoginMode) ...[
                      TextFormField(
                          controller: _loginController,
                          decoration: const InputDecoration(labelText: '아이디 또는 이메일'),
                          validator: (v) => v==null || v.trim().isEmpty ? '아이디 또는 이메일을 입력해주세요.' : null
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: '비밀번호'),
                          obscureText: true,
                          validator: (v) => v==null || v.trim().length<6 ? '6자 이상 입력해주세요.' : null
                      ),
                    ] else ...[
                      TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(labelText: '이름'),
                          validator: (v) => v==null || v.trim().length<2 ? '2자 이상의 이름을 입력해주세요.' : null
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _userIdController,
                        decoration: const InputDecoration(
                          labelText: '아이디',
                          hintText: '영문, 숫자 조합 (4자 이상)',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length < 4) {
                            return '4자 이상의 아이디를 입력해주세요.';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(v.trim())) {
                            return '영문과 숫자만 사용 가능합니다.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: '이메일'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v==null || !v.trim().contains('@') ? '유효한 이메일을 입력해주세요.' : null
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: '비밀번호'),
                          obscureText: true,
                          validator: (v) => v==null || v.trim().length<6 ? '6자 이상 입력해주세요.' : null
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(labelText: '비밀번호 확인'),
                          obscureText: true,
                          validator: (v) => v != _passwordController.text ? '비밀번호가 일치하지 않습니다.' : null
                      ),
                    ],

                    const SizedBox(height: 30),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(onPressed: _trySubmit, child: Text(_isLoginMode ? '로그인' : '회원가입')),
                    const SizedBox(height: 12),

                    if (_isLoginMode)
                      Center(
                        child: TextButton(
                            onPressed: _forgotPassword,
                            child: const Text('비밀번호 찾기')
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthModeButton(String text, bool isLogin) {
    final isSelected = _isLoginMode == isLogin;
    return GestureDetector(
      onTap: () => setState(() { _isLoginMode = isLogin; }),
      child: Text(text, style: TextStyle(fontSize: 20, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Theme.of(context).primaryColor : Colors.grey)),
    );
  }
}