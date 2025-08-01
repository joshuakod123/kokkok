import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/certification.dart';
import '../services/certification_api_service.dart';
import '../services/user_certification_service.dart';
import '../utils/popup_utils.dart';

class CertificationDetailScreen extends StatefulWidget {
  final Certification certification;

  const CertificationDetailScreen({
    super.key,
    required this.certification,
  });

  @override
  State<CertificationDetailScreen> createState() => _CertificationDetailScreenState();
}

class _CertificationDetailScreenState extends State<CertificationDetailScreen> {
  final _userService = UserCertificationService();
  final _apiService = CertificationApiService();
  List<ExamSchedule> _schedules = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isTarget = false;
  bool _isOwned = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _schedules = await _apiService.getExamSchedules(widget.certification.jmCd);
      _isFavorite = _userService.isFavorite(widget.certification.jmCd);
      _isTarget = _userService.isTarget(widget.certification.jmCd);
      _isOwned = _userService.isOwned(widget.certification.jmCd);
    } catch (e) {
      debugPrint('데이터 로드 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      _userService.addFavorite(widget.certification);
      if (mounted) {
        PopupUtils.showSuccess(
          context: context,
          title: '관심 자격증 추가!',
          message: '${widget.certification.jmNm}이(가) 관심 자격증에 추가되었습니다.',
        );
      }
    } else {
      _userService.removeFavorite(widget.certification.jmCd);
      if (mounted) {
        PopupUtils.showInfo(
          context: context,
          title: '관심 자격증에서 제거',
          message: '${widget.certification.jmNm}이(가) 관심 자격증에서 제거되었습니다.',
          color: Colors.grey,
          icon: Icons.heart_broken,
        );
      }
    }
  }

  void _addToTarget() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: widget.certification.categoryColor,
            ),
          ),
          child: child!,
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null && mounted) {
        _userService.addTarget(widget.certification, selectedDate);
        setState(() {
          _isTarget = true;
        });
        PopupUtils.showSuccess(
          context: context,
          title: '목표 추가 완료!',
          message: '${widget.certification.jmNm} 목표가 추가되었습니다! 🎯',
        );
      }
    });
  }

  void _markAsOwned() {
    PopupUtils.showConfirmation(
      context: context,
      title: '자격증 취득 완료',
      message: '${widget.certification.jmNm}을(를) 취득하셨나요?',
      confirmText: '완료',
      confirmColor: Colors.green,
      icon: Icons.celebration,
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        _userService.addOwned(widget.certification);
        setState(() {
          _isOwned = true;
          _isTarget = false;
        });
        PopupUtils.showSuccess(
          context: context,
          title: '🎉 축하합니다!',
          message: '${widget.certification.jmNm} 취득을 기록했습니다! 정말 대단해요!',
        );
      }
    });
  }

  void _shareContent() {
    final content = '''
${widget.certification.jmNm}

📋 계열: ${widget.certification.seriesNm}
🏷️ 자격구분: ${widget.certification.qualClsNm}
📅 시행년도: ${widget.certification.implYy}년

${widget.certification.description}

콕콕 앱에서 더 많은 자격증 정보를 확인하세요!
    ''';

    Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      PopupUtils.showInfo(
        context: context,
        title: '공유 정보 복사 완료',
        message: '자격증 정보가 클립보드에 복사되었습니다.',
        color: Colors.blue,
        icon: Icons.content_copy,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 커스텀 앱바
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: widget.certification.categoryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.certification.jmNm,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.certification.categoryColor,
                      widget.certification.categoryColor.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 20,
                      bottom: 80,
                      child: Icon(
                        _getCategoryIcon(widget.certification.category),
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    if (_isOwned)
                      Positioned(
                        left: 20,
                        bottom: 80,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                '취득 완료',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _shareContent,
              ),
            ],
          ),

          // 상세 정보
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(50.0),
                child: CircularProgressIndicator(),
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 기본 정보
                  _buildInfoSection(),
                  const SizedBox(height: 24),

                  // 시험 일정
                  if (_schedules.isNotEmpty) ...[
                    _buildScheduleSection(),
                    const SizedBox(height: 24),
                  ],

                  // 통계 정보
                  _buildStatsSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // 하단 버튼
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: _isOwned
            ? Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, color: Colors.green),
              SizedBox(width: 8),
              Text(
                '취득 완료된 자격증입니다',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )
            : Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _toggleFavorite,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: widget.certification.categoryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isFavorite ? '관심해제' : '관심등록',
                  style: TextStyle(
                    color: widget.certification.categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isTarget ? _markAsOwned : _addToTarget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTarget ? Colors.green : widget.certification.categoryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isTarget ? '취득 완료' : '목표 추가',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '자격증 정보',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        _buildInfoRow('계열', widget.certification.seriesNm),
        _buildInfoRow('자격구분', widget.certification.qualClsNm),
        if (widget.certification.implYy.isNotEmpty)
          _buildInfoRow('시행년도', '${widget.certification.implYy}년'),
        if (widget.certification.implSeq.isNotEmpty)
          _buildInfoRow('시행회차', '제${widget.certification.implSeq}회'),

        if (widget.certification.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '설명',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.certification.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '시험 일정',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        ..._schedules.map((schedule) => _buildScheduleCard(schedule)),
      ],
    );
  }

  Widget _buildScheduleCard(ExamSchedule schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.certification.categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    schedule.examType,
                    style: TextStyle(
                      color: widget.certification.categoryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (schedule.canApply)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '접수중',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (schedule.applicationStart != null && schedule.applicationEnd != null)
              _buildScheduleRow('접수기간',
                  '${_formatDate(schedule.applicationStart!)} ~ ${_formatDate(schedule.applicationEnd!)}'),

            if (schedule.examDate != null)
              _buildScheduleRow('시험일', _formatDate(schedule.examDate!)),

            if (schedule.resultDate != null)
              _buildScheduleRow('발표일', _formatDate(schedule.resultDate!)),

            if (schedule.fee != null)
              _buildScheduleRow('응시료', '${_formatMoney(schedule.fee!)}원'),

            if (schedule.location != null)
              _buildScheduleRow('지역', schedule.location!),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '통계 정보',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            if (widget.certification.applicants != null)
              Expanded(
                child: _buildStatCard(
                  '응시자 수',
                  '${_formatNumber(widget.certification.applicants!)}명',
                  Icons.people,
                  Colors.blue,
                ),
              ),

            if (widget.certification.passingRate != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '합격률',
                  '${widget.certification.passingRate}%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ],
        ),

        if (widget.certification.difficulty != null) ...[
          const SizedBox(height: 12),
          _buildStatCard(
            '난이도',
            widget.certification.difficulty!,
            Icons.bar_chart,
            Colors.orange,
            fullWidth: true,
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color color, {
        bool fullWidth = false,
      }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: fullWidth
          ? Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      )
          : Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
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
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'it':
        return Icons.computer;
      case 'engineering':
      case '공학':
        return Icons.engineering;
      case 'business':
      case '경영':
        return Icons.business;
      case 'language':
      case '어학':
        return Icons.language;
      case 'finance':
      case '금융':
        return Icons.account_balance;
      default:
        return Icons.school;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _formatMoney(int amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}만';
    }
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  String _formatNumber(int number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}만';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}천';
    }
    return number.toString();
  }
}