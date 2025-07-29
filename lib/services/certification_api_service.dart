import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/certification.dart';

class CertificationApiService {
  // Supabase 클라이언트 인스턴스
  final _supabase = Supabase.instance.client;

  // 싱글톤 패턴
  static final CertificationApiService _instance = CertificationApiService._internal();
  factory CertificationApiService() => _instance;
  CertificationApiService._internal();

  // 국가기술자격 목록 조회 (실제 Supabase DB에서)
  Future<List<Certification>> getCertifications({
    int pageNo = 1,
    int numOfRows = 100,
    String? category,
    String? keyword,
  }) async {
    try {
      var query = _supabase
          .from('certifications')
          .select('''
            id, jm_cd, jm_nm, series_nm, qual_cls_nm, impl_yy, impl_seq,
            description, difficulty, passing_rate, applicants, category
          ''')
          .eq('is_active', true);

      // 카테고리 필터링
      if (category != null && category != '전체') {
        query = query.eq('category', category);
      }

      // 키워드 검색 (간단한 LIKE 검색 사용)
      if (keyword != null && keyword.isNotEmpty) {
        query = query.ilike('jm_nm', '%$keyword%');
      }

      // 정렬 및 페이징
      final query2 = query.order('applicants', ascending: false);

      final startIndex = (pageNo - 1) * numOfRows;
      final finalQuery = query2.range(startIndex, startIndex + numOfRows - 1);

      final response = await finalQuery as List<dynamic>;

      return response.map<Certification>((data) => _mapToCertification(data)).toList();

    } catch (e) {
      debugPrint('자격증 목록 조회 오류: $e');
      return [];
    }
  }

  // 시험 일정 조회 (실제 DB에서)
  Future<List<ExamSchedule>> getExamSchedules(String jmCd) async {
    try {
      final certificationId = await _getCertificationIdByCode(jmCd);
      if (certificationId == null) return [];

      final List<dynamic> response = await _supabase
          .from('exam_schedules')
          .select('''
            exam_type, application_start, application_end, 
            exam_date, result_date, location, fee, status
          ''')
          .eq('certification_id', certificationId)
          .order('exam_date', ascending: true);

      return response.map<ExamSchedule>((data) => ExamSchedule(
        examType: data['exam_type'] ?? '',
        applicationStart: data['application_start'] != null
            ? DateTime.parse(data['application_start']) : null,
        applicationEnd: data['application_end'] != null
            ? DateTime.parse(data['application_end']) : null,
        examDate: data['exam_date'] != null
            ? DateTime.parse(data['exam_date']) : null,
        resultDate: data['result_date'] != null
            ? DateTime.parse(data['result_date']) : null,
        location: data['location'],
        fee: data['fee'],
        status: data['status'],
      )).toList();

    } catch (e) {
      debugPrint('시험 일정 조회 오류: $e');
      return [];
    }
  }

  // 인기 자격증 조회 (응시자 수 기준)
  Future<List<Certification>> getPopularCertifications() async {
    try {
      final response = await _supabase
          .from('certifications')
          .select('''
            id, jm_cd, jm_nm, series_nm, qual_cls_nm, impl_yy, impl_seq,
            description, difficulty, passing_rate, applicants, category
          ''')
          .eq('is_active', true)
          .order('applicants', ascending: false)
          .limit(10) as List<dynamic>;

      return response.map<Certification>((data) => _mapToCertification(data)).toList();

    } catch (e) {
      debugPrint('인기 자격증 조회 오류: $e');
      return [];
    }
  }

  // 자격증 검색
  Future<List<Certification>> searchCertifications(String keyword) async {
    if (keyword.trim().isEmpty) return [];

    try {
      final response = await _supabase
          .from('certifications')
          .select('''
            id, jm_cd, jm_nm, series_nm, qual_cls_nm, impl_yy, impl_seq,
            description, difficulty, passing_rate, applicants, category
          ''')
          .eq('is_active', true)
          .ilike('jm_nm', '%$keyword%')
          .order('applicants', ascending: false)
          .limit(50) as List<dynamic>;

      return response.map<Certification>((data) => _mapToCertification(data)).toList();

    } catch (e) {
      debugPrint('자격증 검색 오류: $e');
      return [];
    }
  }

