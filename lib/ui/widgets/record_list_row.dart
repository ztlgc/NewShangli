import 'package:flutter/material.dart';

import '../app_data.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../contact_avatar.dart';

class RecordListRow extends StatelessWidget {
  const RecordListRow({
    super.key,
    required this.name,
    required this.direction,
    required this.amountCent,
    required this.subtitle,
    required this.occurredAt,
    this.avatarUrl,
    this.onTap,
    this.onLongPress,
    this.borderBottom = true,
    this.selectionMode = false,
    this.selected = false,
  });

  final String? avatarUrl;
  final String name;
  final RecordDirection direction;
  final int amountCent;
  final String subtitle;
  final DateTime occurredAt;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool borderBottom;
  final bool selectionMode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final amountText = _formatSignedAmount(direction, amountCent);
    final amountColor = direction == RecordDirection.income ? AppColors.green600 : AppColors.red500;
    final dateText = '${occurredAt.month.toString().padLeft(2, '0')}-${occurredAt.day.toString().padLeft(2, '0')}';

    return PrototypePressableRow(
      onTap: onTap,
      onLongPress: onLongPress,
      borderBottom: borderBottom,
      pressedColor: selectionMode ? AppColors.indigo50 : AppColors.gray50,
      enablePressedFeedback: !selectionMode,
      child: Row(
        children: [
          if (selectionMode) ...[
            _SelectDot(selected: selected),
            const SizedBox(width: 10),
          ],
          ContactAvatar(
            name: name,
            avatarUrl: avatarUrl,
            size: 40,
            shape: ContactAvatarShape.circle,
            border: Border.all(color: AppColors.gray100, width: 1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTypography.base(
                          fontSize: 16,
                          fontWeight: AppTypography.medium,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      amountText,
                      style: AppTypography.base(
                        fontSize: 16,
                        fontWeight: AppTypography.semibold,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: AppTypography.base(
                          fontSize: 12,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    Text(
                      dateText,
                      style: AppTypography.base(
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSignedAmount(RecordDirection direction, int cent) {
    final sign = direction == RecordDirection.income ? '+' : '-';
    final absCent = cent.abs();
    final yuan = (absCent / 100).toStringAsFixed(2);
    final parts = yuan.split('.');
    final intPart = parts[0];
    final fracPart = parts[1];
    final grouped = intPart.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return '$sign$grouped.$fracPart';
  }
}

class _SelectDot extends StatelessWidget {
  const _SelectDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.indigo600 : Colors.transparent,
        border: Border.all(color: selected ? AppColors.indigo600 : AppColors.gray300, width: 1.5),
      ),
      alignment: Alignment.center,
      child: selected ? const Icon(Icons.check, size: 12, color: AppColors.white) : null,
    );
  }
}
