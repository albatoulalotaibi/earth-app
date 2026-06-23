import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routing/app_router.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../data/models/user_model.dart';
import '../../services/session_manager.dart';
import '../../providers/app_preferences.dart';

class LoginScreen extends StatefulWidget {
  final bool isBeneficiaryLogin;
  const LoginScreen({Key? key, this.isBeneficiaryLogin = false}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _fetchAndSetUserProfile(String token) async {
    try {
      final profileUri = Uri.parse('https://ruba-gsh7.onrender.com/api/users/profile/');
      final response = await http.get(
        profileUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        SessionManager.instance.setUser(UserModel(
          id: data['id']?.toString() ?? '',
          firstName: data['first_name'] ?? '',
          lastName: data['last_name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          nationalId: data['national_id'] ?? '',
          accountType: widget.isBeneficiaryLogin ? AccountType.beneficiary : AccountType.normal,
        ));
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleLogin(bool isAr) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/users/login/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _idController.text.trim(), 
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          final token = data['token'];
          
          final profileSuccess = await _fetchAndSetUserProfile(token);

          if (!mounted) return;

          if (profileSuccess) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', token);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isAr ? 'تم تسجيل الدخول بنجاح!' : 'Logged in successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRouter.mainShell,
              (route) => false,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isAr ? 'خطأ في جلب بيانات الحساب' : 'Failed to fetch profile data'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'خطأ في اسم المستخدم أو كلمة المرور' : 'Invalid credentials'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'خطأ في الاتصال بالخادم' : 'Server connection error'),
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

    final titleWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isAr ? 'مرحباً بك في' : 'WELCOME TO',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.isBeneficiaryLogin 
            ? (isAr ? 'تسجيل دخول المستفيد' : 'BENEFICIARY LOGIN') 
            : AppConstants.appName,
          style: TextStyle(
            fontFamily: (widget.isBeneficiaryLogin || !isAr) ? null : 'Amiri Quran',
            color: Colors.white,
            fontSize: widget.isBeneficiaryLogin ? 22 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: widget.isBeneficiaryLogin ? 1.2 : 0,
            height: 1.0,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        titleWidget: titleWidget,
        showBackButton: widget.isBeneficiaryLogin, 
      ),
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
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // National ID
                CustomTextField(
                  enabled: !_isLoading,
                  label: isAr ? 'رقم الهوية / اسم المستخدم' : 'ID / Username',
                  controller: _idController,
                  keyboardType: TextInputType.text,
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textHint, size: 20),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return isAr ? 'يرجى إدخال الهوية' : 'Please enter your ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 4),

                // Password
                CustomTextField(
                  enabled: !_isLoading,
                  label: isAr ? 'كلمة المرور' : 'Password',
                  controller: _passwordController,
                  isPassword: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return isAr ? 'يرجى إدخال كلمة المرور' : 'Please enter your password';
                    }
                    return null;
                  },
                ),

                // Forgot Password
                Align(
                  alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.forgotPassword);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                    ),
                    child: Text(
                      isAr ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Login button
                CustomButton(
                  text: isAr ? 'تسجيل الدخول' : 'Login',
                  isLoading: _isLoading,
                  hasShadow: true,
                  onPressed: () => _handleLogin(isAr),
                ),
                const SizedBox(height: 16),

                // OR divider
                if (!widget.isBeneficiaryLogin) ...[
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          isAr ? 'أو' : 'OR',
                          style: const TextStyle(color: AppColors.textHint, fontSize: 13),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.divider)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Login with Nafath
                  CustomButton(
                    text: isAr ? 'تسجيل الدخول عبر نفاذ' : 'Login with Nafath',
                    isOutlined: false,
                    hasShadow: false,
                    backgroundColor: AppColors.greenMuted,
                    textColor: AppColors.textOnPrimary,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 20),
                ],

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isAr ? 'ليس لديك حساب؟' : "Don't have account?",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context, 
                          AppRouter.register,
                          arguments: widget.isBeneficiaryLogin ? {'isBeneficiary': true} : null,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(left: 4),
                        minimumSize: const Size(0, 30),
                      ),
                      child: Text(
                        isAr ? 'تسجيل جديد' : 'Register',
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

                // Beneficiary register link
                if (!widget.isBeneficiaryLogin) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAr ? 'هل أنت مستفيد؟' : 'Are you a beneficiary?',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRouter.beneficiaryLogin);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(left: 4),
                          minimumSize: const Size(0, 30),
                        ),
                        child: Text(
                          isAr ? 'مستفيد' : 'Beneficiary',
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