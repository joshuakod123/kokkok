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

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  String username = "사용자";
  bool _isLoading = true;
  String? _userMajor;
  Certification? _nearestTarget;
  List<Certification> _recommendations = [];
  List<Certification> _trending = [];
  List<Certification> _recentCertifications = [];

  final _apiService = CertificationApiService();
  final _userService = UserCertificationService();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _userService.initialize();
    await _loadUserInfo();
    await _loadCertificationData();
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
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  '콕콕',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black87),
                  onPressed: () {
                    widget.onNavigateToTab?.call(1);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: _isLoading
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(50.0),
                  child: CircularProgressIndicator(),
                ),
              )
                  : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeMessage(),
                    const SizedBox(height: 32),

                    _buildQuickActions(),
                    const SizedBox(height: 32),

                    if (_nearestTarget != null) ...[
                      _buildSectionTitle('나의 다음 목표',
                          subtitle: '목표를 향해 달려가세요! 🎯'),
                      const SizedBox(height: 12),
                      DDayCard(
                        certification: _nearestTarget!,
                        onTap: () => _navigateToCertificationDetail(_nearestTarget!),
                      ),
                      const SizedBox(height: 32),
                    ],

                    if (_recommendations.isNotEmpty) ...[
                      _buildSectionTitle('콕콕! 맞춤 추천',
                          subtitle: '${_userMajor ?? '당신'}에게 최적화된 자격증'),
                      const SizedBox(height: 12),
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

                    if (_trending.isNotEmpty) ...[
                      _buildSectionTitle('지금 인기 급상승! 🔥',
                          subtitle: '많은 사람들이 도전하고 있어요'),
                      const SizedBox(height: 12),
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

                    _buildSectionTitle('최신 자격증 정보',
                        subtitle: '새롭게 추가된 자격증들을 확인해보세요'),
                    const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(greetingIcon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$username님,',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '오늘은 어떤 성장을 꿈꾸시나요?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.rocket_launch,
              color: Colors.white,
              size: 32,
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
        _buildSectionTitle('빠른 실행', subtitle: '자주 사용하는 기능들'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_task,
                title: '목표 추가',
                subtitle: '새로운 도전',
                color: Theme.of(context).primaryColor,
                onTap: _showAddTargetDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.explore,
                title: '자격증 탐색',
                subtitle: '둘러보기',
                color: Colors.orange,
                onTap: () {
                  widget.onNavigateToTab?.call(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.analytics,
                title: '내 스펙',
                subtitle: '진행상황',
                color: Colors.green,
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Column(
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
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  void _showAddTargetDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTargetSheet(onTargetAdded: () {
        _refreshData();
      }),
    );
  }
}

class AddTargetSheet extends StatefulWidget {
  final VoidCallback onTargetAdded;

  const AddTargetSheet({super.key, required this.onTargetAdded});

  @override
  State<AddTargetSheet> createState() => _AddTargetSheetState();
}

class _AddTargetSheetState extends State<AddTargetSheet> {
  final _searchController = TextEditingController();
  List<Certification> _searchResults = [];
  List<Certification> _popularSuggestions = [];
  bool _isSearching = false;
  bool _isLoading = true;
  final _apiService = CertificationApiService();
  final _userService = UserCertificationService();

  @override
  void initState() {
    super.initState();
    _loadPopularSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPopularSuggestions() async {
    try {
      _popularSuggestions = await _apiService.getPopularCertifications();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('인기 자격증 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchCertifications(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _apiService.searchCertifications(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      debugPrint('검색 오류: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _addTarget(Certification certification) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null && mounted) {
        _userService.addTarget(certification, selectedDate);
        Navigator.pop(context);
        widget.onTargetAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${certification.jmNm} 목표가 추가되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  '목표 자격증 추가',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '자격증 이름을 검색해보세요',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchCertifications('');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _searchCertifications,
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _buildPopularSuggestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final cert = _searchResults[index];
        return _buildCertificationCard(cert);
      },
    );
  }

  Widget _buildPopularSuggestions() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '인기 자격증',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._popularSuggestions.take(10).map((cert) => _buildCertificationCard(cert)),
        ],
      ),
    );
  }

  Widget _buildCertificationCard(Certification cert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cert.categoryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(cert.category),
            color: cert.categoryColor,
            size: 24,
          ),
        ),
        title: Text(
          cert.jmNm,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(cert.seriesNm),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cert.categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cert.qualClsNm,
                    style: TextStyle(
                      color: cert.categoryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (cert.passingRate != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.trending_up,
                    size: 12,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${cert.passingRate}%',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _addTarget(cert),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('추가'),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'it':
        return Icons.computer;
      case '공학':
        return Icons.engineering;
      case '경영':
        return Icons.business;
      case '어학':
        return Icons.language;
      case '금융':
        return Icons.account_balance;
      case '서비스':
        return Icons.room_service;
      case '안전':
        return Icons.security;
      default:
        return Icons.school;
    }
  }
}