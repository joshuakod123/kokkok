import 'package:flutter/material.dart';
import '../models/certification.dart';
import '../services/certification_api_service.dart';
import '../services/user_certification_service.dart';
import '../widgets/certification_list_tile.dart';
import 'certification_detail_screen.dart';

class MySpecScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const MySpecScreen({super.key, this.onNavigateToTab});

  @override
  State<MySpecScreen> createState() => _MySpecScreenState();
}

class _MySpecScreenState extends State<MySpecScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _userService = UserCertificationService();

  List<Certification> _targetCertifications = [];
  List<Certification> _ownedCertifications = [];
  List<Certification> _favoriteCertifications = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await _userService.initialize();

    setState(() {
      _targetCertifications = _userService.targetCertifications;
      _ownedCertifications = _userService.ownedCertifications;
      _favoriteCertifications = _userService.favoriteCertifications;
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _removeTarget(Certification certification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('목표 제거'),
        content: Text('${certification.jmNm} 목표를 제거하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              _userService.removeTarget(certification.jmCd);
              Navigator.pop(context);
              _refreshData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${certification.jmNm} 목표가 제거되었습니다'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('제거'),
          ),
        ],
      ),
    );
  }

  void _markAsCompleted(Certification certification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('자격증 취득 완료'),
        content: Text('${certification.jmNm}을(를) 취득하셨나요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              _userService.addOwned(certification);
              Navigator.pop(context);
              _refreshData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('축하합니다! ${certification.jmNm} 취득을 기록했습니다 🎉'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }

  void _editTargetDate(Certification certification) {
    showDatePicker(
      context: context,
      initialDate: certification.targetDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    ).then((selectedDate) {
      if (selectedDate != null && mounted) {
        _userService.addTarget(certification, selectedDate);
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('목표 날짜가 수정되었습니다'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });
  }

  void _navigateToCertificationDetail(Certification certification) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificationDetailScreen(
          certification: certification,
        ),
      ),
    );
  }

  void _navigateToTab(int tabIndex) {
    // 하단 네비게이션에서 탭 변경
    widget.onNavigateToTab?.call(tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180, // 높이 줄임
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  '나의 스펙',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20, // 폰트 크기 조정
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 20,
                        bottom: 80, // 위치 조정
                        child: Icon(
                          Icons.school,
                          size: 80, // 크기 줄임
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 90, // 위치 조정
                        child: _buildStatsOverview(),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                labelStyle: const TextStyle(fontSize: 14), // 탭 텍스트 크기 조정
                tabs: [
                  Tab(
                    text: '목표 (${_targetCertifications.length})',
                    icon: const Icon(Icons.flag, size: 16), // 아이콘 크기 조정
                  ),
                  Tab(
                    text: '취득 (${_ownedCertifications.length})',
                    icon: const Icon(Icons.emoji_events, size: 16),
                  ),
                  Tab(
                    text: '관심 (${_favoriteCertifications.length})',
                    icon: const Icon(Icons.favorite, size: 16),
                  ),
                ],
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              // 빠른 액션 바 - 패딩과 크기 조정
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 패딩 조정
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showAddTargetDialog,
                        icon: const Icon(Icons.add, size: 18), // 아이콘 크기 조정
                        label: const Text('목표 추가', style: TextStyle(fontSize: 14)), // 텍스트 크기 조정
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10), // 패딩 조정
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToTab(1),
                        icon: const Icon(Icons.explore, size: 18),
                        label: const Text('자격증 찾기', style: TextStyle(fontSize: 14)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 탭뷰 내용
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTargetTab(),
                    _buildOwnedTab(),
                    _buildFavoriteTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final totalTargets = _targetCertifications.length;
    final totalOwned = _ownedCertifications.length;
    final upcomingTargets = _targetCertifications.where((cert) =>
    cert.dDay != null && cert.dDay! >= 0 && cert.dDay! <= 30
    ).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '나의 성장 현황',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12, // 폰트 크기 조정
          ),
        ),
        const SizedBox(height: 6), // 간격 조정
        Row(
          children: [
            _buildStatItem('취득', totalOwned.toString(), Icons.emoji_events),
            const SizedBox(width: 16), // 간격 조정
            _buildStatItem('목표', totalTargets.toString(), Icons.flag),
            const SizedBox(width: 16),
            _buildStatItem('임박', upcomingTargets.toString(), Icons.schedule),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: 14), // 아이콘 크기 조정
        const SizedBox(width: 3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16, // 폰트 크기 조정
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10, // 폰트 크기 조정
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetTab() {
    if (_targetCertifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.flag_outlined,
        title: '목표 자격증이 없습니다',
        subtitle: '도전하고 싶은 자격증을 추가해보세요',
        actionText: '목표 추가하기',
        onAction: _showAddTargetDialog,
      );
    }

    final sortedTargets = List<Certification>.from(_targetCertifications);
    sortedTargets.sort((a, b) {
      final aDDay = a.dDay ?? 999999;
      final bDDay = b.dDay ?? 999999;
      return aDDay.compareTo(bDDay);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedTargets.length,
      itemBuilder: (context, index) {
        final cert = sortedTargets[index];
        return _buildTargetCard(cert);
      },
    );
  }

  Widget _buildTargetCard(Certification certification) {
    final dDay = certification.dDay ?? 0;
    final isUrgent = dDay >= 0 && dDay <= 7;
    final isPassed = dDay < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUrgent ? Colors.red.withValues(alpha: 0.3) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isUrgent
              ? LinearGradient(
            colors: [Colors.red.withValues(alpha: 0.05), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isPassed
                                    ? Colors.grey
                                    : isUrgent
                                    ? Colors.red
                                    : Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                certification.jmNm,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2, // 최대 2줄로 제한
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            certification.seriesNm,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12), // 간격 추가
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? Colors.grey.withValues(alpha: 0.1)
                          : isUrgent
                          ? Colors.red.withValues(alpha: 0.1)
                          : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isPassed ? 'D+' : 'D-',
                          style: TextStyle(
                            color: isPassed
                                ? Colors.grey[600]
                                : isUrgent
                                ? Colors.red
                                : Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '${dDay.abs()}',
                          style: TextStyle(
                            color: isPassed
                                ? Colors.grey[600]
                                : isUrgent
                                ? Colors.red
                                : Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (certification.targetDate != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '목표일: ${_formatDate(certification.targetDate!)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _editTargetDate(certification),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('날짜 수정', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _markAsCompleted(certification),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('취득 완료', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _removeTarget(certification),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnedTab() {
    if (_ownedCertifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.emoji_events_outlined,
        title: '취득한 자격증이 없습니다',
        subtitle: '첫 번째 자격증 취득을 목표로 해보세요',
        actionText: '목표 설정하기',
        onAction: _showAddTargetDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ownedCertifications.length,
      itemBuilder: (context, index) {
        final cert = _ownedCertifications[index];
        return _buildOwnedCard(cert);
      },
    );
  }

  Widget _buildOwnedCard(Certification certification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.amber.withValues(alpha: 0.1),
              Colors.orange.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      certification.jmNm,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2, // 최대 2줄로 제한
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      certification.seriesNm,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '취득 완료',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.verified,
                color: Colors.green,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteTab() {
    if (_favoriteCertifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_outline,
        title: '관심 자격증이 없습니다',
        subtitle: '관심있는 자격증을 저장해보세요',
        actionText: '자격증 둘러보기',
        onAction: () => _navigateToTab(1),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteCertifications.length,
      itemBuilder: (context, index) {
        final cert = _favoriteCertifications[index];
        return CertificationListTile(
          certification: cert,
          onTap: () => _navigateToCertificationDetail(cert),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTargetDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTargetSheet(onTargetAdded: _refreshData),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

// 목표 추가 바텀시트
class AddTargetSheet extends StatefulWidget {
  final VoidCallback onTargetAdded;

  const AddTargetSheet({super.key, required this.onTargetAdded});

  @override
  State<AddTargetSheet> createState() => _AddTargetSheetState();
}

class _AddTargetSheetState extends State<AddTargetSheet> {
  final _searchController = TextEditingController();
  List<Certification> _searchResults = [];
  bool _isSearching = false;
  final _apiService = CertificationApiService();
  final _userService = UserCertificationService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        widget.onTargetAdded(); // 콜백 호출
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
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들바
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
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

          // 검색바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '자격증 이름을 검색해보세요',
                prefixIcon: const Icon(Icons.search),
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

          // 검색 결과
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(
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
                    _searchController.text.isEmpty
                        ? '자격증 이름을 입력해주세요'
                        : '검색 결과가 없습니다',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final cert = _searchResults[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}