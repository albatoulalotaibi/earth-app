import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routing/app_router.dart';
import '../../providers/app_preferences.dart';

/// Intro / splash screen.
///
/// Full green gradient with the app tagline and a "Start" button.
class IntroScreen extends StatelessWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<AppPreferences>(context).locale.languageCode == 'ar';

    final String tagline = isAr 
        ? 'إدارة آمنة\nلأصولك الرقمية\nللمستقبل'
        : 'Securely manage\nyour digital assets for\nthe future';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topEnd,
            end: AlignmentDirectional.bottomStart,
            colors: [
              AppColors.greenDark,
              AppColors.greenMid,
              AppColors.greenLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 3),
                // Tagline
                Text(
                  tagline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(flex: 4),
                // Start button
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    width: 140,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRouter.login);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.greenMuted.withOpacity(0.5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isAr ? 'ابدأ' : 'Start', 
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}