// lib/screens/assets/category_assets_screen.dart
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/routing/app_router.dart';
import '../../widgets/custom_app_bar.dart';
import '../../data/models/asset_model.dart';
import '../../services/session_manager.dart';
import '../../data/models/user_model.dart';
import '../../providers/app_preferences.dart';

/// Displays assets filtered by category.
class CategoryAssetsScreen extends StatefulWidget {
  final AssetCategory? category;

  const CategoryAssetsScreen({Key? key, this.category}) : super(key: key);

  @override
  State<CategoryAssetsScreen> createState() => _CategoryAssetsScreenState();
}

class _CategoryAssetsScreenState extends State<CategoryAssetsScreen> {
  List<AssetModel> _assets = [];
  bool _isLoading = true;
  bool _isClassificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowClassificationDialog();
    });
  }

  void _checkAndShowClassificationDialog() {
    final isNormalUser = SessionManager.instance.currentUser?.accountType == AccountType.normal;
    if (isNormalUser && widget.category == AssetCategory.officialDocument) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.3),
        builder: (ctx) => _buildClassificationDialog(ctx),
      );
    }
  }

  Widget _buildClassificationDialog(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? Colors.grey[900] : AppColors.cardBackground,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isAr ? 'التصنيف الذكي للمستندات' : 'Smart Document Classification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                isAr 
                ? 'عند رفع مستند، يقوم نظامنا تلقائياً بقراءته وفرزه في الفئة الصحيحة (مثل وصية، سند ملكية، هوية). هذا يوفر وقتك ويبقي ملفاتك منظمة.'
                : 'When you upload a document, our system automatically reads and sorts it into the right category (e.g. will, property deed, ID). This saves you time and keeps your files organized.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: isAr ? TextAlign.right : TextAlign.left,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _isClassificationEnabled = false);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(isAr ? 'ليس الآن' : 'Not now',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _isClassificationEnabled = true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        isAr ? 'تفعيل التصنيف التلقائي' : 'Enable Auto-Classification',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

    Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    
    try {
      // 👈 1. فحص نوع الحساب الحالي (هل هو مستفيد أم مالك؟)
      final isBeneficiary = SessionManager.instance.currentUser?.accountType == AccountType.beneficiary;
      
      // 👈 2. بناء الرابط بناءً على النتيجة
      final String urlString = isBeneficiary 
          ? 'https://ruba-gsh7.onrender.com/api/documents/?role=beneficiary'
          : 'https://ruba-gsh7.onrender.com/api/documents/';
          
      final uri = Uri.parse(urlString);
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final String responseString = utf8.decode(response.bodyBytes, allowMalformed: true);
        final dynamic decodedData = jsonDecode(responseString);
        
        List<dynamic> data = [];
        if (decodedData is List) {
          data = decodedData;
        } else if (decodedData is Map && decodedData.containsKey('results')) {
          data = decodedData['results'];
        } else if (decodedData is Map) {
          data = [decodedData];
        }
        
        List<AssetModel> fetchedAssets = [];
        
        for (var item in data) {
          try {
            if (item == null) continue;
            final Map<String, dynamic> json = Map<String, dynamic>.from(item);
            
            // قراءة الرابط
            String fileUrl = json['file_url']?.toString() ?? json['file']?.toString() ?? '';
            String extension = '';
            String fileName = json['title']?.toString() ?? 'ملف';
            
            if (fileUrl.isNotEmpty) {
              try {
                final Uri parsedUri = Uri.parse(fileUrl);
                if (parsedUri.pathSegments.isNotEmpty) {
                  fileName = parsedUri.pathSegments.last;
                  if (fileName.contains('.')) {
                    extension = fileName.split('.').last.toLowerCase().trim();
                  }
                }
              } catch (e) {
                final parts = fileUrl.split('?').first.split('/');
                fileName = parts.last;
                if (fileName.contains('.')) {
                  extension = fileName.split('.').last.toLowerCase().trim();
                }
              }
            }

            // تحويل تصنيفات الباك إند لتصنيفات الفلاتر
            AssetCategory determinedCategory = _determineCategory(json['asset_type']?.toString(), extension);
            AssetClassification determinedClass = _determineClassification(json['sensitivity_level']?.toString());
            AssetAction determinedAction = _parseAssetAction(json['posthumous_action']?.toString());

            fetchedAssets.add(AssetModel(
              id: json['asset_id']?.toString() ?? UniqueKey().toString(),
              name: json['title']?.toString() ?? 'بدون عنوان',
              description: json['description']?.toString(),
              category: determinedCategory,
              classification: determinedClass,
              action: determinedAction,
              fileInfo: AssetFileInfo(
                fileName: fileName,
                fileExtension: extension,
                fileSizeBytes: 1024, // للسهولة
                fileUrl: fileUrl, // تمرير الرابط لضمان فتحه للمستفيد
                previewUrl: fileUrl,
              ),
            ));
          } catch (innerError) {
            debugPrint('⚠️ خطأ في معالجة أحد الملفات: $innerError');
          }
        }

        if (widget.category != null) {
          fetchedAssets = fetchedAssets.where((a) => a.category == widget.category).toList();
        }

        if (mounted) {
          setState(() {
            _assets = fetchedAssets;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
        debugPrint('Failed to load assets: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading assets: $e');
    }
  }


  AssetAction _parseAssetAction(String? actionStr) {
    if (actionStr == null || actionStr.isEmpty) return AssetAction.values.first;
    final str = actionStr.toLowerCase();
    for (var action in AssetAction.values) {
      final enumName = action.toString().split('.').last.toLowerCase();
      if (str.contains(enumName) || enumName.contains(str) || (str == 'delete_after_death' && enumName.contains('delete'))) {
        return action;
      }
    }
    return AssetAction.values.first; 
  }

  AssetCategory _determineCategory(String? dbTypeRaw, String extension) {
    final dbType = dbTypeRaw?.toLowerCase() ?? '';
    if (dbType == 'debt' || dbType == 'personal_debt') return AssetCategory.personalDept;

    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'];
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv'];

    if (imageExtensions.contains(extension) || dbType.contains('image')) {
      return AssetCategory.photo;
    } else if (videoExtensions.contains(extension) || dbType.contains('video')) {
      return AssetCategory.video;
    }
    return AssetCategory.officialDocument;
  }

  AssetClassification _determineClassification(String? sensitivity) {
    if (sensitivity == null) return AssetClassification.medium;
    switch (sensitivity.toLowerCase()) {
      case 'high': return AssetClassification.high;
      case 'low': return AssetClassification.low;
      default: return AssetClassification.medium;
    }
  }

  String _getTitle(bool isAr) {
    if (widget.category == null) return isAr ? 'جميع الأصول' : 'All Assets';
    switch (widget.category!) {
      case AssetCategory.officialDocument:
        return isAr ? 'المستندات الرسمية' : 'Official Documents';
      case AssetCategory.photo:
        return isAr ? 'الصور' : 'Photos';
      case AssetCategory.video:
        return isAr ? 'مقاطع الفيديو' : 'Videos';
      case AssetCategory.personalDept:
        return isAr ? 'الديون الشخصية' : 'Personal Debts';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: CustomAppBar(title: _getTitle(isAr)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.category == AssetCategory.officialDocument &&
                  _isClassificationEnabled
              ? _buildClassifiedView(isAr, isDark)
              : _buildFlatGrid(isAr, isDark),
    );
  }

  Widget _buildClassifiedView(bool isAr, bool isDark) {
    final highAssets = _assets.where((a) => a.classification == AssetClassification.high).toList();
    final medAssets = _assets.where((a) => a.classification == AssetClassification.medium).toList();
    final lowAssets = _assets.where((a) => a.classification == AssetClassification.low).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildClassificationSection(isAr ? 'عالي الأهمية' : 'HIGH', highAssets, Colors.red, isDark),
          const SizedBox(height: 16),
          _buildClassificationSection(isAr ? 'متوسط الأهمية' : 'MEDIUM', medAssets, Colors.orange, isDark),
          const SizedBox(height: 16),
          _buildClassificationSection(isAr ? 'منخفض الأهمية' : 'LOW', lowAssets, Colors.green, isDark),
        ],
      ),
    );
  }

  Widget _buildClassificationSection(String label, List<AssetModel> assets, Color textColor, bool isDark) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        children: [
          _buildAssetGrid(assets, isDark),
        ],
      ),
    );
  }

  Widget _buildAssetGrid(List<AssetModel> assets, bool isDark) {
    final isAr = Provider.of<AppPreferences>(context, listen: false).locale.languageCode == 'ar';
    
    if (assets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(isAr ? 'لا توجد أصول هنا' : 'No assets', style: const TextStyle(color: AppColors.textHint)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) => _buildFileCard(assets[index], isDark),
    );
  }

  Widget _buildFlatGrid(bool isAr, bool isDark) {
    if (_assets.isEmpty) {
      return Center(
        child: Text(isAr ? 'لا توجد أصول هنا' : 'No assets', style: const TextStyle(color: AppColors.textHint)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _assets.length,
        itemBuilder: (context, index) => _buildFileCard(_assets[index], isDark),
      ),
    );
  }

  Widget _buildFileCard(AssetModel asset, bool isDark) {
    final fileInfo = asset.fileInfo;
    IconData typeIcon;
    Color typeColor;

    if (asset.category == AssetCategory.personalDept) {
      typeIcon = Icons.description_outlined;
      typeColor = AppColors.primaryBlue;
    } else {
      switch (fileInfo?.fileExtension.toLowerCase() ?? '') {
        case 'pdf':
          typeIcon = Icons.picture_as_pdf;
          typeColor = Colors.red;
          break;
        case 'png':
        case 'jpg':
        case 'jpeg':
          typeIcon = Icons.image;
          typeColor = AppColors.primaryBlue;
          break;
        case 'mp4':
        case 'mov':
          typeIcon = Icons.videocam;
          typeColor = AppColors.greenMid;
          break;
        default:
          typeIcon = Icons.insert_drive_file;
          typeColor = AppColors.textHint;
      }
    }

    final isBeneficiary = SessionManager.instance.currentUser?.accountType == AccountType.beneficiary;

    return GestureDetector(
      onTap: () async {
        if (asset.category == AssetCategory.personalDept) {
          // 👈 التعديل المنقذ هنا: توجيه الديون إلى شاشة التفاصيل (AssetDetail) بدل العارض
          final result = await Navigator.pushNamed(
            context, 
            AppRouter.assetDetail, 
            arguments: asset
          );
          
          // 👈 تحديث القائمة إذا تم حذف أو تعديل الدين
          if (result == true) {
            _loadAssets();
          }
        } else {
          final result = await Navigator.pushNamed(
            context,
            isBeneficiary ? AppRouter.assetViewer : AppRouter.assetDetail,
            arguments: asset,
          );
          
          // إذا انحذف الملف من شاشة التفاصيل، نحدث القائمة هنا
          if (result == true) {
            _loadAssets();
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(typeIcon, size: 48, color: isDark ? Colors.grey[600] : Colors.grey[300]),
                Positioned(
                  bottom: 0,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (fileInfo?.fileExtension ?? '').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                fileInfo?.fileName ?? asset.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            if (fileInfo != null && fileInfo.fileSizeFormatted.isNotEmpty && fileInfo.fileSizeFormatted != '0 B')
              Text(
                '${fileInfo.fileSizeFormatted} •',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textHint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}