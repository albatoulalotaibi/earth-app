import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Reusable button that supports filled, outlined, and loading states.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool hasShadow;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? icon;
  final double? iconSize;
  final bool iconOnRight;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isOutlined = false,
    this.hasShadow = false,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.iconSize,
    this.iconOnRight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color bg = isOutlined
        ? Colors.transparent
        : (backgroundColor ?? AppColors.primaryBlue);
    final Color txtColor =
        isOutlined ? AppColors.primaryBlue : (textColor ?? Colors.white);

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: isOutlined ? Border.all(color: AppColors.primaryBlue) : null,
        boxShadow: hasShadow
            ? [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: txtColor, // modern API
                    ),
                  )
                : _buildContent(txtColor),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color txtColor) {
    final textWidget = Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: txtColor,
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );

    if (icon == null) return textWidget;

    final iconWidget = SizedBox(
      width: iconSize ?? 20,
      height: iconSize ?? 20,
      child: Center(
        child: IconTheme(
          data: IconThemeData(size: iconSize ?? 20),
          child: icon!,
        ),
      ),
    );

    final children = iconOnRight
        ? <Widget>[
            Flexible(child: textWidget),
            const SizedBox(width: 10),
            iconWidget
          ]
        : <Widget>[
            iconWidget,
            const SizedBox(width: 10),
            Flexible(child: textWidget)
          ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}
