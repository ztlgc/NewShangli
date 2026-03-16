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
    this.onSelectionToggle,
    this.fadeDuration = const Duration(milliseconds: 250),
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
  final VoidCallback? onSelectionToggle;
  final Duration fadeDuration;

  @override
  Widget build(BuildContext context) {
    final amountText = _formatSignedAmount(direction, amountCent);
    final amountColor = direction == RecordDirection.income ? AppColors.green600 : AppColors.red500;
    final dateText =
        '${occurredAt.month.toString().padLeft(2, '0')}-${occurredAt.day.toString().padLeft(2, '0')}';

    return PrototypePressableRow(
      onTap: onTap,
      onLongPress: onLongPress,
      borderBottom: borderBottom,
      child: Row(
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
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !selectionMode,
                    child: AnimatedOpacity(
                      opacity: selectionMode ? 1 : 0,
                      duration: fadeDuration,
                      curve: Curves.easeInOut,
                      child: _AvatarSelectionCheckbox(
                        label: name,
                        selected: selected,
                        onToggle: onSelectionToggle ?? onTap,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

class _AvatarSelectionCheckbox extends StatelessWidget {
  const _AvatarSelectionCheckbox({
    required this.label,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final bool selected;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected ? AppColors.brandPrimary : AppColors.gray500.withValues(alpha: 0.2);
    return Semantics(
      checked: selected,
      button: true,
      label: '$label，${selected ? '已选中' : '未选中'}',
      child: GestureDetector(
        onTap: onToggle,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2),
            boxShadow: AppShadows.sm,
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: selected
                ? const Icon(
                    Icons.check,
                    key: ValueKey('selected'),
                    size: 16,
                    color: AppColors.white,
                  )
                : const SizedBox(key: ValueKey('unselected')),
          ),
        ),
      ),
    );
  }
}
