import '../models/certification.dart';
import 'certification_api_service.dart';
import 'user_certification_service.dart';

class UserProfile {
  final String? primaryCategory;
  final List<Certification> ownedCertifications;
  final List<String> interests;
  final String? major;

  UserProfile({
    this.primaryCategory,
    required this.ownedCertifications,
    this.interests = const [],
    this.major,
  });
}

class RecommendationEngine {
  final _apiService = CertificationApiService();
  final _userService = UserCertificationService();

  Future<List<Certification>> getPersonalizedRecommendations({String? userMajor}) async {
    try {
      final userProfile = await _analyzeUserProfile();

      // 기본 추천 로직
      List<Certification> recommendations = [];

      // 1. 전공 기반 추천
      if (userMajor != null) {
        final majorRecommendations = await _apiService.getRecommendedCertifications(userMajor);
        recommendations.addAll(majorRecommendations);
      }

      // 2. 소유 자격증 기반 시너지 추천
      if (userProfile.ownedCertifications.isNotEmpty) {
        final synergyRecommendations = await _getSynergyRecommendations(userProfile.ownedCertifications);
        recommendations.addAll(synergyRecommendations);
      }

      // 3. 협업 필터링 기반 추천
      final collaborativeRecommendations = await _getCollaborativeRecommendations(userProfile);
      recommendations.addAll(collaborativeRecommendations);

      // 중복 제거 및 정렬
      final uniqueRecommendations = _removeDuplicates(recommendations);
      return uniqueRecommendations.take(10).toList();

    } catch (e) {
      // 오류 발생 시 인기 자격증 반환
      return await _apiService.getPopularCertifications();
    }
  }

  Future<UserProfile> _analyzeUserProfile() async {
    try {
      await _userService.initialize();

      final ownedCertifications = _userService.ownedCertifications;
      final favoriteCertifications = _userService.favoriteCertifications;

      // 주요 카테고리 분석
      String? primaryCategory;
      if (ownedCertifications.isNotEmpty) {
        final categoryCount = <String, int>{};
        for (final cert in ownedCertifications) {
          final category = cert.category ?? '기타';
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }

        primaryCategory = categoryCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      // 관심사 분석
      final interests = favoriteCertifications
          .map((cert) => cert.category ?? '기타')
          .toSet()
          .toList();

      return UserProfile(
        primaryCategory: primaryCategory,
        ownedCertifications: ownedCertifications,
        interests: interests,
      );
    } catch (e) {
      return UserProfile(ownedCertifications: []);
    }
  }

  Future<List<Certification>> _getSynergyRecommendations(List<Certification> ownedCertifications) async {
    try {
      // 소유한 자격증과 시너지가 좋은 자격증 추천
      final recommendations = <Certification>[];

      for (final cert in ownedCertifications) {
        final category = cert.category;
        if (category != null) {
          final categoryRecommendations = await _apiService.getCertificationsByCategory(category);
          recommendations.addAll(categoryRecommendations.take(3));
        }
      }

      return recommendations;
    } catch (e) {
      return [];
    }
  }

  Future<List<Certification>> _getCollaborativeRecommendations(UserProfile profile) async {
    try {
      // 비슷한 사용자들이 선호하는 자격증 추천
      // 현재는 인기 자격증으로 대체
      return await _apiService.getPopularCertifications();
    } catch (e) {
      return [];
    }
  }

  List<Certification> _removeDuplicates(List<Certification> certifications) {
    final seen = <String>{};
    return certifications.where((cert) => seen.add(cert.jmCd)).toList();
  }

  Future<double> calculateRecommendationScore(Certification certification, UserProfile profile) async {
    double score = 0.0;

    // 카테고리 매칭 점수
    if (certification.category == profile.primaryCategory) {
      score += 0.4;
    }

    // 관심사 매칭 점수
    if (profile.interests.contains(certification.category)) {
      score += 0.3;
    }

    // 인기도 점수
    if (certification.applicants != null && certification.applicants! > 1000) {
      score += 0.2;
    }

    // 합격률 점수 (적당한 난이도)
    if (certification.passingRate != null) {
      final passingRate = certification.passingRate!;
      if (passingRate >= 30 && passingRate <= 70) {
        score += 0.1;
      }
    }

    return score;
  }
}