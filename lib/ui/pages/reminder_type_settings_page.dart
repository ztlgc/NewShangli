import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../import/default_book_service.dart';
import '../../reminders/reminders_service.dart';
import '../app_database_scope.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../navigation.dart';
import '../prototype_kit.dart';

class ReminderTypeSettingsPage extends StatelessWidget {
  const ReminderTypeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: _Canvas(),
    );
  }
}

class _Canvas extends StatefulWidget {
  const _Canvas();

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  Future<String?> _resolveBookId() {
    return DefaultBookService().ensureDefaultBookId(AppDatabaseScope.of(context));
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    final service = RemindersService(db: db);
    return FutureBuilder<String?>(
      future: _resolveBookId(),
      builder: (context, snapshot) {
        final bookId = snapshot.data;
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
              ),
              child: Row(
                children: [
                  PrototypeIconButton(
                    icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 14),
                    backgroundColor: AppColors.gray100,
                    foregroundColor: AppColors.textSecondary,
                    onPressed: () => AppNav.pop(context),
                    radius: 12,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('提醒类型设置', style: AppTypography.h2().copyWith(fontSize: 20))),
                  PrototypeIconButton(
                    icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                    backgroundColor: AppColors.gray100,
                    foregroundColor: AppColors.textSecondary,
                    onPressed: bookId == null ? null : () => _addType(context, service, bookId),
                    radius: 12,
                  ),
                ],
              ),
            ),
            Expanded(
              child: bookId == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<String>>(
                      stream: service.watchTypeOptions(bookId),
                      builder: (context, typeSnapshot) {
                        final list = typeSnapshot.data ?? RemindersService.defaultTypes;
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          children: [
                            for (final item in list)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: const BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: AppRadii.brXl,
                                  boxShadow: AppShadows.sm,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: AppTypography.base(
                                          fontSize: 14,
                                          fontWeight: AppTypography.medium,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addType(BuildContext context, RemindersService service, String bookId) async {
    final ctrl = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新增自定义类型'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: '请输入 2-10 个汉字'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.of(context).pop(ctrl.text.trim()), child: const Text('保存')),
          ],
        );
      },
    );
    ctrl.dispose();
    if (value == null) return;
    if (!RegExp(r'^[\u4e00-\u9fa5]{2,10}$').hasMatch(value)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入 2-10 个汉字')));
      return;
    }
    final ok = await service.addCustomType(bookId: bookId, name: value);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '新增成功' : '类型已存在')),
    );
  }
}
