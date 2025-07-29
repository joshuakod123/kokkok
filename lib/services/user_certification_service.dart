// lib/services/user_certification_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/certification.dart';
import 'certification_api_service.dart';

class UserCertificationService {
  static final UserCertificationService _instance = UserCertificationService._internal();
  factory UserCertificationService() => _instance;
  UserCertificationService._internal();

  final _apiService = CertificationApiService();
  final _supabase = Supabase.instance.client;

  // 캐시된 데이터 (성능 최적화용)
  List<Certification> _favoriteCertifications = [];
  List<Certification> _targetCertifications = [];
  List<Certification> _ownedCertifications = [];

  bool _isInitialized = false;

  // 관심 자격증 관리
  List<Certification> get favoriteCertifications => List.unmodifiable(_favoriteCertifications);

  Future<void> addFavorite(Certification certification) async {
    try {
      final success = await _apiService.addFavoriteCertification(certification.jmCd);
      if (success) {
        if (!_favoriteCertifications.any((c) => c.jmCd == certification.jmCd)) {
          _favoriteCertifications.add(certification.copyWith(isFavorite: true));
        }
      }
    } catch (e) {
      debugPrint('관심 자격증 추가 오류: $e');
      rethrow;
    }
  }

  Future<void> removeFavorite(String jmCd) async {
    try {
      final success = await _apiService.removeFavoriteCertification(jmCd);
      if (success) {
        _favoriteCertifications.removeWhere((c) => c.jmCd == jmCd);
      }
    } catch (e) {
      debugPrint('관심 자격증 제거 오류: $e');
      rethrow;
    }
  }

  bool isFavorite(String jmCd) {
    return _favoriteCertifications.any((c) => c.jmCd == jmCd);
  }

  // 목표 자격증 관리
  List<Certification> get targetCertifications => List.unmodifiable(_targetCertifications);

  Future<void> addTarget(Certification certification, DateTime targetDate) async {
    try {
      final success = await _apiService.addTargetCertification(certification.jmCd, targetDate);
      if (success) {
        final targetCert = certification.copyWith(targetDate: targetDate);
        final existingIndex = _targetCertifications.indexWhere((c) => c.jmCd == certification.jmCd);
        if (existingIndex != -1) {
          _targetCertifications[existingIndex] = targetCert;
        } else {
          _targetCertifications.add(targetCert);
        }
      }
    } catch (e) {
      debugPrint('목표 자격증 추가 오류: $e');
      rethrow;
    }
  }

  Future<void> removeTarget(String jmCd) async {
    try {
      final success = await _apiService.removeTargetCertification(jmCd);
      if (success) {
        _targetCertifications.removeWhere((c) => c.jmCd == jmCd);
      }
    } catch (e) {
      debugPrint('목표 자격증 제거 오류: $e');
      rethrow;
    }
  }

  bool isTarget(String jmCd) {
    return _targetCertifications.any((c) => c.jmCd == jmCd);
  }

  // 취득한 자격증 관리
  List<Certification> get ownedCertifications => List.unmodifiable(_ownedCertifications);

  Future<void> addOwned(Certification certification, {DateTime? acquiredDate, String? certificateNumber}) async {
    try {
      final success = await _apiService.addOwnedCertification(
          certification.jmCd,
          acquiredDate: acquiredDate,
          certificateNumber: certificateNumber
      );

      if (success) {
        if (!_ownedCertifications.any((c) => c.jmCd == certification.jmCd)) {
          _ownedCertifications.add(certification);
        }
        _targetCertifications.removeWhere((c) => c.jmCd == certification.jmCd);
      }
    } catch (e) {
      debugPrint('취득 자격증 추가 오류: $e');
      rethrow;
    }
  }

  Future<void> removeOwned(String jmCd) async {
    try {
      final success = await _apiService.removeOwnedCertification(jmCd);
      if (success) {
        _ownedCertifications.removeWhere((c) => c.jmCd == jmCd);
      }
    } catch (e) {
      debugPrint('취득 자격증 제거 오류: $e');
      rethrow;
    }
  }

