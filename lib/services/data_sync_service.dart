// lib/services/data_sync_service.dart

// 데이터 모델 정의
enum BackupStatusType { none, inProgress, success, failed }

class BackupStatus {
  final BackupStatusType status;
  final DateTime? lastBackup;
  final String? errorMessage;

  BackupStatus({required this.status, this.lastBackup, this.errorMessage});
}

// 추상 클래스로 변경하여 다른 클래스에서 구현하도록 유도
abstract class DataSyncService {
  Future<bool> backupToServer();
  Future<bool> restoreFromServer();
  Future<BackupStatus> getBackupStatus();
}