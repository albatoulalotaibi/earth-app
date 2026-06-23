import 'package:flutter/material.dart';

/// A single settings row with icon, title, and chevron.
class SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  const SettingItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color effectiveTextColor = textColor ?? Colors.black87;
    final Color effectiveIconColor = textColor ?? Colors.grey;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: effectiveIconColor),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: effectiveTextColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: effectiveIconColor),
          ],
        ),
      ),
    );
  }
}
