import 'package:flutter/material.dart';
import '../models/certification.dart';
import '../services/user_certification_service.dart';

class CertificationListTile extends StatefulWidget {
  final Certification certification;
  final VoidCallback onTap;
  final bool showFavoriteButton;

  const CertificationListTile({
    super.key,
    required this.certification,
    required this.onTap,
    this.showFavoriteButton = true,
  });

  @override
  State<CertificationListTile> createState() => _CertificationListTileState();
}

class _CertificationListTileState extends State<CertificationListTile> {
  final _userService = UserCertificationService();
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCertificationStatus();
  }

  // Supabase에서 실시간 상태 확인
  Future<void> _loadCertificationStatus() async {
    try {
      final status = await _userService.getCertificationStatus(widget.certification.jmCd);
      if (mounted) {
        setState(() {
          _isFavorite = status['isFavorite'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('자격증 상태 로드 오류: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFavorite) {
        await _userService.removeFavorite(widget.certification.jmCd);
        if (mounted) {
          setState(() {
            _isFavorite = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('관심 자격증에서 제거되었습니다'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await _userService.addFavorite(widget.certification);
        if (mounted) {
          setState(() {
            _isFavorite = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('관심 자격증에 추가되었습니다'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('관심 자격증 토글 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: widget.certification.categoryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(widget.certification.category),
            color: widget.certification.categoryColor,
            size: 24,
          ),
        ),
        title: Text(
          widget.certification.jmNm,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              widget.certification.seriesNm,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.certification.categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.certification.qualClsNm,
                    style: TextStyle(
                      color: widget.certification.categoryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.certification.implYy.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${widget.certification.implYy}년',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
                if (widget.certification.passingRate != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.trending_up,
                    size: 12,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${widget.certification.passingRate}%',
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
        trailing: widget.showFavoriteButton
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            )
                : IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.grey,
                size: 20,
              ),
              onPressed: _toggleFavorite,
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey[400],
            ),
          ],
        )
            : Icon(
          Icons.arrow_forward_ios,
          size: 12,
          color: Colors.grey[400],
        ),
        onTap: widget.onTap,
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
      case '서비스':
        return Icons.room_service;
      case '안전':
        return Icons.security;
      default:
        return Icons.school;
    }
  }
}