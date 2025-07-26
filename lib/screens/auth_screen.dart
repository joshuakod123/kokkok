import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController(); // 아이디/이메일 입력용
  final _emailController = TextEditingController(); // 회원가입용 이메일
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController(); // 실명
  final _userIdController = TextEditingController(); // 아이디

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
        // 로그인 로직 - 아이디 또는 이메일로 로그인 가능
        await _performLogin();
      } else {
        // 회원가입 로직
        await _performSignUp();
      }
    } on AuthException catch (error) {
      if (mounted) _showErrorSnackBar(error.message);
    } catch (error) {
      if (mounted) _showErrorSnackBar('예상치 못한 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _performLogin() async {
    final loginInput = _loginController.text.trim();
    String email = loginInput;

    // 이메일이 아닌 아이디로 로그인 시도하는 경우, 아이디로 이메일을 찾기
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

    // 이메일로 로그인
    await supabase.auth.signInWithPassword(
      email: email,
      password: _passwordController.text.trim(),
    );
  }

  Future<void> _performSignUp() async {
    // 아이디 중복 확인
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
      _showSuccessSnackBar('회원가입 완료! 로그인해주세요.');
      setState(() {
        _isLoginMode = true;
        _passwordController.clear();
        _confirmPasswordController.clear();
        _loginController.text = _userIdController.text; // 가입한 아이디를 로그인 필드에 자동 입력
      });
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
        if (mounted) _showErrorSnackBar('사용자를 찾을 수 없거나 오류가 발생했습니다.');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  Future<bool?> _showInputDialog({
    required String title,
    required String label,
    required TextEditingController controller,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
            autofocus: true
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('확인')),
        ],
      ),
    );
  }

  void _showTempPasswordDialog(String password, String loginInput) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('임시 비밀번호 발급 완료'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('임시 비밀번호가 발급되었습니다.\n아래 비밀번호로 로그인 후 즉시 변경해주세요.'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
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
              _showSuccessSnackBar('임시 비밀번호가 복사되었습니다.');
            },
            child: const Text('복사하기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loginController.text = loginInput;
              _passwordController.text = password;
              _showSuccessSnackBar('임시 비밀번호로 로그인해주세요.');
            },
            child: const Text('로그인하기'),
          ),
        ],
      ),
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
                      // 로그인 모드
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
                      // 회원가입 모드
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