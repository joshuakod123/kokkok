import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'enhanced_home_screen.dart';
import 'certification_browse_screen.dart';
import 'my_spec_screen.dart';
import 'profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  bool _needsPasswordChange = false;
  bool _isCheckingPasswordStatus = true;

  // TabController를 통한 탭 변경을 위한 GlobalKey
  final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _browseNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _communityNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _specNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _profileNavigatorKey = GlobalKey<NavigatorState>();

  List<Widget> get _widgetOptions => <Widget>[
    Navigator(
      key: _homeNavigatorKey,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => EnhancedHomeScreen(
            onNavigateToTab: _navigateToTab,
          ),
        );
      },
    ),
    Navigator(
      key: _browseNavigatorKey,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => const CertificationBrowseScreen(),
        );
      },
    ),
    Navigator(
      key: _communityNavigatorKey,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  '커뮤니티',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '곧 만나요! 🚀',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
    Navigator(
      key: _specNavigatorKey,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => MySpecScreen(
            onNavigateToTab: _navigateToTab,
          ),
        );
      },
    ),
    Navigator(
      key: _profileNavigatorKey,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => ProfileScreen(
            needsPasswordChange: _needsPasswordChange,
            onPasswordChanged: _handlePasswordChanged,
          ),
        );
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfPasswordChangeIsNeeded();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handlePasswordChanged() {
    setState(() {
      _needsPasswordChange = false;
    });
  }

  // 탭 변경 함수 - 다른 화면에서 호출 가능
  void _navigateToTab(int tabIndex) {
    if (_needsPasswordChange && tabIndex != 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('비밀번호 변경을 먼저 완료해주세요.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _selectedIndex = tabIndex;
    });
    _tabController.animateTo(tabIndex);
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
          _tabController.animateTo(4);

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

  // 탭 변경 시 호출되는 함수
  void _onTabChange(int index) {
    _navigateToTab(index);
  }

  @override
  Widget build(BuildContext context) {
    // 비밀번호 상태 확인 중일 때 로딩 표시
    if (_isCheckingPasswordStatus) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.rocket_launch,
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '콕콕',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                '사용자 정보를 확인하는 중...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        physics: _needsPasswordChange ? const NeverScrollableScrollPhysics() : null,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: GNav(
              backgroundColor: Colors.white,
              color: Colors.grey[600],
              activeColor: Colors.white,
              tabBackgroundColor: _needsPasswordChange
                  ? Colors.orange
                  : Theme.of(context).primaryColor,
              gap: 8,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              selectedIndex: _selectedIndex,
              onTabChange: _onTabChange,
              tabs: [
                GButton(
                  icon: Icons.home_outlined,
                  text: '홈',
                  iconColor: _needsPasswordChange ? Colors.grey[400] : Colors.grey[600],
                  textColor: Colors.white,
                ),
                GButton(
                  icon: Icons.explore_outlined,
                  text: '탐색',
                  iconColor: _needsPasswordChange ? Colors.grey[400] : Colors.grey[600],
                  textColor: Colors.white,
                ),
                GButton(
                  icon: Icons.chat_bubble_outline,
                  text: '커뮤니티',
                  iconColor: _needsPasswordChange ? Colors.grey[400] : Colors.grey[600],
                  textColor: Colors.white,
                ),
                GButton(
                  icon: Icons.assessment_outlined,
                  text: '나의 스펙',
                  iconColor: _needsPasswordChange ? Colors.grey[400] : Colors.grey[600],
                  textColor: Colors.white,
                ),
                GButton(
                  icon: _needsPasswordChange ? Icons.lock : Icons.person_outline,
                  text: '내 정보',
                  // 비밀번호 변경이 필요한 경우 강조 표시
                  iconColor: _needsPasswordChange ? Colors.orange : Colors.grey[600],
                  textColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}