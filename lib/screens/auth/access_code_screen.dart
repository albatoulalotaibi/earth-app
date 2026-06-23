// lib/screens/auth/access_code_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/routing/app_router.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../data/models/user_model.dart';
import '../../services/session_manager.dart';
import '../../providers/app_preferences.dart';

class AccessCodeScreen extends StatefulWidget {
  const AccessCodeScreen({Key? key}) : super(key: key);

  @override
  State<AccessCodeScreen> createState() => _AccessCodeScreenState();
}

class _AccessCodeScreenState extends State<AccessCodeScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorText;

  bool _isCodeSent = false; 

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestAccessCode(bool isAr) async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorText = isAr ? 'يرجى إدخال بريد إلكتروني صالح' : 'Please enter a valid email');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/documents/beneficiary/request-code/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _isCodeSent = true;
          _errorText = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم إرسال الرمز إلى بريدك الإلكتروني' : 'Code sent to your email'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMsg = isAr ? 'البريد غير مسجل كمستفيد أو الوفاة غير مؤكدة' : 'Email not registered or death not verified';
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData['error'] != null) errorMsg = errorData['error'];
        } catch (_) {}
        setState(() => _errorText = errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = isAr ? 'خطأ بالاتصال بالخادم' : 'Server connection error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerify(bool isAr) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorText = isAr ? 'يرجى إدخال رمز الوصول' : 'Please enter the access code');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/documents/beneficiary/verify/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_code': code}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (data['status'] == 'verified') {
           if (data['token'] != null) {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('auth_token', data['token']);
           }

           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAr ? 'تم التحقق بنجاح!' : 'Verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          SessionManager.instance.setUser(UserModel(
            id: 'beneficiary_$code', 
            firstName: data['beneficiary_name'] ?? 'مستفيد',
            lastName: '', 
            email: _emailController.text.trim(),
            phone: '',
            nationalId: code,
            accountType: AccountType.beneficiary,
          ));

          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRouter.mainShell,
            (route) => false,
          );
        } else {
           setState(() => _errorText = isAr ? 'الرمز غير صحيح' : 'Invalid code');
        }
      } else {
        String errorMsg = isAr ? 'الرمز غير صحيح' : 'Invalid code';
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData['error'] != null) {
             errorMsg = errorData['error'];
             if (errorMsg.contains('Access not yet available')) {
                errorMsg = isAr ? 'لم يتم تأكيد الوفاة بعد' : 'Death not verified yet';
            } else if (errorMsg.contains('No death verification found')) {
                errorMsg = isAr ? 'لا يوجد طلب للتحقق من الوفاة.' : 'No death verification found.';
            }
          }
        } catch (_) {}
        setState(() => _errorText = errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
       setState(() => _errorText = isAr ? 'خطأ بالاتصال بالخادم' : 'Server connection error');
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
      appBar: CustomAppBar(title: isAr ? 'الوصول للمستفيد' : 'Beneficiary Access'),
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isCodeSent 
                          ? (isAr ? 'أدخل رمز الوصول المستلم' : 'Enter the received access code')
                          : (isAr ? 'أدخل بريدك الإلكتروني لتلقي الرمز' : 'Enter your email to receive code'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      if (!_isCodeSent) ...[
                         TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'example@mail.com',
                            hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                            errorText: _errorText,
                            prefixIcon: const Icon(Icons.email_outlined),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: isAr ? 'إرسال الرمز' : 'Send Code',
                            isLoading: _isLoading,
                            hasShadow: true,
                            backgroundColor: AppColors.primaryBlue,
                            onPressed: () => _requestAccessCode(isAr),
                          ),
                        ),
                      ] else ...[
                        TextField(
                          controller: _codeController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 22, letterSpacing: 8, color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: '••••••',
                            hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                            errorText: _errorText,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: isAr ? 'تحقق ودخول' : 'Verify & Enter',
                            isLoading: _isLoading,
                            hasShadow: true,
                            backgroundColor: AppColors.primaryBlue,
                            onPressed: () => _handleVerify(isAr),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => setState(() { _isCodeSent = false; _errorText = null; }),
                          child: Text(isAr ? 'تغيير البريد الإلكتروني؟' : 'Change email?'),
                        )
                      ],
                    ],
                  ),
                ),
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