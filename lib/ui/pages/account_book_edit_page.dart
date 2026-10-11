import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../data/local/drift/app_database.dart';
import '../../utils/date_util.dart';
import '../app_database_scope.dart';
import '../app_bottom_sheet.dart';
import '../app_dialog.dart';
import '../app_notifier.dart';
import '../app_notification_tokens.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../edit_protection_guard.dart';
import '../lunar_date_picker.dart';
import '../navigation.dart';
import '../ui_kit.dart';
import 'reason_manage_page.dart';

import '../app_icons.dart';

import '../app_layout.dart';

class AccountBookEditPage extends StatelessWidget {
  const AccountBookEditPage({super.key, this.bookId});

  final String? bookId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: _Canvas(bookId: bookId),
    );
  }
}

class _Canvas extends StatefulWidget {
  const _Canvas({required this.bookId});

  final String? bookId;

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;

  AccountBook? _book;
  late final TextEditingController _nameCtrl;
  String _reasonType = '';
  String _themeColor = '#312E81';
  DateTime _bookTime = DateTime.now();
  late final TextEditingController _noteCtrl;
  bool _loadedOnce = false;

  static const List<_ThemeOption> _themes = [
    _ThemeOption(hex: '#312E81', color: AppColors.indigo900),
    _ThemeOption(hex: '#6366F1', color: AppColors.indigo500),
    _ThemeOption(hex: '#EC4899', color: AppColors.pink500),
    _ThemeOption(hex: '#F97316', color: AppColors.orange500),
    _ThemeOption(hex: '#22C55E', color: AppColors.green500),
    _ThemeOption(hex: '#3B82F6', color: AppColors.blue500),
    _ThemeOption(hex: '#A855F7', color: AppColors.purple500),
    _ThemeOption(hex: '#6B7280', color: AppColors.gray500),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedOnce) return;
    _loadedOnce = true;
    _load();
  }

  AppDatabase get _db => AppDatabaseScope.of(context);

  Future<void> _load() async {
    if (widget.bookId == null) {
      setState(() => _loading = false);
      return;
    }
    final book = await _db.accountBooksDao.findById(widget.bookId!);
    if (!mounted) return;
    if (book == null) {
      _toast('账簿不存在或已被删除');
      AppNav.pop(context);
      return;
    }
    if (book.reasonType.trim().isNotEmpty) {
      final reason = await _db.reasonsDao.findByName(book.reasonType);
      if (reason == null) {
        await _db.reasonsDao.create(name: book.reasonType, enabled: true);
      }
    }
    setState(() {
      _book = book;
      _nameCtrl.text = book.name;
      _reasonType = book.reasonType;
      _themeColor = book.themeColor;
      _bookTime = DateTime.fromMillisecondsSinceEpoch(book.bookTime);
      _noteCtrl.text = book.description ?? '';
      _loading = false;
    });
  }

  Future<void> _pickBookTime() async {
    final initialDate = DateTime(
      _bookTime.year,
      _bookTime.month,
      _bookTime.day,
    );
    final picked = await showLunarDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(DateTime.now().year + 10, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      _bookTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _bookTime.hour,
        _bookTime.minute,
        _bookTime.second,
        _bookTime.millisecond,
        _bookTime.microsecond,
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_book != null) {
      final okAuth = await requireEditProtectionPassword(
        context,
        title: '编辑账簿',
      );
      if (!okAuth) return;
    }
    if (_book?.isDefault == 1) {
      _toast('默认账簿不可更改');
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('账簿名称不能为空');
      return;
    }
    final reason = await _db.reasonsDao.findByName(_reasonType);
    if (reason == null || !reason.enabled) {
      _toast('事由类型无效，请从列表中选择已启用的事由');
      return;
    }
    final note = _noteCtrl.text.trim();
    setState(() => _saving = true);
    try {
      if (_book == null) {
        await _db.accountBooksDao.insertOne(
          AccountBooksCompanion(
            name: Value(name),
            reasonType: Value(_reasonType),
            themeColor: Value(_themeColor),
            description: note.isEmpty ? const Value.absent() : Value(note),
            bookTime: Value(_bookTime.millisecondsSinceEpoch),
            isDefault: const Value(0),
          ),
        );
      } else {
        final updated = _book!.copyWith(
          name: name,
          reasonType: _reasonType,
          themeColor: _themeColor,
          description: Value(note.isEmpty ? null : note),
          bookTime: _bookTime.millisecondsSinceEpoch,
          isDefault: _book!.isDefault,
        );
        await _db.accountBooksDao.updateOne(updated);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _toast('保存失败：$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (_deleting || _book == null) return;
    final okAuth = await requireEditProtectionPassword(context, title: '删除账簿');
    if (!okAuth) return;
    if (!mounted) return;
    final ok = await AppDialog.confirm(
      context,
      title: '确认删除账簿',
      message: '删除账簿将同时删除其中的所有记录，且无法恢复。',
      confirmLabel: '确认删除',
      cancelLabel: '取消',
      danger: true,
      tone: AppNotificationTone.error,
    );
    if (!mounted || ok != true) return;
    setState(() => _deleting = true);
    try {
      await _db.accountBooksDao.deleteById(_book!.bookId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _toast('删除失败：$e');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _pickReasonType() async {
    final reasons = await _db.reasonsDao.listAll();
    if (!mounted) return;
    final enabled = reasons.where((e) => e.enabled).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final picked = await AppBottomSheet.showCustom<String>(
      context,
      builder: (context) => _ReasonTypePickerSheet(
        reasons: enabled,
        selectedReasonType: _reasonType,
      ),
    );
    if (!mounted || picked == null) return;
    if (picked == _ReasonTypePickerSheet.manageAction) {
      AppNav.push(context, const ReasonManagePage());
      return;
    }
    setState(() => _reasonType = picked);
  }

  void _toast(String message) {
    AppNotifier.info(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final title = _book == null ? '新建账簿' : '编辑账簿';
    final isReadonlyDefault = _book?.isDefault == 1;
    final themeColor = _parseHexColor(_themeColor);
    final icon = _iconByReasonType(_reasonType);
    final reasonTypeLabel = isReadonlyDefault
        ? '全部事由'
        : _labelByReasonType(_reasonType);
    final bookTimeLabel = _formatBookTime(_bookTime);

    return Column(
      children: [
        FHeader.nested(
          title: Text(title),
          prefixes: [
            FButton(
              variant: .ghost,
              size: .sm,
              mainAxisSize: MainAxisSize.min,
              onPress: _saving ? null : () => AppNav.pop(context),
              child: const Text('取消'),
            ),
          ],
          suffixes: [
            FButton(
              size: .sm,
              mainAxisSize: MainAxisSize.min,
              onPress: (_saving || isReadonlyDefault) ? null : _save,
              child: Text(
                isReadonlyDefault ? '不可修改' : (_saving ? '保存中' : '保存'),
              ),
            ),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _IconPreview(color: themeColor, icon: icon),
                    const SizedBox(height: AppLayout.sectionGap),
                    _BasicCard(
                      nameCtrl: _nameCtrl,
                      reasonTypeLabel: reasonTypeLabel,
                      bookTimeLabel: bookTimeLabel,
                      editable: !isReadonlyDefault,
                      onPickReasonType: _pickReasonType,
                      onPickBookTime: _pickBookTime,
                    ),
                    const SizedBox(height: AppLayout.sectionGap),
                    const _Overline(title: '主题颜色'),
                    const SizedBox(height: 12),
                    _ColorPickerCard(
                      options: _themes,
                      selectedHex: _themeColor,
                      onPick: isReadonlyDefault
                          ? null
                          : (hex) => setState(() => _themeColor = hex),
                    ),
                    const SizedBox(height: AppLayout.sectionGap),
                    _NoteCard(
                      noteCtrl: _noteCtrl,
                      editable: !isReadonlyDefault,
                    ),
                    if (_book != null && !isReadonlyDefault) ...[
                      const SizedBox(height: AppLayout.sectionGap),
                      _DeleteButton(disabled: _deleting, onTap: _delete),
                      const SizedBox(height: 8),
                      const _DeleteHint(),
                    ],
                    if (_book != null && isReadonlyDefault) ...[
                      const SizedBox(height: AppLayout.sectionGap),
                      const _ReadonlyHint(text: '默认账簿为系统保留账簿，不支持编辑或删除。'),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _IconPreview extends StatelessWidget {
  const _IconPreview({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.sm,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 30, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          '预览图标样式',
          style: AppTypography.base(
            fontSize: 12,
            fontWeight: AppTypography.regular,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _BasicCard extends StatelessWidget {
  const _BasicCard({
    required this.nameCtrl,
    required this.reasonTypeLabel,
    required this.bookTimeLabel,
    required this.editable,
    required this.onPickReasonType,
    required this.onPickBookTime,
  });

  final TextEditingController nameCtrl;
  final String reasonTypeLabel;
  final String bookTimeLabel;
  final bool editable;
  final VoidCallback onPickReasonType;
  final VoidCallback onPickBookTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          _TextFieldRow(
            label: '账簿名称',
            requiredMark: true,
            controller: nameCtrl,
            hintText: '请输入账簿名称',
            multiline: false,
            editable: editable,
          ),
          const AppDivider(color: AppColors.borderDivider),
          _SelectRow(
            label: '事由类型',
            value: reasonTypeLabel,
            onTap: editable ? onPickReasonType : null,
          ),
          const AppDivider(color: AppColors.borderDivider),
          _SelectRow(
            label: '账簿时间',
            value: bookTimeLabel,
            borderBottom: false,
            onTap: editable ? onPickBookTime : null,
          ),
        ],
      ),
    );
  }
}

class _TextFieldRow extends StatelessWidget {
  const _TextFieldRow({
    required this.label,
    required this.requiredMark,
    required this.controller,
    required this.hintText,
    required this.multiline,
    required this.editable,
  });

  final String label;
  final bool requiredMark;
  final TextEditingController controller;
  final String hintText;
  final bool multiline;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: AppTypography.base(
                fontSize: 12,
                fontWeight: AppTypography.regular,
                color: AppColors.textTertiary,
              ),
              children: [
                TextSpan(text: label),
                if (requiredMark)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: context.appColors.stateDanger),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FTextField(
            control: FTextFieldControl.managed(controller: controller),
            readOnly: !editable,
            maxLines: multiline ? 4 : 1,
            minLines: multiline ? 3 : 1,
            hint: hintText,
          ),
        ],
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.label,
    required this.value,
    this.borderBottom = true,
    this.onTap,
  });

  final String label;
  final String value;
  final bool borderBottom;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressableRow(
      onTap: onTap,
      borderBottom: borderBottom,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.base(
                    fontSize: 16,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              AppIcons.chevronRight,
              size: 10,
              color: AppColors.gray300,
            ),
        ],
      ),
    );
  }
}

class _Overline extends StatelessWidget {
  const _Overline({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTypography.base(
          fontSize: 12,
          fontWeight: AppTypography.bold,
          color: AppColors.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ReasonTypePickerSheet extends StatefulWidget {
  const _ReasonTypePickerSheet({
    required this.reasons,
    required this.selectedReasonType,
  });

  static const String manageAction = '__manage_reason__';

  final List<Reason> reasons;
  final String selectedReasonType;

  @override
  State<_ReasonTypePickerSheet> createState() => _ReasonTypePickerSheetState();
}

String _formatBookTime(DateTime dt) {
  return DateUtil.format(dt);
}

class _ReasonTypePickerSheetState extends State<_ReasonTypePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.reasons.where((reason) {
      final key = _keyword.trim().toLowerCase();
      if (key.isEmpty) return true;
      return reason.name.toLowerCase().contains(key);
    }).toList();
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 620),
          decoration: BoxDecoration(
            color: context.appColors.surfaceCard,
            borderRadius: AppRadii.br2xl,
            boxShadow: AppShadows.lg,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceDisabled,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '选择事由',
                        style: AppTypography.base(
                          fontSize: 18,
                          fontWeight: AppTypography.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    AppIconButton(
                      icon: const Icon(AppIcons.x, size: 14),
                      backgroundColor: context.appColors.surfaceSubtle,
                      foregroundColor: AppColors.textSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                      radius: 12,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: AppSearchField(
                  controller: _searchController,
                  hintText: '搜索事由',
                  onChanged: (v) => setState(() => _keyword = v),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          widget.reasons.isEmpty ? '暂无可选事由' : '没有匹配结果',
                          style: AppTypography.base(
                            fontSize: 13,
                            fontWeight: AppTypography.regular,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final reason = filtered[index];
                          return AppPressableRow(
                            borderBottom: index != filtered.length - 1,
                            onTap: () => Navigator.of(context).pop(reason.name),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reason.name,
                                    style: AppTypography.base(
                                      fontSize: 14,
                                      fontWeight: AppTypography.medium,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (reason.name == widget.selectedReasonType)
                                  const Icon(
                                    AppIcons.check,
                                    size: 14,
                                    color: AppColors.indigo600,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: AppSecondaryButton(
                  label: '管理事由',
                  onTap: () =>
                      Navigator.of(context)
                          .pop(_ReasonTypePickerSheet.manageAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadonlyHint extends StatelessWidget {
  const _ReadonlyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.base(
        fontSize: 12,
        fontWeight: AppTypography.regular,
        color: AppColors.textMuted,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _ColorPickerCard extends StatelessWidget {
  const _ColorPickerCard({
    required this.options,
    required this.selectedHex,
    this.onPick,
  });

  final List<_ThemeOption> options;
  final String selectedHex;
  final ValueChanged<String>? onPick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppLayout.pagePadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final opt in options)
            _ColorDot(
              key: ValueKey<String>('book_theme_${opt.hex}'),
              color: opt.color,
              selected: opt.hex == selectedHex,
              onTap: onPick == null ? null : () => onPick!(opt.hex),
            ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    super.key,
    required this.color,
    required this.selected,
    this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: _Dot(color: color, selected: selected),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.selected});

  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }

    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.indigo500, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.noteCtrl, required this.editable});

  final TextEditingController noteCtrl;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppLayout.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '备注',
            style: AppTypography.base(
              fontSize: 12,
              fontWeight: AppTypography.regular,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          FTextField(
            control: FTextFieldControl.managed(controller: noteCtrl),
            readOnly: !editable,
            maxLines: 5,
            minLines: 3,
            hint: '补充说明（可选）',
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.disabled, required this.onTap});

  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: disabled ? null : onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appColors.borderSubtle, width: 1),
          boxShadow: AppShadows.sm,
        ),
        alignment: Alignment.center,
        child: Text(
          disabled ? '删除中...' : '删除账簿',
          style: AppTypography.base(
            fontSize: 14,
            fontWeight: AppTypography.medium,
            color: AppColors.red500,
          ),
        ),
      ),
    );
  }
}

class _DeleteHint extends StatelessWidget {
  const _DeleteHint();

  @override
  Widget build(BuildContext context) {
    return Text(
      '删除账簿将同时删除其中的所有记录，且无法恢复。',
      style: AppTypography.base(
        fontSize: 12,
        fontWeight: AppTypography.regular,
        color: AppColors.textMuted,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _ThemeOption {
  const _ThemeOption({required this.hex, required this.color});

  final String hex;
  final Color color;
}

String _labelByReasonType(String reasonType) {
  final v = reasonType.trim();
  if (v.isEmpty) return '未选择';
  return v;
}

IconData _iconByReasonType(String reasonType) {
  final v = reasonType.trim();
  if (v.contains('婚') || v.contains('宴') || v.contains('喜')) {
    return AppIcons.heart;
  }
  if (v.contains('商务') || v.contains('公司') || v.contains('企业')) {
    return AppIcons.briefcaseBusiness;
  }
  return AppIcons.bookOpen;
}

Color _parseHexColor(String hex) {
  final clean = hex.replaceAll('#', '');
  final full = clean.length == 6 ? 'FF$clean' : clean;
  return Color(int.parse(full, radix: 16));
}
