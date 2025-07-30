import 'package:supabase_flutter/supabase_flutter.dart';

class UserJourneyReport {
  final int totalEvents;
  final Map<String, int> eventCounts;
  final DateTime startDate;
  final DateTime endDate;

  const UserJourneyReport({
    required this.totalEvents,
    required this.eventCounts,
    required this.startDate,
    required this.endDate,
  });
}

class AnalyticsService {
  final _supabase = Supabase.instance.client;

  static const Map<String, String> keyEvents = {
    'app_open': '앱 실행',
    'certification_view': '자격증 조회',
    'target_added': '목표 추가',
    'certification_achieved': '자격증 취득',
    'favorite_added': '관심 자격증 추가',
    'search_performed': '검색 수행',
  };

  Future<UserJourneyReport> generateUserJourneyReport() async {
    try {
      final events = await _getRecentUserEvents();
      final eventCounts = <String, int>{};

      for (final event in events) {
        final eventType = event['event_type'] as String? ?? 'unknown';
        eventCounts[eventType] = (eventCounts[eventType] ?? 0) + 1;
      }

      return UserJourneyReport(
        totalEvents: events.length,
        eventCounts: eventCounts,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );
    } catch (e) {
      return UserJourneyReport(
        totalEvents: 0,
        eventCounts: {},
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );
    }
  }

  Future<void> trackEvent(String eventType,
      {Map<String, dynamic>? properties}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_analytics_events').insert({
        'user_id': userId,
        'event_type': eventType,
        'properties': properties ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // 분석 이벤트 실패는 사용자 경험에 영향을 주지 않도록 조용히 처리
    }
  }

  Future<List<dynamic>> _getRecentUserEvents() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_analytics_events')
          .select('event_type, properties, created_at')
          .eq('user_id', userId)
          .gte('created_at',
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
          .order('created_at', ascending: false)
          .limit(1000);

      return response;
    } catch (e) {
      return [];
    }
  }

  Future<int> _getTotalUserCount() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .count();
      return response.count;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getActiveUserCount() async {
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final response = await _supabase
          .from('user_analytics_events')
          .select('user_id')
          .gte('created_at', weekAgo.toIso8601String())
          .count();
      return response.count;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _calculateRetentionRate() async {
    try {
      final totalUsers = await _getTotalUserCount();
      final activeUsers = await _getActiveUserCount();

      if (totalUsers == 0) return 0.0;
      return (activeUsers / totalUsers) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  Future<Duration> _getAverageSessionDuration() async {
    try {
      // 세션 데이터가 있다면 평균 계산
      // 현재는 더미 데이터 반환
      return const Duration(minutes: 15);
    } catch (e) {
      return Duration.zero;
    }
  }

  Future<Map<String, int>> _analyzeConversionFunnel() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final events = await _supabase
          .from('user_analytics_events')
          .select('event_type')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final funnel = <String, int>{};
      for (final event in events) {
        final eventType = event['event_type'] as String;
        funnel[eventType] = (funnel[eventType] ?? 0) + 1;
      }

      return funnel;
    } catch (e) {
      return {};
    }
  }
