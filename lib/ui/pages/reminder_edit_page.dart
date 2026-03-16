import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../../reminders/reminders_service.dart';
import '../app_database_scope.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../lunar_date_picker.dart';
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
  bool _lunarCalendar = false;
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  String? _personId;
  bool _relationEnabled = false;
  Set<String> _relationPersonIds = <String>{};

  static const List<String> _typePresets = <String>[
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
      _lunarCalendar = _repeatRule == ReminderRepeatRule.lunarYearly;
      _date = _parseYmdOrNow(r.targetDate);
      _time = TimeOfDay(hour: remindAt.hour, minute: remindAt.minute);
      _personId = r.personId;
      _relationPersonIds = RemindersService.parseRelationPersonIds(r.relationPersonIds).toSet();
      _relationEnabled = _relationPersonIds.isNotEmpty;
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
      final effectiveRule = _lunarCalendar && _repeatRule == ReminderRepeatRule.yearly
          ? ReminderRepeatRule.lunarYearly
          : (!_lunarCalendar && _repeatRule == ReminderRepeatRule.lunarYearly
              ? ReminderRepeatRule.yearly
              : _repeatRule);

      if (_reminder == null) {
        await _service.create(
          bookId: widget.bookId,
          title: title,
          reminderType: _type,
          personId: _personId,
          relationPersonIds: _relationEnabled ? _relationPersonIds.toList() : const <String>[],
          targetDate: _date,
          remindAt: remindAt,
          repeatRule: effectiveRule,
          note: note.isEmpty ? null : note,
        );
      } else {
        await _service.update(
          reminderId: _reminder!.reminderId,
          title: title,
          reminderType: _type,
          personId: _personId,
          relationPersonIds: _relationEnabled ? _relationPersonIds.toList() : const <String>[],
          targetDate: _date,
          remindAt: remindAt,
          repeatRule: effectiveRule,
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
    const addCustomValue = '__add_custom__';
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
                  child: StreamBuilder<List<String>>(
                    stream: _service.watchTypeOptions(widget.bookId),
                    builder: (context, snapshot) {
                      final options = snapshot.data ?? _typePresets;
                      return ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 12),
                        children: [
                          for (final t in options)
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
                            onTap: () => Navigator.of(context).pop(addCustomValue),
                            borderBottom: false,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '新增自定义类型',
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
    if (picked == null) return;
    if (picked == addCustomValue) {
      final v = await _editText(
        title: '新增自定义提醒类型',
        label: '类型',
        initial: '',
        hintText: '例如：乔迁/满月/升学宴',
        multiline: false,
        requiredField: true,
      );
      if (v == null) return;
      final normalized = v.trim();
      if (!RegExp(r'^[\u4e00-\u9fa5]{2,10}$').hasMatch(normalized)) {
        _toast('请输入 2-10 个汉字');
        return;
      }
      final added = await _service.addCustomType(bookId: widget.bookId, name: normalized);
      if (!added) {
        _toast('类型已存在');
        return;
      }
      setState(() => _type = normalized);
      return;
    }
    setState(() => _type = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showLunarDatePicker(
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
    setState(() {
      _repeatRule = picked;
      if (picked == ReminderRepeatRule.lunarYearly) {
        _lunarCalendar = true;
      } else if (picked == ReminderRepeatRule.yearly) {
        _lunarCalendar = false;
      }
    });
  }

  void _setLunarCalendar(bool value) {
    setState(() {
      _lunarCalendar = value;
      if (_repeatRule == ReminderRepeatRule.yearly && value) {
        _repeatRule = ReminderRepeatRule.lunarYearly;
      } else if (_repeatRule == ReminderRepeatRule.lunarYearly && !value) {
        _repeatRule = ReminderRepeatRule.yearly;
      }
    });
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
                          '选择人物（可选）',
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
                                  child: Text('不关联人物'),
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
                                '当前账簿暂无人物数据',
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
    final busy = _saving || _deleting;
    final footerLabel = _reminder == null ? '创建提醒任务' : '保存提醒任务';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
          ),
          child: Row(
            children: [
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 16),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textSecondary,
                onPressed: busy ? null : () => AppNav.pop(context),
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
                onTap: busy ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    _saving ? '保存中' : '保存',
                    style: AppTypography.base(
                      fontSize: 15,
                      fontWeight: AppTypography.bold,
                      color: AppColors.indigo900,
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _BasicCard(
                      titleCtrl: _titleCtrl,
                      typeValue: _type,
                      onPickType: _pickType,
                    ),
                    const SizedBox(height: 16),
                    _ScheduleCard(
                      date: _date,
                      time: _time,
                      repeatRule: _repeatRule,
                      lunarCalendar: _lunarCalendar,
                      onPickDate: _pickDate,
                      onPickTime: _pickTime,
                      onPickRepeatRule: _pickRepeatRule,
                      onSwitchCalendar: _setLunarCalendar,
                    ),
                    const SizedBox(height: 16),
                    _PersonCard(
                      personId: _personId,
                      db: _db,
                      bookId: widget.bookId,
                      onPick: _pickPerson,
                    ),
                    const SizedBox(height: 16),
                    _NoteCard(noteCtrl: _noteCtrl),
                    if (_reminder != null) ...[
                      const SizedBox(height: 16),
                      _DeleteButton(disabled: _deleting, onTap: _delete),
                    ],
                    const SizedBox(height: 16),
                    _BottomAction(
                      label: _saving ? '保存中' : footerLabel,
                      onTap: busy ? null : _save,
                    ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '事件名称',
          style: AppTypography.base(
            fontSize: 13,
            fontWeight: AppTypography.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.brXl,
            boxShadow: AppShadows.sm,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: titleCtrl,
            maxLines: 1,
            style: AppTypography.base(
              fontSize: 15,
              fontWeight: AppTypography.medium,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '请输入提醒名称，例如：张三的婚礼',
              hintStyle: AppTypography.base(
                fontSize: 14,
                fontWeight: AppTypography.regular,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.br2xl,
            boxShadow: AppShadows.sm,
          ),
          child: _IconSelectRow(
            label: '提醒类型',
            value: typeValue.trim().isEmpty ? '自定义' : typeValue.trim(),
            icon: FontAwesomeIcons.tags,
            iconBg: AppColors.indigo50,
            iconColor: AppColors.indigo700,
            borderBottom: false,
            onTap: onPickType,
          ),
        ),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.date,
    required this.time,
    required this.repeatRule,
    required this.lunarCalendar,
    required this.onPickDate,
    required this.onPickTime,
    required this.onPickRepeatRule,
    required this.onSwitchCalendar,
  });

  final DateTime date;
  final TimeOfDay time;
  final ReminderRepeatRule repeatRule;
  final bool lunarCalendar;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onPickRepeatRule;
  final ValueChanged<bool> onSwitchCalendar;

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
          _IconSelectRow(
            label: '日期',
            value: _formatYmd(date),
            icon: FontAwesomeIcons.calendarDays,
            iconBg: AppColors.orange100,
            iconColor: AppColors.orange600,
            trailing: _CalendarSwitch(
              lunar: lunarCalendar,
              onChanged: onSwitchCalendar,
            ),
            onTap: onPickDate,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _IconSelectRow(
            label: '提醒时间',
            value: _formatHm(time),
            icon: FontAwesomeIcons.clock,
            iconBg: AppColors.blue100,
            iconColor: AppColors.blue600,
            onTap: onPickTime,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _IconSelectRow(
            label: '重复频率',
            value: _repeatRuleLabel(repeatRule),
            icon: FontAwesomeIcons.rotate,
            iconBg: AppColors.green100,
            iconColor: AppColors.green600,
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
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.br2xl,
            boxShadow: AppShadows.sm,
          ),
          child: _IconSelectRow(
            label: '关联人物',
            value: label == '不关联' ? '选择联系人' : label,
            icon: FontAwesomeIcons.user,
            iconBg: AppColors.purple100,
            iconColor: AppColors.purple600,
            borderBottom: false,
            onTap: onPick,
          ),
        );
      },
    );
  }
}

class _IconSelectRow extends StatelessWidget {
  const _IconSelectRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
    this.trailing,
    this.borderBottom = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    return PrototypePressableRow(
      onTap: onTap,
      borderBottom: borderBottom,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: FaIcon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppTypography.base(
                    fontSize: 15,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          trailing ?? const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
        ],
      ),
    );
  }
}

class _CalendarSwitch extends StatelessWidget {
  const _CalendarSwitch({
    required this.lunar,
    required this.onChanged,
  });

  final bool lunar;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final solarSelected = !lunar;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onChanged(false),
            behavior: HitTestBehavior.opaque,
            child: _CalendarSwitchItem(
              label: '公历',
              selected: solarSelected,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => onChanged(true),
            behavior: HitTestBehavior.opaque,
            child: _CalendarSwitchItem(
              label: '农历',
              selected: lunar,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarSwitchItem extends StatelessWidget {
  const _CalendarSwitchItem({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? AppColors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: selected ? AppShadows.sm : null,
      ),
      child: Text(
        label,
        style: AppTypography.base(
          fontSize: 10,
          fontWeight: AppTypography.bold,
          color: selected ? AppColors.indigo700 : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.noteCtrl});

  final TextEditingController noteCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '备注',
          style: AppTypography.base(
            fontSize: 13,
            fontWeight: AppTypography.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.brXl,
            boxShadow: AppShadows.sm,
          ),
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: noteCtrl,
            maxLines: 4,
            minLines: 4,
            style: AppTypography.base(
              fontSize: 14,
              fontWeight: AppTypography.regular,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: '添加更多细节描述...',
              hintStyle: AppTypography.base(
                fontSize: 14,
                fontWeight: AppTypography.regular,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PrototypePrimaryButton(label: label, onTap: onTap),
        const SizedBox(height: 12),
        Text(
          '我们将通过系统通知在设定的时间提醒您',
          style: AppTypography.base(
            fontSize: 12,
            fontWeight: AppTypography.regular,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
    case ReminderRepeatRule.lunarYearly:
      return '每年（农历）';
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
