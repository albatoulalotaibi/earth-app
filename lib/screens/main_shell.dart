// lib/screens/main_shell.dart
import 'dart:async'; 
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http; 
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../services/session_manager.dart';
import '../providers/app_preferences.dart';
import 'home/normal_home_screen.dart';
import 'home/beneficiary_home_screen.dart';
import 'settings/settings_screen.dart';
import 'beneficiary/my_beneficiary_screen.dart';
import 'assets/add_asset_category_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // 👈 مسحنا الـ PageController لأن راح نستخدم IndexedStack الأسرع والأكثر استقراراً
  int _currentIndex = 0;
  
  late List<Widget> _pages;

  Timer? _notificationTimer;
  bool _isCheckingNotifications = false; // 👈 قفل لمنع تداخل طلبات الإشعارات
  
  static final Set<String> _shownNotifications = {};

  bool get _isBeneficiary => SessionManager.instance.isBeneficiary;

  List<_NavItemData> _getNavItems(bool isAr) {
    if (_isBeneficiary) {
      return [
        _NavItemData(icon: Icons.home_outlined, label: isAr ? 'الرئيسية' : 'Home'),
        _NavItemData(icon: Icons.settings, label: isAr ? 'الإعدادات' : 'Settings'),
      ];
    }
    return [
      _NavItemData(icon: Icons.home_outlined, label: isAr ? 'الرئيسية' : 'Home'),
      _NavItemData(icon: Icons.description_outlined, label: isAr ? 'إضافة' : 'Add'),
      _NavItemData(icon: Icons.person_outline, label: isAr ? 'المستفيدين' : 'Beneficiary'),
      _NavItemData(icon: Icons.settings, label: isAr ? 'الإعدادات' : 'Settings'),
    ];
  }

@override
  void initState() {
    super.initState();
    if (_isBeneficiary) {
      _pages = const [BeneficiaryHomeScreen(), SettingsScreen()];
    } else {
      _pages = const [
        NormalHomeScreen(),
        AddAssetCategoryScreen(),
        MyBeneficiaryScreen(),
        SettingsScreen(),
      ];
    }
    
    // 👈 تشغيل الإشعارات فقط إذا كان المستخدم مسجل دخول
    _startNotificationPolling();
  }

  void _startNotificationPolling() async {
    // 👈 تأكد من وجود توكن قبل تشغيل التايمر
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null || token.isEmpty) return;

    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkForNewNotifications();
    });
  }

  Future<void> _checkForNewNotifications() async {
    if (_isCheckingNotifications || !mounted) return; 
    _isCheckingNotifications = true;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final url = Uri.parse('https://ruba-gsh7.onrender.com/notifications/my-list/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 5)); 

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        if (data['status'] == 'success' && data['notifications'] != null) {
          final List notifications = data['notifications'];
          
          if (notifications.isNotEmpty) {
            final latestNotification = notifications.first;
            final currentId = latestNotification['id'].toString();

            // فحص التكرار
            if (_shownNotifications.contains(currentId)) return;
            _shownNotifications.add(currentId);
            
            if (mounted) {
              _showCustomNotification(
                title: 'تنبيه ⚠️',
                message: 'لاحظنا عدم وجود نشاط مؤخراً، يرجى تسجيل الدخول خلال 72 ساعة القادمة.',
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Polling error: $e');
    } finally {
      if (mounted) _isCheckingNotifications = false;
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }
  void _showCustomNotification({required String title, required String message}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 6),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    Text(
                      message, 
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  _showSmallPopup(title, message);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('عرض', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSmallPopup(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_active, color: AppColors.primaryBlue, size: 28),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('حسناً', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onNavTap(int index) {
    // 👈 فقط نغير الإندكس والـ IndexedStack يتكفل بالباقي بدون تدمير الصفحات
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      // 🔥 استخدام IndexedStack هو الحل الجذري لمنع إعادة الريندر والرجفة
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildNavBar(isAr, isDark),
    );
  }

  Widget _buildNavBar(bool isAr, bool isDark) {
    final navItems = _getNavItems(isAr);
    
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(navItems.length, (i) {
          final item = navItems[i];
          final isActive = _currentIndex == i;
          return GestureDetector(
            onTap: () => _onNavTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: isActive 
                        ? AppColors.primaryBlue 
                        : (isDark ? Colors.grey[500] : AppColors.textHint),
                    size: 26,
                  ),
                  const SizedBox(height: 4),
                  if (isActive)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}