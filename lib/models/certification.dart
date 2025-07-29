import 'package:flutter/material.dart';

// ExamSchedule 클래스 정의
class ExamSchedule {
  final String examType; // 필기/실기
  final DateTime? applicationStart; // 접수 시작일
  final DateTime? applicationEnd; // 접수 마감일
  final DateTime? examDate; // 시험일
  final DateTime? resultDate; // 합격 발표일
  final String? location; // 시험 지역
  final int? fee; // 응시료
  final String? status; // 접수상태

  const ExamSchedule({
    required this.examType,
    this.applicationStart,
    this.applicationEnd,
    this.examDate,
    this.resultDate,
    this.location,
    this.fee,
    this.status,
  });

  factory ExamSchedule.fromJson(Map<String, dynamic> json) {
    return ExamSchedule(
      examType: json['examType'] ?? '',
      applicationStart: json['applicationStart'] != null
          ? DateTime.parse(json['applicationStart'])
          : null,
      applicationEnd: json['applicationEnd'] != null
          ? DateTime.parse(json['applicationEnd'])
          : null,
      examDate: json['examDate'] != null
          ? DateTime.parse(json['examDate'])
          : null,
      resultDate: json['resultDate'] != null
          ? DateTime.parse(json['resultDate'])
          : null,
      location: json['location'],
      fee: json['fee'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'examType': examType,
      'applicationStart': applicationStart?.toIso8601String(),
      'applicationEnd': applicationEnd?.toIso8601String(),
      'examDate': examDate?.toIso8601String(),
      'resultDate': resultDate?.toIso8601String(),
      'location': location,
      'fee': fee,
      'status': status,
    };
  }

  // 접수 가능 여부 확인
  bool get canApply {
    final now = DateTime.now();
    return applicationStart != null &&
        applicationEnd != null &&
        now.isAfter(applicationStart!) &&
        now.isBefore(applicationEnd!);
  }

  // 접수까지 남은 일수
  int? get daysUntilApplication {
    if (applicationStart == null) return null;
    final now = DateTime.now();
    if (now.isAfter(applicationStart!)) return null;
    return applicationStart!.difference(now).inDays;
  }
}

// Certification 클래스 정의
class Certification {
  final String jmCd; // 종목코드
  final String jmNm; // 종목명
  final String seriesNm; // 계열명
  final String qualClsNm; // 자격구분명
  final String implYy; // 시행년도
  final String implSeq; // 시행회차
  final String description; // 설명
  final String? difficulty; // 난이도
  final List<ExamSchedule>? schedules; // 시험일정
  final int? passingRate; // 합격률
  final int? applicants; // 응시자 수
  final String? category; // 카테고리
  final bool isFavorite; // 관심 자격증 여부
  final DateTime? targetDate; // 목표 응시일

  const Certification({
    required this.jmCd,
    required this.jmNm,
    required this.seriesNm,
    required this.qualClsNm,
    required this.implYy,
    required this.implSeq,
    required this.description,
    this.difficulty,
    this.schedules,
    this.passingRate,
    this.applicants,
    this.category,
    this.isFavorite = false,
    this.targetDate,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      jmCd: json['jmCd'] ?? '',
      jmNm: json['jmNm'] ?? '',
      seriesNm: json['seriesNm'] ?? '',
      qualClsNm: json['qualClsNm'] ?? '',
      implYy: json['implYy'] ?? '',
      implSeq: json['implSeq'] ?? '',
      description: json['description'] ?? '',
      difficulty: json['difficulty'],
      schedules: json['schedules'] != null
          ? (json['schedules'] as List)
          .map((e) => ExamSchedule.fromJson(e))
          .toList()
          : null,
      passingRate: json['passingRate'],
      applicants: json['applicants'],
      category: json['category'],
      isFavorite: json['isFavorite'] ?? false,
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jmCd': jmCd,
      'jmNm': jmNm,
      'seriesNm': seriesNm,
      'qualClsNm': qualClsNm,
      'implYy': implYy,
      'implSeq': implSeq,
      'description': description,
      'difficulty': difficulty,
      'schedules': schedules?.map((e) => e.toJson()).toList(),
      'passingRate': passingRate,
      'applicants': applicants,
      'category': category,
      'isFavorite': isFavorite,
      'targetDate': targetDate?.toIso8601String(),
    };
  }

  // D-Day 계산
  int? get dDay {
    if (targetDate == null) return null;
    final now = DateTime.now();
    final target = DateTime(targetDate!.year, targetDate!.month, targetDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    return target.difference(today).inDays;
  }

  // 자격증 카테고리별 색상
  Color get categoryColor {
    switch (category?.toLowerCase()) {
      case 'it':
        return Colors.blue;
      case 'engineering':
        return Colors.orange;
      case 'business':
        return Colors.green;
      case 'language':
        return Colors.purple;
      case 'finance':
        return Colors.teal;
      case '공학':
        return Colors.orange;
      case '경영':
        return Colors.green;
      case '어학':
        return Colors.purple;
      case '금융':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Certification copyWith({
    String? jmCd,
    String? jmNm,
    String? seriesNm,
    String? qualClsNm,
    String? implYy,
    String? implSeq,
    String? description,
    String? difficulty,
    List<ExamSchedule>? schedules,
    int? passingRate,
    int? applicants,
    String? category,
    bool? isFavorite,
    DateTime? targetDate,
  }) {
    return Certification(
      jmCd: jmCd ?? this.jmCd,
      jmNm: jmNm ?? this.jmNm,
      seriesNm: seriesNm ?? this.seriesNm,
      qualClsNm: qualClsNm ?? this.qualClsNm,
      implYy: implYy ?? this.implYy,
      implSeq: implSeq ?? this.implSeq,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      schedules: schedules ?? this.schedules,
      passingRate: passingRate ?? this.passingRate,
      applicants: applicants ?? this.applicants,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      targetDate: targetDate ?? this.targetDate,
    );
  }
}