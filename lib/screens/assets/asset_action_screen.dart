// lib/screens/assets/asset_action_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/app_preferences.dart';

class AssetActionScreen extends StatefulWidget {
  final bool isPersonalDebt;
  const AssetActionScreen({Key? key, this.isPersonalDebt = false})
      : super(key: key);

  @override
  _AssetActionScreenState createState() => _AssetActionScreenState();
}

class _AssetActionScreenState extends State<AssetActionScreen> {
  String? selectedAction;
  bool isDropdownOpen = false;
  bool _isSaving = false;
  String? _assetId;

  // 👈 حقل اسم المالك صار هنا 
  final _ownerNameController = TextEditingController();

  late final List<String> actionsKeys;

  @override
  void initState() {
    super.initState();
    if (widget.isPersonalDebt) {
      actionsKeys = ['Transfer to Beneficiary'];
    } else {
      actionsKeys = [
        'Delete Asset',
        'Transfer to Beneficiary',
      ];
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _assetId = args;
    } else if (args is Map && args['assetId'] != null) {
      _assetId = args['assetId'].toString();
    }
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    super.dispose();
  }

  String _translateAction(String key, bool isAr) {
    if (!isAr) return key;
    switch (key) {
      case 'Delete Asset': return 'حذف الأصل';
      case 'Transfer to Beneficiary': return 'تحويل لمستفيد';
      default: return key;
    }
  }

  Future<void> _onSave(bool isAr) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    if (selectedAction == null) return;

    final ownerName = _ownerNameController.text.trim();
    if (ownerName.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(isAr 
              ? 'يرجى إدخال اسمك (اسم المالك) لتسجيله مع الأصل' 
              : 'Please enter your name (Owner Name) to record it with the asset'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_assetId == null) {
      _showSuccessAndGoHome(isAr);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/documents/action/');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      String actionValue = selectedAction == 'Delete Asset' ? 'delete' : 'transfer';

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'asset_id': _assetId,
          'posthumous_action': actionValue, 
          'owner_name': ownerName, 
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (actionValue == 'transfer') {
          navigator.pushNamed(
            AppRouter.selectAssetBeneficiary,
            arguments: {'senderName': ownerName, 'assetId': _assetId},
          );
        } else {
          _showSuccessAndGoHome(isAr);
        }
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(isAr ? 'حدث خطأ أثناء الحفظ: ${response.statusCode}' : 'Error saving action: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(isAr ? 'خطأ بالاتصال' : 'Connection error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessAndGoHome(bool isAr) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr ? 'تم حفظ الأصل وتحديث الإجراء بنجاح!' : 'Asset saved and action recorded successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.mainShell, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: '',
        style: AppBarStyle.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              Text(
                isAr ? 'اختر الإجراء بعد الوفاة' : 'Choose the posthumous action',
                style: AppTextStyles.heading3.copyWith(
                  color: isDark ? Colors.lightBlueAccent : AppColors.primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Dropdown trigger
              GestureDetector(
                onTap: () {
                  setState(() {
                    isDropdownOpen = !isDropdownOpen;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: isDark ? Border.all(color: Colors.grey[700]!) : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedAction != null ? _translateAction(selectedAction!, isAr) : (isAr ? 'الإجراء' : 'Action'),
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Icon(
                        isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Dropdown options
              if (isDropdownOpen)
                ...actionsKeys.map((action) => _buildActionOption(action, isAr, isDark)).toList(),

              // ── Owner name field (Always visible) ──
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: isDark ? Border.all(color: Colors.grey[700]!) : Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: _ownerNameController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: isAr ? 'اسمك (مطلوب)' : 'Your Name (required)',
                    labelStyle: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14,
                    ),
                    hintText: isAr ? 'أدخل اسمك لتسجيله كمالك لهذا الأصل' : 'Enter your name as the owner of this asset',
                    hintStyle: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.textHint, size: 20),
                  ),
                ),
              ),

              const Spacer(),

              // Save button
              Center(
                child: SizedBox(
                  width: 200,
                  child: CustomButton(
                    text: isAr ? 'متابعة' : 'Continue',
                    isLoading: _isSaving,
                    backgroundColor: AppColors.primaryBlue,
                    onPressed: selectedAction != null ? () => _onSave(isAr) : null,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionOption(String titleKey, bool isAr, bool isDark) {
    bool isSelected = selectedAction == titleKey;
    
    final Map<String, String> descriptionsEn = {
      'Delete Asset': 'This action will delete selected assets after death is confirmed.',
      'Transfer to Beneficiary': 'This action will transfer selected assets to a designated beneficiary after death is confirmed.',
    };
    
    final Map<String, String> descriptionsAr = {
      'Delete Asset': 'هذا الإجراء سيقوم بحذف الأصول المحددة بعد تأكيد الوفاة.',
      'Transfer to Beneficiary': 'هذا الإجراء سيقوم بتحويل الأصول المحددة للمستفيد بعد تأكيد الوفاة.',
    };

    final String description = isAr ? (descriptionsAr[titleKey] ?? '') : (descriptionsEn[titleKey] ?? '');

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAction = titleKey;
          isDropdownOpen = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryBlue.withOpacity(0.2) : AppColors.primaryBlue.withOpacity(0.05))
              : (isDark ? Colors.grey[850] : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(color: AppColors.primaryBlue) 
              : (isDark ? Border.all(color: Colors.grey[700]!) : null),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _translateAction(titleKey, isAr),
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (description.isNotEmpty && isSelected) ...[
              const SizedBox(height: 6),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}