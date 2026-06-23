import '../models/asset_model.dart';
import '../repositories/asset_repository.dart';

/// Mock implementation of [AssetRepository] for offline development.
class MockAssetRepository implements AssetRepository {
  static final List<AssetModel> _assets = [
    // ── Official Documents ─ HIGH ────────────────────────────────────
    AssetModel(
      id: '1',
      name: 'تقسيم التركة',
      category: AssetCategory.officialDocument,
      classification: AssetClassification.high,
      action: AssetAction.transferToBeneficiary,
      assignedBeneficiary: 'Sara',
      senderName: 'Sundus Ahmed',
      lastEdited: DateTime(2026, 5, 2),
      fileInfo: const AssetFileInfo(
        fileName: 'تقسيم التركة.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 96256,
      ),
    ),
    AssetModel(
      id: '2',
      name: 'حصر الورثة',
      category: AssetCategory.officialDocument,
      classification: AssetClassification.high,
      action: AssetAction.transferToBeneficiary,
      assignedBeneficiary: 'Ahmed',
      senderName: 'Sundus Ahmed',
      lastEdited: DateTime(2026, 4, 15),
      fileInfo: const AssetFileInfo(
        fileName: 'حصر الورثة.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 96256,
      ),
    ),
    AssetModel(
      id: '3',
      name: 'شهادة وفاة',
      category: AssetCategory.officialDocument,
      classification: AssetClassification.high,
      action: AssetAction.deletion,
      lastEdited: DateTime(2026, 3, 10),
      fileInfo: const AssetFileInfo(
        fileName: 'شهادة وفاة.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 96256,
      ),
    ),
    AssetModel(
      id: '4',
      name: 'إقرار مديونية',
      category: AssetCategory.officialDocument,
      classification: AssetClassification.high,
      action: AssetAction.transferToBeneficiary,
      assignedBeneficiary: 'Khalid',
      senderName: 'Sundus Ahmed',
      lastEdited: DateTime(2026, 2, 20),
      fileInfo: const AssetFileInfo(
        fileName: 'إقرار مديونية.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 96256,
      ),
    ),
    AssetModel(
      id: '5',
      name: 'وثيقة وصية',
      category: AssetCategory.officialDocument,
      classification: AssetClassification.high,
      action: AssetAction.transferToBeneficiary,
      assignedBeneficiary: 'Fatima',
      senderName: 'Sundus Ahmed',
      lastEdited: DateTime(2026, 1, 5),
      fileInfo: const AssetFileInfo(
        fileName: 'وثيقة وصية.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 96256,
      ),
    ),

    // ── Official Documents ─ MEDIUM ──────────────────────────────────
    AssetModel(
      id: '6',
      name: 'رقم الهوية الوطنية',
      category: AssetCategory.officialDocument,
      classification: AssetClassification.medium,
      action: AssetAction.transferToBeneficiary,
      assignedBeneficiary: 'Sara',
      senderName: 'Sundus Ahmed',
      lastEdited: DateTime(2026, 4, 1),
      fileInfo: const AssetFileInfo(
        fileName: 'رقم الهوية الوطنية.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 96256,
      ),
    ),
    AssetModel(
      id: '7',
      name: 'رقم الآيبان',
      category: AssetCategory.officialDocument,
      classification: AssetClassification.medium,
      action: AssetAction.deletion,
      lastEdited: DateTime(2026, 3, 28),
      fileInfo: const AssetFileInfo(
        fileName: 'رقم الآيبان.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 96256,
      ),
    ),
    AssetModel(
      id: '8',
      name: 'عقد شراكة',
      category: AssetCategory.officialDocument,
      classification: AssetClassification.medium,
      action: AssetAction.transferToBeneficiary,
      assignedBeneficiary: 'Ahmed',
      senderName: 'Sundus Ahmed',
      lastEdited: DateTime(2026, 2, 15),
      fileInfo: const AssetFileInfo(
        fileName: 'عقد شراكة.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 96256,
      ),
    ),

    // ── Official Documents ─ LOW ─────────────────────────────────────
    AssetModel(
      id: '9',
      name: 'فاتورة كهرباء',
      category: AssetCategory.officialDocument,
      classification: AssetClassification.low,
      action: AssetAction.deletion,
      lastEdited: DateTime(2026, 1, 20),
      fileInfo: const AssetFileInfo(
        fileName: 'فاتورة كهرباء.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 96256,
      ),
    ),
    AssetModel(
      id: '10',
      name: 'إيصال دفع',
      category: AssetCategory.officialDocument,
      classification: AssetClassification.low,
      action: AssetAction.deletion,
      lastEdited: DateTime(2026, 1, 10),
      fileInfo: const AssetFileInfo(
        fileName: 'إيصال دفع.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 96256,
      ),
    ),
    AssetModel(
      id: '11',
      name: 'تقرير شهري',
      category: AssetCategory.officialDocument,
      classification: AssetClassification.low,
      action: AssetAction.transferToBeneficiary,
      assignedBeneficiary: 'Fatima',
      senderName: 'Sundus Ahmed',
      lastEdited: DateTime(2025, 12, 25),
      fileInfo: const AssetFileInfo(
        fileName: 'تقرير شهري.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 96256,
      ),
    ),

    // ── Photos ───────────────────────────────────────────────────────
    AssetModel(
      id: '12',
      name: 'صورة لـ العائلة',
      category: AssetCategory.photo,
      action: AssetAction.transferToBeneficiary,
      assignedBeneficiary: 'Aryam',
      senderName: 'Sundus Ahmed',
      lastEdited: DateTime(2026, 5, 2),
      fileInfo: const AssetFileInfo(
        fileName: 'Photo of.png',
        fileExtension: 'png',
        fileSizeBytes: 99328,
      ),
    ),
    AssetModel(
      id: '13',
      name: 'صورة لـ الذكريات',
      category: AssetCategory.photo,
      action: AssetAction.transferToBeneficiary,
      assignedBeneficiary: 'Sara',
      senderName: 'Sundus Ahmed',
      lastEdited: DateTime(2026, 4, 20),
      fileInfo: const AssetFileInfo(
        fileName: 'memories.jpg',
        fileExtension: 'jpg',
        fileSizeBytes: 150000,
      ),
    ),
    AssetModel(
      id: '14',
      name: 'صورة لـ المنزل',
      category: AssetCategory.photo,
      action: AssetAction.deletion,
      lastEdited: DateTime(2026, 3, 15),
      fileInfo: const AssetFileInfo(
        fileName: 'house.png',
        fileExtension: 'png',
        fileSizeBytes: 200000,
      ),
    ),

    // ── Videos ───────────────────────────────────────────────────────
    AssetModel(
      id: '15',
      name: 'فيديو لـ الحفل',
      category: AssetCategory.video,
      action: AssetAction.transferToBeneficiary,
      assignedBeneficiary: 'Ahmed',
      senderName: 'Sundus Ahmed',
      lastEdited: DateTime(2026, 4, 10),
      fileInfo: const AssetFileInfo(
        fileName: 'video of.mp4',
        fileExtension: 'mp4',
        fileSizeBytes: 99328,
      ),
    ),
    AssetModel(
      id: '16',
      name: 'فيديو لـ الرحلة',
      category: AssetCategory.video,
      action: AssetAction.deletion,
      lastEdited: DateTime(2026, 3, 5),
      fileInfo: const AssetFileInfo(
        fileName: 'trip.mp4',
        fileExtension: 'mp4',
        fileSizeBytes: 5242880,
      ),
    ),
    AssetModel(
      id: '17',
      name: 'فيديو لـ التخرج',
      category: AssetCategory.video,
      action: AssetAction.transferToBeneficiary,
      assignedBeneficiary: 'Fatima',
      senderName: 'Sundus Ahmed',
      lastEdited: DateTime(2026, 2, 1),
      fileInfo: const AssetFileInfo(
        fileName: 'graduation.mp4',
        fileExtension: 'mp4',
        fileSizeBytes: 8388608,
      ),
    ),

    // ── Personal Debts ───────────────────────────────────────────────
    AssetModel(
      id: '18',
      name: 'صيام شهر رمضان الماضي',
      description: 'ثلاثة أيام من رمضان بسبب المرض',
      debtType: 'قضاء صيام',
      category: AssetCategory.personalDept,
      action: AssetAction.transferToBeneficiary,
      assignedBeneficiary: 'Sara',
      senderName: 'Sundus Ahmed',
      lastEdited: DateTime(2026, 4, 18),
    ),
    AssetModel(
      id: '19',
      name: 'كفارة يمين',
      description: 'إطعام مساكين بسبب يمين معقودة',
      debtType: 'كفارة حلف',
      category: AssetCategory.personalDept,
      action: AssetAction.transferToBeneficiary,
      assignedBeneficiary: 'Ahmed',
      senderName: 'Sundus Ahmed',
      lastEdited: DateTime(2026, 4, 10),
    ),
  ];

  @override
  Future<List<AssetModel>> getAssets() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_assets);
  }

  @override
  Future<List<AssetModel>> getAssetsByCategory(AssetCategory category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _assets.where((a) => a.category == category).toList();
  }

  @override
  Future<AssetModel?> getAssetById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _assets.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AssetModel>> searchAssets(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lowerQuery = query.toLowerCase();
    return _assets.where((a) {
      return a.name.toLowerCase().contains(lowerQuery) ||
          a.categoryLabel.toLowerCase().contains(lowerQuery) ||
          (a.fileInfo?.fileName.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  @override
  Future<void> deleteAsset(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _assets.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> updateAsset(AssetModel asset) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _assets.indexWhere((a) => a.id == asset.id);
    if (index != -1) {
      _assets[index] = asset;
    }
  }
}
