// lib/screens/assets/asset_viewer_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../data/models/asset_model.dart';
import '../../services/session_manager.dart';
import '../../data/models/user_model.dart';
import '../../providers/app_preferences.dart';
import '../../widgets/viewers/image_viewer_screen.dart';
import '../../widgets/viewers/video_player_screen.dart';
import '../../widgets/viewers/pdf_viewer_screen.dart';

class AssetViewerScreen extends StatefulWidget {
  final AssetModel asset;

  const AssetViewerScreen({Key? key, required this.asset}) : super(key: key);

  @override
  State<AssetViewerScreen> createState() => _AssetViewerScreenState();
}

class _AssetViewerScreenState extends State<AssetViewerScreen> {
  late AssetModel _asset;
  bool _isLoadingAsset = false;
  
  String _creatorUsername = 'جاري التحميل...';
  List<String> _beneficiaries = [];

  @override
  void initState() {
    super.initState();
    _asset = widget.asset;
    _fetchAssetDetails();
  }

  Future<void> _fetchAssetDetails() async {
    if (_asset.id == null) return;
    setState(() => _isLoadingAsset = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/documents/${_asset.id}/');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        String fetchedName = 'غير معروف';
        if (data['owner_name'] != null) {
          fetchedName = data['owner_name'].toString();
        } else if (data['owner'] != null && data['owner'] is Map) {
          fetchedName = data['owner']['name']?.toString() ??
                        data['owner']['username']?.toString() ??
                        'غير معروف';
        } else if (data['sender_name'] != null) {
          fetchedName = data['sender_name'].toString();
        }

        List<String> fetchedBeneficiaries = [];
        final List<dynamic>? bens = data['beneficiaries'] ?? data['shared_with'] ?? data['assigned_users'];
        if (bens != null && bens.isNotEmpty) {
          for (var b in bens) {
            if (b is Map) {
              String bName = (b['first_name'] != null && b['last_name'] != null)
                  ? '${b['first_name']} ${b['last_name']}'
                  : b['name']?.toString() ?? b['username']?.toString() ?? b['email']?.toString() ?? 'مستفيد';
              fetchedBeneficiaries.add(bName);
            } else if (b is String) {
              fetchedBeneficiaries.add(b);
            }
          }
        }

        String? fetchedDebtType = _asset.debtType;
        if (data['debt_type'] != null && data['debt_type'].toString() != 'null' && data['debt_type'].toString().trim().isNotEmpty) {
          fetchedDebtType = data['debt_type'].toString().trim();
        } else if (data['debtType'] != null && data['debtType'].toString() != 'null' && data['debtType'].toString().trim().isNotEmpty) {
          fetchedDebtType = data['debtType'].toString().trim();
        }
        
        DateTime? updatedTime = _asset.lastEdited;
        if (data['updated_at'] != null) {
          try {
            updatedTime = DateTime.parse(data['updated_at'].toString()).toLocal();
          } catch (e) {
            debugPrint('Error parsing updated_at: $e');
          }
        }

        String? fetchedUrl = data['file_url']?.toString() ?? data['file']?.toString() ?? data['download_url']?.toString();
        AssetFileInfo? updatedFileInfo = _asset.fileInfo;

        if (fetchedUrl != null && fetchedUrl.isNotEmpty) {
          if (updatedFileInfo != null) {
            updatedFileInfo = AssetFileInfo(
              fileName: updatedFileInfo.fileName,
              fileExtension: updatedFileInfo.fileExtension,
              fileSizeBytes: updatedFileInfo.fileSizeBytes,
              fileUrl: fetchedUrl,
              previewUrl: fetchedUrl,
            );
          } else {
            String ext = 'pdf'; 
            String urlLower = fetchedUrl.toLowerCase();
            if (urlLower.contains('.mp4')) ext = 'mp4';
            else if (urlLower.contains('.mov')) ext = 'mov';
            else if (urlLower.contains('.jpg') || urlLower.contains('.jpeg')) ext = 'jpg';
            else if (urlLower.contains('.png')) ext = 'png';

            updatedFileInfo = AssetFileInfo(
              fileName: data['title']?.toString() ?? 'ملف مرفق',
              fileExtension: ext,
              fileSizeBytes: 0,
              fileUrl: fetchedUrl,
              previewUrl: fetchedUrl,
            );
          }
        }

        setState(() {
          _asset = _asset.copyWith(
            name: data['title']?.toString() ?? _asset.name,
            description: data['description']?.toString() ?? _asset.description,
            debtType: fetchedDebtType,
            lastEdited: updatedTime,
            fileInfo: updatedFileInfo, 
          );
          _creatorUsername = fetchedName;
          _beneficiaries = fetchedBeneficiaries;
        });
      }
    } catch (e) {
      debugPrint('Error auto-fetching asset: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingAsset = false);
      }
    }
  }

  bool get _isNormalUser =>
      SessionManager.instance.currentUser?.accountType == AccountType.normal;

  String? get _currentUrl => _asset.fileInfo?.fileUrl ?? _asset.fileInfo?.previewUrl;

  bool get _isPdf {
    final url = _currentUrl;
    if (url == null || url.isEmpty) return false;
    final path = Uri.parse(url).path.toLowerCase();
    final name = _asset.name.toLowerCase();
    
    if (path.endsWith('.pdf') || name.endsWith('.pdf')) return true;
    if (_asset.category == AssetCategory.officialDocument && 
        !path.endsWith('.jpg') && !path.endsWith('.png') && !path.endsWith('.jpeg')) {
      return true;
    }
    return false;
  }

  bool get _isVideo {
    final url = _currentUrl;
    if (url == null || url.isEmpty) return false;
    final path = Uri.parse(url).path.toLowerCase();
    final name = _asset.name.toLowerCase();
    
    if (path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi') || name.endsWith('.mp4')) return true;
    if (_asset.category == AssetCategory.video) return true;
    return false;
  }

  bool get _isImage {
    if (_isPdf || _isVideo) return false;
    return true; 
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: _asset.name, 
        style: AppBarStyle.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isNormalUser)
              _buildSentByBadge(isAr, isDark),

            _buildAssetContent(context, isAr, isDark),
            const SizedBox(height: 32),
            
            if (!_isNormalUser) 
              const SizedBox.shrink()
            else if (_asset.category == AssetCategory.personalDept)
              _buildDebtActions(context, isAr, isDark)
            else
              _buildStandardActions(context, isAr, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSentByBadge(bool isAr, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : const Color(0xFFF3F4F6), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF2563EB), 
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'مُرسل من قبل' : 'Sent by',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey, 
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _creatorUsername,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E3A8A), 
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: isDark ? Colors.white : Colors.black54,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiariesInline(bool isAr, bool isDark) {
    if (_beneficiaries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'المستفيدين المرتبطين:' : 'Assigned Beneficiaries:',
          style: const TextStyle(color: AppColors.textHint, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ..._beneficiaries.map((name) => Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: isDark ? Colors.lightBlueAccent : AppColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildAssetContent(BuildContext context, bool isAr, bool isDark) {
    switch (_asset.category) {
      case AssetCategory.officialDocument:
        return _buildDocumentViewer(isAr, isDark);
      case AssetCategory.photo:
        return _buildPhotoViewer(isAr, isDark);
      case AssetCategory.video:
        return _buildVideoViewer(isAr, isDark);
      case AssetCategory.personalDept:
        return _buildPersonalDeptViewer(isAr, isDark);
    }
  }

  Widget _buildDocumentViewer(bool isAr, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'بيانات ومحتويات المستند' : 'Document Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.lightBlueAccent : AppColors.primaryBlue,
                ),
              ),
              const Divider(height: 32),
              
              _buildInfoRow(isAr ? 'اسم الأصل' : 'Asset Name', _asset.name, isDark),
              const SizedBox(height: 12),
              _buildInfoRow(isAr ? 'الفئة' : 'Category', _asset.categoryLabel, isDark),
              const SizedBox(height: 12),
              _buildInfoRow(isAr ? 'الإجراء' : 'Action', _asset.actionLabel, isDark),
              
              if (_isNormalUser) ...[
                const SizedBox(height: 12),
                _buildInfoRow(isAr ? 'المالك' : 'Creator', _creatorUsername, isDark),
                
                if (_beneficiaries.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildBeneficiariesInline(isAr, isDark),
                ],
              ],
              
              if (_asset.classification != null) ...[
                const SizedBox(height: 12),
                _buildClassificationRow(isAr, isDark),
              ],
              
              const SizedBox(height: 12),
              _buildInfoRow(
                isAr ? 'آخر تعديل' : 'Last Edited',
                _asset.lastEdited != null
                    ? '${_asset.lastEdited!.day}/${_asset.lastEdited!.month}/${_asset.lastEdited!.year} - ${_asset.lastEdited!.hour}:${_asset.lastEdited!.minute.toString().padLeft(2, '0')}'
                    : (isAr ? 'غير متوفر' : 'N/A'),
                isDark,
              ),
              
              if (_asset.fileInfo != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(isAr ? 'اسم الملف' : 'File Name', _asset.fileInfo!.fileName, isDark),
                const SizedBox(height: 12),
                _buildInfoRow(isAr ? 'حجم الملف' : 'File Size', _asset.fileInfo!.fileSizeFormatted, isDark),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        Text(
          isAr ? 'معاينة المستند' : 'Document Preview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _openFullScreenPreview(context),
          child: Container(
            height: 400,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isLoadingAsset 
                  ? const Center(child: CircularProgressIndicator())
                  : _currentUrl != null && _currentUrl!.isNotEmpty
                      ? (_isPdf
                          ? _buildPdfTapToOpen(isAr, isDark) 
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  _currentUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildDocumentPlaceholder(isAr, isDark),
                                ),
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.fullscreen, color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          isAr ? 'اضغط للعرض' : 'Tap to view',
                                          style: const TextStyle(color: Colors.white, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ))
                      : _buildPdfTapToOpen(isAr, isDark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassificationRow(bool isAr, bool isDark) {
    Color classColor;
    switch (_asset.classification!) {
      case AssetClassification.high:
        classColor = Colors.red;
        break;
      case AssetClassification.medium:
        classColor = Colors.orange;
        break;
      case AssetClassification.low:
        classColor = Colors.green;
        break;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(isAr ? 'التصنيف' : 'Classification',
            style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: classColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _asset.classificationLabel,
            style: TextStyle(
              color: classColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoViewer(bool isAr, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(isAr ? 'اسم الأصل' : 'Asset Name', _asset.name, isDark),
              const SizedBox(height: 12),
              _buildInfoRow(isAr ? 'الفئة' : 'Category', _asset.categoryLabel, isDark),
              const SizedBox(height: 12),
              _buildInfoRow(isAr ? 'الإجراء' : 'Action', _asset.actionLabel, isDark),
              
              if (_isNormalUser) ...[
                const SizedBox(height: 12),
                _buildInfoRow(isAr ? 'المالك' : 'Creator', _creatorUsername, isDark),
                
                if (_beneficiaries.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildBeneficiariesInline(isAr, isDark),
                ],
              ],
              
              if (_asset.classification != null) ...[
                const SizedBox(height: 12),
                _buildClassificationRow(isAr, isDark),
              ],
              
              const SizedBox(height: 12),
              _buildInfoRow(
                isAr ? 'آخر تعديل' : 'Last Edited',
                _asset.lastEdited != null
                    ? '${_asset.lastEdited!.day}/${_asset.lastEdited!.month}/${_asset.lastEdited!.year} - ${_asset.lastEdited!.hour}:${_asset.lastEdited!.minute.toString().padLeft(2, '0')}'
                    : (isAr ? 'غير متوفر' : 'N/A'),
                isDark,
              ),

              if (_asset.fileInfo != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(isAr ? 'الملف' : 'File', _asset.fileInfo!.fileName, isDark),
                const SizedBox(height: 12),
                _buildInfoRow(isAr ? 'الحجم' : 'Size', _asset.fileInfo!.fileSizeFormatted, isDark),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => _openFullScreenPreview(context),
          child: Container(
            constraints: const BoxConstraints(minHeight: 300),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _isLoadingAsset
                  ? const Center(child: CircularProgressIndicator())
                  : _currentUrl != null && _currentUrl!.isNotEmpty
                      ? (_isPdf 
                          ? SizedBox(height: 300, child: _buildPdfTapToOpen(isAr, isDark))
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.network(
                                  _currentUrl!,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => SizedBox(
                                    height: 300,
                                    child: _buildPhotoPlaceholder(isAr, isDark),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          isAr ? 'اضغط للفتح' : 'Tap to view image',
                                          style: const TextStyle(color: Colors.white, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ))
                      : SizedBox(
                          height: 300,
                          child: _buildImageTapToOpen(isAr, isDark),
                        ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoViewer(bool isAr, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openFullScreenPreview(context),
          child: Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isLoadingAsset)
                    const Center(child: CircularProgressIndicator())
                  else if (_currentUrl != null && _currentUrl!.isNotEmpty)
                    _buildVideoTapToOpen(isAr, isDark)
                  else
                    _buildVideoTapToOpen(isAr, isDark),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(isAr ? 'اسم الأصل' : 'Asset Name', _asset.name, isDark),
              const SizedBox(height: 12),
              _buildInfoRow(isAr ? 'الفئة' : 'Category', _asset.categoryLabel, isDark),
              const SizedBox(height: 12),
              _buildInfoRow(isAr ? 'الإجراء' : 'Action', _asset.actionLabel, isDark),
              
              if (_isNormalUser) ...[
                const SizedBox(height: 12),
                _buildInfoRow(isAr ? 'المالك' : 'Creator', _creatorUsername, isDark),
                
                if (_beneficiaries.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildBeneficiariesInline(isAr, isDark),
                ],
              ],
              
              if (_asset.classification != null) ...[
                const SizedBox(height: 12),
                _buildClassificationRow(isAr, isDark),
              ],
              
              const SizedBox(height: 12),
              _buildInfoRow(
                isAr ? 'آخر تعديل' : 'Last Edited',
                _asset.lastEdited != null
                    ? '${_asset.lastEdited!.day}/${_asset.lastEdited!.month}/${_asset.lastEdited!.year} - ${_asset.lastEdited!.hour}:${_asset.lastEdited!.minute.toString().padLeft(2, '0')}'
                    : (isAr ? 'غير متوفر' : 'N/A'),
                isDark,
              ),

              if (_asset.fileInfo != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(isAr ? 'الملف' : 'File', _asset.fileInfo!.fileName, isDark),
                const SizedBox(height: 12),
                _buildInfoRow(isAr ? 'الحجم' : 'Size', _asset.fileInfo!.fileSizeFormatted, isDark),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDeptViewer(bool isAr, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'تفاصيل الدين الشخصي' : 'Personal Debt Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.lightBlueAccent : AppColors.primaryBlue,
            ),
          ),
          const Divider(height: 32),
          
          _buildInfoRow(isAr ? 'اسم الأصل' : 'Asset Name', _asset.name, isDark),
          const SizedBox(height: 12),
          _buildInfoRow(isAr ? 'الفئة' : 'Category', _asset.categoryLabel, isDark),
          const SizedBox(height: 12),
          _buildInfoRow(isAr ? 'نوع الدين' : 'Debt Type', _asset.debtType ?? (isAr ? 'غير متوفر' : 'N/A'), isDark),
          const SizedBox(height: 12),
          _buildInfoRow(isAr ? 'الوصف' : 'Description', _asset.description ?? (isAr ? 'غير متوفر' : 'N/A'), isDark),
          const SizedBox(height: 12),
          _buildInfoRow(isAr ? 'الإجراء' : 'Action', _asset.actionLabel, isDark),
          
          if (_isNormalUser) ...[
            const SizedBox(height: 12),
            _buildInfoRow(isAr ? 'المالك' : 'Creator', _creatorUsername, isDark),
            
            if (_beneficiaries.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildBeneficiariesInline(isAr, isDark),
            ],
          ],
          
          const SizedBox(height: 12),
          _buildInfoRow(
            isAr ? 'آخر تعديل' : 'Last Edited',
            _asset.lastEdited != null
                ? '${_asset.lastEdited!.day}/${_asset.lastEdited!.month}/${_asset.lastEdited!.year} - ${_asset.lastEdited!.hour}:${_asset.lastEdited!.minute.toString().padLeft(2, '0')}'
                : (isAr ? 'غير متوفر' : 'N/A'),
            isDark,
          ),

          if (_asset.fileInfo != null || _isLoadingAsset) ...[
            const SizedBox(height: 20),
            Text(
              isAr ? 'المستند الداعم' : 'Supporting Document',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildDebtSupportingDocCard(isAr, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildDebtSupportingDocCard(bool isAr, bool isDark) {
    if (_isLoadingAsset) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUrl == null || _currentUrl!.isEmpty) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: () => _openFullScreenPreview(context),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _isPdf 
              ? _buildPdfTapToOpen(isAr, isDark) 
              : _isVideo 
                  ? _buildVideoTapToOpen(isAr, isDark) 
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _currentUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDocumentPlaceholder(isAr, isDark),
                        ),
                        Positioned(
                          bottom: 12, right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.open_in_new, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(isAr ? 'عرض الملف' : 'View File', style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  void _openFullScreenPreview(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context, listen: false).locale.languageCode == 'ar';

    if (_isLoadingAsset) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'جاري جلب الملف، يرجى الانتظار...' : 'Fetching file, please wait...')),
      );
      return;
    }

    final url = _currentUrl;
    
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'لا يوجد رابط ملف صالح للعرض' : 'No valid file URL to display')),
      );
      return;
    }
    
    if (_isPdf) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          pdfUrl: url, 
          name: _asset.name,
          assetId: _isNormalUser ? _asset.id : null,
        ),
      )).then((deleted) {
        if (deleted == true) {
          Navigator.pop(context, true); 
        }
      });
    } else if (_isVideo) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoUrl: url, name: _asset.name),
      ));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ImageViewerScreen(imageUrl: url, name: _asset.name),
      ));
    }
  }

  Widget _buildStandardActions(BuildContext context, bool isAr, bool isDark) {
    return Column(
      children: [
        _buildDownloadButton(isAr),
      ],
    );
  }

  Widget _buildDebtActions(BuildContext context, bool isAr, bool isDark) {
    return Column(
      children: [
      ],
    );
  }

  Widget _buildDocumentPlaceholder(bool isAr, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 64, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text(
            isAr ? 'المعاينة غير متاحة' : 'Preview not available',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(bool isAr, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            isAr ? 'الصورة غير متاحة' : 'Image not available',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfTapToOpen(bool isAr, bool isDark) {
    return Container(
      color: isDark ? Colors.grey[800] : Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              isAr ? 'مستند PDF' : 'PDF Document',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.open_in_full, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(isAr ? 'اضغط لفتح المستند' : 'Tap to Open Document',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTapToOpen(bool isAr, bool isDark) {
    return Container(
      color: isDark ? Colors.grey[800] : Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image, size: 80, color: AppColors.primaryBlue),
            const SizedBox(height: 16),
            Text(
              isAr ? 'صورة' : 'Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.open_in_full, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(isAr ? 'اضغط لفتح الصورة' : 'Tap to View Photo',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTapToOpen(bool isAr, bool isDark) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, size: 80, color: AppColors.greenMid),
            const SizedBox(height: 16),
            const Text(
              'Video File',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(isAr ? 'اضغط لتشغيل الفيديو' : 'Tap to Play Video',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton(bool isAr) {
    return ElevatedButton.icon(
      onPressed: _isLoadingAsset ? null : () async {
        final url = _currentUrl;
        if (url != null && url.isNotEmpty) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isAr ? 'لا يمكن فتح الرابط' : 'Could not open URL'), backgroundColor: Colors.red),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isAr ? 'الملف غير متاح' : 'File not available'), backgroundColor: Colors.orange),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.download, color: Colors.white),
      label: _isLoadingAsset
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(isAr ? 'تحميل الأصل' : 'Download Asset',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}