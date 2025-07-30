import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/certification.dart';
import '../services/certification_api_service.dart';
import '../services/user_certification_service.dart';
import '../widgets/d_day_card.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/trending_card.dart';
import '../widgets/certification_list_tile.dart';
import 'certification_detail_screen.dart';

final supabase = Supabase.instance.client;

class EnhancedHomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const EnhancedHomeScreen({super.key, this.onNavigateToTab});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with SingleTickerProviderStateMixin {
  String username = "사용자";
  bool _isLoading = true;
  String? _userMajor;
  Certification? _nearestTarget;
  List<Certification> _recommendations = [];
  List<Certification> _trending = [];
  List<Certification> _recentCertifications = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _apiService = CertificationApiService();
  final _userService = UserCertificationService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _userService.initialize();
    await _loadUserInfo();
    await _loadCertificationData();
    _animationController.forward();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        String? name = user.userMetadata?['username'];
        if (name == null || name.isEmpty) {
          final profileData = await supabase
              .from('profiles')
              .select('username, major')
              .eq('id', user.id)
              .maybeSingle();

          if (profileData != null) {
            name = profileData['username'];
            _userMajor = profileData['major'];
          }
        }

        if (name != null && name.isNotEmpty) {
          setState(() {
            username = name!;
          });
        }
      }
    } catch (error) {
      debugPrint('사용자 정보 로드 오류: $error');
    }
  }

  Future<void> _loadCertificationData() async {
    try {
      await Future.wait([
        _loadNearestTarget(),
        _loadRecommendations(),
        _loadTrendingCertifications(),
        _loadRecentCertifications(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('자격증 데이터 로드 오류: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNearestTarget() async {
    _nearestTarget = _userService.nearestTargetCertification;
  }

  Future<void> _loadRecommendations() async {
    if (_userMajor != null) {
      _recommendations = await _apiService.getRecommendedCertifications(_userMajor!);
    } else {
      _recommendations = await _apiService.getRecommendedCertifications('컴퓨터공학과');
    }
  }

  Future<void> _loadTrendingCertifications() async {
    _trending = await _apiService.getPopularCertifications();
  }

  Future<void> _loadRecentCertifications() async {
    _recentCertifications = await _apiService.getRecentCertifications();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadCertificationData();
  }

  void _navigateToCertificationDetail(Certification certification) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificationDetailScreen(certification: certification),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Theme.of(context).primaryColor,
        child: CustomScrollView(
          slivers: [
            // 커스텀 앱바
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.diamond,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '콕콕',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withValues(alpha: 0.05),
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_none, color: Colors.black87, size: 20),
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.search, color: Colors.black87, size: 20),
                  ),
                  onPressed: () {
                    widget.onNavigateToTab?.call(1);
                  },
                ),
                const SizedBox(width: 12),
              ],
            ),

            SliverToBoxAdapter(
              child: _isLoading
                  ? const SizedBox(
                height: 400,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('데이터를 불러오는 중...',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
                  : FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 환영 메시지
                      _buildWelcomeMessage(),
                      const SizedBox(height: 24),

                      // 빠른 액션 버튼들
                      _buildQuickActions(),
                      const SizedBox(height: 32),

                      // D-Day 카드
                      if (_nearestTarget != null) ...[
                        _buildSectionHeader(
                          '나의 다음 목표',
                          '목표를 향해 달려가세요! 🎯',
                          Icons.flag_outlined,
                        ),
                        const SizedBox(height: 16),
                        DDayCard(
                          certification: _nearestTarget!,
                          onTap: () => _navigateToCertificationDetail(_nearestTarget!),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // 맞춤 추천
                      if (_recommendations.isNotEmpty) ...[
                        _buildSectionHeader(
                          '콕콕! 맞춤 추천',
                          '${_userMajor ?? '당신'}에게 최적화된 자격증',
                          Icons.recommend_outlined,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 4),
                            itemCount: _recommendations.length,
                            itemBuilder: (context, index) {
                              return RecommendationCard(
                                certification: _recommendations[index],
                                onTap: () => _navigateToCertificationDetail(_recommendations[index]),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // 인기 급상승
                      if (_trending.isNotEmpty) ...[
                        _buildSectionHeader(
                          '지금 인기 급상승! 🔥',
                          '많은 사람들이 도전하고 있어요',
                          Icons.trending_up,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 4),
                            itemCount: _trending.take(5).length,
                            itemBuilder: (context, index) {
                              return TrendingCard(
                                certification: _trending[index],
                                rank: index + 1,
                                onTap: () => _navigateToCertificationDetail(_trending[index]),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // 최신 자격증 정보
                      _buildSectionHeader(
                        '최신 자격증 정보',
                        '새롭게 추가된 자격증들을 확인해보세요',
                        Icons.new_releases_outlined,
                      ),
                      const SizedBox(height: 16),
                      ..._recentCertifications.map((cert) =>
                          CertificationListTile(
                            certification: cert,
                            onTap: () => _navigateToCertificationDetail(cert),
                          )
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = '좋은 아침이에요';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 18) {
      greeting = '좋은 오후에요';
      greetingIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = '좋은 저녁이에요';
      greetingIcon = Icons.nights_stay;
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(greetingIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        greeting,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$username님,',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '오늘은 어떤 성장을\n꿈꾸시나요?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.rocket_launch,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          '빠른 실행',
          '자주 사용하는 기능들',
          Icons.flash_on_outlined,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_task,
                title: '목표 추가',
                subtitle: '새로운 도전',
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                onTap: _showAddTargetDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.explore,
                title: '자격증 탐색',
                subtitle: '둘러보기',
                gradient: const LinearGradient(
                  colors: [Colors.orange, Color(0xFFFF8A50)],
                ),
                onTap: () {
                  widget.onNavigateToTab?.call(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.assessment,
                title: '내 스펙',
                subtitle: '진행상황',
                gradient: const LinearGradient(
                  colors: [Colors.green, Color(0xFF66BB6A)],
                ),
                onTap: () {
                  widget.onNavigateToTab?.call(3);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddTargetDialog() {
    // 간단한 알림만 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('목표 추가 기능은 나의 스펙 탭에서 이용하실 수 있습니다.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: '이동',
          onPressed: () {
            widget.onNavigateToTab?.call(3);
          },
        ),
      ),
    );
  }
}