// lib/screens/home/beneficiary_home_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/asset_model.dart';
import '../../services/session_manager.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/app_preferences.dart';
import '../assets/asset_detail_screen.dart'; // 👈 تم التعديل إلى شاشة التفاصيل الصحيحة

/// Home screen for beneficiary accounts.
class BeneficiaryHomeScreen extends StatefulWidget {
  const BeneficiaryHomeScreen({Key? key}) : super(key: key);

  @override
  State<BeneficiaryHomeScreen> createState() => _BeneficiaryHomeScreenState();
}

class _BeneficiaryHomeScreenState extends State<BeneficiaryHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<AssetModel> _allAssets = <AssetModel>[];
  List<AssetModel> _filteredAssets = <AssetModel>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    _scrollController.dispose(); 
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/documents/?role=beneficiary');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        await prefs.remove('auth_token');
        SessionManager.instance.clear();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false);
        return;
      }

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
          if (item == null) continue;
          final Map<String, dynamic> json = Map<String, dynamic>.from(item);

          String fileUrl = json['file_url']?.toString() ?? json['download_url']?.toString() ?? json['file']?.toString() ?? '';
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

          AssetCategory cat = _determineCategory(json['asset_type']?.toString(), extension);
          AssetClassification cls = _determineClassification(json['sensitivity_level']?.toString());
          AssetAction act = _parseAssetAction(json['posthumous_action']?.toString());

          fetchedAssets.add(AssetModel(
            id: json['asset_id']?.toString() ?? UniqueKey().toString(),
            name: json['title']?.toString() ?? 'بدون عنوان',
            description: json['description']?.toString(),
            category: cat,
            classification: cls,
            action: act,
            fileInfo: AssetFileInfo(
              fileName: fileName,
              fileExtension: extension,
              fileSizeBytes: 1024,
              fileUrl: fileUrl,
              previewUrl: fileUrl, 
            ),
          ));
        }

        if (mounted) {
          setState(() {
            _allAssets = fetchedAssets;
            // 👈 تطبيق البحث التلقائي
            final q = _searchController.text.trim().toLowerCase();
            _filteredAssets = q.isEmpty 
                ? fetchedAssets 
                : fetchedAssets.where((a) => a.name.toLowerCase().contains(q)).toList();
            _isLoading = false;
          });
          print("🚨 Total Assets Fetched: ${_allAssets.length}"); 
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  AssetCategory _determineCategory(String? dbTypeRaw, String extension) {
    final dbType = dbTypeRaw?.toLowerCase() ?? '';
    if (dbType == 'debt' || dbType == 'personal_debt') return AssetCategory.personalDept;
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'];
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv'];
    if (imageExtensions.contains(extension) || dbType.contains('image')) return AssetCategory.photo;
    if (videoExtensions.contains(extension) || dbType.contains('video')) return AssetCategory.video;
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

  void _onSearch() {
    final String q = _searchController.text.trim().toLowerCase();

    setState(() {
      if (q.isEmpty) {
        _filteredAssets = _allAssets;
      } else {
        _filteredAssets = _allAssets.where((AssetModel a) {
          return a.name.toLowerCase().contains(q) ||
              a.categoryLabel.toLowerCase().contains(q) ||
              (a.fileInfo?.fileName.toLowerCase().contains(q) ?? false);
        }).toList();
      }
    });
  }

  int _countByCategory(AssetCategory cat) {
    return _filteredAssets.where((AssetModel a) => a.category == cat).length;
  }

  Color _mix(Color base, Color target, double amount) {
    return Color.lerp(base, target, amount) ?? base;
  }

  @override
  Widget build(BuildContext context) {
    final String name = SessionManager.instance.displayName;
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: isAr ? 'مرحباً، ${name.toUpperCase()}' : 'HI, ${name.toUpperCase()}',
        style: AppBarStyle.large,
        showBackButton: false,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                thickness: 6.0,
                radius: const Radius.circular(10),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(isAr, isDark),
                      const SizedBox(height: 24),
                      
                      // 👈 نتائج البحث
                      if (_searchController.text.isNotEmpty)
                        _buildSearchResults(isAr, isDark)
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isAr ? 'أصولك الرقمية\nالموروثة' : 'YOUR INHERITED DIGITAL\nASSETS',
                                style: AppTextStyles.heading3.copyWith(
                                  color: isDark ? Colors.lightBlueAccent : AppColors.primaryBlue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRouter.categoryAssets,
                                  arguments: null,
                                ).then((_) => _loadAssets());
                              },
                              child: Text(
                                isAr ? 'عرض الكل' : 'View All',
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryCard(
                          label: isAr ? 'المستندات الرسمية' : 'OFFICIAL DOCUMENT',
                          icon: Icons.description_outlined,
                          count: _countByCategory(AssetCategory.officialDocument),
                          baseColor: const Color(0xFF95A7BF),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.categoryAssets,
                            arguments: AssetCategory.officialDocument,
                          ).then((_) => _loadAssets()),
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryCard(
                          label: isAr ? 'الصور' : 'PHOTOS',
                          icon: Icons.camera_alt_outlined,
                          count: _countByCategory(AssetCategory.photo),
                          baseColor: const Color(0xFF99B5AE),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.categoryAssets,
                            arguments: AssetCategory.photo,
                          ).then((_) => _loadAssets()),
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryCard(
                          label: isAr ? 'الفيديو' : 'VIDEOS',
                          icon: Icons.videocam_outlined,
                          count: _countByCategory(AssetCategory.video),
                          baseColor: const Color(0xFF98A3BD),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.categoryAssets,
                            arguments: AssetCategory.video,
                          ).then((_) => _loadAssets()),
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryCard(
                          label: isAr ? 'الديون الشخصية' : 'PERSONAL DEPTS',
                          icon: Icons.description_outlined,
                          count: _countByCategory(AssetCategory.personalDept),
                          baseColor: const Color(0xFFB0A6C1),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.categoryAssets,
                            arguments: AssetCategory.personalDept,
                          ).then((_) => _loadAssets()),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSearchBar(bool isAr, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : AppColors.divider),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: isAr ? 'بحث' : 'search',
          hintStyle: TextStyle(color: isDark ? Colors.grey[500] : AppColors.textHint, fontSize: 14),
          suffixIcon: Icon(Icons.search, color: isDark ? Colors.grey[500] : AppColors.textHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isAr, bool isDark) {
    if (_filteredAssets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Center(
          child: Text(
            isAr ? 'لا توجد نتائج مطابقة لبحثك' : 'No results found',
            style: const TextStyle(color: AppColors.textHint, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredAssets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final asset = _filteredAssets[index];
        return InkWell(
          onTap: () {
            // 👈 تم الربط هنا بـ AssetDetailScreen لفتح التفاصيل
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssetDetailScreen(asset: asset),
              ),
            ).then((_) => _loadAssets());
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey[700]! : AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    asset.category == AssetCategory.officialDocument ? Icons.description_outlined :
                    asset.category == AssetCategory.photo ? Icons.image_outlined :
                    asset.category == AssetCategory.video ? Icons.videocam_outlined :
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        asset.categoryLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard({
    required String label,
    required IconData icon,
    required int count,
    required Color baseColor,
    required VoidCallback onTap,
  }) {
    final Color backgroundTop = _mix(baseColor, Colors.white, 0.08);
    final Color backgroundBottom = _mix(baseColor, Colors.black, 0.08);
    final Color pillColor = Colors.black.withOpacity(0.35);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 156,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                backgroundTop,
                baseColor,
                backgroundBottom,
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                bottom: 68,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            size: 50,
                            color: Colors.white.withOpacity(0.70),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 44,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            letterSpacing: 1.0,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white.withOpacity(0.95),
                          size: 20,
                        ),
                      ),
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

  Widget _buildInfoRow(String title, String description, bool isAr, bool isDark) {
    return GestureDetector(
      onTap: () => _showInfoDialog(title, description, isAr, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.grey[700]! : AppColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Text(
              isAr ? 'التفاصيل' : 'Details',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String description, bool isAr, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[300] : AppColors.textSecondary,
            height: 1.5,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isAr ? 'فهمت ذلك' : 'I Understand',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}