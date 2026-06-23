// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/routing/app_router.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/setting_item.dart';
import '../../services/session_manager.dart';
import '../../providers/app_preferences.dart';

/// Settings screen – general preferences & about section.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDeleting = false;

  Future<void> _handleLogout(bool isAr) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/users/logout/');
      if (token != null) {
        await http.post(uri, headers: {'Authorization': 'Token $token'});
      }
    } catch (e) {
      // Fallback
    } finally {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // تفريغ كامل للكاش لضمان عدم الرجوع
      SessionManager.instance.clear();
      
      if (!mounted) return;
      // توجيه لصفحة الترحيب
      Navigator.pushNamedAndRemoveUntil(context, AppRouter.intro, (route) => false);
    }
  }

  Future<void> _handleDeleteAccount(BuildContext ctx, bool isAr) async {
    setState(() => _isDeleting = true);
    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/users/profile/'); 
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        await http.delete(uri, headers: {'Authorization': 'Token $token'});
      }
    } catch (e) {
      debugPrint('Delete Account Error: $e');
    } finally {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // تفريغ كامل
      SessionManager.instance.clear();

      if (!mounted) return;
      setState(() => _isDeleting = false);
      
      Navigator.pop(ctx); 
      // 👈 تم التعديل هنا: التوجيه لصفحة الترحيب (intro) بدل الـ (login)
      Navigator.pushNamedAndRemoveUntil(context, AppRouter.intro, (route) => false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم حذف الحساب بنجاح' : 'Account deleted successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80.0;

    final appPrefs = Provider.of<AppPreferences>(context);
    final isAr = appPrefs.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: isAr ? 'الإعدادات' : 'SETTINGS', 
        showBackButton: false
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'عام' : 'General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.lightBlueAccent : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SettingItem(
              icon: Icons.person_outline,
              title: isAr ? 'معلومات الحساب' : 'Account Information',
              onTap: () => Navigator.pushNamed(context, AppRouter.accountInfo),
            ),
            Divider(color: isDark ? Colors.grey[800] : AppColors.divider),

            SettingItem(
              icon: Icons.language,
              title: isAr ? 'اللغة (العربية)' : 'Language (English)',
              onTap: () {
                appPrefs.toggleLanguage(); 
              },
            ),
            Divider(color: isDark ? Colors.grey[800] : AppColors.divider),

            SettingItem(
              icon: isDark ? Icons.light_mode_outlined : Icons.brightness_2_outlined,
              title: isAr 
                  ? (isDark ? 'المظهر (داكن)' : 'المظهر (فاتح)') 
                  : (isDark ? 'Appearance (Dark)' : 'Appearance (Light)'),
              onTap: () {
                appPrefs.toggleTheme();
              },
            ),
            Divider(color: isDark ? Colors.grey[800] : AppColors.divider),
            
            SettingItem(
              icon: Icons.logout,
              title: isAr ? 'تسجيل الخروج' : 'Log out',
              onTap: () => _handleLogout(isAr),
            ),
            Divider(color: isDark ? Colors.grey[800] : AppColors.divider),
            const SizedBox(height: 30),
            Text(
              isAr ? 'عن تطبيق إرث' : 'About Erth',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.lightBlueAccent : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SettingItem(
              icon: Icons.email_outlined,
              title: isAr ? 'تواصل معنا' : 'Contact us',
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) {
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.email_outlined, size: 48, color: AppColors.primaryBlue),
                            const SizedBox(height: 16),
                            Text(
                              isAr ? 'تواصل معنا' : 'Contact Us',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isAr 
                                ? 'يمكنك التواصل معنا في أي وقت عبر البريد الإلكتروني. سنرد عليك في أقرب وقت ممكن.' 
                                : 'You can reach us anytime via email. We will get back to you as soon as possible.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : AppColors.textSecondary),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[850] : AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'erth.dlms@gmail.com',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: AppColors.primaryBlue),
                                    onPressed: () {
                                      Clipboard.setData(const ClipboardData(text: 'erth.dlms@gmail.com'));
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isAr ? 'تم نسخ البريد الإلكتروني' : 'Email copied to clipboard'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            Divider(color: isDark ? Colors.grey[800] : AppColors.divider),
            SettingItem(
              icon: Icons.delete_outline,
              title: isAr ? 'حذف الحساب' : 'Delete Account',
              textColor: AppColors.error,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(
                      isAr ? 'حذف الحساب' : 'Delete Account',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                    ),
                    content: Text(
                      isAr 
                        ? 'هل أنت متأكد من حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء وسيتم مسح كافة بياناتك نهائياً.' 
                        : 'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: _isDeleting ? null : () => Navigator.pop(ctx),
                        child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: _isDeleting ? null : () => _handleDeleteAccount(ctx, isAr),
                        child: _isDeleting 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}