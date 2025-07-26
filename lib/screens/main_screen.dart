import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:kokkok/screens/home_screen.dart';
import 'package:kokkok/screens/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _pageController = PageController(initialPage: 0);
  int _selectedIndex = 0;
  bool _needsPasswordChange = false;
  bool _isCheckingPasswordStatus = true;

  List<Widget> get _widgetOptions => <Widget>[
    const HomeScreen(),
    const Center(child: Text('전체보기', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
    const Center(child: Text('커뮤니티', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
    const Center(child: Text('나의 스펙', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
    ProfileScreen(
      needsPasswordChange: _needsPasswordChange,
      onPasswordChanged: _handlePasswordChanged,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfPasswordChangeIsNeeded();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePasswordChanged() {
    setState(() {
      _needsPasswordChange = false;
    });
  }

  Future<void> _checkIfPasswordChangeIsNeeded() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('profiles')
          .select('force_password_change')
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        final needsChange = data['force_password_change'] as bool? ?? false;

        if (needsChange) {
          setState(() {
            _needsPasswordChange = true;
            _selectedIndex = 4; // 내 정보 탭으로 이동
            _isCheckingPasswordStatus = false;
          });
          // 강제로 내 정보 탭으로 이동
          _pageController.jumpToPage(4);

          // 사용자에게 알림 표시
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔒 보안을 위해 비밀번호를 변경해주세요.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          setState(() {
            _isCheckingPasswordStatus = false;
          });
        }
      } else {
        setState(() {
          _isCheckingPasswordStatus = false;
        });
      }
    } catch (error) {
      debugPrint('Error checking password change status: $error');
      setState(() {
        _isCheckingPasswordStatus = false;
      });
    }
  }

  // 비밀번호 변경이 필요한 경우 다른 탭으로 이동 방지
  void _onTabChange(int index) {
    if (_needsPasswordChange && index != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호 변경을 먼저 완료해주세요.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    // 비밀번호 상태 확인 중일 때 로딩 표시
    if (_isCheckingPasswordStatus) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('로딩 중...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          // 비밀번호 변경이 필요한 경우 다른 페이지로 스와이프 방지
          if (_needsPasswordChange && index != 4) {
            _pageController.jumpToPage(4);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('비밀번호 변경을 먼저 완료해주세요.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF1F1F1F),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            child: GNav(
              backgroundColor: const Color(0xFF1F1F1F),
              color: Colors.white,
              activeColor: Colors.white,
              tabBackgroundColor: _needsPasswordChange
                  ? Colors.orange.withOpacity(0.8)  // 비밀번호 변경 필요 시 주황색
                  : Theme.of(context).primaryColor,
              gap: 8,
              padding: const EdgeInsets.all(16),
              selectedIndex: _selectedIndex,
              onTabChange: _onTabChange,
              tabs: [
                GButton(
                  icon: Icons.home_outlined,
                  text: '홈',
                  // 비밀번호 변경이 필요한 경우 탭 비활성화 표시
                  iconColor: _needsPasswordChange ? Colors.grey : Colors.white,
                  textColor: _needsPasswordChange ? Colors.grey : Colors.white,
                ),
                GButton(
                  icon: Icons.search,
                  text: '전체보기',
                  iconColor: _needsPasswordChange ? Colors.grey : Colors.white,
                  textColor: _needsPasswordChange ? Colors.grey : Colors.white,
                ),
                GButton(
                  icon: Icons.chat_bubble_outline,
                  text: '커뮤니티',
                  iconColor: _needsPasswordChange ? Colors.grey : Colors.white,
                  textColor: _needsPasswordChange ? Colors.grey : Colors.white,
                ),
                GButton(
                  icon: Icons.bookmark_border,
                  text: '나의 스펙',
                  iconColor: _needsPasswordChange ? Colors.grey : Colors.white,
                  textColor: _needsPasswordChange ? Colors.grey : Colors.white,
                ),
                GButton(
                  icon: _needsPasswordChange ? Icons.lock : Icons.person_outline,
                  text: '내 정보',
                  // 비밀번호 변경이 필요한 경우 강조 표시
                  iconColor: _needsPasswordChange ? Colors.orange : Colors.white,
                  textColor: _needsPasswordChange ? Colors.orange : Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}