  // 카테고리별 자격증 조회
  Future<List<Certification>> getCertificationsByCategory(String category) async {
    try {
      var query = _supabase
          .from('certifications')
          .select('''
            id, jm_cd, jm_nm, series_nm, qual_cls_nm, impl_yy, impl_seq,
            description, difficulty, passing_rate, applicants, category
          ''')
          .eq('is_active', true);

      if (category != '전체') {
        query = query.eq('category', category);
      }

      final response = await query
          .order('applicants', ascending: false)
          .limit(100) as List<dynamic>;

      return response.map<Certification>((data) => _mapToCertification(data)).toList();

    } catch (e) {
      debugPrint('카테고리별 자격증 조회 오류: $e');
      return [];
    }
  }

  // 추천 자격증 (사용자 전공 기반)
  Future<List<Certification>> getRecommendedCertifications(String userProfile) async {
    try {
      // 전공별 추천 키워드 매핑
      final recommendations = <String, List<String>>{
        '컴퓨터공학과': ['정보처리기사', 'SQLD', '정보보안기사', '네트워크관리사', '리눅스마스터'],
        '컴퓨터과학과': ['정보처리기사', 'SQLD', '정보보안기사', '네트워크관리사'],
        '전기공학과': ['전기기사', '전기산업기사'],
        '기계공학과': ['기계기사', '산업안전기사'],
        '건축학과': ['건축기사', '토목기사'],
        '화학공학과': ['화학공학기사'],
        '경영학과': ['사회조사분석사', 'ERP', '재경관리사', '전산회계'],
        '회계학과': ['전산회계', '재경관리사'],
        '영어영문학과': ['TOEIC', 'TOEFL', 'IELTS'],
        '일어일문학과': ['JPT', 'JLPT'],
        '중어중문학과': ['HSK'],
        '관광학과': ['관광통역안내사', 'TOEIC'],
        '호텔경영학과': ['조리기능사', '관광통역안내사'],
        '조리학과': ['조리기능사', '제과기능사'],
        '미용학과': ['미용사'],
        '안전공학과': ['산업안전기사', '소방설비기사'],
        '소방학과': ['소방설비기사', '산업안전기사'],
      };

      final targetKeywords = recommendations[userProfile] ?? ['정보처리기사', 'TOEIC', '컴퓨터활용능력'];

      // 첫 번째 키워드로 검색 (단순화)
      final response = await _supabase
          .from('certifications')
          .select('''
            id, jm_cd, jm_nm, series_nm, qual_cls_nm, impl_yy, impl_seq,
            description, difficulty, passing_rate, applicants, category
          ''')
          .eq('is_active', true)
          .ilike('jm_nm', '%${targetKeywords.first}%')
          .order('applicants', ascending: false)
          .limit(6) as List<dynamic>;

      return response.map<Certification>((data) => _mapToCertification(data)).toList();

    } catch (e) {
      debugPrint('추천 자격증 조회 오류: $e');
      return [];
    }
  }

  // 최신 자격증 정보
  Future<List<Certification>> getRecentCertifications() async {
    try {
      final List<dynamic> response = await _supabase
          .from('certifications')
          .select('''
            id, jm_cd, jm_nm, series_nm, qual_cls_nm, impl_yy, impl_seq,
            description, difficulty, passing_rate, applicants, category
          ''')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(5);

      return response.map<Certification>((data) => _mapToCertification(data)).toList();

    } catch (e) {
      debugPrint('최신 자격증 조회 오류: $e');
      return [];
    }
  }

  // 난이도별 자격증 조회
  Future<List<Certification>> getCertificationsByDifficulty(String difficulty) async {
    try {
      final List<dynamic> response = await _supabase
          .from('certifications')
          .select('''
            id, jm_cd, jm_nm, series_nm, qual_cls_nm, impl_yy, impl_seq,
            description, difficulty, passing_rate, applicants, category
          ''')
          .eq('is_active', true)
          .eq('difficulty', difficulty)
          .order('applicants', ascending: false)
          .limit(50);

      return response.map<Certification>((data) => _mapToCertification(data)).toList();

    } catch (e) {
      debugPrint('난이도별 자격증 조회 오류: $e');
      return [];
    }
  }

