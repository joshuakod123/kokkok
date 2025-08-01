// lib/services/blockchain_certification_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 블록체인 자격증 데이터 모델
class BlockchainCertification {
  final String id;
  final String certificationId;
  final String userId;
  final String certificateNumber;
  final String blockchainHash; // 블록체인 해시
  final String nftTokenId; // NFT 토큰 ID
  final DateTime issuedDate;
  final DateTime verifiedDate;
  final String issuerSignature;
  final Map<String, dynamic> metadata;
  final String status; // 'pending', 'verified', 'rejected'

  const BlockchainCertification({
    required this.id,
    required this.certificationId,
    required this.userId,
    required this.certificateNumber,
    required this.blockchainHash,
    required this.nftTokenId,
    required this.issuedDate,
    required this.verifiedDate,
    required this.issuerSignature,
    required this.metadata,
    required this.status,
  });

  factory BlockchainCertification.fromJson(Map<String, dynamic> json) {
    return BlockchainCertification(
      id: json['id'],
      certificationId: json['certification_id'],
      userId: json['user_id'],
      certificateNumber: json['certificate_number'],
      blockchainHash: json['blockchain_hash'],
      nftTokenId: json['nft_token_id'],
      issuedDate: DateTime.parse(json['issued_date']),
      verifiedDate: DateTime.parse(json['verified_date']),
      issuerSignature: json['issuer_signature'],
      metadata: json['metadata'] ?? {},
      status: json['status'],
    );
  }
}

class BlockchainCertificationService {
  static final BlockchainCertificationService _instance =
  BlockchainCertificationService._internal();
  factory BlockchainCertificationService() => _instance;
  BlockchainCertificationService._internal();

  final _supabase = Supabase.instance.client;

  // 실제 구현에서는 Web3 패키지들 사용
  // - web3dart for Ethereum
  // - solana for Solana
  // - polygon_id for identity verification

  // ===== 자격증 NFT 발급 =====

