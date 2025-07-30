import 'package:flutter/foundation.dart';
import 'user_certification_service.dart';

class SmartNotificationService {
  final _userService = UserCertificationService();

  Future<void> scheduleDDayNotifications() async {
    try {
      await _userService.initialize();
      final targets = _userService.targetCertifications;

      for (final cert in targets) {
        if (cert.targetDate != null) {
          final dDay = cert.dDay;

          if (dDay != null) {
            // D-30, D-7, D-1, D-Day 알림 스케줄링
            if (dDay == 30) {
              await _scheduleNotification(
                'dday_30_${cert.jmCd}',
                'D-30 알림',
                '${cert.jmNm} 시험까지 30일 남았습니다!',
                DateTime.now(),
              );
            } else if (dDay == 7) {
              await _scheduleNotification(
                'dday_7_${cert.jmCd}',
                'D-7 알림',
                '${cert.jmNm} 시험까지 일주일 남았습니다!',
                DateTime.now(),
              );
            } else if (dDay == 1) {
              await _scheduleNotification(
                'dday_1_${cert.jmCd}',
                'D-1 알림',
                '내일은 ${cert.jmNm} 시험일입니다. 파이팅!',
                DateTime.now(),
              );
            } else if (dDay == 0) {
              await _scheduleNotification(
                'dday_0_${cert.jmCd}',
                '시험일 알림',
                '오늘은 ${cert.jmNm} 시험일입니다. 최선을 다하세요!',
                DateTime.now(),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('D-Day 알림 스케줄링 오류: $e');
    }
  }

  Future<void> scheduleMotivationalNotifications() async {
    try {
      final lastActivity = await _getLastActivityDate();
      final daysSinceLastActivity = DateTime.now().difference(lastActivity).inDays;

      // 비활성 사용자에게 동기부여 알림
      if (daysSinceLastActivity >= 3) {
        await _scheduleNotification(
          'motivation_return',
          '콕콕이 기다리고 있어요!',
          '새로운 자격증 정보가 업데이트되었습니다. 목표를 향해 다시 시작해보세요!',
          DateTime.now().add(const Duration(hours: 1)),
        );
      }

      // 주간 동기부여 알림
      await _scheduleWeeklyMotivation();

    } catch (e) {
      debugPrint('동기부여 알림 스케줄링 오류: $e');
    }
  }

  Future<void> scheduleStudyReminders() async {
    try {
      await _userService.initialize();
      final targets = _userService.targetCertifications;

      for (final cert in targets) {
        if (cert.targetDate != null && cert.dDay != null && cert.dDay! > 0) {
          // 매일 오후 7시 학습 알림
          final reminderTime = DateTime.now().copyWith(hour: 19, minute: 0, second: 0);

          await _scheduleNotification(
            'study_reminder_${cert.jmCd}',
            '학습 시간이에요!',
            '${cert.jmNm} 준비를 위한 학습 시간입니다. D-${cert.dDay}',
            reminderTime,
          );
        }
      }
    } catch (e) {
      debugPrint('학습 알림 스케줄링 오류: $e');
    }
  }

  Future<void> _scheduleWeeklyMotivation() async {
    try {
      await _userService.initialize();
      final stats = _userService.statistics;

      final motivationMessages = [
        '이번 주도 목표를 향해 꾸준히 나아가세요!',
        '작은 걸음이 큰 성과를 만듭니다. 계속 도전하세요!',
        '당신의 노력이 빛을 발할 때가 올 거예요!',
        '목표 달성까지 한 걸음씩 나아가고 있어요!',
      ];

      final randomMessage = motivationMessages[
      DateTime.now().millisecondsSinceEpoch % motivationMessages.length
      ];

      // 매주 월요일 오전 9시 동기부여 알림
      final nextMonday = _getNextMonday().copyWith(hour: 9, minute: 0);

      await _scheduleNotification(
        'weekly_motivation',
        '새로운 한 주를 시작해요!',
        '$randomMessage (취득: ${stats['totalOwned']}개, 목표: ${stats['totalTargets']}개)',
        nextMonday,
      );
    } catch (e) {
      debugPrint('주간 동기부여 알림 오류: $e');
    }
  }

  Future<void> _scheduleNotification(String id, String title, String body, DateTime scheduledTime) async {
    try {
      // 실제 알림 스케줄링 로직은 플랫폼별 구현 필요
      // 현재는 로그만 출력
      debugPrint('알림 스케줄링: $id');
      debugPrint('제목: $title');
      debugPrint('내용: $body');
      debugPrint('예정 시간: $scheduledTime');

      // 실제 구현에서는 flutter_local_notifications 패키지 사용
      // await FlutterLocalNotificationsPlugin().schedule(...)
    } catch (e) {
      debugPrint('알림 스케줄링 실패: $e');
    }
  }

  Future<DateTime> _getLastActivityDate() async {
    try {
      // 실제 구현에서는 사용자의 마지막 활동 시간을 데이터베이스에서 조회
      // 현재는 더미 데이터 반환
      return DateTime.now().subtract(const Duration(days: 2));
    } catch (e) {
      return DateTime.now().subtract(const Duration(days: 1));
    }
  }

  DateTime _getNextMonday() {
    final now = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday) % 7;
    return now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
  }

  Future<void> cancelAllNotifications() async {
    try {
      debugPrint('모든 알림 취소');
      // 실제 구현에서는 flutter_local_notifications의 cancelAll() 사용
    } catch (e) {
      debugPrint('알림 취소 실패: $e');
    }
  }

  Future<void> cancelNotification(String id) async {
    try {
      debugPrint('알림 취소: $id');
      // 실제 구현에서는 flutter_local_notifications의 cancel() 사용
    } catch (e) {
      debugPrint('알림 취소 실패: $e');
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      // 실제 구현에서는 알림 권한 상태 확인
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> requestNotificationPermission() async {
    try {
      debugPrint('알림 권한 요청');
      // 실제 구현에서는 permission_handler 패키지 사용
    } catch (e) {
      debugPrint('알림 권한 요청 실패: $e');
    }
  }
}