import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../security/edit_protection.dart';
import 'app_tokens.dart';
import 'prototype_kit.dart';

Future<bool> requireEditProtectionPassword(
  BuildContext context, {
  required String title,
}) async {
  final config = await EditProtectionConfig.load();
  if (!config.enabled) return true;
  if (!context.mounted) return false;
  final password = await showEditProtectionPasswordDialog(
    context,
    title: title,
  );
  final v = password?.trim() ?? '';
  if (v.isEmpty) return false;
  final ok = await EditProtectionService().verifyPassword(v);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('密码错误')));
  }
  return ok;
}

Future<String?> showEditProtectionPasswordDialog(
  BuildContext context, {
  required String title,
}) async {
  final controller = TextEditingController();
  try {
    return await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _EditProtectionPasswordDialog(
          title: title,
          controller: controller,
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

class _EditProtectionPasswordDialog extends StatefulWidget {
  const _EditProtectionPasswordDialog({
    required this.title,
    required this.controller,
  });

  final String title;
  final TextEditingController controller;

  @override
  State<_EditProtectionPasswordDialog> createState() =>
      _EditProtectionPasswordDialogState();
}

class _EditProtectionPasswordDialogState
    extends State<_EditProtectionPasswordDialog> {
  bool _obscure = true;

  void _submit() {
    Navigator.of(context).pop(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.br2xl,
            border: Border.all(color: AppColors.gray100),
            boxShadow: AppShadows.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.indigo50,
                      borderRadius: AppRadii.brXl,
                    ),
                    alignment: Alignment.center,
                    child: const FaIcon(
                      FontAwesomeIcons.lock,
                      size: 16,
                      color: AppColors.indigo700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.base(
                            fontSize: AppTypography.fs18,
                            fontWeight: AppTypography.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '验证后继续操作',
                          style: AppTypography.base(
                            fontSize: AppTypography.fs12,
                            fontWeight: AppTypography.regular,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: widget.controller,
                autofocus: true,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: AppTypography.base(
                  fontSize: AppTypography.fs16,
                  fontWeight: AppTypography.medium,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '请输入编辑密码',
                  hintStyle: AppTypography.base(
                    fontSize: AppTypography.fs14,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 14, right: 10),
                    child: FaIcon(FontAwesomeIcons.key, size: 15),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 44,
                  ),
                  suffixIcon: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: FaIcon(
                      _obscure
                          ? FontAwesomeIcons.eye
                          : FontAwesomeIcons.eyeSlash,
                      size: 15,
                    ),
                  ),
                  suffixIconColor: AppColors.textTertiary,
                  filled: true,
                  fillColor: AppColors.gray50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadii.brXl,
                    borderSide: const BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadii.brXl,
                    borderSide: const BorderSide(
                      color: AppColors.indigo600,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _DialogActionButton(
                      label: '取消',
                      background: AppColors.gray100,
                      foreground: AppColors.textSecondary,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DialogActionButton(
                      label: '确认',
                      background: AppColors.brandPrimary,
                      foreground: AppColors.white,
                      onTap: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadii.brXl,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.base(
            fontSize: AppTypography.fs14,
            fontWeight: AppTypography.semibold,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
