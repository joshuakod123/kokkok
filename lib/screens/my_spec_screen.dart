import 'package:flutter/material.dart';
import '../models/certification.dart';
import '../services/certification_api_service.dart';
import '../services/user_certification_service.dart';
import '../widgets/certification_list_tile.dart';
import '../utils/popup_utils.dart';
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
    PopupUtils.showConfirmation(
      context: context,
      title: '목표 제거 확인',
      message: '${certification.jmNm} 목표를 제거하시겠습니까?',
      confirmText: '제거',
      confirmColor: Colors.red,
      icon: Icons.delete_outline,
    ).then((confirmed) {
      if (confirmed == true) {
        _userService.removeTarget(certification.jmCd);
        _refreshData();
        if (mounted) {
          PopupUtils.showInfo(
            context: context,
            title: '목표 제거 완료',
            message: '${certification.jmNm} 목표가 제거되었습니다.',
            color: Colors.grey,
            icon: Icons.remove_circle_outline,
          );
        }
      }
    });
  }

  void _markAsCompleted(Certification certification) {
    PopupUtils.showConfirmation(
      context: context,
      title: '🎉 축하합니다!',
      message: '${certification.jmNm}을(를) 취득하셨나요?',
      confirmText: '완료',
      confirmColor: Colors.green,
      icon: Icons.celebration,
    ).then((confirmed) {
      if (confirmed == true) {
        _userService.addOwned(certification);
        _refreshData();
        if (mounted) {
          PopupUtils.showSuccess(
            context: context,
            title: '🎉 축하합니다!',
            message: '${certification.jmNm} 취득을 기록했습니다! 정말 대단해요!',
          );
        }
      }
    });
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
        if (mounted) {
          PopupUtils.showSuccess(
            context: context,
            title: '목표 날짜 수정 완료',
            message: '목표 날짜가 성공적으로 수정되었습니다.',
          );
        }
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
    widget.onNavigateToTab?.call(tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 고정된 헤더 영역
            Container(
              width: double.infinity,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 헤더
                    SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withAlpha(204),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.military_tech,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '나의 스펙',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '목표를 달성해 나가세요',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 통계 카드
                    SizedBox(
                      height: 80,
                      child: _buildStatsCard(),
                    ),

                    const SizedBox(height: 20),

                    // 빠른 액션 버튼들
                    SizedBox(
                      height: 50,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.add_task,
                              title: '목표 추가',
                              color: Theme.of(context).primaryColor,
                              onTap: _showAddTargetDialog,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.explore,
                              title: '자격증 찾기',
                              color: Colors.orange,
                              onTap: () => _navigateToTab(1),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 탭바
                    SizedBox(
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[600],
                          indicator: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: [
                            Tab(text: '목표 (${_targetCertifications.length})'),
                            Tab(text: '취득 (${_ownedCertifications.length})'),
                            Tab(text: '관심 (${_favoriteCertifications.length})'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 탭뷰 내용
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                onRefresh: _refreshData,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTargetTab(),
                    _buildOwnedTab(),
                    _buildFavoriteTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalTargets = _targetCertifications.length;
    final totalOwned = _ownedCertifications.length;
    final upcomingTargets = _targetCertifications
        .where((cert) => cert.dDay != null && cert.dDay! >= 0 && cert.dDay! <= 30)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withAlpha(25),
            Theme.of(context).primaryColor.withAlpha(13),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withAlpha(51),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('취득', totalOwned.toString(), Icons.emoji_events, Colors.amber),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey[300],
          ),
          _buildStatItem('목표', totalTargets.toString(), Icons.flag, Colors.blue),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey[300],
          ),
          _buildStatItem('임박', upcomingTargets.toString(), Icons.schedule, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withAlpha(25),
              color.withAlpha(13),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withAlpha(51),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
      ),
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

    return Container(
      color: const Color(0xFFF8F9FA),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedTargets.length,
        itemBuilder: (context, index) {
          final cert = sortedTargets[index];
          return _buildTargetCard(cert);
        },
      ),
    );
  }

  Widget _buildTargetCard(Certification certification) {
    final dDay = certification.dDay ?? 0;
    final isUrgent = dDay >= 0 && dDay <= 7;
    final isPassed = dDay < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? Colors.red.withAlpha(77)
              : isPassed
              ? Colors.grey.withAlpha(51)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? Colors.red.withAlpha(25)
                : Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    certification.jmNm,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPassed
                          ? [Colors.grey.withAlpha(25), Colors.grey.withAlpha(13)]
                          : isUrgent
                          ? [Colors.red.withAlpha(38), Colors.red.withAlpha(25)]
                          : [
                        Theme.of(context).primaryColor.withAlpha(38),
                        Theme.of(context).primaryColor.withAlpha(25)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPassed ? 'D+${dDay.abs()}' : 'D-${dDay.abs()}',
                    style: TextStyle(
                      color: isPassed
                          ? Colors.grey[600]
                          : isUrgent
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              certification.seriesNm,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (certification.targetDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withAlpha(51)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '목표일: ${_formatDate(certification.targetDate!)}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
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
                      side: BorderSide(color: Colors.grey.withAlpha(77)),
                    ),
                    child: const Text('날짜수정', style: TextStyle(fontSize: 12)),
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
                      elevation: 1,
                    ),
                    child: const Text('취득완료', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeTarget(certification),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withAlpha(25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                ),
              ],
            ),
          ],
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

    return Container(
      color: const Color(0xFFF8F9FA),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ownedCertifications.length,
        itemBuilder: (context, index) {
          final cert = _ownedCertifications[index];
          return _buildOwnedCard(cert);
        },
      ),
    );
  }

  Widget _buildOwnedCard(Certification certification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withAlpha(25),
            Colors.orange.withAlpha(13),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withAlpha(77),
                    Colors.amber.withAlpha(51),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.amber,
                size: 24,
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
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    certification.seriesNm,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '취득 완료',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.star,
                color: Colors.amber,
                size: 20,
              ),
            ),
          ],
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

    return Container(
      color: const Color(0xFFF8F9FA),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteCertifications.length,
        itemBuilder: (context, index) {
          final cert = _favoriteCertifications[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: CertificationListTile(
              certification: cert,
              onTap: () => _navigateToCertificationDetail(cert),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withAlpha(25),
                      Theme.of(context).primaryColor.withAlpha(13),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: Theme.of(context).primaryColor.withAlpha(178),
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
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _addTarget(Certification certification) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    ).then((selectedDate) {
      if (selectedDate != null && mounted) {
        _userService.addTarget(certification, selectedDate);
        Navigator.pop(context);
        widget.onTargetAdded();
        if (mounted) {
          PopupUtils.showSuccess(
            context: context,
            title: '목표 추가 완료!',
            message: '${certification.jmNm} 목표가 추가되었습니다! 🎯',
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들바
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 32,
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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_task,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '목표 자격증 추가',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),

          // 검색바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withAlpha(51)),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '자격증 이름을 검색해보세요',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[500], size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _searchCertifications('');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: _searchCertifications,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 검색 결과
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      _searchController.text.isEmpty
                          ? Icons.search
                          : Icons.search_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? '자격증 이름을 입력해주세요'
                        : '검색 결과가 없습니다',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_searchController.text.isEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '예: 정보처리기사, SQLD, 토익 등',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final cert = _searchResults[index];
                return _buildCertificationCard(cert);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationCard(Certification cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(38)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cert.categoryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCategoryIcon(cert.category),
                color: cert.categoryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cert.jmNm,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cert.seriesNm,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cert.categoryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cert.qualClsNm,
                          style: TextStyle(
                            color: cert.categoryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (cert.passingRate != null) ...[
                        const SizedBox(width: 6),
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
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _addTarget(cert),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 1,
                minimumSize: const Size(60, 32),
              ),
              child: const Text(
                '추가',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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