  // 합격률 범위별 자격증 조회
  Future<List<Certification>> getCertificationsByPassingRate(int minRate, int maxRate) async {
    try {
      final List<dynamic> response = await _supabase
          .from('certifications')
          .select('''
            id, jm_cd, jm_nm, series_nm, qual_cls_nm, impl_yy, impl_seq,
            description, difficulty, passing_rate, applicants, category
          ''')
          .eq('is_active', true)
          .gte('passing_rate', minRate)
          .lte('passing_rate', maxRate)
          .order('applicants', ascending: false)
          .limit(50);

      return response.map<Certification>((data) => _mapToCertification(data)).toList();

    } catch (e) {
      debugPrint('합격률별 자격증 조회 오류: $e');
      return [];
    }
  }

  // 전체 자격증 수 조회
  Future<int> getTotalCertificationCount() async {
    try {
      final List<dynamic> response = await _supabase
          .from('certifications')
          .select('id')
          .eq('is_active', true);

      return response.length;
    } catch (e) {
      debugPrint('전체 자격증 수 조회 오류: $e');
      return 0;
    }
  }

  // 카테고리별 통계
  Future<Map<String, int>> getCategoryStats() async {
    try {
      final List<dynamic> response = await _supabase
          .from('certifications')
          .select('category')
          .eq('is_active', true);

      final stats = <String, int>{};
      for (final item in response) {
        final category = item['category'] as String? ?? '기타';
        stats[category] = (stats[category] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('카테고리 통계 조회 오류: $e');
      return {};
    }
  }

  // ===== 사용자별 자격증 관리 함수들 =====

  // 관심 자격증 추가
  Future<bool> addFavoriteCertification(String jmCd) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final certificationId = await _getCertificationIdByCode(jmCd);
      if (certificationId == null) return false;

      await _supabase.from('user_favorite_certifications').insert({
        'user_id': userId,
        'certification_id': certificationId,
      });

      return true;
    } catch (e) {
      debugPrint('관심 자격증 추가 오류: $e');
      return false;
    }
  }

  // 관심 자격증 제거
  Future<bool> removeFavoriteCertification(String jmCd) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final certificationId = await _getCertificationIdByCode(jmCd);
      if (certificationId == null) return false;

      await _supabase
          .from('user_favorite_certifications')
          .delete()
          .eq('user_id', userId)
          .eq('certification_id', certificationId);

