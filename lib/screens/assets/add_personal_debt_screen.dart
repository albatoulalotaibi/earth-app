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
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/app_preferences.dart';

class AddPersonalDebtScreen extends StatefulWidget {
  const AddPersonalDebtScreen({Key? key}) : super(key: key);

  @override
  _AddPersonalDebtScreenState createState() => _AddPersonalDebtScreenState();
}

class _AddPersonalDebtScreenState extends State<AddPersonalDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedDebtType;
  bool _isTypeDropdownOpen = false;
  
  PlatformFile? _pickedFile; 
  bool _isUploading = false; 

  final List<String> _debtTypesKeys = [
    'قضاء صيام',
    'كفارة حلف',
    'اشتراك جمعيه',
    'زكاة ذهب',
    'أخرى',
  ];

  String _translateType(String key, bool isAr) {
    if (isAr) return key;
    switch (key) {
      case 'قضاء صيام': return 'Fasting Make-up';
      case 'كفارة حلف': return 'Oath Expiation';
      case 'اشتراك جمعيه': return 'Association Sub';
      case 'زكاة ذهب': return 'Gold Zakat';
      case 'أخرى': return 'Other';
      default: return key;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

 Future<void> _handleSave(bool isAr) async {
    if (!_formKey.currentState!.validate() || _selectedDebtType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'يرجى اختيار الفئة وملء الحقول المطلوبة' : 'Please select Category and fill all required fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/documents/upload/');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      var request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Token $token';

      request.fields['title'] = _nameController.text.trim();

      request.fields['description'] = _descriptionController.text.trim();
      request.fields['debt_type'] = _selectedDebtType!; 
      
      request.fields['asset_type'] = 'personal_debt'; 
      request.fields['posthumous_action'] = 'transfer';

      if (_pickedFile != null) {
        MediaType? mediaType;
        final ext = _pickedFile!.extension?.toLowerCase() ?? '';
        if (ext == 'jpg' || ext == 'jpeg') mediaType = MediaType('image', 'jpeg');
        else if (ext == 'png') mediaType = MediaType('image', 'png');
        else if (ext == 'pdf') mediaType = MediaType('application', 'pdf');

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
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        String newAssetId = responseData['asset_id']?.toString() ?? responseData['id']?.toString() ?? '';

        Navigator.pushNamed(context, AppRouter.assetAction, arguments: {'assetId': newAssetId});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'فشل الحفظ: ${response.statusCode}' : 'Failed to save: ${response.statusCode}'), backgroundColor: Colors.red),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    isAr ? 'أضف دين شخصي' : 'Add Personal Debt',
                    style: AppTextStyles.heading2.copyWith(
                      color: isDark ? Colors.lightBlueAccent : AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Dropdown for Debt Type
                  _buildDropdown(isAr, isDark),

                  const SizedBox(height: 20),

                  // Name Field
                  CustomTextField(
                    label: isAr ? 'الاسم' : 'Name',
                    controller: _nameController,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                  ),

                  const SizedBox(height: 20),

                  // Description Field
                  CustomTextField(
                    label: isAr ? 'الوصف' : 'Description',
                    maxLines: 3,
                    controller: _descriptionController,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                  ),

                  const SizedBox(height: 30),

                  // Upload Area
                  _buildUploadArea(isAr, isDark),

                  const SizedBox(height: 30),

                  const SizedBox(height: 40),

                  // Save button
                  SizedBox(
                    width: 180,
                    child: CustomButton(
                      text: isAr ? 'حفظ' : 'save',
                      isLoading: _isUploading,
                      backgroundColor: AppColors.primaryBlue,
                      onPressed: () => _handleSave(isAr),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildDropdown(bool isAr, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isTypeDropdownOpen = !_isTypeDropdownOpen;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDebtType != null ? _translateType(_selectedDebtType!, isAr) : (isAr ? 'الفئة' : 'Category'),
                  style: TextStyle(
                    color: _selectedDebtType != null
                        ? (isDark ? Colors.white : AppColors.textPrimary)
                        : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  _isTypeDropdownOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
        if (_isTypeDropdownOpen)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: _debtTypesKeys.map((type) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDebtType = type;
                      _isTypeDropdownOpen = false;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: AppColors.divider.withOpacity(0.5))),
                    ),
                    child: Text(
                      _translateType(type, isAr),
                      style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
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
          border: Border.all(color: AppColors.divider),
        ),
        child: CustomPaint(
          painter: DashedRectPainter(color: isDark ? Colors.grey[700]! : Colors.grey.shade400),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Icon(
                  _pickedFile == null ? Icons.cloud_upload_outlined : Icons.insert_drive_file,
                  size: 48, 
                  color: isDark ? Colors.grey[400] : Colors.grey
                ),
                const SizedBox(height: 16),
                Text(
                  _pickedFile == null 
                      ? (isAr ? 'رفع مستند إثبات (اختياري)' : 'Upload optional supporting document')
                      : _pickedFile!.name,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _pickedFile == null ? (isAr ? 'تصفح الملفات' : 'Browse File') : (isAr ? 'تغيير الملف' : 'Change File'),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
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
      canvas.drawLine(Offset(startX, 0),
          Offset((startX + dashWidth).clamp(0, size.width), 0), paint);
      startX += dashWidth + dashSpace;
    }
    startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
          Offset(startX, size.height),
          Offset((startX + dashWidth).clamp(0, size.width), size.height),
          paint);
      startX += dashWidth + dashSpace;
    }
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY),
          Offset(0, (startY + dashWidth).clamp(0, size.height)), paint);
      startY += dashWidth + dashSpace;
    }
    startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
          Offset(size.width, startY),
          Offset(size.width, (startY + dashWidth).clamp(0, size.height)),
          paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}