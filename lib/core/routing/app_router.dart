// lib/core/routing/app_router.dart
import 'package:flutter/material.dart';
import '../../screens/intro/intro_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/access_code_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/beneficiary/my_beneficiary_screen.dart';
import '../../screens/beneficiary/new_beneficiary_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/account_information_screen.dart';
import '../../screens/assets/add_asset_category_screen.dart';
import '../../screens/assets/add_asset_details_screen.dart';
import '../../screens/assets/asset_action_screen.dart';
import '../../screens/assets/select_asset_beneficiary_screen.dart';
import '../../screens/assets/add_asset_beneficiary_screen.dart';
import '../../screens/assets/asset_detail_screen.dart';
import '../../screens/assets/asset_viewer_screen.dart';
import '../../screens/assets/category_assets_screen.dart';
import '../../screens/assets/add_personal_debt_screen.dart';
import '../../data/models/asset_model.dart';

class AppRouter {
  AppRouter._();

  static const String intro = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot_password'; 
  static const String myBeneficiary = '/my_beneficiary';
  static const String newBeneficiary = '/new_beneficiary';
  static const String settings = '/settings';
  static const String accountInfo = '/account_info';
  static const String addAssetCategory = '/add_asset_category';
  static const String addAssetDetails = '/add_asset_details';
  static const String assetAction = '/asset_action';
  static const String selectAssetBeneficiary = '/select_asset_beneficiary';
  static const String addAssetBeneficiary = '/add_asset_beneficiary';
  static const String assetDetail = '/asset_detail';
  static const String mainShell = '/main_shell';
  static const String accessCode = '/access_code';
  static const String categoryAssets = '/category_assets';
  static const String beneficiaryLogin = '/beneficiary_login';
  static const String assetViewer = '/asset_viewer';
  static const String addPersonalDebt = '/add_personal_debt';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    Widget page;
    switch (routeSettings.name) {
      case intro:
        page = const IntroScreen();
        break;
      case login:
        page = const LoginScreen();
        break;
      case register:
        page = const RegisterScreen();
        break;
      case forgotPassword: 
        page = const ForgotPasswordScreen();
        break;
      case myBeneficiary:
        page = const MyBeneficiaryScreen();
        break;
      case newBeneficiary:
        page = const NewBeneficiaryScreen();
        break;
      case settings:
        page = const SettingsScreen();
        break;
      case accountInfo:
        page = const AccountInformationScreen();
        break;
      case addAssetCategory:
        page = const AddAssetCategoryScreen();
        break;
      case addAssetDetails:
        page = const AddAssetDetailsScreen();
        break;
      case assetAction:
        bool isPersonalDebt = false;
        if (routeSettings.arguments is bool) {
          isPersonalDebt = routeSettings.arguments as bool;
        } else if (routeSettings.arguments is Map) {
          isPersonalDebt = (routeSettings.arguments as Map)['isPersonalDebt'] ?? false;
        }
        page = AssetActionScreen(isPersonalDebt: isPersonalDebt);
        break;
      case selectAssetBeneficiary:
        page = const SelectAssetBeneficiaryScreen();
        break;
      case addAssetBeneficiary:
        page = const AddAssetBeneficiaryScreen();
        break;
      case assetDetail:
        page = AssetDetailScreen(asset: routeSettings.arguments as AssetModel);
        break;
      case assetViewer:
        page = AssetViewerScreen(asset: routeSettings.arguments as AssetModel);
        break;
      case mainShell:
        page = const MainShell();
        break;
      case accessCode:
        page = const AccessCodeScreen();
        break;
      case beneficiaryLogin:
        page = const LoginScreen(isBeneficiaryLogin: true);
        break;
      case addPersonalDebt:
        page = const AddPersonalDebtScreen();
        break;
      case categoryAssets:
        final category = routeSettings.arguments as AssetCategory?;
        page = CategoryAssetsScreen(category: category);
        break;
      default:
        page = const IntroScreen();
    }
    return MaterialPageRoute(builder: (_) => page, settings: routeSettings);
  }
}