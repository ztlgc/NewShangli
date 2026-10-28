import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../app_icons.dart';
import '../app_tokens.dart';
import '../components.dart';

Text transferText(
  BuildContext context,
  String value,
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w400,
  int? maxLines,
}) => Text(
  value,
  maxLines: maxLines,
  overflow: maxLines == null ? null : TextOverflow.ellipsis,
  style: AppTypography.base(
    fontSize: size,
    fontWeight: weight,
    color: color ?? context.appColors.textPrimary,
    height: 1.35,
  ),
);

String transferFileSize(int bytes) => bytes < 1024
    ? '$bytes B'
    : bytes < 1024 * 1024
    ? '${(bytes / 1024).toStringAsFixed(bytes < 10240 ? 1 : 0)} KB'
    : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

String transferDate(DateTime date) =>
    '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

class TransferIconWell extends StatelessWidget {
  const TransferIconWell({super.key, required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.appColors.surfaceSubtle,
      borderRadius: AppRadii.brXl,
    ),
    child: Icon(icon, size: 19, color: context.appColors.textSecondary),
  );
}

class TransferFooter extends StatelessWidget {
  const TransferFooter({
    super.key,
    required this.label,
    required this.hint,
    this.onPressed,
    this.secondary,
    this.hintColor,
  });
  final String label;
  final String hint;
  final VoidCallback? onPressed;
  final Widget? secondary;
  final Color? hintColor;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
    decoration: BoxDecoration(
      color: context.appColors.surfaceCard,
      border: Border(top: BorderSide(color: context.appColors.borderDefault)),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (secondary != null) ...[secondary!, const SizedBox(height: 8)],
            AppPrimaryButton(label: label, onTap: onPressed),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: AppTypography.base(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: hintColor ?? context.appColors.textTertiary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class TransferHeading extends StatelessWidget {
  const TransferHeading({
    super.key,
    required this.title,
    this.detail,
    this.detailColor,
    this.onTap,
  });
  final String title;
  final String? detail;
  final Color? detailColor;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Expanded(
          child: transferText(context, title, 16, weight: FontWeight.w600),
        ),
        if (detail != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: transferText(
              context,
              detail!,
              11,
              color: detailColor ?? context.appColors.textTertiary,
            ),
          ),
        ],
        if (onTap != null) ...[
          const SizedBox(width: 6),
          Icon(
            AppIcons.chevronRight,
            size: 14,
            color: context.appColors.textTertiary,
          ),
        ],
      ],
    );
    if (onTap == null) return row;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: FButton.raw(
        variant: .ghost,
        onPress: onTap,
        semanticsLabel: title,
        child: row,
      ),
    );
  }
}

class TransferSelectionRow extends StatelessWidget {
  const TransferSelectionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 44),
    child: FButton.raw(
      variant: .ghost,
      onPress: onTap,
      semanticsLabel: label,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: subtitle == null ? 8 : 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: context.appColors.textSecondary),
            const SizedBox(width: 10),
            transferText(
              context,
              label,
              13,
              color: context.appColors.textSecondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  transferText(context, value, 13, maxLines: 2),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    transferText(
                      context,
                      subtitle!,
                      11,
                      color: context.appColors.textTertiary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              AppIcons.chevronRight,
              size: 14,
              color: context.appColors.textTertiary,
            ),
          ],
        ),
      ),
    ),
  );
}

class TransferMessage extends StatelessWidget {
  const TransferMessage({
    super.key,
    required this.message,
    this.error = false,
    this.action,
  });
  final String message;
  final bool error;
  final Widget? action;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              error ? AppIcons.triangleAlert : AppIcons.info,
              size: 16,
              color: error
                  ? context.appColors.stateDanger
                  : context.appColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: transferText(
                context,
                message,
                12,
                color: error
                    ? context.appColors.stateDangerStrong
                    : context.appColors.textSecondary,
              ),
            ),
          ],
        ),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ],
    ),
  );
}