  bool isOwned(String jmCd) {
    return _ownedCertifications.any((c) => c.jmCd == jmCd);
  }

  Certification? get nearestTargetCertification {
    if (_targetCertifications.isEmpty) return null;
    final validTargets = _targetCertifications.where((cert) => cert.targetDate != null).toList();
    if (validTargets.isEmpty) return null;
    validTargets.sort((a, b) => (a.dDay ?? 999999).compareTo(b.dDay ?? 999999));
    return validTargets.first;
  }

  Map<String, int> get statistics {
    final upcomingTargets = _targetCertifications.where((cert) => cert.dDay != null && cert.dDay! >= 0).length;
    return {
      'totalOwned': _ownedCertifications.length,
      'totalTargets': _targetCertifications.length,
      'upcomingTargets': upcomingTargets,
      'totalFavorites': _favoriteCertifications.length,
    };
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final futures = await Future.wait([
        _apiService.getUserFavoriteCertifications(),
        _apiService.getUserTargetCertifications(),
        _apiService.getUserOwnedCertifications(),
      ]);
      _favoriteCertifications = futures[0];
      _targetCertifications = futures[1];
      _ownedCertifications = futures[2];
      _isInitialized = true;
    } catch (e) {
      debugPrint('사용자 자격증 데이터 초기화 오류: $e');
    }
  }

  Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }

  Future<Map<String, bool>> getCertificationStatus(String jmCd) async {
    try {
      return await _apiService.getUserCertificationStatus(jmCd);
    } catch (e) {
      debugPrint('자격증 상태 확인 오류: $e');
      return {'isFavorite': false, 'isTarget': false, 'isOwned': false};
    }
  }

  void clearCache() {
    _favoriteCertifications.clear();
    _targetCertifications.clear();
    _ownedCertifications.clear();
    _isInitialized = false;
  }

  Future<Map<String, dynamic>> exportData() async {
    await initialize();
    return {
      'favorites': _favoriteCertifications.map((cert) => cert.toJson()).toList(),
      'targets': _targetCertifications.map((cert) => cert.toJson()).toList(),
      'owned': _ownedCertifications.map((cert) => cert.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // --- 🚨 여기에 백업 및 복원 함수 추가 ---

  Future<void> backupDataToSupabase() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    try {
      final dataToBackup = await exportData(); // 현재 캐시된 모든 데이터를 JSON으로 변환
      await _supabase.from('user_data_backups').upsert({
        'user_id': userId,
        'backup_data': dataToBackup,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase 백업 오류: $e');
      throw Exception('서버에 데이터를 저장하는 데 실패했습니다.');
    }
  }

  Future<void> restoreDataFromSupabase() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    try {
      final response = await _supabase
          .from('user_data_backups')
          .select('backup_data')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['backup_data'] != null) {
        final data = response['backup_data'];

        // TODO: 복원된 데이터를 서버의 개별 테이블에 다시 쓰는 로직이 필요.
        // 우선 로컬 캐시를 업데이트하여 UI에 즉시 반영.
        _favoriteCertifications = (data['favorites'] as List)
            .map((json) => Certification.fromJson(json))
            .toList();
        _targetCertifications = (data['targets'] as List)
            .map((json) => Certification.fromJson(json))
            .toList();
        _ownedCertifications = (data['owned'] as List)
            .map((json) => Certification.fromJson(json))
            .toList();

        // 여기에 서버 데이터를 동기화하는 코드를 추가해야 완벽해집니다.
        // 예: for (var cert in _favoriteCertifications) { await addFavorite(cert); }
      }
    } catch (e) {
      debugPrint('Supabase 복원 오류: $e');
      throw Exception('서버에서 데이터를 불러오는 데 실패했습니다.');
    }
  }
}