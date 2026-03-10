import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../app_data.dart';
import '../app_database_scope.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import 'reason_manage_page.dart';

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
  String _reasonType = '结婚礼金';
  String _themeColor = '#312E81';
  late final TextEditingController _noteCtrl;
  bool _isDefault = false;
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
    await AppDataScope.of(context).ensureReasonExists(name: book.reasonType);
    setState(() {
      _book = book;
      _nameCtrl.text = book.name;
      _reasonType = book.reasonType;
      _themeColor = book.themeColor;
      _noteCtrl.text = book.description ?? '';
      _isDefault = book.isDefault == 1;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('账簿名称不能为空');
      return;
    }
    final data = AppDataScope.of(context);
    if (!data.isReasonEnabledByName(_reasonType)) {
      _toast('事由类型无效，请从列表中选择已启用的事由');
      return;
    }
    final note = _noteCtrl.text.trim();
    setState(() => _saving = true);
    try {
      if (_book == null) {
        final newId = await _db.accountBooksDao.insertOne(
          AccountBooksCompanion(
            name: Value(name),
            reasonType: Value(_reasonType),
            themeColor: Value(_themeColor),
            description: note.isEmpty ? const Value.absent() : Value(note),
            isDefault: Value(_isDefault ? 1 : 0),
          ),
        );
        if (_isDefault) {
          await _db.accountBooksDao.setDefaultBook(newId);
        }
      } else {
        final updated = _book!.copyWith(
          name: name,
          reasonType: _reasonType,
          themeColor: _themeColor,
          description: Value(note.isEmpty ? null : note),
          isDefault: _isDefault ? 1 : 0,
        );
        await _db.accountBooksDao.updateOne(updated);
        if (_isDefault) {
          await _db.accountBooksDao.setDefaultBook(updated.bookId);
        }
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
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadii.br2xl,
              boxShadow: AppShadows.lg,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '确认删除账簿',
                          style: AppTypography.base(
                            fontSize: 14,
                            fontWeight: AppTypography.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      PrototypeIconButton(
                        icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                        backgroundColor: AppColors.gray100,
                        foregroundColor: AppColors.textSecondary,
                        onPressed: () => Navigator.of(context).pop(false),
                        radius: 12,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '删除账簿将同时删除其中的所有记录，且无法恢复。',
                        style: AppTypography.base(
                          fontSize: 13,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: PrototypeSecondaryButton(
                              label: '取消',
                              onTap: () => Navigator.of(context).pop(false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrototypePrimaryButton(
                              label: '确认删除',
                              onTap: () => Navigator.of(context).pop(true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true) return;
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
    final data = AppDataScope.of(context);
    final reasons = data.enabledReasons.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadii.br2xl,
              boxShadow: AppShadows.lg,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '选择事由类型',
                          style: AppTypography.base(
                            fontSize: 14,
                            fontWeight: AppTypography.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      PrototypeIconButton(
                        icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                        backgroundColor: AppColors.gray100,
                        foregroundColor: AppColors.textSecondary,
                        onPressed: () => Navigator.of(context).pop(),
                        radius: 12,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      for (final r in reasons)
                        PrototypePressableRow(
                          onTap: () => Navigator.of(context).pop(r.name),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r.name,
                                  style: AppTypography.base(
                                    fontSize: 14,
                                    fontWeight: AppTypography.medium,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (r.name == _reasonType)
                                const FaIcon(FontAwesomeIcons.check, size: 14, color: AppColors.indigo600),
                            ],
                          ),
                        ),
                      PrototypePressableRow(
                        onTap: () {
                          Navigator.of(context).pop();
                          AppNav.push(context, const ReasonManagePage());
                        },
                        borderBottom: false,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '管理事由',
                                style: AppTypography.base(
                                  fontSize: 14,
                                  fontWeight: AppTypography.medium,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() => _reasonType = picked);
  }

  Future<String?> _editText({
    required String title,
    required String label,
    required String initial,
    required String hintText,
    required bool multiline,
    required bool requiredField,
  }) async {
    final ctrl = TextEditingController(text: initial);
    final ok = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadii.br2xl,
              boxShadow: AppShadows.lg,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.base(
                            fontSize: 14,
                            fontWeight: AppTypography.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      PrototypeIconButton(
                        icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                        backgroundColor: AppColors.gray100,
                        foregroundColor: AppColors.textSecondary,
                        onPressed: () => Navigator.of(context).pop(),
                        radius: 12,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
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
                            if (requiredField)
                              const TextSpan(
                                text: ' *',
                                style: TextStyle(color: AppColors.red500),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: ctrl,
                        autofocus: true,
                        maxLines: multiline ? 6 : 1,
                        minLines: multiline ? 3 : 1,
                        style: AppTypography.base(
                          fontSize: 14,
                          fontWeight: AppTypography.medium,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.gray50,
                          hintText: hintText,
                          hintStyle: AppTypography.base(
                            fontSize: 14,
                            fontWeight: AppTypography.regular,
                            color: AppColors.textMuted,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.borderFocus, width: 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrototypePrimaryButton(
                        label: '保存',
                        onTap: () {
                          final text = ctrl.text.trim();
                          if (requiredField && text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$label不能为空')),
                            );
                            return;
                          }
                          Navigator.of(context).pop(text);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    // 说明：
    // - bottom sheet pop 后会有退出动画，立即 dispose controller 在某些版本 Flutter 上可能触发断言；
    // - 这里延后到下一帧再释放，避免 “_dependents.isEmpty” 等框架级断言。
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
    return ok;
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final title = _book == null ? '新建账簿' : '编辑账簿';
    final themeColor = _parseHexColor(_themeColor);
    final icon = _iconByReasonType(_reasonType);
    final reasonTypeLabel = _labelByReasonType(_reasonType);

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
              GestureDetector(
                onTap: _saving ? null : () => AppNav.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '取消',
                    style: AppTypography.base(
                      fontSize: 14,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: AppTypography.base(
                      fontSize: 18,
                      fontWeight: AppTypography.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              PressableScale(
                onTap: _saving ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: AppShadows.sm,
                  ),
                  child: Text(
                    _saving ? '保存中' : '保存',
                    style: AppTypography.base(
                      fontSize: 14,
                      fontWeight: AppTypography.medium,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _IconPreview(color: themeColor, icon: icon),
                    const SizedBox(height: 24),
                    _BasicCard(
                      nameCtrl: _nameCtrl,
                      reasonTypeLabel: reasonTypeLabel,
                      onPickReasonType: _pickReasonType,
                    ),
                    const SizedBox(height: 24),
                    const _Overline(title: '主题颜色'),
                    const SizedBox(height: 12),
                    _ColorPickerCard(
                      options: _themes,
                      selectedHex: _themeColor,
                      onPick: (hex) => setState(() => _themeColor = hex),
                    ),
                    const SizedBox(height: 24),
                    _NoteCard(noteCtrl: _noteCtrl),
                    const SizedBox(height: 24),
                    _DefaultToggleCard(
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v),
                    ),
                    if (_book != null) ...[
                      const SizedBox(height: 24),
                      _DeleteButton(disabled: _deleting, onTap: _delete),
                      const SizedBox(height: 8),
                      const _DeleteHint(),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _IconPreview extends StatelessWidget {
  const _IconPreview({
    required this.color,
    required this.icon,
  });

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
          child: FaIcon(icon, size: 30, color: color),
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
    required this.onPickReasonType,
  });

  final TextEditingController nameCtrl;
  final String reasonTypeLabel;
  final VoidCallback onPickReasonType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
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
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _SelectRow(
            label: '事由类型',
            value: reasonTypeLabel,
            borderBottom: false,
            onTap: onPickReasonType,
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
  });

  final String label;
  final bool requiredMark;
  final TextEditingController controller;
  final String hintText;
  final bool multiline;

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
                  const TextSpan(text: ' *', style: TextStyle(color: AppColors.red500)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: multiline ? 4 : 1,
            minLines: multiline ? 3 : 1,
            style: AppTypography.base(
              fontSize: 16,
              fontWeight: AppTypography.medium,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.gray50,
              hintText: hintText,
              hintStyle: AppTypography.base(
                fontSize: 14,
                fontWeight: AppTypography.regular,
                color: AppColors.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderFocus, width: 1),
              ),
            ),
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
    required this.onTap,
  });

  final String label;
  final String value;
  final bool borderBottom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PrototypePressableRow(
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
          const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
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

class _ColorPickerCard extends StatelessWidget {
  const _ColorPickerCard({
    required this.options,
    required this.selectedHex,
    required this.onPick,
  });

  final List<_ThemeOption> options;
  final String selectedHex;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final opt in options)
            _ColorDot(
              key: ValueKey<String>('book_theme_${opt.hex}'),
              color: opt.color,
              selected: opt.hex == selectedHex,
              onTap: () => onPick(opt.hex),
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
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

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
      return Container(width: 32, height: 32, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
    }

    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.indigo500, width: 2),
      ),
      child: Container(decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.noteCtrl});

  final TextEditingController noteCtrl;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
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
          TextField(
            controller: noteCtrl,
            maxLines: 5,
            minLines: 3,
            style: AppTypography.base(
              fontSize: 14,
              fontWeight: AppTypography.regular,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.gray50,
              hintText: '补充说明（可选）',
              hintStyle: AppTypography.base(
                fontSize: 14,
                fontWeight: AppTypography.regular,
                color: AppColors.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderFocus, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultToggleCard extends StatelessWidget {
  const _DefaultToggleCard({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      shadow: AppShadows.sm,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '设为默认账簿',
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '打开应用时自动显示此账簿',
                  style: AppTypography.base(
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.indigo600,
            activeTrackColor: AppColors.indigo200,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({
    required this.disabled,
    required this.onTap,
  });

  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: disabled ? null : onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray100, width: 1),
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
  if (v.contains('婚') || v.contains('宴') || v.contains('喜')) return FontAwesomeIcons.heart;
  if (v.contains('商务') || v.contains('公司') || v.contains('企业')) return FontAwesomeIcons.briefcase;
  return FontAwesomeIcons.book;
}

Color _parseHexColor(String hex) {
  final clean = hex.replaceAll('#', '');
  final full = clean.length == 6 ? 'FF$clean' : clean;
  return Color(int.parse(full, radix: 16));
}

