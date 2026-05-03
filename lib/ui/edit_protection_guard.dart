import 'package:flutter/material.dart';

import '../security/edit_protection.dart';

Future<bool> requireEditProtectionPassword(
  BuildContext context, {
  required String title,
}) async {
  final config = await EditProtectionConfig.load();
  if (!config.enabled) return true;
  if (!context.mounted) return false;
  final controller = TextEditingController();
  final password = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: '请输入编辑密码'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('确定'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  final v = password?.trim() ?? '';
  if (v.isEmpty) return false;
  final ok = await EditProtectionService().verifyPassword(v);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('密码错误')),
    );
  }
  return ok;
}

