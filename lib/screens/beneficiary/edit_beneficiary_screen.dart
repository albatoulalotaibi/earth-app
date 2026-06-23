import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/beneficiary_model.dart';
import '../../providers/app_preferences.dart';

class EditBeneficiaryScreen extends StatefulWidget {
  final BeneficiaryModel beneficiary;

  const EditBeneficiaryScreen({Key? key, required this.beneficiary})
      : super(key: key);

  @override
  State<EditBeneficiaryScreen> createState() => _EditBeneficiaryScreenState();
}

class _EditBeneficiaryScreenState extends State<EditBeneficiaryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _nationalIdController; 
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _relationshipController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.beneficiary;
    _firstNameController = TextEditingController(text: b.firstName);
    _lastNameController = TextEditingController(text: b.lastName);
    _nationalIdController = TextEditingController(text: b.nationalId ?? ''); 
    _phoneController = TextEditingController(text: b.phone);
    _emailController = TextEditingController(text: b.email);
    _relationshipController = TextEditingController(text: b.relationship);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _save(bool isAr) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final String beneficiaryId = widget.beneficiary.id ?? '';
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/users/beneficiaries/$beneficiaryId/');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.patch(
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
          'relationship': _relationshipController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final updated = widget.beneficiary.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          nationalId: _nationalIdController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          relationship: _relationshipController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم حفظ التعديلات بنجاح' : 'Changes saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(updated);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'حدث خطأ أثناء الحفظ' : 'Failed to save changes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'خطأ في الاتصال بالسيرفر' : 'Connection error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: CustomAppBar(title: isAr ? 'تعديل المستفيد' : 'Edit Beneficiary'),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: isAr ? 'الاسم الأول' : 'First name',
                controller: _firstNameController,
                validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
              ),
              CustomTextField(
                label: isAr ? 'الاسم الأخير' : 'Last name',
                controller: _lastNameController,
                validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
              ),
              CustomTextField(
                label: isAr ? 'الرقم الوطني / الهوية' : 'National ID',
                controller: _nationalIdController,
                keyboardType: TextInputType.number,
              ),
              CustomTextField(
                label: isAr ? 'رقم الهاتف' : 'Phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              CustomTextField(
                label: isAr ? 'البريد الإلكتروني' : 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              CustomTextField(
                label: isAr ? 'صلة القرابة' : 'Relationship',
                controller: _relationshipController,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: isAr ? 'إلغاء' : 'Cancel',
                      isOutlined: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: isAr ? 'حفظ' : 'Save',
                      isLoading: _isSaving,
                      backgroundColor: AppColors.primaryBlue,
                      onPressed: () => _save(isAr),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}