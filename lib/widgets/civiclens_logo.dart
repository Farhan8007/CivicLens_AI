import 'package:flutter/material.dart';

class CivicLensLogo extends StatelessWidget {
  final double size;
  final bool isDark;

  const CivicLensLogo({
    super.key,
    this.size = 80.0,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          isDark ? 'assets/logo/logo_dark.jpg' : 'assets/logo/logo_light.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
