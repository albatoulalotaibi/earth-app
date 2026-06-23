// lib/screens/auth/forgot_password_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../providers/app_preferences.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isSending = false;
  bool _isCodeSent = false; 

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v, bool isAr) {
    if (v == null || v.trim().isEmpty) return isAr ? 'يرجى إدخال بريدك الإلكتروني' : 'Please enter your email';
    final email = v.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) return isAr ? 'يرجى إدخال بريد إلكتروني صالح' : 'Please enter a valid email';
    return null;
  }

  Future<void> _sendResetLink(bool isAr) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/users/forgot-password/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم إرسال كود التحقق بنجاح' : 'Verification code sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isCodeSent = true; 
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'لم يتم العثور على حساب بهذا البريد' : 'No account found with this email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'حدث خطأ في الاتصال بالسيرفر' : 'Server connection error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _resetPassword(bool isAr) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/users/reset-password/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'otp': _otpController.text.trim(),
          'new_password': _newPasswordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم تغيير كلمة المرور بنجاح!' : 'Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // الرجوع لشاشة تسجيل الدخول
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? (isAr ? 'كود غير صحيح أو منتهي الصلاحية' : 'Invalid or expired code')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'حدث خطأ في الاتصال' : 'Connection error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: isAr ? 'نسيان كلمة المرور' : 'Forgot Password', 
        showBackButton: true
      ),
      body: Stack(
        children: [
          // decorative triangle bottom-right
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
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
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          !_isCodeSent 
                            ? (isAr 
                                ? 'أدخل بريدك الإلكتروني وسنرسل\nلك كود التحقق لإعادة التعيين' 
                                : 'Enter your email and we\'ll send\nyou a verification code')
                            : (isAr 
                                ? 'أدخل الكود المرسل إلى بريدك\nوكلمة المرور الجديدة' 
                                : 'Enter the code sent to your email\nand your new password'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (!_isCodeSent) ...[
                                CustomTextField(
                                  label: isAr ? 'البريد الإلكتروني' : 'Email',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) => _validateEmail(v, isAr),
                                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textHint, size: 20),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: CustomButton(
                                    text: isAr ? 'إرسال الرمز' : 'Send Code',
                                    isLoading: _isSending,
                                    backgroundColor: AppColors.primaryBlue,
                                    onPressed: _isSending ? null : () => _sendResetLink(isAr),
                                  ),
                                ),
                              ] 
                              else ...[
                                CustomTextField(
                                  label: isAr ? 'رمز التحقق (6 أرقام)' : 'Verification Code (6 digits)',
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.textHint, size: 20),
                                  validator: (v) => (v == null || v.isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  label: isAr ? 'كلمة المرور الجديدة' : 'New Password',
                                  controller: _newPasswordController,
                                  isPassword: true,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return isAr ? 'مطلوب' : 'Required';
                                    if (v.length < 6) return isAr ? 'يجب أن تكون 6 أحرف على الأقل' : 'Must be at least 6 chars';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  label: isAr ? 'تأكيد كلمة المرور' : 'Confirm Password',
                                  controller: _confirmPasswordController,
                                  isPassword: true,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return isAr ? 'مطلوب' : 'Required';
                                    if (v != _newPasswordController.text) return isAr ? 'غير متطابقة' : 'Passwords do not match';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: CustomButton(
                                    text: isAr ? 'تغيير كلمة المرور' : 'Reset Password',
                                    isLoading: _isSending,
                                    backgroundColor: AppColors.greenMid,
                                    onPressed: _isSending ? null : () => _resetPassword(isAr),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 18),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
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