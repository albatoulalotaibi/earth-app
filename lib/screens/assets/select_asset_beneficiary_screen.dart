// lib/screens/assets/select_asset_beneficiary_screen.dart
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

class SelectAssetBeneficiaryScreen extends StatefulWidget {
  const SelectAssetBeneficiaryScreen({Key? key}) : super(key: key);

  @override
  State<SelectAssetBeneficiaryScreen> createState() =>
      _SelectAssetBeneficiaryScreenState();
}

class _SelectAssetBeneficiaryScreenState extends State<SelectAssetBeneficiaryScreen> {
  List<BeneficiaryModel> _beneficiaries = [];
  final Map<String, bool> _selected = {};
  bool _loading = true;
  bool _isSaving = false;
  String? _assetId; 

  @override
  void initState() {
    super.initState();
    _loadBeneficiaries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _assetId = args;
    } else if (args is Map) {
      _assetId = args['assetId']?.toString();
    }
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

            _selected.clear();
            for (final b in _beneficiaries) {
              _selected[b.id ?? b.fullName] = false;
            }
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
        debugPrint('Failed to load beneficiaries: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint('Error: $e');
    }
  }

  void _toggleSelection(String key, bool? value) {
    if (value == null) return;
    setState(() => _selected[key] = value);
  }

  List<BeneficiaryModel> get _selectedBeneficiaries {
    return _beneficiaries
        .where((b) => _selected[b.id ?? b.fullName] ?? false)
        .toList();
  }

  Future<void> _saveSelection(bool isAr) async {
    if (_assetId == null || _assetId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'خطأ: لم يتم العثور على رقم الملف!' : 'Error: Asset ID not found!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selected = _selectedBeneficiaries;
    if (selected.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/documents/beneficiary/assign/');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final List<String> beneficiaryIds = selected.map((b) => b.id!).toList();

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'asset_id': _assetId,
          'beneficiary_ids': beneficiaryIds, 
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم نقل الأصل للمستفيدين بنجاح!' : 'Asset successfully assigned to beneficiaries!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, AppRouter.mainShell, (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'حدث خطأ في ربط بعض المستفيدين' : 'Some assignments failed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'حدث خطأ بالاتصال' : 'Connection error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: isAr ? 'اختيار المستفيد' : 'Select Beneficiary',
        style: AppBarStyle.transparent,
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
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _beneficiaries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final b = _beneficiaries[index];
                              final key = b.id ?? b.fullName;
                              final value = _selected[key] ?? false;
                              return Container(
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[800] : AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: CheckboxListTile(
                                  value: value,
                                  onChanged: (v) => _toggleSelection(key, v),
                                  title: Text(
                                    '${b.firstName} ${b.lastName}',
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                  ),
                                  subtitle: Text(
                                    b.relationship,
                                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: AppColors.primaryBlue,
                                  checkColor: Colors.white,
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 48,
                        child: CustomButton(
                          text: isAr ? 'مستفيد جديد' : 'New Beneficiary',
                          hasShadow: true,
                          isOutlined: false,
                          backgroundColor: isDark ? Colors.grey[800] : AppColors.backgroundDark,
                          textColor: AppColors.primaryBlue,
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryBlue, size: 20),
                          onPressed: () {
                            Navigator.pushNamed(context, AppRouter.addAssetBeneficiary)
                                .then((_) => _loadBeneficiaries());
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: CustomButton(
                          text: isAr ? 'حفظ' : 'Save',
                          hasShadow: true,
                          isLoading: _isSaving,
                          backgroundColor: AppColors.primaryBlue,
                          onPressed: _selectedBeneficiaries.isNotEmpty ? () => _saveSelection(isAr) : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}