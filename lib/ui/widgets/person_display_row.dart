import 'package:flutter/material.dart';

import '../app_tokens.dart';
import '../contact_avatar.dart';

class PersonDisplayRow extends StatelessWidget {
  const PersonDisplayRow({
    super.key,
    required this.name,
    required this.subtitle,
    this.avatarUrl,
    this.trailing,
    this.avatarOverlay,
  });

  final String name;
  final String subtitle;
  final String? avatarUrl;
  final Widget? trailing;
  final Widget? avatarOverlay;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ContactAvatar(
                name: name,
                avatarUrl: avatarUrl,
                size: 40,
                shape: ContactAvatarShape.circle,
                border: Border.all(color: AppColors.gray100, width: 1),
              ),
              if (avatarOverlay != null) Positioned.fill(child: avatarOverlay!),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTypography.base(
                  fontSize: 16,
                  fontWeight: AppTypography.medium,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.base(
                  fontSize: 12,
                  fontWeight: AppTypography.regular,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}