      return true;
    } catch (e) {
      debugPrint('관심 자격증 제거 오류: $e');
      return false;
    }
  }

  // 사용자 관심 자격증 목록 조회
  Future<List<Certification>> getUserFavoriteCertifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final List<dynamic> response = await _supabase
          .from('user_favorite_certifications')
          .select('''
            certifications(
              id, jm_cd, jm_nm, series_nm, qual_cls_nm, impl_yy, impl_seq,
              description, difficulty, passing_rate, applicants, category
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response
          .map<Certification>((data) => _mapToCertification(data['certifications']))
          .toList();

    } catch (e) {
      debugPrint('사용자 관심 자격증 조회 오류: $e');
      return [];
    }
  }

  // 목표 자격증 추가
  Future<bool> addTargetCertification(String jmCd, DateTime targetDate) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final certificationId = await _getCertificationIdByCode(jmCd);
      if (certificationId == null) return false;

      await _supabase.from('user_target_certifications').insert({
        'user_id': userId,
        'certification_id': certificationId,
        'target_date': targetDate.toIso8601String().split('T')[0], // YYYY-MM-DD 형식
      });

      return true;
    } catch (e) {
      debugPrint('목표 자격증 추가 오류: $e');
      return false;
    }
  }

  // 목표 자격증 제거
  Future<bool> removeTargetCertification(String jmCd) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final certificationId = await _getCertificationIdByCode(jmCd);
      if (certificationId == null) return false;

      await _supabase
          .from('user_target_certifications')
          .delete()
          .eq('user_id', userId)
          .eq('certification_id', certificationId);

      return true;
    } catch (e) {
      debugPrint('목표 자격증 제거 오류: $e');
      return false;
    }
  }

  // 사용자 목표 자격증 목록 조회
  Future<List<Certification>> getUserTargetCertifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final List<dynamic> response = await _supabase
          .from('user_target_certifications')
          .select('''
            target_date,
            certifications(
              id, jm_cd, jm_nm, series_nm, qual_cls_nm, impl_yy, impl_seq,
              description, difficulty, passing_rate, applicants, category
            )
          ''')
          .eq('user_id', userId)
          .order('target_date', ascending: true);

      return response.map<Certification>((data) {
        final cert = _mapToCertification(data['certifications']);
        final targetDate = DateTime.parse(data['target_date']);
        return cert.copyWith(targetDate: targetDate);
      }).toList();

    } catch (e) {
      debugPrint('사용자 목표 자격증 조회 오류: $e');
      return [];
    }
  }

  // 취득 자격증 추가
  Future<bool> addOwnedCertification(String jmCd, {DateTime? acquiredDate, String? certificateNumber}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final certificationId = await _getCertificationIdByCode(jmCd);
      if (certificationId == null) return false;

      await _supabase.from('user_owned_certifications').insert({
        'user_id': userId,
        'certification_id': certificationId,
        'acquired_date': (acquiredDate ?? DateTime.now()).toIso8601String().split('T')[0],
        if (certificateNumber != null) 'certificate_number': certificateNumber,
      });

      // 목표 자격증에서 자동 제거
      await removeTargetCertification(jmCd);

      return true;
    } catch (e) {
      debugPrint('취득 자격증 추가 오류: $e');
      return false;
    }
  }

  // 취득 자격증 제거
  Future<bool> removeOwnedCertification(String jmCd) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final certificationId = await _getCertificationIdByCode(jmCd);
      if (certificationId == null) return false;

      await _supabase
          .from('user_owned_certifications')
          .delete()
          .eq('user_id', userId)
          .eq('certification_id', certificationId);

      return true;
    } catch (e) {
      debugPrint('취득 자격증 제거 오류: $e');
      return false;
    }
  }

  // 사용자 취득 자격증 목록 조회
  Future<List<Certification>> getUserOwnedCertifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final List<dynamic> response = await _supabase
          .from('user_owned_certifications')
          .select('''
            acquired_date, certificate_number,
            certifications(
              id, jm_cd, jm_nm, series_nm, qual_cls_nm, impl_yy, impl_seq,
              description, difficulty, passing_rate, applicants, category
            )
          ''')
          .eq('user_id', userId)
          .order('acquired_date', ascending: false);

      return response.map<Certification>((data) => _mapToCertification(data['certifications'])).toList();

    } catch (e) {
      debugPrint('사용자 취득 자격증 조회 오류: $e');
      return [];
    }
  }

  // 사용자 자격증 상태 확인 (관심/목표/취득 여부)
  Future<Map<String, bool>> getUserCertificationStatus(String jmCd) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {'isFavorite': false, 'isTarget': false, 'isOwned': false};

      final certificationId = await _getCertificationIdByCode(jmCd);
      if (certificationId == null) return {'isFavorite': false, 'isTarget': false, 'isOwned': false};

      final futures = await Future.wait([
        _supabase.from('user_favorite_certifications')
            .select('id').eq('user_id', userId).eq('certification_id', certificationId).maybeSingle(),
        _supabase.from('user_target_certifications')
            .select('id').eq('user_id', userId).eq('certification_id', certificationId).maybeSingle(),
        _supabase.from('user_owned_certifications')
            .select('id').eq('user_id', userId).eq('certification_id', certificationId).maybeSingle(),
      ]);

      return {
        'isFavorite': futures[0] != null,
        'isTarget': futures[1] != null,
        'isOwned': futures[2] != null,
      };

    } catch (e) {
      debugPrint('사용자 자격증 상태 확인 오류: $e');
      return {'isFavorite': false, 'isTarget': false, 'isOwned': false};
    }
  }

  // ===== 유틸리티 함수들 =====

  // 자격증 코드로 UUID 조회 (내부 함수)
  Future<String?> _getCertificationIdByCode(String jmCd) async {
    try {
      final response = await _supabase
          .from('certifications')
          .select('id')
          .eq('jm_cd', jmCd)
          .eq('is_active', true)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      debugPrint('자격증 ID 조회 오류: $e');
      return null;
    }
  }

  // Supabase 데이터를 Certification 객체로 변환 (내부 함수)
  Certification _mapToCertification(Map<String, dynamic> data) {
    return Certification(
      jmCd: data['jm_cd'] ?? '',
      jmNm: data['jm_nm'] ?? '',
      seriesNm: data['series_nm'] ?? '',
      qualClsNm: data['qual_cls_nm'] ?? '',
      implYy: data['impl_yy'] ?? '',
      implSeq: data['impl_seq'] ?? '',
      description: data['description'] ?? '',
      difficulty: data['difficulty'],
      passingRate: data['passing_rate'],
      applicants: data['applicants'],
      category: data['category'],
    );
  }
}