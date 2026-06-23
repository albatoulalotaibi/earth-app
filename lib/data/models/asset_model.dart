// lib/data/models/asset_model.dart

enum AssetCategory { officialDocument, photo, video, personalDept }
enum AssetClassification { high, medium, low }
enum AssetAction { deletion, transferToBeneficiary }

class AssetFileInfo {
  final String fileName;
  final String fileExtension;
  final int fileSizeBytes;
  final String? fileUrl;
  final String? previewUrl;
  final bool isDownloaded;

  const AssetFileInfo({
    required this.fileName,
    required this.fileExtension,
    required this.fileSizeBytes,
    this.fileUrl,
    this.previewUrl,
    this.isDownloaded = false,
  });

  factory AssetFileInfo.fromJson(Map<String, dynamic> json) {
    return AssetFileInfo(
      fileName: json['file_name']?.toString() ?? '',
      fileExtension: json['file_extension']?.toString() ?? '',
      fileSizeBytes: int.tryParse(json['file_size_bytes']?.toString() ?? '0') ?? 0,
      fileUrl: json['file_url']?.toString(),
      previewUrl: json['preview_url']?.toString(),
      isDownloaded: json['is_downloaded'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_name': fileName,
      'file_extension': fileExtension,
      'file_size_bytes': fileSizeBytes,
      if (fileUrl != null) 'file_url': fileUrl,
      if (previewUrl != null) 'preview_url': previewUrl,
      'is_downloaded': isDownloaded,
    };
  }

  String get fileSizeFormatted {
    if (fileSizeBytes <= 0) return 'متاح'; 
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class AssetModel {
  final String? id;
  final String name;
  final String? description;
  final String? debtType;
  final AssetCategory category;
  final AssetClassification? classification;
  final AssetAction action;
  final String? assignedBeneficiary;
  final String? senderName;
  final DateTime? lastEdited;
  final AssetFileInfo? fileInfo;

  const AssetModel({
    this.id,
    required this.name,
    this.description,
    this.debtType,
    required this.category,
    this.classification,
    required this.action,
    this.assignedBeneficiary,
    this.senderName,
    this.lastEdited,
    this.fileInfo,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    AssetFileInfo? extractedFileInfo;

    String urlString = (json['file_url'] ?? json['file'] ?? json['url'])?.toString() ?? '';

    if (urlString.isNotEmpty) {
      final uriPath = Uri.parse(urlString).path;
      final extension = uriPath.split('.').last.toLowerCase();
      final fileName = uriPath.split('/').last;

      extractedFileInfo = AssetFileInfo(
        fileName: fileName.isNotEmpty ? fileName : 'ملف_مرفق',
        fileExtension: extension,
        fileSizeBytes: 0,
        fileUrl: urlString,
        previewUrl: urlString,
      );
    } else if (json['file_info'] != null && json['file_info'] is Map) {
      extractedFileInfo = AssetFileInfo.fromJson(json['file_info'] as Map<String, dynamic>);
    }

    return AssetModel(
      id: json['asset_id']?.toString() ?? json['id']?.toString(),
      name: json['title']?.toString() ?? json['name']?.toString() ?? 'بدون اسم',
      description: json['description']?.toString(),
      debtType: json['debt_type']?.toString(),
      category: _categoryFromString(json['asset_type']?.toString() ?? json['category']?.toString()),
      classification: _classificationFromString(json['sensitivity_level']?.toString() ?? json['classification']?.toString()),
      action: _actionFromString(json['posthumous_action']?.toString() ?? json['action']?.toString()),
      assignedBeneficiary: json['assigned_beneficiary']?.toString(),
      senderName: json['owner_name']?.toString() ?? json['sender_name']?.toString(),
      lastEdited: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : (json['last_edited'] != null ? DateTime.tryParse(json['last_edited'].toString()) : null),
      fileInfo: extractedFileInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (debtType != null) 'debt_type': debtType,
      'category': category.name,
      'classification': classification?.name,
      'action': action.name,
      if (assignedBeneficiary != null) 'assigned_beneficiary': assignedBeneficiary,
      if (senderName != null) 'sender_name': senderName,
      if (lastEdited != null) 'last_edited': lastEdited!.toIso8601String(),
      if (fileInfo != null) 'file_info': fileInfo!.toJson(),
    };
  }

  AssetModel copyWith({
    String? id,
    String? name,
    String? description,
    String? debtType,
    AssetCategory? category,
    AssetClassification? classification,
    AssetAction? action,
    String? assignedBeneficiary,
    String? senderName,
    DateTime? lastEdited,
    AssetFileInfo? fileInfo,
  }) {
    return AssetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      debtType: debtType ?? this.debtType,
      category: category ?? this.category,
      classification: classification ?? this.classification,
      action: action ?? this.action,
      assignedBeneficiary: assignedBeneficiary ?? this.assignedBeneficiary,
      senderName: senderName ?? this.senderName,
      lastEdited: lastEdited ?? this.lastEdited,
      fileInfo: fileInfo ?? this.fileInfo,
    );
  }

  // Getters
  String get categoryLabel {
    switch (category) {
      case AssetCategory.officialDocument: return 'OFFICIAL DOCUMENT';
      case AssetCategory.photo: return 'PHOTO';
      case AssetCategory.video: return 'VIDEO';
      case AssetCategory.personalDept: return 'PERSONAL DEPTS';
    }
  }

  String get classificationLabel {
    switch (classification) {
      case AssetClassification.high: return 'HIGH';
      case AssetClassification.medium: return 'MEDIUM';
      case AssetClassification.low: return 'LOW';
      default: return '';
    }
  }

  String get actionLabel {
    switch (action) {
      case AssetAction.deletion: return 'Deletion';
      case AssetAction.transferToBeneficiary:
        return assignedBeneficiary != null ? 'Transfer to "$assignedBeneficiary"' : 'Transfer to beneficiary';
    }
  }

  // Helpers
  static AssetCategory _categoryFromString(String? value) {
    final val = value?.toLowerCase();
    if (val == 'document' || val == 'officialdocument') return AssetCategory.officialDocument;
    if (val == 'image' || val == 'photo') return AssetCategory.photo;
    if (val == 'video') return AssetCategory.video;
    if (val == 'personaldept' || val == 'debt') return AssetCategory.personalDept;
    return AssetCategory.officialDocument;
  }

  static AssetClassification? _classificationFromString(String? value) {
    final val = value?.toLowerCase();
    if (val == 'high') return AssetClassification.high;
    if (val == 'medium') return AssetClassification.medium;
    if (val == 'low') return AssetClassification.low;
    return null;
  }

  static AssetAction _actionFromString(String? value) {
    final val = value?.toLowerCase();
    if (val == 'deletion' || val == 'delete') return AssetAction.deletion;
    if (val == 'transfer' || val == 'transfertobeneficiary') return AssetAction.transferToBeneficiary;
    return AssetAction.deletion;
  }
}