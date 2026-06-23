// lib/screens/beneficiary/add_asset_beneficiary_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../providers/app_preferences.dart';

/// Form screen for adding a new beneficiary.
class AddAssetBeneficiaryScreen extends StatefulWidget {
  const AddAssetBeneficiaryScreen({Key? key}) : super(key: key);

  @override
  State<AddAssetBeneficiaryScreen> createState() =>
      _AddAssetBeneficiaryScreen();
}

class _AddAssetBeneficiaryScreen extends State<AddAssetBeneficiaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _otherRelationshipController = TextEditingController();
  bool _isLoading = false;

  String? _selectedRelationship;
  bool _showOtherField = false;

  static const List<String> _relationshipsKeys = [
    'Father',
    'Mother',
    'Wife',
    'Husband',
    'Sister',
    'Brother',
    'Son',
    'Daughter',
    'Other',
  ];

  String _translateRel(String key, bool isAr) {
    if (!isAr) return key;
    switch (key) {
      case 'Father': return 'أب';
      case 'Mother': return 'أم';
      case 'Wife': return 'زوجة';
      case 'Husband': return 'زوج';
      case 'Sister': return 'أخت';
      case 'Brother': return 'أخ';
      case 'Son': return 'ابن';
      case 'Daughter': return 'ابنة';
      case 'Other': return 'أخرى';
      default: return key;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _otherRelationshipController.dispose();
    super.dispose();
  }

  Future<void> _handleAdd(bool isAr) async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_selectedRelationship == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(isAr ? 'يرجى اختيار صلة القرابة' : 'Please select a relationship'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/users/beneficiaries/');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'national_id': _nationalIdController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'relationship': _finalRelationship,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم إضافة المستفيد بنجاح!' : 'Beneficiary added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        navigator.pop(true); 
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(isAr ? 'فشل الإضافة: ${response.statusCode}' : 'Failed to add beneficiary: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(isAr ? 'حدث خطأ بالاتصال' : 'Connection error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _finalRelationship {
    if (_selectedRelationship == 'Other') {
      return _otherRelationshipController.text.trim();
    }
    return _selectedRelationship ?? '';
  }

  String? _validatePhone(String? v, bool isAr) {
    if (v == null || v.trim().isEmpty) return isAr ? 'يرجى إدخال رقم الهاتف' : 'Please enter phone number';
    return null;
  }

  String? _validateEmail(String? v, bool isAr) {
    if (v == null || v.trim().isEmpty) return isAr ? 'يرجى إدخال البريد الإلكتروني' : 'Please enter email';
    final email = v.trim();
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return isAr ? 'يرجى إدخال بريد صحيح' : 'Please enter a valid email';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: isAr ? 'مستفيد جديد' : 'New Beneficiary',
        style: AppBarStyle.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'إضافة مستفيد جديد' : 'New Beneficiary',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        label: isAr ? 'الاسم الأول' : 'First name',
                        controller: _firstNameController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                      ),
                      CustomTextField(
                        label: isAr ? 'الاسم الأخير' : 'Last name',
                        controller: _lastNameController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                      ),

                      // National ID
                      CustomTextField(
                        label: isAr ? 'الرقم الوطني' : 'National ID',
                        controller: _nationalIdController,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                      ),
                      CustomTextField(
                        label: isAr ? 'رقم الهاتف' : 'Phone number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (v) => _validatePhone(v, isAr),
                      ),
                      CustomTextField(
                        label: isAr ? 'البريد الإلكتروني' : 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => _validateEmail(v, isAr),
                      ),

                      // Relationship dropdown
                      const SizedBox(height: 4),
                      _buildRelationshipDropdown(isAr, isDark),

                      // "Other" text field
                      if (_showOtherField) ...[
                        const SizedBox(height: 8),
                        CustomTextField(
                          label: isAr ? 'حدد صلة القرابة' : 'Specify relationship',
                          controller: _otherRelationshipController,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? (isAr ? 'يرجى التحديد' : 'Please specify')
                              : null,
                        ),
                      ],

                      const SizedBox(height: 20),
                      CustomButton(
                        text: isAr ? 'إضافة' : 'Add',
                        hasShadow: true,
                        isLoading: _isLoading,
                        backgroundColor: AppColors.primaryBlueDark,
                        onPressed: () => _handleAdd(isAr),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipDropdown(bool isAr, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'صلة القرابة' : 'Relationship',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: isDark ? Colors.grey[800] : Colors.white,
              value: _selectedRelationship,
              hint: Text(
                isAr ? 'اختر صلة القرابة' : 'Select relationship',
                style: const TextStyle(color: AppColors.textHint, fontSize: 14),
              ),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textHint),
              items: _relationshipsKeys.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(
                    _translateRel(r, isAr), 
                    style: TextStyle(color: isDark ? Colors.white : Colors.black)
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedRelationship = val;
                  _showOtherField = val == 'Other';
                  if (!_showOtherField) {
                    _otherRelationshipController.clear();
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}