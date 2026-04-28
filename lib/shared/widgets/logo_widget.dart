import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
      ),
    );
  }
}