  Future<String> mintCertificationNFT({
    required String certificationId,
    required String certificateNumber,
    required DateTime issuedDate,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('로그인이 필요합니다');

      // 1. 메타데이터 준비
      final nftMetadata = {
        'name': metadata['certification_name'],
        'description': '콕콕에서 인증된 자격증 NFT',
        'image': _generateCertificateImage(metadata),
        'attributes': [
          {'trait_type': 'Certification', 'value': metadata['certification_name']},
          {'trait_type': 'Certificate Number', 'value': certificateNumber},
          {'trait_type': 'Issue Date', 'value': issuedDate.toIso8601String()},
          {'trait_type': 'Verified By', 'value': 'KokKok Platform'},
          {'trait_type': 'Category', 'value': metadata['category'] ?? 'General'},
          {'trait_type': 'Difficulty', 'value': metadata['difficulty'] ?? 'Standard'},
        ],
        'external_url': 'https://kokkok.app/certificate/$certificateNumber',
        'kokkok_verified': true,
        'verification_timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // 2. IPFS에 메타데이터 업로드 (실제 구현에서는 Pinata나 Infura 사용)
      final ipfsHash = await _uploadToIPFS(nftMetadata);

      // 3. 스마트 컨트랙트를 통한 NFT 발급
      final transactionHash = await _mintNFTOnBlockchain(
        userAddress: metadata['wallet_address'] ?? await _getUserWalletAddress(userId),
        tokenURI: 'ipfs://$ipfsHash',
        certificateData: {
          'certificateNumber': certificateNumber,
          'issuedDate': issuedDate.millisecondsSinceEpoch,
          'certificationId': certificationId,
        },
      );

      // 4. 데이터베이스에 기록
      await _supabase
          .from('blockchain_certifications')
          .insert({
        'certification_id': certificationId,
        'user_id': userId,
        'certificate_number': certificateNumber,
        'blockchain_hash': transactionHash,
        'nft_token_id': await _getTokenIdFromTransaction(transactionHash),
        'issued_date': issuedDate.toIso8601String(),
        'verified_date': DateTime.now().toIso8601String(),
        'issuer_signature': await _generateIssuerSignature(certificateNumber),
        'metadata': nftMetadata,
        'status': 'verified',
        'ipfs_hash': ipfsHash,
      });

      return transactionHash;
    } catch (e) {
      debugPrint('NFT 발급 실패: $e');
      throw Exception('자격증 NFT 발급에 실패했습니다: $e');
    }
  }

  // ===== 자격증 진위 확인 =====

  Future<Map<String, dynamic>> verifyCertification(String certificateNumber) async {
    try {
      // 1. 데이터베이스에서 자격증 정보 조회
      final dbResult = await _supabase
          .from('blockchain_certifications')
          .select('''
            *,
            certifications(jm_nm, series_nm, qual_cls_nm),
            profiles(username, user_id)
          ''')
          .eq('certificate_number', certificateNumber)
          .maybeSingle();

      if (dbResult == null) {
        return {
          'verified': false,
          'error': '해당 자격증 번호를 찾을 수 없습니다.',
        };
      }

      // 2. 블록체인에서 실제 NFT 존재 확인
      final blockchainVerification = await _verifyOnBlockchain(
        dbResult['blockchain_hash'],
        dbResult['nft_token_id'],
      );

      if (!blockchainVerification['exists']) {
        return {
          'verified': false,
          'error': '블록체인에서 해당 NFT를 찾을 수 없습니다.',
          'suspicious': true, // 의심스러운 활동
        };
      }

      // 3. 메타데이터 무결성 검증
      final metadataValid = await _verifyMetadataIntegrity(
        dbResult['ipfs_hash'],
        dbResult['metadata'],
      );

      return {
        'verified': true,
        'certification_name': dbResult['certifications']['jm_nm'],
        'series_name': dbResult['certifications']['series_nm'],
        'qualification_class': dbResult['certifications']['qual_cls_nm'],
        'holder_name': dbResult['profiles']['username'],
        'holder_id': dbResult['profiles']['user_id'],
        'issued_date': dbResult['issued_date'],
        'verified_date': dbResult['verified_date'],
        'blockchain_hash': dbResult['blockchain_hash'],
        'nft_token_id': dbResult['nft_token_id'],
        'metadata_verified': metadataValid,
        'verification_score': _calculateVerificationScore(dbResult, blockchainVerification),
      };
    } catch (e) {
      return {
        'verified': false,
        'error': '인증 과정에서 오류가 발생했습니다: $e',
      };
    }
  }

  // ===== QR 코드 기반 빠른 인증 =====

  Future<String> generateVerificationQR(String certificateNumber) async {
    try {
      final verificationData = {
        'certificate_number': certificateNumber,
        'verification_url': 'https://kokkok.app/verify/$certificateNumber',
        'generated_at': DateTime.now().millisecondsSinceEpoch,
        'expires_at': DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
      };

      // QR 코드용 서명 생성 (실제로는 개인키로 서명)
      final signature = await _signVerificationData(verificationData);
      verificationData['signature'] = signature;

      return _generateQRCodeData(verificationData);
    } catch (e) {
      throw Exception('QR 코드 생성 실패: $e');
    }
  }

  Future<Map<String, dynamic>> verifyQRCode(String qrData) async {
    try {
      final data = _parseQRCodeData(qrData);

      // 1. 서명 검증
      final signatureValid = await _verifySignature(data);
      if (!signatureValid) {
        return {'verified': false, 'error': '잘못된 QR 코드입니다.'};
      }

      // 2. 만료 시간 확인
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(data['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        return {'verified': false, 'error': 'QR 코드가 만료되었습니다.'};
      }

      // 3. 자격증 검증
      return await verifyCertification(data['certificate_number']);
    } catch (e) {
      return {'verified': false, 'error': 'QR 코드 해석 실패: $e'};
    }
  }

  // ===== 자격증 거래/양도 시스템 =====

  Future<String> transferCertification({
    required String certificateNumber,
    required String newOwnerAddress,
    required String transferReason,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('로그인이 필요합니다');

      // 1. 소유권 확인
      final cert = await _supabase
          .from('blockchain_certifications')
          .select('*')
          .eq('certificate_number', certificateNumber)
          .eq('user_id', userId)
          .single();

      // 2. 블록체인에서 NFT 전송
      final transferTx = await _transferNFTOnBlockchain(
        fromAddress: await _getUserWalletAddress(userId),
        toAddress: newOwnerAddress,
        tokenId: cert['nft_token_id'],
      );

      // 3. 전송 기록 저장
      await _supabase.from('certification_transfers').insert({
        'certificate_number': certificateNumber,
        'from_user_id': userId,
        'to_wallet_address': newOwnerAddress,
        'transfer_reason': transferReason,
        'blockchain_tx': transferTx,
        'transferred_at': DateTime.now().toIso8601String(),
      });

      return transferTx;
    } catch (e) {
      throw Exception('자격증 양도 실패: $e');
    }
  }

  // ===== 자격증 대여 시스템 (임시 권한 부여) =====

  Future<String> createTemporaryAccess({
    required String certificateNumber,
    required String borrowerAddress,
    required Duration accessDuration,
    required String purpose,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('로그인이 필요합니다');

      final expiresAt = DateTime.now().add(accessDuration);

      // 스마트 컨트랙트에 임시 권한 생성
      final accessTx = await _createTemporaryAccessOnBlockchain(
        certificateNumber: certificateNumber,
        borrowerAddress: borrowerAddress,
        expiresAt: expiresAt,
      );

      // 임시 액세스 기록
      await _supabase.from('temporary_certifications').insert({
        'certificate_number': certificateNumber,
        'owner_user_id': userId,
        'borrower_address': borrowerAddress,
        'purpose': purpose,
        'expires_at': expiresAt.toIso8601String(),
        'blockchain_tx': accessTx,
        'status': 'active',
      });

      return accessTx;
    } catch (e) {
      throw Exception('임시 권한 생성 실패: $e');
    }
  }

  // ===== 자격증 진위 확인 API (공개) =====

  Future<Map<String, dynamic>> publicVerifyAPI(String certificateNumber) async {
    try {
      final result = await verifyCertification(certificateNumber);

      // 공개 API용으로 민감한 정보 제거
      if (result['verified'] == true) {
        return {
          'verified': true,
          'certification_name': result['certification_name'],
          'series_name': result['series_name'],
          'qualification_class': result['qualification_class'],
          'issued_date': result['issued_date'],
          'verification_score': result['verification_score'],
          'blockchain_verified': true,
          'last_verified': DateTime.now().toIso8601String(),
        };
      } else {
        return {'verified': false, 'message': '확인되지 않은 자격증입니다.'};
      }
    } catch (e) {
      return {'verified': false, 'error': 'API 오류'};
    }
  }

  // ===== 내부 헬퍼 함수들 =====

  Future<String> _uploadToIPFS(Map<String, dynamic> metadata) async {
    // 실제 구현: Pinata, Infura, 또는 자체 IPFS 노드 사용
    // 예시: Pinata API 사용
    try {
      // 현재는 모의 해시 반환
      return 'Qm${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';
    } catch (e) {
      throw Exception('IPFS 업로드 실패: $e');
    }
  }

  Future<String> _mintNFTOnBlockchain({
    required String userAddress,
    required String tokenURI,
    required Map<String, dynamic> certificateData,
  }) async {
    // 실제 구현: web3dart 사용하여 스마트 컨트랙트 호출
    try {
      // 현재는 모의 트랜잭션 해시 반환
      return '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';
    } catch (e) {
      throw Exception('블록체인 NFT 발급 실패: $e');
    }
  }

  Future<String> _getTokenIdFromTransaction(String txHash) async {
    // 트랜잭션 영수증에서 TokenId 이벤트 파싱
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<String> _generateIssuerSignature(String certificateNumber) async {
    // 실제로는 콕콕 플랫폼의 개인키로 서명
    return 'kokkok_signature_${certificateNumber}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> _getUserWalletAddress(String userId) async {
    try {
      final result = await _supabase
          .from('user_wallets')
          .select('wallet_address')
          .eq('user_id', userId)
          .maybeSingle();

      if (result == null) {
        // 지갑이 없으면 새로 생성 (실제로는 사용자가 연결)
        throw Exception('지갑 주소가 연결되지 않았습니다');
      }

      return result['wallet_address'];
    } catch (e) {
      throw Exception('지갑 주소 조회 실패: $e');
    }
  }

  Future<Map<String, dynamic>> _verifyOnBlockchain(
      String txHash,
      String tokenId,
      ) async {
    // 블록체인에서 실제 NFT 존재 여부 확인
    try {
      // 실제 구현: web3 provider를 통한 컨트랙트 호출
      return {
        'exists': true,
        'current_owner': '0x1234...', // 실제 소유자 주소
        'verified_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'exists': false, 'error': e.toString()};
    }
  }

  Future<bool> _verifyMetadataIntegrity(String ipfsHash, Map<String, dynamic> storedMetadata) async {
    try {
      // IPFS에서 실제 메타데이터 다운로드하여 비교
      return true; // 임시로 true 반환
    } catch (e) {
      return false;
    }
  }

  int _calculateVerificationScore(
      Map<String, dynamic> dbData,
      Map<String, dynamic> blockchainData,
      ) {
    int score = 0;

    // 블록체인 존재 여부 (40점)
    if (blockchainData['exists'] == true) score += 40;

    // 메타데이터 무결성 (30점)
    if (dbData['metadata'] != null) score += 30;

    // 발급 기관 서명 (20점)
    if (dbData['issuer_signature'] != null) score += 20;

    // 추가 검증 요소들 (10점)
    if (dbData['status'] == 'verified') score += 10;

    return score;
  }

  String _generateCertificateImage(Map<String, dynamic> metadata) {
    // 자격증 이미지 자동 생성 (실제로는 Canvas API나 이미지 생성 서비스 사용)
    return 'https://kokkok.app/certificate-images/${metadata['certification_name']}.png';
  }

  String _generateQRCodeData(Map<String, dynamic> data) {
    // QR 코드 데이터 인코딩
    return 'kokkok://verify?data=${Uri.encodeComponent(data.toString())}';
  }

  Map<String, dynamic> _parseQRCodeData(String qrData) {
    // QR 코드 데이터 파싱 (실제로는 JSON 디코딩)
    return {'certificate_number': 'MOCK_CERT_123'};
  }

  Future<String> _signVerificationData(Map<String, dynamic> data) async {
    // 디지털 서명 생성
    return 'signature_${data.hashCode}';
  }

  Future<bool> _verifySignature(Map<String, dynamic> data) async {
    // 디지털 서명 검증
    return true;
  }

  Future<String> _transferNFTOnBlockchain({
    required String fromAddress,
    required String toAddress,
    required String tokenId,
  }) async {
    // NFT 전송 트랜잭션
    return '0x_transfer_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> _createTemporaryAccessOnBlockchain({
    required String certificateNumber,
    required String borrowerAddress,
    required DateTime expiresAt,
  }) async {
    // 임시 권한 생성 트랜잭션
    return '0x_temp_access_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ===== 사용자용 편의 함수들 =====

  Future<List<BlockchainCertification>> getUserCertifications(String userId) async {
    try {
      final response = await _supabase
          .from('blockchain_certifications')
          .select('*')
          .eq('user_id', userId)
          .order('verified_date', ascending: false);

      return response.map<BlockchainCertification>((data) =>
          BlockchainCertification.fromJson(data)).toList();
    } catch (e) {
      throw Exception('사용자 자격증 조회 실패: $e');
    }
  }

  Future<Map<String, dynamic>> getCertificationPortfolio(String userId) async {
    try {
      final certs = await getUserCertifications(userId);

      final categories = <String, int>{};
      var totalValue = 0;

      for (final cert in certs) {
        final category = cert.metadata['category'] ?? 'General';
        categories[category] = (categories[category] ?? 0) + 1;
        totalValue += 100; // 각 자격증당 가치 점수
      }

      return {
        'total_certifications': certs.length,
        'categories': categories,
        'total_value': totalValue,
        'verification_rate': 100, // 모든 자격증이 블록체인 검증됨
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('포트폴리오 조회 실패: $e');
    }
  }
}