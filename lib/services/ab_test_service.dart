// lib/services/ab_test_service.dart (Fixed unused import)
import 'package:flutter/foundation.dart';

class ABTest {
  final String id;
  final String name;
  final List<String> variants;
  final List<double> trafficSplit;
  final String successMetric;

  const ABTest({
    required this.id,
    required this.name,
    required this.variants,
    required this.trafficSplit,
    required this.successMetric,
  });
}

class ABTestService {
  static const Map<String, ABTest> activeTests = {
    'onboarding_flow_v2': ABTest(
      id: 'onboarding_flow_v2',
      name: '온보딩 플로우 개선',
      variants: ['control', 'simplified', 'gamified'],
      trafficSplit: [0.4, 0.3, 0.3],
      successMetric: 'first_target_added',
    ),
    'home_layout_test': ABTest(
      id: 'home_layout_test',
      name: '홈 화면 레이아웃 테스트',
      variants: ['original', 'card_based', 'list_based'],
      trafficSplit: [0.33, 0.33, 0.34],
      successMetric: 'daily_active_time',
    ),
    'recommendation_algorithm': ABTest(
      id: 'recommendation_algorithm',
      name: '추천 알고리즘 개선',
      variants: ['popularity', 'collaborative', 'hybrid'],
      trafficSplit: [0.3, 0.3, 0.4],
      successMetric: 'recommendation_click_rate',
    ),
  };

  Future<String> getVariantForUser(String testId, String userId) async {
    final test = activeTests[testId];
    if (test == null) return 'control';

    final hash = _hashString('$testId-$userId');
    final bucket = hash % 100;

    double cumulative = 0;
    for (int i = 0; i < test.variants.length; i++) {
      cumulative += test.trafficSplit[i] * 100;
      if (bucket < cumulative) {
        await _logTestAssignment(testId, userId, test.variants[i]);
        return test.variants[i];
      }
    }
    return test.variants.first;
  }

  Future<void> trackConversion(String testId, String userId, String variant) async {
    try {
      debugPrint('A/B Test Conversion: Test($testId), User($userId), Variant($variant)');
      // 실제 구현에서는 분석 서비스에 변환 이벤트 전송
    } catch (e) {
      debugPrint('A/B Test conversion tracking error: $e');
    }
  }

  Future<Map<String, dynamic>> getTestResults(String testId) async {
    try {
      final test = activeTests[testId];
      if (test == null) return {};

      // 실제 구현에서는 분석 데이터에서 결과 조회
      return {
        'test_id': testId,
        'variants': test.variants,
        'sample_sizes': [150, 145, 155], // 예시 데이터
        'conversion_rates': [0.12, 0.15, 0.18], // 예시 데이터
        'statistical_significance': 0.95,
        'winner': test.variants[2], // 예시로 마지막 variant가 승리
      };
    } catch (e) {
      debugPrint('A/B Test results error: $e');
      return {};
    }
  }

  int _hashString(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = (hash << 5) - hash + input.codeUnitAt(i);
      hash |= 0; // 32bit integer
    }
    return hash.abs();
  }

  Future<void> _logTestAssignment(String testId, String userId, String variant) async {
    debugPrint('A/B Test: User($userId) assigned to Variant($variant) for Test($testId)');
    // 실제 구현에서는 분석 서비스에 할당 이벤트 전송
  }

  // 현재 활성 테스트 목록 조회
  List<ABTest> getActiveTests() {
    return activeTests.values.toList();
  }

  // 특정 사용자의 모든 테스트 variant 조회
  Future<Map<String, String>> getAllVariantsForUser(String userId) async {
    final variants = <String, String>{};

    for (final testId in activeTests.keys) {
      variants[testId] = await getVariantForUser(testId, userId);
    }

    return variants;
  }
}