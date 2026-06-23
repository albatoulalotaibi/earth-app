// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

enum AppBarStyle { primary, large, transparent }

/// Reusable app bar that supports standard, large rounded, and transparent styles.
///
/// You can pass either `title` (String) or `titleWidget` (Widget). If both
/// are provided, `titleWidget` takes precedence.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final AppBarStyle style;

  const CustomAppBar({
    Key? key,
    this.title,
    this.titleWidget,
    this.showBackButton = true,
    this.style = AppBarStyle.primary,
  })  : assert(title != null || titleWidget != null,
            'Either title or titleWidget must be provided'),
        super(key: key);

  @override
  Size get preferredSize {
    switch (style) {
      case AppBarStyle.large:
        return const Size.fromHeight(140.0);
      case AppBarStyle.primary:
      case AppBarStyle.transparent:
      default:
        return const Size.fromHeight(100.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration;
    Color iconColor;
    TextStyle titleStyle;

    switch (style) {
      case AppBarStyle.large:
        decoration = const BoxDecoration(
          gradient: AppColors.appBarGradient,
        );
        iconColor = Colors.white;
        titleStyle = AppTextStyles.heading2.copyWith(
          color: Colors.white,
          letterSpacing: 1.2,
          fontSize: 16,
        );
        break;
      case AppBarStyle.transparent:
        decoration = const BoxDecoration(color: Colors.transparent);
        iconColor = AppColors.primaryBlue;
        titleStyle = AppTextStyles.heading2.copyWith(
          color: AppColors.primaryBlue,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        );
        break;
      case AppBarStyle.primary:
      default:
        decoration = const BoxDecoration(gradient: AppColors.appBarGradient);
        iconColor = Colors.white;
        titleStyle = AppTextStyles.appBarTitle;
        break;
    }

    return Container(
      height: preferredSize.height,
      decoration: decoration,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Back button
              if (showBackButton)
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),

              // Centered title: use titleWidget if provided else normal Text
              Center(
                child: titleWidget ??
                    Text(
                      title ?? '',
                      textAlign: TextAlign.center,
                      style: titleStyle,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
