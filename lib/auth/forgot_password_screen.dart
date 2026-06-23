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
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
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
            content: Text(isAr ? 'تم إرسال رابط إعادة التعيين بنجاح' : 'Reset link sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _fallbackSuccess(isAr);
      }
    } catch (e) {
      if (!mounted) return;
      // Fallback
      _fallbackSuccess(isAr);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _fallbackSuccess(bool isAr) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr 
          ? 'إذا كان البريد موجوداً، تم إرسال الرابط إلى ${_emailController.text.trim()}' 
          : 'If that email exists, a reset link was sent to ${_emailController.text.trim()}'),
      ),
    );
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
                  // Card container similar to your design screenshot
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
                          isAr 
                            ? 'أدخل بريدك الإلكتروني وسنرسل\nلك رابط إعادة تعيين كلمة المرور' 
                            : 'Enter your email and we\'ll send\nyou a password reset link',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Email input
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              CustomTextField(
                                label: isAr ? 'البريد الإلكتروني' : 'Email',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => _validateEmail(v, isAr),
                                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textHint, size: 20),
                              ),
                              const SizedBox(height: 20),
                              // Send Reset Link button — pill shaped like the screenshot
                              SizedBox(
                                width: double.infinity,
                                child: CustomButton(
                                  text: isAr ? 'إرسال رابط' : 'Send Reset Link',
                                  isLoading: _isSending,
                                  backgroundColor: AppColors.primaryBlue,
                                  onPressed: _isSending ? null : () => _sendResetLink(isAr),
                                ),
                              ),
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