import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'enhanced_home_screen.dart';
import 'certification_browse_screen.dart';
import 'my_spec_screen.dart';
import 'profile_screen.dart';
import 'new_community_screen.dart';
import '../utils/popup_utils.dart';
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

  late AnimationController _navigationAnimationController;
  late Animation<double> _slideAnimation;

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
          builder: (context) => const NewCommunityScreen(),
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
    _navigationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _navigationAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // 시스템 상태 바 스타일 설정 - 투명하게 만들기
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfPasswordChangeIsNeeded();
    });

    _navigationAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _navigationAnimationController.dispose();
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
      _showPasswordChangeNotification();
      return;
    }

    setState(() {
      _selectedIndex = tabIndex;
    });
    _tabController.animateTo(tabIndex);
  }

  void _showPasswordChangeNotification() {
    if (!mounted) return;

    PopupUtils.showWarning(
      context: context,
      title: '비밀번호 변경 필요',
      message: '보안을 위해 비밀번호 변경을 먼저 완료해주세요.',
    );
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
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;

            PopupUtils.showWarning(
              context: context,
              title: '🔒 보안 알림',
              message: '안전을 위해 비밀번호를 변경해주세요.',
            );
          });
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
        backgroundColor: const Color(0xFFF8F9FA),
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        Theme.of(context).primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.diamond,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '콕콕',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '자격증 관리의 새로운 기준',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '사용자 정보를 확인하는 중...',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FA),
      body: TabBarView(
        controller: _tabController,
        physics: _needsPasswordChange
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        children: _widgetOptions,
      ),
      bottomNavigationBar: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: GNav(
                backgroundColor: Colors.white,
                color: _needsPasswordChange ? Colors.grey[400] : Colors.grey[600],
                activeColor: Colors.white,
                tabBackgroundGradient: _needsPasswordChange
                    ? LinearGradient(
                  colors: [Colors.orange, Colors.orange.shade600],
                )
                    : LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                gap: 10,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                selectedIndex: _selectedIndex,
                onTabChange: _onTabChange,
                tabs: [
                  GButton(
                    icon: Icons.home_rounded,
                    text: '홈',
                    iconActiveColor: Colors.white,
                    textColor: Colors.white,
                    iconSize: 22,
                  ),
                  GButton(
                    icon: Icons.explore_rounded,
                    text: '탐색',
                    iconActiveColor: Colors.white,
                    textColor: Colors.white,
                    iconSize: 22,
                  ),
                  GButton(
                    icon: Icons.people_rounded,
                    text: '커뮤니티',
                    iconActiveColor: Colors.white,
                    textColor: Colors.white,
                    iconSize: 22,
                  ),
                  GButton(
                    icon: Icons.assessment_rounded,
                    text: '나의 스펙',
                    iconActiveColor: Colors.white,
                    textColor: Colors.white,
                    iconSize: 22,
                  ),
                  GButton(
                    icon: _needsPasswordChange ? Icons.lock_rounded : Icons.person_rounded,
                    text: '내 정보',
                    iconActiveColor: Colors.white,
                    textColor: Colors.white,
                    iconSize: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}