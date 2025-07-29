// lib/services/ad_service.dart
import 'package:flutter/material.dart';

class AdService {
  Widget buildNativeAd({
    required String placement,
    required BuildContext context,
  }) {
    // 실제 광고 SDK 연동 전의 UI 예시
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '추천',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'AD',
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 광고 내용 (예시)
        ],
      ),
    );
  }

  bool shouldShowAd(String placement) {
    final lastAdShown = _getLastAdTime(placement);
    const cooldownPeriod = Duration(minutes: 30);
    return DateTime.now().difference(lastAdShown) > cooldownPeriod;
  }

  // 실제 구현 시 SharedPreferences 등을 사용하여 마지막 광고 표시 시간을 저장해야 합니다.
  DateTime _getLastAdTime(String placement) {
    return DateTime.now().subtract(const Duration(hours: 1));
  }
}