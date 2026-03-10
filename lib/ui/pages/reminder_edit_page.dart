import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../../reminders/reminders_service.dart';
import '../app_database_scope.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';

/// 页面：新建/编辑提醒。
///
/// 说明：
/// - 该页面负责收集用户输入；
/// - 真正的校验与落库由 [RemindersService] 完成；
/// - 保存成功后会 `pop(true)`，便于上层页面做“操作反馈/刷新”。
class ReminderEditPage extends StatelessWidget {
  const ReminderEditPage({
    super.key,
    required this.bookId,
    this.reminderId,
  });

  final String bookId;
  final String? reminderId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: _Canvas(bookId: bookId, reminderId: reminderId),
    );
  }
}

class _Canvas extends StatefulWidget {
  const _Canvas({
    required this.bookId,
    required this.reminderId,
  });

  final String bookId;
  final String? reminderId;

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;
  bool _loadedOnce = false;

  EventReminder? _reminder;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;

  String _type = '自定义';
  ReminderRepeatRule _repeatRule = ReminderRepeatRule.none;
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  String? _personId;

  static const List<String> _typePresets = <String>[
    '自定义',
    '生日',
    '回礼',
    '纪念日',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  AppDatabase get _db => AppDatabaseScope.of(context);
  RemindersService get _service => RemindersService(db: _db);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedOnce) return;
    _loadedOnce = true;
    _load();
  }

  Future<void> _load() async {
    if (widget.reminderId == null) {
      setState(() => _loading = false);
      return;
    }
    final r = await _db.eventRemindersDao.findById(widget.reminderId!);
    if (!mounted) return;
    if (r == null) {
      _toast('提醒不存在或已被删除');
      AppNav.pop(context);
      return;
    }
    final remindAt = DateTime.fromMillisecondsSinceEpoch(r.remindAt);
    setState(() {
      _reminder = r;
      _titleCtrl.text = r.title;
      _type = r.reminderType.trim().isEmpty ? '自定义' : r.reminderType.trim();
      _repeatRule = RemindersService.parseRepeatRule(r.repeatRule);
      _date = _parseYmdOrNow(r.targetDate);
      _time = TimeOfDay(hour: remindAt.hour, minute: remindAt.minute);
      _personId = r.personId;
      _noteCtrl.text = r.note ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final title = _titleCtrl.text.trim();
      final note = _noteCtrl.text.trim();
      final remindAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );

      if (_reminder == null) {
        await _service.create(
          bookId: widget.bookId,
          title: title,
          reminderType: _type,
          personId: _personId,
          targetDate: _date,
          remindAt: remindAt,
          repeatRule: _repeatRule,
          note: note.isEmpty ? null : note,
        );
      } else {
        await _service.update(
          reminderId: _reminder!.reminderId,
          title: title,
          reminderType: _type,
          personId: _personId,
          targetDate: _date,
          remindAt: remindAt,
          repeatRule: _repeatRule,
          note: note.isEmpty ? null : note,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ReminderException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } catch (e) {
      if (!mounted) return;
      _toast('保存失败：$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (_deleting || _reminder == null) return;
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
                          '确认删除提醒',
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
                        '删除后无法恢复。',
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
      await _service.deleteById(_reminder!.reminderId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _toast('删除失败：$e');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _pickType() async {
    const customValue = '__custom__';
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
                          '选择提醒类型',
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
                      for (final t in _typePresets)
                        PrototypePressableRow(
                          onTap: () => Navigator.of(context).pop(t),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t,
                                  style: AppTypography.base(
                                    fontSize: 14,
                                    fontWeight: AppTypography.medium,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (t == _type)
                                const FaIcon(FontAwesomeIcons.check, size: 14, color: AppColors.indigo600),
                            ],
                          ),
                        ),
                      PrototypePressableRow(
                        onTap: () => Navigator.of(context).pop(customValue),
                        borderBottom: false,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '自定义类型',
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
    if (picked == customValue) {
      final v = await _editText(
        title: '自定义提醒类型',
        label: '类型',
        initial: _isPresetType(_type) ? '' : _type,
        hintText: '例如：乔迁/满月/升学宴',
        multiline: false,
        requiredField: true,
      );
      if (v == null) return;
      setState(() => _type = v.trim());
      return;
    }
    setState(() => _type = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked == null) return;
    setState(() => _time = picked);
  }

  Future<void> _pickRepeatRule() async {
    final picked = await showModalBottomSheet<ReminderRepeatRule>(
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
                          '重复规则',
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
                      for (final r in ReminderRepeatRule.values)
                        PrototypePressableRow(
                          onTap: () => Navigator.of(context).pop(r),
                          borderBottom: r != ReminderRepeatRule.values.last,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _repeatRuleLabel(r),
                                  style: AppTypography.base(
                                    fontSize: 14,
                                    fontWeight: AppTypography.medium,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (r == _repeatRule)
                                const FaIcon(FontAwesomeIcons.check, size: 14, color: AppColors.indigo600),
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
    setState(() => _repeatRule = picked);
  }

  Future<void> _pickPerson() async {
    final selected = await showModalBottomSheet<String?>(
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
                          '选择关系人（可选）',
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
                  child: StreamBuilder<List<Person>>(
                    stream: _db.personsDao.watchAllInBook(widget.bookId),
                    builder: (context, snapshot) {
                      final people = snapshot.data ?? const <Person>[];
                      return ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 12),
                        children: [
                          PrototypePressableRow(
                            onTap: () => Navigator.of(context).pop(null),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text('不关联关系人'),
                                ),
                                if (_personId == null)
                                  const FaIcon(FontAwesomeIcons.check, size: 14, color: AppColors.indigo600),
                              ],
                            ),
                          ),
                          if (people.isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Text(
                                '当前账簿暂无关系人数据',
                                style: AppTypography.base(
                                  fontSize: 12,
                                  fontWeight: AppTypography.regular,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          for (final p in people)
                            PrototypePressableRow(
                              onTap: () => Navigator.of(context).pop(p.personId),
                              borderBottom: true,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: AppTypography.base(
                                            fontSize: 14,
                                            fontWeight: AppTypography.medium,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        if ((p.phone ?? '').trim().isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            p.phone!.trim(),
                                            style: AppTypography.base(
                                              fontSize: 12,
                                              fontWeight: AppTypography.regular,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (p.personId == _personId)
                                    const FaIcon(FontAwesomeIcons.check, size: 14, color: AppColors.indigo600),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null && _personId == null) return;
    setState(() => _personId = selected);
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
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
    return ok;
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _reminder == null ? '新建提醒' : '编辑提醒';

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
                    _BasicCard(
                      titleCtrl: _titleCtrl,
                      typeValue: _type,
                      onPickType: _pickType,
                    ),
                    const SizedBox(height: 24),
                    _ScheduleCard(
                      date: _date,
                      time: _time,
                      repeatRule: _repeatRule,
                      onPickDate: _pickDate,
                      onPickTime: _pickTime,
                      onPickRepeatRule: _pickRepeatRule,
                    ),
                    const SizedBox(height: 24),
                    _PersonCard(
                      personId: _personId,
                      db: _db,
                      bookId: widget.bookId,
                      onPick: _pickPerson,
                    ),
                    const SizedBox(height: 24),
                    _NoteCard(noteCtrl: _noteCtrl),
                    if (_reminder != null) ...[
                      const SizedBox(height: 24),
                      _DeleteButton(disabled: _deleting, onTap: _delete),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _BasicCard extends StatelessWidget {
  const _BasicCard({
    required this.titleCtrl,
    required this.typeValue,
    required this.onPickType,
  });

  final TextEditingController titleCtrl;
  final String typeValue;
  final VoidCallback onPickType;

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
            label: '标题',
            requiredMark: true,
            controller: titleCtrl,
            hintText: '例如：张伟生日 / 王强乔迁',
            multiline: false,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _SelectRow(
            label: '类型',
            value: typeValue.trim().isEmpty ? '自定义' : typeValue.trim(),
            borderBottom: false,
            onTap: onPickType,
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.date,
    required this.time,
    required this.repeatRule,
    required this.onPickDate,
    required this.onPickTime,
    required this.onPickRepeatRule,
  });

  final DateTime date;
  final TimeOfDay time;
  final ReminderRepeatRule repeatRule;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onPickRepeatRule;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          _SelectRow(
            label: '日期',
            value: _formatYmd(date),
            onTap: onPickDate,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _SelectRow(
            label: '时间',
            value: _formatHm(time),
            onTap: onPickTime,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _SelectRow(
            label: '重复',
            value: _repeatRuleLabel(repeatRule),
            borderBottom: false,
            onTap: onPickRepeatRule,
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.personId,
    required this.db,
    required this.bookId,
    required this.onPick,
  });

  final String? personId;
  final AppDatabase db;
  final String bookId;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Person>>(
      stream: db.personsDao.watchAllInBook(bookId),
      builder: (context, snapshot) {
        final people = snapshot.data ?? const <Person>[];
        String label = '不关联';
        if ((personId ?? '').trim().isNotEmpty) {
          final found = people.where((e) => e.personId == personId).toList();
          if (found.isNotEmpty) label = found.first.name;
        }
        return PrototypeCard(
          padding: const EdgeInsets.all(0),
          child: _SelectRow(
            label: '关系人（可选）',
            value: label,
            borderBottom: false,
            onTap: onPick,
          ),
        );
      },
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
          disabled ? '删除中...' : '删除提醒',
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

bool _isPresetType(String type) {
  final v = type.trim();
  if (v.isEmpty) return true;
  return _CanvasState._typePresets.contains(v);
}

String _repeatRuleLabel(ReminderRepeatRule rule) {
  switch (rule) {
    case ReminderRepeatRule.none:
      return '不重复';
    case ReminderRepeatRule.daily:
      return '每天';
    case ReminderRepeatRule.weekly:
      return '每周';
    case ReminderRepeatRule.monthly:
      return '每月';
    case ReminderRepeatRule.yearly:
      return '每年';
  }
}

String _formatYmd(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _formatHm(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

DateTime _parseYmdOrNow(String raw) {
  final s = raw.trim();
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
  if (m == null) return DateTime.now();
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}
