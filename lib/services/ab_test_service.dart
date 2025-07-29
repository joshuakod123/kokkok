// lib/services/ab_test_service.dart
import 'dart:convert';
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
  }
}