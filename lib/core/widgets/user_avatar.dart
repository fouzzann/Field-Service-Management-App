import 'package:flutter/material.dart';
import '../utils/text_styles.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final Color roleColor;
  final double size;

  const UserAvatar({
    super.key,
    required this.name,
    required this.roleColor,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((l) => l[0]).take(2).join().toUpperCase()
        : 'U';

    final innerCircleSize = size - 20;
    final avatarRadius = (size - 36) / 2;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: roleColor.withValues(alpha: 0.2),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: roleColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          Container(
            width: innerCircleSize,
            height: innerCircleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: roleColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
          ),
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: roleColor.withValues(alpha: 0.1),
            child: Text(
              initials,
              style: AppTextStyles.heading2.copyWith(
                color: roleColor,
                fontWeight: FontWeight.bold,
                fontSize: avatarRadius * 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
