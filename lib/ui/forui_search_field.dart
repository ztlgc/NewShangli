import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'app_forui_theme.dart';

import 'app_icons.dart';

/// Search input shared across Forui pages.
class ForuiSearchField extends StatelessWidget {
  const ForuiSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.showClearButton = true,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool showClearButton;

  @override
  Widget build(BuildContext context) => AppForuiBoundary(
    child: FTextField(
      control: FTextFieldControl.managed(
        controller: controller,
        onChange: (value) => onChanged(value.text),
      ),
      hint: hint,
      textInputAction: TextInputAction.search,
      prefixBuilder: (context, style, variants) => FTextField.prefixIconBuilder(
        context,
        style,
        variants,
        const Icon(AppIcons.search),
      ),
      clearable: (value) => showClearButton && value.text.isNotEmpty,
    ),
  );
}
