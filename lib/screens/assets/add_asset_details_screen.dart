// lib/screens/assets/add_asset_details_screen.dart
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/app_preferences.dart';

class AddAssetDetailsScreen extends StatefulWidget {
  const AddAssetDetailsScreen({Key? key}) : super(key: key);

  @override
  _AddAssetDetailsScreenState createState() => _AddAssetDetailsScreenState();
}

class _AddAssetDetailsScreenState extends State<AddAssetDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  String? _selectedCategory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _selectedCategory = args;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'mp4', 'mov'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _handleSave(bool isAr) async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'يرجى إدخال اسم للأصل' : 'Please enter a name for your asset')),
      );
      return;
    }

    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'يرجى اختيار ملف للرفع' : 'Please select a file to upload')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/documents/upload/');
      SharedPreferences prefs = await SharedPreferences.getInstance();

      final rawToken = prefs.getString('auth_token');
      final token = rawToken?.trim(); 

      var request = http.MultipartRequest('POST', uri);
      
      if (token != null && token.isNotEmpty) {
        request.headers.addAll({
          'Authorization': 'Token $token',
          'Accept': 'application/json',
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'خطأ في المصادقة، يرجى تسجيل الدخول مجدداً' : 'Auth error, please login again'), backgroundColor: Colors.red),
        );
        setState(() => _isUploading = false);
        return;
      }

      request.fields['title'] = name;
      
      String assetType = 'document';
      final ext = _pickedFile!.extension?.toLowerCase() ?? '';
      if (_selectedCategory == 'Photos' || ['jpg', 'jpeg', 'png'].contains(ext)) assetType = 'image';
      if (_selectedCategory == 'Videos' || ['mp4', 'mov'].contains(ext)) assetType = 'video';
      
      request.fields['asset_type'] = assetType;

      MediaType? mediaType;
      if (ext == 'mp4') {
        mediaType = MediaType('video', 'mp4');
      } else if (ext == 'mov') {
        mediaType = MediaType('video', 'quicktime');
      } else if (ext == 'jpg' || ext == 'jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else if (ext == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (ext == 'pdf') {
        mediaType = MediaType('application', 'pdf');
      }

      if (_pickedFile!.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file', 
          _pickedFile!.bytes!, 
          filename: _pickedFile!.name,
          contentType: mediaType,
        ));
      } else if (_pickedFile!.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file', 
          _pickedFile!.path!,
          contentType: mediaType,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        String sensitivityLevel = responseData['sensitivity_level'] ?? 'Medium';
        String newAssetId = responseData['asset_id']?.toString() ?? responseData['id']?.toString() ?? '';

        if (assetType == 'document') {
          _showClassificationDialog(sensitivityLevel, isAr, newAssetId);
        } else {
          _showGenericSuccessDialog(isAr, newAssetId);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'فشل الرفع: ${response.statusCode}' : 'Upload failed: ${response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'خطأ بالاتصال' : 'Connection error'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showClassificationDialog(String classificationLevel, bool isAr, String newAssetId) {
    final levelCapitalized = classificationLevel[0].toUpperCase() + classificationLevel.substring(1).toLowerCase();
    
    String translatedLevel;
    switch (levelCapitalized) {
      case 'High': translatedLevel = isAr ? 'عالي' : 'High'; break;
      case 'Low': translatedLevel = isAr ? 'منخفض' : 'Low'; break;
      default: translatedLevel = isAr ? 'متوسط' : 'Medium'; break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.greenMid.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.greenMid, size: 40),
              ),
              const SizedBox(height: 20),

              Text(
                isAr ? 'تم الرفع بنجاح' : 'Upload successful',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: isAr ? 'تم تصنيف المستندات الخاصة بك بدرجة حساسية\n' : 'Your documents have been classified as\n'),
                    TextSpan(
                      text: isAr ? translatedLevel : '$levelCapitalized sensitivity',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _colorForLevel(levelCapitalized),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: isAr ? 'تم' : 'Done',
                  hasShadow: true,
                  backgroundColor: AppColors.primaryBlue,
                  onPressed: () {
                    Navigator.pop(ctx); 
                    Navigator.pushNamed(context, AppRouter.assetAction, arguments: {'assetId': newAssetId});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGenericSuccessDialog(bool isAr, String newAssetId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.greenMid.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.greenMid, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                isAr ? 'تم الرفع بنجاح' : 'Upload successful',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isAr ? 'تم رفع الملف الخاص بك بنجاح.' : 'Your file has been uploaded successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: isAr ? 'تم' : 'Done',
                  hasShadow: true,
                  backgroundColor: AppColors.primaryBlue,
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, AppRouter.assetAction, arguments: {'assetId': newAssetId});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorForLevel(String level) {
    switch (level) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: '',
        style: AppBarStyle.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      isAr ? 'أضف الأصل الرقمي الخاص بك هنا' : 'Add your digital asset here',
                      style: AppTextStyles.heading2.copyWith(
                        color: isDark ? Colors.lightBlueAccent : AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    _buildUploadArea(isAr, isDark),

                    const SizedBox(height: 30),

                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      child: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: isAr ? 'أدخل اسم الأصل الرقمي' : 'Enter your digital asset name',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: 180,
                      child: CustomButton(
                        text: isAr ? 'حفظ' : 'save',
                        isLoading: _isUploading,
                        backgroundColor: AppColors.primaryBlue,
                        onPressed: () => _handleSave(isAr),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadArea(bool isAr, bool isDark) {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomPaint(
          painter: DashedRectPainter(color: isDark ? Colors.grey[700]! : Colors.grey.shade400),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: _pickedFile == null
                ? _buildEmptyUploadState(isAr, isDark)
                : _buildFileSelectedState(isAr, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyUploadState(bool isAr, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Icon(Icons.cloud_upload_outlined, size: 48, color: isDark ? Colors.white70 : Colors.black87),
        const SizedBox(height: 16),
        Text(
          isAr ? 'اختر ملفاً أو اسحبه وأفلته هنا' : 'Choose a file or drag & drop it here',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          isAr ? 'صيغ JPEG، PNG، PDF، و MP4 حتى 50 ميغابايت' : 'JPEG, PNG, PDF, and MP4 formats, up to 50 MB',
          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey.shade500, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isAr ? 'تصفح الملفات' : 'Browse File',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFileSelectedState(bool isAr, bool isDark) {
    final file = _pickedFile!;
    final sizeKb = (file.size / 1024).toStringAsFixed(0);
    final ext = file.extension ?? '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          ext == 'pdf'
              ? Icons.picture_as_pdf
              : (ext == 'mp4' || ext == 'mov')
                  ? Icons.videocam
                  : Icons.image,
          size: 40,
          color: ext == 'pdf'
              ? Colors.red
              : (ext == 'mp4' || ext == 'mov')
                  ? AppColors.greenMid
                  : AppColors.primaryBlue,
        ),
        const SizedBox(height: 12),
        Text(
          file.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '$sizeKb KB • ${ext.toUpperCase()}',
          style: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryBlue),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isAr ? 'تغيير الملف' : 'Change File',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset((startX + dashWidth).clamp(0, size.width), 0), paint);
      startX += dashWidth + dashSpace;
    }
    startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, size.height), Offset((startX + dashWidth).clamp(0, size.width), size.height), paint);
      startX += dashWidth + dashSpace;
    }
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, (startY + dashWidth).clamp(0, size.height)), paint);
      startY += dashWidth + dashSpace;
    }
    startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width, startY), Offset(size.width, (startY + dashWidth).clamp(0, size.height)), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}