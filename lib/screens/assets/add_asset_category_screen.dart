import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_router.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/app_preferences.dart';

class AddAssetCategoryScreen extends StatefulWidget {
  const AddAssetCategoryScreen({Key? key}) : super(key: key);

  @override
  _AddAssetCategoryScreenState createState() => _AddAssetCategoryScreenState();
}

class _AddAssetCategoryScreenState extends State<AddAssetCategoryScreen> {
  String? selectedCategory;
  bool isCategoryDropdownOpen = true;

  final List<String> categoriesKeys = [
    'Official Documents',
    'Photos',
    'Videos',
    'personal depts'
  ];

  String _translateCategory(String key, bool isAr) {
    switch (key) {
      case 'Official Documents': return isAr ? 'المستندات الرسمية' : 'Official Documents';
      case 'Photos': return isAr ? 'الصور' : 'Photos';
      case 'Videos': return isAr ? 'مقاطع الفيديو' : 'Videos';
      case 'personal depts': return isAr ? 'الديون الشخصية' : 'Personal Debts';
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: isAr ? 'أضف أصولك الرقمية' : 'ADD YOUR DIGITAL ASSETS',
        showBackButton: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isCategoryDropdownOpen = !isCategoryDropdownOpen;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: isDark ? Border.all(color: Colors.grey[700]!) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedCategory != null 
                                ? _translateCategory(selectedCategory!, isAr) 
                                : (isAr ? 'الفئة' : 'Category'),
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Icon(
                            isCategoryDropdownOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isCategoryDropdownOpen)
                    ...categoriesKeys
                        .map((category) => _buildCategoryOption(category, isAr, isDark))
                        .toList(),
                  const Spacer(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryOption(String titleKey, bool isAr, bool isDark) {
    bool isSelected = selectedCategory == titleKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = titleKey;
        });
        if (titleKey == 'personal depts') {
          Navigator.pushNamed(context, AppRouter.addPersonalDebt);
        } else {
          Navigator.pushNamed(context, AppRouter.addAssetDetails);
        }
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
        child: Text(
          _translateCategory(titleKey, isAr),
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? (isDark ? Colors.lightBlueAccent : AppColors.primaryBlue)
                : (isDark ? Colors.white : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}