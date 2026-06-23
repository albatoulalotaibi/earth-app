// lib/screens/beneficiary/my_beneficiary_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/routing/app_router.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../data/models/beneficiary_model.dart';
import '../../providers/app_preferences.dart';
import 'edit_beneficiary_screen.dart';

/// Displays the current user's list of beneficiaries (editable).
class MyBeneficiaryScreen extends StatefulWidget {
  const MyBeneficiaryScreen({Key? key}) : super(key: key);

  @override
  State<MyBeneficiaryScreen> createState() => _MyBeneficiaryScreenState();
}

class _MyBeneficiaryScreenState extends State<MyBeneficiaryScreen> {
  List<BeneficiaryModel> _beneficiaries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBeneficiaries();
  }

  Future<void> _loadBeneficiaries() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/users/beneficiaries/');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _beneficiaries = data.map<BeneficiaryModel>((item) => BeneficiaryModel(
              id: item['id'].toString(),
              firstName: item['first_name'] ?? '',
              lastName: item['last_name'] ?? '',
              nationalId: item['national_id'] ?? '',
              phone: item['phone'] ?? '',
              email: item['email'] ?? '',
              relationship: item['relationship'] ?? '',
            )).toList();
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteBeneficiary(String id, bool isAr) async {
    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/users/beneficiaries/$id/');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (!mounted) return;
        setState(() {
          _beneficiaries.removeWhere((b) => b.id == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم حذف المستفيد بنجاح' : 'Beneficiary deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'فشل الحذف' : 'Failed to delete'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'خطأ بالاتصال' : 'Connection error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editBeneficiary(BeneficiaryModel beneficiary) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditBeneficiaryScreen(beneficiary: beneficiary),
      ),
    );
    _loadBeneficiaries();
  }

  void _confirmDelete(BeneficiaryModel b, bool isAr, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          isAr ? 'حذف المستفيد' : 'Delete beneficiary',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          isAr ? 'هل أنت متأكد من حذف ${b.firstName} ${b.lastName}؟' : 'Are you sure you want to delete ${b.firstName} ${b.lastName}?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (b.id != null) _deleteBeneficiary(b.id!, isAr);
            },
            child: Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _translateRel(String rel, bool isAr) {
    if (!isAr) return rel;
    switch (rel) {
      case 'Father': return 'أب';
      case 'Mother': return 'أم';
      case 'Wife': return 'زوجة';
      case 'Husband': return 'زوج';
      case 'Sister': return 'أخت';
      case 'Brother': return 'أخ';
      case 'Son': return 'ابن';
      case 'Daughter': return 'ابنة';
      case 'Other': return 'أخرى';
      default: return rel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: isAr ? 'المستفيدين' : 'MY BENEFICIARY', 
        showBackButton: false
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: _beneficiaries.isEmpty
                        ? Center(
                            child: Text(
                              isAr ? 'لم يتم العثور على مستفيدين' : 'No beneficiaries found',
                              style: TextStyle(color: isDark ? Colors.white70 : AppColors.textHint),
                            )
                          )
                        : ListView.separated(
                            itemCount: _beneficiaries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final b = _beneficiaries[index];
                              return Container(
                                margin: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[850] : AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: ListTile(
                                  title: Text(
                                    '${b.firstName} ${b.lastName}',
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                  ),
                                  subtitle: Text(
                                    _translateRel(b.relationship, isAr),
                                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        color: AppColors.primaryBlue,
                                        onPressed: () => _editBeneficiary(b),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: Colors.redAccent,
                                        onPressed: () => _confirmDelete(b, isAr, isDark),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _editBeneficiary(b),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: isAr ? 'مستفيد جديد' : 'New Beneficiary',
                      hasShadow: true,
                      isOutlined: false,
                      backgroundColor: isDark ? Colors.grey[800] : AppColors.backgroundDark,
                      textColor: AppColors.primaryBlue,
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryBlue, size: 20),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRouter.newBeneficiary)
                            .then((_) => _loadBeneficiaries());
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}