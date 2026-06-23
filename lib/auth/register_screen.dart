// lib/screens/auth/register_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/routing/app_router.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../providers/app_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isBeneficiary = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dynamic args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['isBeneficiary'] == true) {
      _isBeneficiary = true;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(bool isAr) async {
    if (_isBeneficiary) {
       Navigator.pushReplacementNamed(context, AppRouter.accessCode);
       return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/users/register/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _idController.text.trim(), 
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(), 
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم إنشاء الحساب بنجاح!' : 'Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacementNamed(context, AppRouter.login);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'فشل التسجيل. تأكد من البيانات' : 'Registration failed. Check details.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'خطأ بالاتصال' : 'Connection Error'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: CustomAppBar(title: isAr ? 'إنشاء حساب جديد' : 'Create New Account'),
      body: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: ClipPath(
              clipper: _TriangleClipper(),
              child: Container(
                width: 220,
                height: 220,
                color: isDark ? AppColors.greenDark.withOpacity(0.5) : AppColors.greenDark,
              ),
            ),
          ),
          _buildFormCard(isAr, isDark),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isAr, bool isDark) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: isAr ? 'الاسم الأول' : 'First name',
                        controller: _firstNameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: isAr ? 'الاسم الأخير' : 'Last name',
                        controller: _lastNameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                      ),
                    ),
                  ],
                ),

                CustomTextField(
                  label: isAr ? 'رقم الهوية' : 'ID',
                  controller: _idController,
                  keyboardType: TextInputType.text,
                  validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'يرجى إدخال الهوية' : 'Please enter your ID') : null,
                ),

                CustomTextField(
                  label: isAr ? 'البريد الإلكتروني' : 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return isAr ? 'يرجى إدخال الإيميل' : 'Please enter your email';
                    if (!v.contains('@')) return isAr ? 'إيميل غير صالح' : 'Please enter a valid email';
                    return null;
                  },
                ),

                CustomTextField(
                  label: isAr ? 'رقم الهاتف' : 'Phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'يرجى إدخال رقم الهاتف' : 'Please enter your phone number') : null,
                ),

                CustomTextField(
                  label: isAr ? 'كلمة المرور' : 'Password',
                  controller: _passwordController,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return isAr ? 'مطلوب' : 'Please enter a password';
                    if (v.length < 6) return isAr ? 'يجب أن تكون 6 أحرف على الأقل' : 'Password must be at least 6 characters';
                    return null;
                  },
                ),

                CustomTextField(
                  label: isAr ? 'تأكيد كلمة المرور' : 'Confirm Password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return isAr ? 'تأكيد كلمة المرور مطلوب' : 'Please confirm your password';
                    if (v != _passwordController.text) return isAr ? 'كلمات المرور غير متطابقة' : 'Passwords do not match';
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // Register button
                CustomButton(
                  text: _isBeneficiary ? (isAr ? 'لدي رمز وصول' : 'I have Access Code') : (isAr ? 'تسجيل' : 'Register'),
                  isLoading: _isLoading,
                  hasShadow: true,
                  onPressed: () => _handleRegister(isAr),
                ),
                const SizedBox(height: 16),

                // Already have an account? Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isAr ? 'لديك حساب بالفعل؟' : 'Already have an account?',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRouter.login);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(left: 4),
                        minimumSize: const Size(0, 30),
                      ),
                      child: Text(
                        isAr ? 'تسجيل الدخول' : 'Login',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(0, size.height);
    p.lineTo(size.width, size.height);
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}