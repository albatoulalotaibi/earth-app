// lib/screens/settings/account_information_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/session_manager.dart';
import '../../data/models/user_model.dart';
import '../../providers/app_preferences.dart';

/// Account information screen – view of the user's profile fetched from backend.
///
/// All fields are non-editable. No Save button.
class AccountInformationScreen extends StatefulWidget {
  const AccountInformationScreen({Key? key}) : super(key: key);

  @override
  State<AccountInformationScreen> createState() => _AccountInformationScreenState();
}

class _AccountInformationScreenState extends State<AccountInformationScreen> {
  UserModel? _user;
  bool _isLoading = true;

  String _nationalId = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _user = SessionManager.instance.currentUser;
    _phone = _user?.phone ?? '';
    _nationalId = _user?.nationalId ?? '';
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/users/profile/');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          
          // 👈 تم التعديل هنا: جلب الـ national_id بدلاً من username العادي للظهور الصحيح
          final fetchedNationalId = data['national_id']?.toString() ?? data['username']?.toString() ?? '';
          final fetchedPhone = data['phone']?.toString() ?? _user?.phone ?? '';
          
          final updatedUser = UserModel(
            id: data['id']?.toString() ?? _user?.id ?? '',
            firstName: data['first_name'] ?? _user?.firstName ?? '',
            lastName: data['last_name'] ?? _user?.lastName ?? '',
            email: data['email'] ?? _user?.email ?? '',
            phone: fetchedPhone,
            nationalId: fetchedNationalId, 
            accountType: _user?.accountType ?? AccountType.normal,
          );
          SessionManager.instance.setUser(updatedUser);
          
          setState(() {
            _user = updatedUser;
            _nationalId = fetchedNationalId;
            _phone = fetchedPhone;      
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: isAr ? 'معلومات الحساب' : 'ACCOUNT INFORMATION',
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReadOnlyField(isAr ? 'الاسم الأول' : 'First name', _user?.firstName ?? '', isDark),
                  _buildReadOnlyField(isAr ? 'الاسم الأخير' : 'Last name', _user?.lastName ?? '', isDark),
                  _buildReadOnlyField(isAr ? 'البريد الإلكتروني' : 'Email', _user?.email ?? '', isDark),
                  _buildReadOnlyField(isAr ? 'رقم الهاتف' : 'Phone number', _phone, isDark),
                  _buildReadOnlyField(isAr ? 'رقم الهوية' : 'ID', _nationalId, isDark),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : AppColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.grey[700]! : AppColors.divider),
            ),
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}