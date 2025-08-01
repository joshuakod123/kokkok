import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_certification_service.dart';
import '../utils/popup_utils.dart';

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
  final _userService = UserCertificationService();

  String username = "이름 없음";
  String userId = "아이디 없음";
  String email = "이메일 없음";
  String? major;
  bool _isLoading = true;
  bool _isSyncing = false;

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
              .select('username, user_id, major')
              .eq('id', user.id)
              .maybeSingle();

          if (profileData != null) {
            username = profileData['username'] ?? username;
            userId = profileData['user_id'] ?? userId;
            major = profileData['major'];
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
    final confirmed = await PopupUtils.showConfirmation(
      context: context,
      title: '로그아웃 확인',
      message: '정말 로그아웃하시겠습니까?',
      confirmText: '로그아웃',
      confirmColor: Colors.red,
      icon: Icons.logout,
    );

    if (confirmed == true) {
      try {
        await supabase.auth.signOut();
      } on AuthException catch (error) {
        if (mounted) {
          await PopupUtils.showError(
            context: context,
            title: '로그아웃 실패',
            message: error.message,
          );
        }
      }
    }
  }

  void _changePassword() {
    final passwordController = TextEditingController();

    PopupUtils.showCustom(
      context: context,
      title: '비밀번호 변경',
      titleIcon: Icons.lock_outline,
      titleColor: widget.needsPasswordChange ? Colors.orange : Colors.blue,
      barrierDismissible: !widget.needsPasswordChange,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.needsPasswordChange)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '보안을 위해 비밀번호를 변경해주세요.',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '새 비밀번호 (6자 이상)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        if (!widget.needsPasswordChange)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('취소', style: TextStyle(color: Colors.grey[600])),
          ),
        if (!widget.needsPasswordChange) const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            if (passwordController.text.trim().length < 6) {
              await PopupUtils.showError(
                context: context,
                title: '입력 오류',
                message: '비밀번호는 6자 이상이어야 합니다.',
              );
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

              Navigator.of(context).pop();
              if (mounted) {
                await PopupUtils.showSuccess(
                  context: context,
                  title: '비밀번호 변경 완료',
                  message: '비밀번호가 성공적으로 변경되었습니다.',
                  onPressed: widget.onPasswordChanged,
                );
              }
            } on AuthException catch (error) {
              if (mounted) {
                await PopupUtils.showError(
                  context: context,
                  title: '비밀번호 변경 실패',
                  message: error.message,
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.needsPasswordChange ? Colors.orange : Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('변경'),
        ),
      ],
    );
  }

  void _editProfile() {
    final nameController = TextEditingController(text: username);
    final majorController = TextEditingController(text: major ?? '');

    PopupUtils.showCustom(
      context: context,
      title: '프로필 수정',
      titleIcon: Icons.edit,
      titleColor: Colors.blue,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '이름',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: majorController,
            decoration: const InputDecoration(
              labelText: '전공 (선택사항)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school),
              hintText: '예: 컴퓨터공학과',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('취소', style: TextStyle(color: Colors.grey[600])),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.trim().isEmpty) {
              await PopupUtils.showError(
                context: context,
                title: '입력 오류',
                message: '이름을 입력해주세요.',
              );
              return;
            }

            try {
              final user = supabase.auth.currentUser;
              if (user != null) {
                await supabase.from('profiles').upsert({
                  'id': user.id,
                  'username': nameController.text.trim(),
                  'major': majorController.text.trim().isEmpty ? null : majorController.text.trim(),
                  'updated_at': DateTime.now().toIso8601String(),
                });

                Navigator.of(context).pop();
                if (mounted) {
                  await PopupUtils.showSuccess(
                    context: context,
                    title: '프로필 업데이트 완료',
                    message: '프로필이 성공적으로 업데이트되었습니다.',
                    onPressed: _loadUserProfile,
                  );
                }
              }
            } catch (error) {
              if (mounted) {
                await PopupUtils.showError(
                  context: context,
                  title: '업데이트 실패',
                  message: '프로필 업데이트에 실패했습니다.',
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('저장'),
        ),
      ],
    );
  }

  Future<void> _backupToServer() async {
    setState(() => _isSyncing = true);
    try {
      await _userService.backupDataToSupabase();
      if (mounted) {
        await PopupUtils.showSuccess(
          context: context,
          title: '백업 완료!',
          message: '데이터가 서버에 안전하게 보관되었습니다.',
        );
      }
    } catch (e) {
      if (mounted) {
        await PopupUtils.showError(
          context: context,
          title: '백업 실패',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _restoreFromServer() async {
    setState(() => _isSyncing = true);
    try {
      await _userService.restoreDataFromSupabase();
      if (mounted) {
        await PopupUtils.showSuccess(
          context: context,
          title: '복원 완료!',
          message: '스펙 정보를 최신 상태로 업데이트했습니다.',
        );
      }
    } catch (e) {
      if (mounted) {
        await PopupUtils.showError(
          context: context,
          title: '복원 실패',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showRestoreDialog() {
    PopupUtils.showConfirmation(
      context: context,
      title: '데이터 복원 확인',
      message: '정말 복원하시겠어요?\n\n현재 휴대폰의 스펙 정보는 모두 사라지고, 서버의 데이터로 대체됩니다. 이 작업은 되돌릴 수 없습니다.',
      confirmText: '복원',
      confirmColor: Colors.orange,
      icon: Icons.warning_amber_rounded,
    ).then((confirmed) {
      if (confirmed == true) {
        _restoreFromServer();
      }
    });
  }

  void _showAppInfo() {
    showAboutDialog(
      context: context,
      applicationName: '콕콕',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.school,
          color: Theme.of(context).primaryColor,
          size: 32,
        ),
      ),
      children: [
        const Text('자격증 관리를 위한 혁신적인 모바일 애플리케이션'),
        const SizedBox(height: 16),
        const Text('📚 목표 설정과 진행 상황 추적'),
        const Text('🔍 스마트한 자격증 검색과 추천'),
        const Text('📊 개인화된 대시보드와 통계'),
        const Text('💾 안전한 데이터 백업과 복원'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('내 정보', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showAppInfo,
          ),
        ],
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
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🔒 보안을 위해 임시 비밀번호를 변경해주세요.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 사용자 프로필 카드
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
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            username.isNotEmpty ? username.substring(0, 1) : '?',
                            style: TextStyle(
                                fontSize: 24,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold),
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
                              if (major != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    major!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _editProfile,
                          icon: const Icon(Icons.edit_outlined),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 계정 관리 섹션
                _SectionHeader(title: '계정 관리'),
                _buildMenuTile(
                  icon: Icons.lock_outline,
                  title: '비밀번호 변경',
                  subtitle: '계정 보안을 위해 정기적으로 변경해주세요',
                  onTap: _changePassword,
                ),
                _buildMenuTile(
                  icon: Icons.notifications_outlined,
                  title: '알림 설정',
                  subtitle: 'D-Day 알림, 추천 알림 등을 설정해보세요',
                  onTap: () {
                    PopupUtils.showInfo(
                      context: context,
                      title: '알림 설정',
                      message: '알림 설정 기능을 준비중입니다.',
                      color: Colors.orange,
                      icon: Icons.construction,
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.logout,
                  title: '로그아웃',
                  color: Colors.red,
                  onTap: _signOut,
                ),
                const SizedBox(height: 24),

                // 데이터 관리 섹션
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
                _buildMenuTile(
                  icon: Icons.file_download_outlined,
                  title: '데이터 내보내기',
                  subtitle: '내 스펙 정보를 파일로 내보내서 백업할 수 있어요.',
                  onTap: () async {
                    try {
                      final data = await _userService.exportData();
                      if (mounted) {
                        await PopupUtils.showInfo(
                          context: context,
                          title: '데이터 내보내기 준비 완료',
                          message: '데이터를 준비했습니다. (실제 다운로드 기능은 준비중)',
                          color: Colors.blue,
                          icon: Icons.download_done,
                        );
                        debugPrint('Export data: $data');
                      }
                    } catch (e) {
                      if (mounted) {
                        await PopupUtils.showError(
                          context: context,
                          title: '내보내기 실패',
                          message: '데이터 내보내기에 실패했습니다.',
                        );
                      }
                    }
                  },
                ),

                const SizedBox(height: 24),

                // 앱 정보 섹션
                _SectionHeader(title: '앱 정보'),
                _buildMenuTile(
                  icon: Icons.help_outline,
                  title: '도움말 및 FAQ',
                  subtitle: '자주 묻는 질문과 사용법을 확인해보세요',
                  onTap: () {
                    PopupUtils.showInfo(
                      context: context,
                      title: '도움말',
                      message: '도움말 기능을 준비중입니다.',
                      color: Colors.orange,
                      icon: Icons.construction,
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.feedback_outlined,
                  title: '피드백 보내기',
                  subtitle: '개선 사항이나 버그를 신고해주세요',
                  onTap: () {
                    PopupUtils.showInfo(
                      context: context,
                      title: '피드백',
                      message: '피드백 기능을 준비중입니다.',
                      color: Colors.orange,
                      icon: Icons.construction,
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.info_outline,
                  title: '앱 정보',
                  subtitle: '버전 정보 및 개발자 정보',
                  onTap: _showAppInfo,
                ),

                // 동기화 중일 때 로딩 인디케이터 표시
                if (_isSyncing)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          '데이터를 동기화하는 중...',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? color,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? Theme.of(context).primaryColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color ?? Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: color ?? Colors.black87,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700]),
      ),
    );
  }
}