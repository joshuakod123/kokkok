import 'package:flutter/material.dart';
import '../models/certification.dart';

class DDayCard extends StatelessWidget {
  final Certification certification;
  final VoidCallback onTap;

  const DDayCard({
    super.key,
    required this.certification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dDay = certification.dDay ?? 0;
    final isUrgent = dDay >= 0 && dDay <= 7;
    final isPassed = dDay < 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPassed
                ? [Colors.grey.shade600, Colors.grey.shade700]
                : isUrgent
                ? [Colors.red.shade600, Colors.red.shade700]
                : [Colors.deepPurple, Colors.deepPurple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isPassed
                  ? Colors.grey
                  : isUrgent
                  ? Colors.red
                  : Colors.deepPurple).withValues(alpha: 0.3),
              blurRadius: 15,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      certification.seriesNm,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    certification.jmNm,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isPassed
                            ? Icons.history
                            : dDay == 0
                            ? Icons.celebration
                            : isUrgent
                            ? Icons.warning
                            : Icons.schedule,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPassed
                            ? '${-dDay}일 지남'
                            : dDay == 0
                            ? '오늘이 시험일!'
                            : isUrgent
                            ? '$dDay일 남음 (긴급!)'
                            : '$dDay일 남음',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (certification.targetDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '목표일: ${_formatDate(certification.targetDate!)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Column(
                children: [
                  Text(
                    'D${dDay > 0 ? '-' : dDay == 0 ? '' : '+'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dDay == 0 ? 'DAY' : '${dDay.abs()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}