import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../data/models/asset_model.dart';
import '../../providers/app_preferences.dart';
import '../../services/session_manager.dart'; 
import '../../data/models/user_model.dart'; 
import 'asset_viewer_screen.dart'; 

import 'package:erth_app/widgets/viewers/image_viewer_screen.dart';
import 'package:erth_app/widgets/viewers/pdf_viewer_screen.dart';
import 'package:erth_app/widgets/viewers/video_player_screen.dart';

class AssetDetailScreen extends StatefulWidget {
  final AssetModel asset;

  const AssetDetailScreen({Key? key, required this.asset}) : super(key: key);

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  bool _isDeleting = false;
  bool _isEdited = false; 
  String _creatorUsername = 'جاري التحميل...';
  String _sentByUsername = 'غير معروف';
  
  late AssetModel _currentAsset;
  List<String> _beneficiaries = [];

  @override
  void initState() {
    super.initState();
    _currentAsset = widget.asset;
    _fetchCreatorInfo();
  }

  void _openAssetViewer() {
    final currentUser = SessionManager.instance.currentUser;
    final bool isBeneficiary = currentUser?.accountType != AccountType.normal;
    final bool isDebt = _currentAsset.category == AssetCategory.personalDept;

    // 👈 التعديل السحري: إذا كان مستفيد والملف دين شخصي، يفتح الملف مباشرة بدون الفيوير!
    if (isBeneficiary && isDebt) {
      final isAr = Provider.of<AppPreferences>(context, listen: false).locale.languageCode == 'ar';
      final url = _currentAsset.fileInfo?.fileUrl ?? _currentAsset.fileInfo?.previewUrl;

      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'رابط الملف غير متوفر أو جاري تحميله' : 'File URL is not available'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final ext = _currentAsset.fileInfo?.fileExtension.toLowerCase() ?? '';
      final isPdf = ext == 'pdf' || (_currentAsset.category == AssetCategory.officialDocument && !['jpg','jpeg','png'].contains(ext));
      final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(ext) || _currentAsset.category == AssetCategory.video;

      if (isPdf) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(pdfUrl: url, name: _currentAsset.name, assetId: null),
          ),
        );
      } else if (isVideo) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(videoUrl: url, name: _currentAsset.name),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageViewerScreen(imageUrl: url, name: _currentAsset.name),
          ),
        );
      }
    } else {
      // إذا كان المالك، أو قسم غير الدين، يفتح الفيوير الطبيعي
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AssetViewerScreen(asset: _currentAsset),
        ),
      );
    }
  }

  Future<void> _fetchCreatorInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final uri = Uri.parse(
        'https://ruba-gsh7.onrender.com/api/documents/${_currentAsset.id}/',
      );

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
        String fetchedSenderName = 'غير معروف';

        if (data['owner_name'] != null) {
          fetchedName = data['owner_name'].toString();
          fetchedSenderName = data['owner_name'].toString();
        } else if (data['owner'] != null && data['owner'] is Map) {
          fetchedName =
              data['owner']['name']?.toString() ??
              data['owner']['username']?.toString() ??
              'غير معروف';
          fetchedSenderName = fetchedName;
        } else if (data['sender_name'] != null) {
          fetchedName = data['sender_name'].toString();
          fetchedSenderName = data['sender_name'].toString();
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

        DateTime? updatedTime = _currentAsset.lastEdited;
        if (data['updated_at'] != null) {
          try {
            updatedTime = DateTime.parse(data['updated_at'].toString()).toLocal();
          } catch (e) {
            debugPrint('Error parsing updated_at: $e');
          }
        }

        if (mounted) {
          setState(() {
            _creatorUsername = fetchedName;
            _sentByUsername = fetchedSenderName;
            _beneficiaries = fetchedBeneficiaries; 
            
            String? fetchedDebtType = widget.asset.debtType;
            if (data['debt_type'] != null && data['debt_type'].toString().trim().isNotEmpty && data['debt_type'].toString() != 'null') {
              fetchedDebtType = data['debt_type'].toString().trim();
            } else if (data['debtType'] != null && data['debtType'].toString().trim().isNotEmpty && data['debtType'].toString() != 'null') {
              fetchedDebtType = data['debtType'].toString().trim();
            }

            // --------- التعديل السحري هنا للمستفيد ---------
            String? fetchedUrl = data['file_url']?.toString() ?? data['file']?.toString() ?? data['download_url']?.toString();
            AssetFileInfo? updatedFileInfo = _currentAsset.fileInfo;

            if (fetchedUrl != null && fetchedUrl.isNotEmpty) {
              if (updatedFileInfo != null) {
                // إذا المالك داخل وعنده معلومات الملف مسبقاً
                updatedFileInfo = AssetFileInfo(
                  fileName: updatedFileInfo.fileName,
                  fileExtension: updatedFileInfo.fileExtension,
                  fileSizeBytes: updatedFileInfo.fileSizeBytes,
                  fileUrl: fetchedUrl,
                  previewUrl: fetchedUrl,
                );
              } else {
                // إذا المستفيد داخل (معلومات الملف تكون null)، نصنعله معلومات جديدة!
                String ext = 'pdf'; // افتراضي
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
            // ------------------------------------------------

            _currentAsset = _currentAsset.copyWith(
              name: data['title']?.toString() ?? _currentAsset.name,
              description: data['description']?.toString() ?? _currentAsset.description,
              debtType: fetchedDebtType, 
              lastEdited: updatedTime,
              fileInfo: updatedFileInfo, 
            );
          });
        }
      } else {
        debugPrint('Failed to fetch: ${response.statusCode}');
        if (mounted) setState(() {
          _creatorUsername = 'غير معروف';
          _sentByUsername = 'غير معروف';
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() {
        _creatorUsername = 'غير معروف';
        _sentByUsername = 'غير معروف';
      });
    }
  }

  Future<void> _deleteAsset(BuildContext dialogContext, bool isAr) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final uri = Uri.parse(
        'https://ruba-gsh7.onrender.com/api/documents/${_currentAsset.id}/delete/',
      );

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (!mounted) return;
        Navigator.pop(dialogContext);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'تم حذف الأصل بنجاح!' : 'Asset deleted successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'فشل الحذف: ${response.statusCode}'
                  : 'Failed to delete: ${response.statusCode}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(dialogContext);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'حدث خطأ بالاتصال' : 'Connection error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showDeleteDialog(BuildContext context, bool isAr) {
    showDialog(
      context: context,
      barrierDismissible: !_isDeleting,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              isAr ? 'حذف الأصل' : 'Delete asset',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            content: Text(
              isAr
                  ? 'هل أنت متأكد من حذف هذا الأصل نهائياً؟'
                  : 'Are you sure you want to delete your asset?',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isDeleting ? null : () => Navigator.pop(ctx),
                child: Text(
                  isAr ? 'إلغاء' : 'Cancel',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: _isDeleting
                    ? null
                    : () async {
                        setDialogState(() {
                          _isDeleting = true;
                        });
                        await _deleteAsset(ctx, isAr);
                      },
                child: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isAr ? 'نعم' : 'Yes',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDebtDialog(BuildContext context, bool isAr, bool isDark) {
    final nameController = TextEditingController(text: _currentAsset.name);
    final descController = TextEditingController(text: _currentAsset.description);
    String? selectedType = _currentAsset.debtType;
    final formKey = GlobalKey<FormState>();

    final List<String> debtTypes = [
      'قضاء صيام',
      'كفارة حلف',
      'اشتراك جمعيه',
      'زكاة ذهب',
      'أخرى',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSaving = false; 
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Text(
                          isAr ? 'تعديل معلومات الدين' : 'Edit Debt Information',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.lightBlueAccent : AppColors.primaryBlue),
                        ),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                        value: debtTypes.contains(selectedType) ? selectedType : null,
                        decoration: InputDecoration(
                          labelText: isAr ? 'الفئة' : 'Category',
                          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[850] : Colors.white,
                        ),
                        items: debtTypes
                            .map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: isDark ? Colors.white : Colors.black))))
                            .toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedType = val;
                          });
                        },
                        validator: (v) => v == null ? (isAr ? 'مطلوب' : 'Required') : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: isAr ? 'الاسم' : 'Name',
                          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: isDark ? Colors.grey[850] : Colors.white,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descController,
                        maxLines: 3,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: isAr ? 'الوصف' : 'Description',
                          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: isDark ? Colors.grey[850] : Colors.white,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          if (formKey.currentState!.validate() && selectedType != null) {
                            setModalState(() => isSaving = true);
                            
                            try {
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              final token = prefs.getString('auth_token');
                              
                              final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/documents/${_currentAsset.id}/'); 
                              final response = await http.patch(
                                uri,
                                headers: {
                                  'Content-Type': 'application/json',
                                  if (token != null) 'Authorization': 'Token $token',
                                },
                                body: jsonEncode({
                                  'name': nameController.text.trim(),
                                  'description': descController.text.trim(),
                                  'debt_type': selectedType,
                                })
                              );

                              if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 201) {
                                final updatedAsset = _currentAsset.copyWith(
                                  name: nameController.text.trim(),
                                  description: descController.text.trim(),
                                  debtType: selectedType,
                                  lastEdited: DateTime.now(),
                                );

                                setState(() {
                                  _currentAsset = updatedAsset;
                                  _isEdited = true;
                                });

                                if (!mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(isAr ? 'تم تحديث معلومات الدين!' : 'Debt Information Updated!'), backgroundColor: Colors.green),
                                );
                              } else {
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(isAr ? 'فشل تحديث البيانات' : 'Failed to update data'), backgroundColor: Colors.red),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isAr ? 'حدث خطأ بالاتصال' : 'Connection error'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSaving 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isAr ? 'حفظ التغييرات' : 'Save Changes',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 👈 الشارة المرتبة (Sent by)
  Widget _buildSentByBadge(bool isAr, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                  _sentByUsername,
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

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentUser = SessionManager.instance.currentUser;
    final bool isBeneficiary = currentUser?.accountType != AccountType.normal;
    final String beneficiaryName = currentUser?.firstName ?? SessionManager.instance.displayName;
    
    final bool isDebt = _currentAsset.category == AssetCategory.personalDept;

    return WillPopScope(
      onWillPop: () async {
        if (_isEdited) {
          Navigator.pop(context, true);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
        appBar: CustomAppBar(title: isAr ? '${_currentAsset.name}' : '${_currentAsset.name}'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBeneficiary) ...[
                if (!isDebt) ...[
                  _buildInfoField(
                    isAr ? 'اسم المستفيد:' : 'Beneficiary Name:',
                    beneficiaryName,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                ],
                _buildSentByBadge(isAr, isDark),
              ],

              _buildInfoField(isAr ? 'اسم الأصل:' : 'Asset Name:', _currentAsset.name, isDark),
              const SizedBox(height: 16),
              
              if (!isBeneficiary) ...[
                _buildInfoField(isAr ? 'الفئة:' : 'Category :', _currentAsset.categoryLabel, isDark),
                const SizedBox(height: 16),
              ],

              if (isDebt) ...[
                _buildInfoField(
                  isAr ? 'نوع الدين:' : 'Debt Type:',
                  _currentAsset.debtType ?? (isAr ? 'غير متوفر' : 'N/A'),
                  isDark,
                ),
                const SizedBox(height: 16),
                _buildInfoField(
                  isAr ? 'الوصف:' : 'Description:',
                  _currentAsset.description ?? (isAr ? 'غير متوفر' : 'N/A'),
                  isDark,
                ),
                const SizedBox(height: 16),
              ],
              
              if (!isBeneficiary) ...[
                _buildInfoField(isAr ? 'الإجراء:' : 'Action :', _currentAsset.actionLabel, isDark),
                const SizedBox(height: 16),
                
                _buildInfoField(isAr ? 'المالك:' : 'Creator:', _creatorUsername, isDark),
                const SizedBox(height: 16),

                if (_beneficiaries.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: _buildBeneficiariesInline(isAr, isDark),
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              if (_currentAsset.category == AssetCategory.officialDocument &&
                  _currentAsset.classification != null) ...[
                _buildClassificationField(isAr, isDark),
                const SizedBox(height: 16),
              ],

              _buildInfoField(
                isAr ? 'آخر تعديل:' : 'Last Time Edited :',
                _currentAsset.lastEdited != null
                    ? '${_currentAsset.lastEdited!.day}/${_currentAsset.lastEdited!.month}/${_currentAsset.lastEdited!.year} - ${_currentAsset.lastEdited!.hour}:${_currentAsset.lastEdited!.minute.toString().padLeft(2, '0')}'
                    : (isAr ? 'غير متوفر' : 'N/A'),
                isDark,
              ),
              const SizedBox(height: 32),

              if (_currentAsset.fileInfo != null)
                _buildFilePreview(context, isAr, isDark),

              const SizedBox(height: 32),

              _buildViewAssetButton(isAr, isDark),

              if (!isBeneficiary) ...[
                const SizedBox(height: 16),

                if (isDebt) ...[
                  GestureDetector(
                    onTap: () => _showEditDebtDialog(context, isAr, isDark),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isAr ? 'تعديل معلومات الدين' : 'Edit Debt Information',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                GestureDetector(
                  onTap: () => _showDeleteDialog(context, isAr),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'حذف الأصل' : 'Delete Asset',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewAssetButton(bool isAr, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _openAssetViewer,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
          foregroundColor: isDark ? Colors.white : AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        icon: Icon(Icons.visibility_outlined, color: isDark ? Colors.white : AppColors.primaryBlue),
        label: Text(
          isAr ? 'فتح ومعاينة الأصل' : 'Preview Asset',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(color: AppColors.textHint, fontSize: 14),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: isDark ? Colors.lightBlueAccent : AppColors.primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassificationField(bool isAr, bool isDark) {
    Color classColor;
    String classLabel = _currentAsset.classificationLabel;

    switch (_currentAsset.classification!) {
      case AssetClassification.high:
        classColor = Colors.red;
        if (isAr) classLabel = 'عالي';
        break;
      case AssetClassification.medium:
        classColor = Colors.orange;
        if (isAr) classLabel = 'متوسط';
        break;
      case AssetClassification.low:
        classColor = Colors.green;
        if (isAr) classLabel = 'منخفض';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: isAr ? 'التصنيف : ' : 'Classification : ',
              style: const TextStyle(color: AppColors.textHint, fontSize: 14),
            ),
            TextSpan(
              text: classLabel,
              style: TextStyle(
                color: classColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context, bool isAr, bool isDark) {
    final fi = _currentAsset.fileInfo!;
    IconData typeIcon;
    Color typeColor;

    switch (fi.fileExtension.toLowerCase()) {
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

    return GestureDetector(
      onTap: _openAssetViewer,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : const Color(0xFFF0F3F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    size: 36,
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                  ),
                  Positioned(
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        fi.fileExtension.toUpperCase(),
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
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fi.fileName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${fi.fileSizeFormatted} ${isAr ? 'من' : 'of'} ${fi.fileSizeFormatted} •',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAr ? 'مكتمل' : 'Completed',
                        style: const TextStyle(fontSize: 11, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}