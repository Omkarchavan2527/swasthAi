import 'package:flutter/material.dart';

enum SWButtonVariant { primary, secondary, danger }

class SWButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final SWButtonVariant variant;
  final bool isSmall;

  const SWButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.variant = SWButtonVariant.primary,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor = Colors.white;

    switch (variant) {
      case SWButtonVariant.primary:
        bgColor = const Color(0xFF0D9488);
        break;
      case SWButtonVariant.secondary:
        bgColor = const Color(0xFF64748B);
        break;
      case SWButtonVariant.danger:
        bgColor = const Color(0xFFEF4444);
        break;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: 0,
        padding: isSmall
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isSmall ? 14 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
