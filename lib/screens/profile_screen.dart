import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_certification_service.dart'; // UserCertificationService import

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
  // 의존성 주입 (서비스 클래스 인스턴스화)
  final _userService = UserCertificationService();

  String username = "이름 없음";
  String userId = "아이디 없음";
  String email = "이메일 없음";
  bool _isLoading = true;
  bool _isSyncing = false; // 백업/복원 작업 중 상태 변수 추가

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

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
    // ... 기존 _loadUserProfile 함수 코드는 변경 없음 ...
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        email = user.email ?? "이메일 없음";
        String? metaUsername = user.userMetadata?['username'];
        String? metaUserId = user.userMetadata?['user_id'];

        if (metaUsername != null && metaUserId != null) {
          username = metaUsername;
          userId = metaUserId;
        } else {
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    // ... 기존 _signOut 함수 코드는 변경 없음 ...
    try {
      await supabase.auth.signOut();
    } on AuthException catch (error) {
      if (mounted) _showErrorSnackBar(error.message);
    }
  }

  void _changePassword() {
    // ... 기존 _changePassword 함수 코드는 변경 없음 ...
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

                if (mounted) {
                  Navigator.of(context).pop();
                  _showSuccessSnackBar('비밀번호가 성공적으로 변경되었습니다.');
                  widget.onPasswordChanged();
                }
              } on AuthException catch (error) {
                if (mounted) {
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

  // --- 데이터 백업 및 복원 함수 ---

  Future<void> _backupToServer() async {
    setState(() => _isSyncing = true);
    try {
      await _userService.backupDataToSupabase();
      if (mounted) {
        _showSuccessSnackBar('백업 완료! 데이터가 안전하게 보관되었습니다.');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _restoreFromServer() async {
    setState(() => _isSyncing = true);
    try {
      await _userService.restoreDataFromSupabase();
      if (mounted) {
        _showSuccessSnackBar('복원 완료! 스펙 정보를 최신 상태로 업데이트했습니다.');
        // TODO: 복원 후에는 홈 화면으로 이동하여 데이터를 새로고침 하도록 유도하는 로직 추가
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('데이터 복원 확인'),
          ],
        ),
        content: const Text(
            '정말 복원하시겠어요?\n\n현재 휴대폰의 스펙 정보는 모두 사라지고, 서버의 데이터로 대체됩니다. 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              _restoreFromServer(); // 복원 실행
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('복원'),
          ),
        ],
      ),
    );
  }

  // --- 스낵바 헬퍼 함수 ---

  void _showErrorSnackBar(String message) {
    // ... 기존 코드와 동일 ...
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  void _showSuccessSnackBar(String message) {
    // ... 기존 코드와 동일 ...
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 배경색 변경
      appBar: AppBar(
        title: const Text('내 정보', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
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
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // --- 사용자 프로필 카드 ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(
                            username.isNotEmpty ? username.substring(0, 1) : '?',
                            style: TextStyle(
                                fontSize: 24,
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- 계정 관리 섹션 ---
                _SectionHeader(title: '계정 관리'),
                _buildMenuTile(
                  icon: Icons.lock_outline,
                  title: '비밀번호 변경',
                  onTap: _changePassword,
                ),
                _buildMenuTile(
                  icon: Icons.logout,
                  title: '로그아웃',
                  color: Colors.red,
                  onTap: _signOut,
                ),
                const SizedBox(height: 24),

                // --- 데이터 관리 섹션 ---
                _SectionHeader(title: '내 스펙 데이터 관리'),
                _buildMenuTile(
                  icon: Icons.cloud_upload_outlined,
                  title: '서버에 내 스펙 저장하기',
                  subtitle: '휴대폰을 바꾸거나 앱을 삭제해도 스펙 정보를 안전하게 지킬 수 있어요.',
                  onTap: _backupToServer,
                ),
                _buildMenuTile(
                  icon: Icons.cloud_download_outlined,
                  title: '서버에서 내 스펙 불러오기',
                  subtitle: '새 휴대폰이나 다른 기기에서 스펙 정보를 그대로 가져올 수 있어요.',
                  onTap: _showRestoreDialog,
                ),

                // 동기화 중일 때 로딩 인디케이터 표시
                if (_isSyncing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 재사용을 위한 메뉴 타일 위젯
  Widget _buildMenuTile(
      {required IconData icon,
        required String title,
        String? subtitle,
        VoidCallback? onTap,
        Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color ?? Colors.black87)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12))
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}

// 재사용을 위한 섹션 헤더 위젯
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600]),
      ),
    );
  }
}