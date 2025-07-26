import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ProfileScreen extends StatefulWidget {
  final bool needsPasswordChange;
  final VoidCallback onPasswordChanged;

  const ProfileScreen({
    super.key,
    required this.needsPasswordChange,
    required this.onPasswordChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = "이름 없음";
  String userId = "아이디 없음";
  String email = "이메일 없음";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // 비밀번호 변경이 필요하면 바로 변경 팝업을 띄움
    if (widget.needsPasswordChange) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _changePassword();
      });
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.needsPasswordChange && !oldWidget.needsPasswordChange) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _changePassword();
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // 이메일은 auth.users에서 가져오기
        email = user.email ?? "이메일 없음";

        // username과 user_id는 메타데이터 또는 profiles 테이블에서 가져오기
        String? metaUsername = user.userMetadata?['username'];
        String? metaUserId = user.userMetadata?['user_id'];

        if (metaUsername != null && metaUserId != null) {
          username = metaUsername;
          userId = metaUserId;
        } else {
          // 메타데이터에 없으면 profiles 테이블에서 가져오기
          final profileData = await supabase
              .from('profiles')
              .select('username, user_id')
              .eq('id', user.id)
              .maybeSingle();

          if (profileData != null) {
            username = profileData['username'] ?? username;
            userId = profileData['user_id'] ?? userId;
          }
        }
      }
    } catch (error) {
      debugPrint('Error loading user profile: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (error) {
      if (context.mounted) _showErrorSnackBar(error.message);
    }
  }

  void _changePassword() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 변경'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: '새 비밀번호 (6자 이상)'),
          autofocus: true,
        ),
        actions: [
          if (!widget.needsPasswordChange)
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.trim().length < 6) {
                _showErrorSnackBar('비밀번호는 6자 이상이어야 합니다.');
                return;
              }
              try {
                final userId = supabase.auth.currentUser!.id;
                await supabase.auth.updateUser(
                  UserAttributes(password: passwordController.text.trim()),
                );
                await supabase
                    .from('profiles')
                    .update({'force_password_change': false})
                    .eq('id', userId);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  _showSuccessSnackBar('비밀번호가 성공적으로 변경되었습니다.');
                  widget.onPasswordChanged();
                }
              } on AuthException catch (error) {
                if (context.mounted) {
                  _showErrorSnackBar(error.message);
                }
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 비밀번호 변경이 필요할 때만 상단에 경고 배너를 표시
          if (widget.needsPasswordChange)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              color: Colors.amber.shade100,
              child: const Text(
                '🔒 보안을 위해 임시 비밀번호를 변경해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 사용자 정보 섹션
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('아이디'),
                  subtitle: Text(userId),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('이름'),
                  subtitle: Text(username),
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('이메일'),
                  subtitle: Text(email),
                ),
                const Divider(),

                // 설정 섹션
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('비밀번호 변경'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _changePassword,
                ),
                const Divider(),

                // 로그아웃
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red.shade700),
                  title: Text('로그아웃', style: TextStyle(color: Colors.red.shade700)),
                  onTap: _signOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}