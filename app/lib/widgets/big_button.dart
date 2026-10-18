/// Big child-friendly button: >= 56px touch target, spec palette.
library;

import 'package:flutter/material.dart';

import '../app_theme.dart';

class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final Key? buttonKey;

  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = TownTheme.green,
    this.icon,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: TownTheme.minTouch),
      child: ElevatedButton.icon(
        key: buttonKey,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: TownTheme.ink,
          minimumSize: const Size(120, TownTheme.minTouch),
        ),
        icon: icon != null ? Icon(icon, size: 28) : const SizedBox.shrink(),
        label: Text(label),
      ),
    );
  }
}
