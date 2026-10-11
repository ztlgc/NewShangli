import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart' as forui_material;
import 'package:drift/drift.dart' show Value;
import 'package:dotted_border/dotted_border.dart';

import '../../data/local/drift/app_database.dart';
import '../../import/default_book_service.dart';
import '../../media/media_storage_service.dart';
import '../app_bottom_sheet.dart';
import '../app_database_scope.dart';
import '../app_forui_theme.dart';
import '../app_dialog.dart';
import '../app_notifier.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../edit_protection_guard.dart';
import '../lunar_date_picker.dart';
import '../navigation.dart';
import '../ui_kit.dart';
import '../widgets/person_display_row.dart';
import 'person_edit_page.dart';
import 'person_list_page.dart';
import 'reason_manage_page.dart';

import '../../utils/date_util.dart';

import '../app_icons.dart';

import '../../platform/app_platform.dart';

import '../app_layout.dart';

/// 页面：收支记录 - 收支录入
/// 对照原型：prototype/index.html -> "收支录入"
class RecordAddPage extends StatefulWidget {
  const RecordAddPage({
    super.key,
    this.recordId,
    this.initialPersonId,
    this.lockedBookId,
  }) : assert(recordId == null || lockedBookId == null);

  final String? recordId;
  final String? initialPersonId;

  /// 账簿详情入口：账簿、事由、日期均由该账簿决定。
  final String? lockedBookId;

  @override
  State<RecordAddPage> createState() => _RecordAddPageState();
}

class _RecordAddPageState extends State<RecordAddPage> {
  static const String _defaultBookSelectionId = 'book_default';
  bool _isIncome = true;
  String _bookId = _defaultBookSelectionId;
  String? _personId;
  String _eventName = '';
  DateTime _occurredAt = DateTime.now();
  bool _occurredAtLockedByBookTime = false;
  bool get _bookContextLocked => widget.lockedBookId != null;
  bool _bookDefaultsReady = false;
  bool _dirty = false;
  bool _saving = false;
  bool _loaded = false;
  bool _recordLoaded = false;
  String? _recordLoadError;
  bool _authorized = false;
  bool _authChecked = false;
  bool _suppressDirty = false;
  String _personName = '';
  final DefaultBookService _defaultBookService = DefaultBookService();
  final MediaStorageService _mediaStorageService = MediaStorageService();
  List<String> _attachments = <String>[];

  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _bookId = widget.lockedBookId ?? _defaultBookSelectionId;
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _amountController.addListener(_markDirty);
    _noteController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_markDirty)
      ..dispose();
    _noteController
      ..removeListener(_markDirty)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _authorized = widget.recordId == null;
    _recordLoaded = widget.recordId == null;
    _suppressDirty = true;
    try {
      if (_amountController.text.trim().isEmpty) {
        _amountController.text = '';
      }
    } finally {
      _suppressDirty = false;
      _dirty = false;
    }
    if (widget.recordId != null) {
      _loadRecordFromDrift(widget.recordId!);
    } else {
      _initDefaultsFromDrift();
    }
    if (widget.recordId != null && !_authChecked) {
      _authChecked = true;
      Future<void>(_authorizeEditRecord);
    }
  }

  Future<void> _authorizeEditRecord() async {
    final navigator = Navigator.of(context);
    final ok = await requireEditProtectionPassword(context, title: '编辑记录');
    if (!mounted) return;
    if (!ok) {
      navigator.pop();
      return;
    }
    setState(() => _authorized = true);
  }

  void _markDirty() {
    if (_suppressDirty) return;
    if (_dirty) return;
    setState(() => _dirty = true);
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (_saving) return false;
    if (!_dirty) return true;
    final ok = await AppDialog.confirm(
      context,
      title: '放弃编辑？',
      message: '当前修改尚未保存，确认放弃？',
      confirmLabel: '放弃',
      danger: true,
    );
    return ok == true;
  }

  Future<void> _handleClose() async {
    final ok = await _confirmDiscardIfNeeded();
    if (!ok) return;
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    if (!mounted) return;
    final amountCent = _parseAmountCent(_amountController.text);
    if (amountCent == null || amountCent <= 0) {
      AppNotifier.warning(context, '请输入正确金额');
      return;
    }
    final pid = _personId;
    if (pid == null || pid.trim().isEmpty) {
      AppNotifier.warning(context, '请选择联系人');
      return;
    }
    final eventName = _eventName.trim();
    if (eventName.isEmpty && !_bookContextLocked) {
      AppNotifier.warning(context, '请选择事由');
      return;
    }

    final db = AppDatabaseScope.of(context);
    setState(() => _saving = true);
    try {
      await db.transaction(() async {
        final dbBookId =
            widget.lockedBookId ?? await _resolveDbBookId(db, _bookId);
        final person = await db.personsDao.findById(pid);
        if (person == null || person.deletedAt != null) {
          throw StateError('联系人已删除，请重新选择');
        }
        final book = await db.accountBooksDao.findById(dbBookId);
        if (book == null || book.deletedAt != null) {
          throw StateError('账簿已删除，请重新选择');
        }
        final savedEventName = _bookContextLocked
            ? book.reasonType
            : book.isDefault != 1
            ? (book.reasonType.isEmpty ? eventName : book.reasonType)
            : eventName;
        final occurredAtMs = (_bookContextLocked || book.isDefault != 1)
            ? book.bookTime
            : _occurredAt.millisecondsSinceEpoch;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (widget.recordId == null) {
          await db.giftRecordsDao.insertOne(
            GiftRecordsCompanion.insert(
              bookId: dbBookId,
              personId: pid,
              amountCent: amountCent,
              direction: Value(_isIncome ? '收入' : '支出'),
              eventName: Value(savedEventName),
              occurredAt: occurredAtMs,
              note: Value(
                _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
              ),
              attachments: Value(_attachments.isEmpty ? null : _attachments),
              createdAt: now,
              updatedAt: now,
            ),
          );
        } else {
          final existing = await db.giftRecordsDao.findById(widget.recordId!);
          if (existing == null || existing.deletedAt != null) {
            throw StateError('记录不存在');
          }
          final changed = await db.giftRecordsDao.updateOne(
            existing.copyWith(
              bookId: dbBookId,
              personId: pid,
              amountCent: amountCent,
              direction: _isIncome ? '收入' : '支出',
              eventName: Value(savedEventName),
              occurredAt: occurredAtMs,
              note: Value(
                _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
              ),
              attachments: Value(_attachments.isEmpty ? null : _attachments),
              updatedAt: now,
            ),
          );
          if (!changed) throw StateError('记录未更新');
        }
      });
      if (!mounted) return;
      _dirty = false;
      _closeAfterSave();
    } catch (e) {
      if (!mounted) return;
      AppNotifier.error(context, '保存失败：$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPerson() async {
    final db = AppDatabaseScope.of(context);
    while (mounted) {
      late final List<Person> persons;
      try {
        persons = await db.personsDao.listAll();
      } catch (_) {
        if (mounted) AppNotifier.error(context, '联系人加载失败，请重试');
        return;
      }
      if (!mounted) return;
      final result = await AppBottomSheet.showCustom<_PersonPickerResult>(
        context,
        builder: (context) {
          return _PersonPickerSheet(
            persons: persons,
            selectedPersonId: _personId,
          );
        },
      );
      if (!mounted || result == null) return;
      if (result.action == _PersonPickerAction.add) {
        await AppNav.push(context, const PersonEditPage());
        if (!mounted) return;
        continue;
      }
      if (result.action == _PersonPickerAction.manage) {
        await AppNav.push(context, const PersonListPage());
        if (!mounted) return;
        continue;
      }
      final personId = result.personId;
      if (personId == null) continue;
      Person? picked;
      for (final p in persons) {
        if (p.personId == personId) {
          picked = p;
          break;
        }
      }
      if (picked == null) continue;
      setState(() {
        _personId = picked!.personId;
        _personName = picked.name;
        _dirty = true;
      });
      return;
    }
  }

  Future<void> _pickBook() async {
    if (_bookContextLocked) return;
    final db = AppDatabaseScope.of(context);
    late final List<AccountBook> books;
    try {
      books = await db.select(db.accountBooks).get();
    } catch (_) {
      if (mounted) AppNotifier.error(context, '账簿加载失败，请重试');
      return;
    }
    if (!mounted) return;
    if (books.isEmpty) {
      AppNotifier.warning(context, '暂无账簿，请先创建');
      return;
    }
    final picked = await AppBottomSheet.showPicker<String>(
      context,
      title: '选择所属账簿',
      options: [
        for (final book in books)
          AppSheetOption<String>(
            label: book.name,
            value: book.isDefault == 1 ? _defaultBookSelectionId : book.bookId,
            icon: AppIcons.bookOpen,
            selected:
                (book.isDefault == 1 ? _defaultBookSelectionId : book.bookId) ==
                _bookId,
          ),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() {
      _bookId = picked;
      _dirty = true;
    });
    await _syncOccurredAtFromBookTime();
  }

  Future<void> _syncOccurredAtFromBookTime() async {
    final db = AppDatabaseScope.of(context);
    final selectedBookId = _bookId;
    final dbBookId = await _resolveDbBookId(db, selectedBookId);
    final book = await db.accountBooksDao.findById(dbBookId);
    if (book == null || !mounted || _bookId != selectedBookId) return;
    if (book.isDefault == 1) {
      setState(() {
        _occurredAtLockedByBookTime = false;
        _dirty = true;
      });
      return;
    }
    setState(() {
      _occurredAt = DateTime.fromMillisecondsSinceEpoch(book.bookTime);
      _eventName = book.reasonType;
      _occurredAtLockedByBookTime = true;
      _dirty = true;
    });
  }

  String _resolveBookName(List<AccountBook> books) {
    if (_bookId == _defaultBookSelectionId) {
      for (final b in books) {
        if (b.isDefault == 1) return b.name;
      }
      return '默认账簿';
    }
    for (final b in books) {
      if (b.bookId == _bookId) return b.name;
    }
    return '未选择';
  }

  IconData _reasonIcon(String name) {
    final n = name.trim();
    if (n.contains('婚')) return AppIcons.heart;
    if (n.contains('满月') || n.contains('周岁') || n.contains('孩子')) {
      return AppIcons.baby;
    }
    if (n.contains('生日')) return AppIcons.cake;
    if (n.contains('乔迁') || n.contains('搬家') || n.contains('新居')) {
      return AppIcons.house;
    }
    if (n.contains('年') || n.contains('节')) return AppIcons.partyPopper;
    if (n.contains('白事') || n.contains('丧') || n.contains('祭')) {
      return AppIcons.cloud;
    }
    return AppIcons.ellipsis;
  }

  Color _reasonIconBgColor(String name) {
    final n = name.trim();
    if (n.contains('婚')) return AppColors.pink100;
    if (n.contains('满月') || n.contains('周岁') || n.contains('孩子')) {
      return AppColors.blue100;
    }
    if (n.contains('生日')) return AppColors.orange100;
    if (n.contains('乔迁') || n.contains('搬家') || n.contains('新居')) {
      return AppColors.green100;
    }
    if (n.contains('年') || n.contains('节')) return AppColors.red100;
    if (n.contains('白事') || n.contains('丧') || n.contains('祭')) {
      return AppColors.gray200;
    }
    return AppColors.purple100;
  }

  Color _reasonIconColor(String name) {
    final n = name.trim();
    if (n.contains('婚')) return AppColors.pink600;
    if (n.contains('满月') || n.contains('周岁') || n.contains('孩子')) {
      return AppColors.blue600;
    }
    if (n.contains('生日')) return AppColors.orange600;
    if (n.contains('乔迁') || n.contains('搬家') || n.contains('新居')) {
      return AppColors.green600;
    }
    if (n.contains('年') || n.contains('节')) return AppColors.red600;
    if (n.contains('白事') || n.contains('丧') || n.contains('祭')) {
      return AppColors.gray600;
    }
    return AppColors.purple600;
  }

  Future<void> _pickReason() async {
    if (_occurredAtLockedByBookTime) {
      AppNotifier.info(context, '事由与账簿一致，请在账簿中修改');
      return;
    }
    final db = AppDatabaseScope.of(context);
    late final List<Reason> reasons;
    try {
      reasons =
          (await db.reasonsDao.listAll())
              .where((reason) => reason.enabled)
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      if (mounted) AppNotifier.error(context, '事由加载失败，请重试');
      return;
    }
    if (!mounted) return;

    final picked = await AppBottomSheet.showCustom<String>(
      context,
      builder: (context) => _ReasonPickerSheet(
        reasons: reasons,
        selectedReasonName: _eventName,
        reasonIcon: _reasonIcon,
        reasonIconBgColor: _reasonIconBgColor,
        reasonIconColor: _reasonIconColor,
      ),
    );

    if (!mounted || picked == null) return;
    if (picked == _ReasonPickerSheet.manageAction) {
      AppNav.push(context, const ReasonManagePage());
      return;
    }
    setState(() {
      _eventName = picked;
      _dirty = true;
    });
  }

  Future<void> _pickDate() async {
    if (_occurredAtLockedByBookTime) {
      AppNotifier.info(context, '该账簿已设置账簿时间，记录时间将与账簿时间一致');
      return;
    }
    final initialDate = DateTime(
      _occurredAt.year,
      _occurredAt.month,
      _occurredAt.day,
    );
    final picked = await showLunarDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(DateTime.now().year + 10, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      _occurredAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _occurredAt.hour,
        _occurredAt.minute,
      );
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bookContextLocked && !_bookDefaultsReady && _recordLoadError == null) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.recordId != null && (!_authorized || !_recordLoaded)) {
      return const AppScaffold(
        backgroundColor: AppColors.surfaceApp,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_recordLoadError != null) {
      return AppScaffold(
        backgroundColor: AppColors.surfaceApp,
        body: Center(child: Text(_recordLoadError!)),
      );
    }
    final displayPersonName = _personName.trim().isNotEmpty
        ? _personName.trim()
        : '请选择';
    final title = widget.recordId == null ? '记录收支' : '编辑收支';
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final ok = await _confirmDiscardIfNeeded();
        if (!context.mounted || !ok) return;
        Navigator.of(context).pop();
      },
      child: AppScaffold(
        backgroundColor: AppColors.surfaceApp,
        body: Column(
          children: [
            _Header(
              title: title,
              saving: _saving,
              onClose: _handleClose,
              onSave: _handleSave,
            ),
            Expanded(
              child: AbsorbPointer(
                absorbing: _saving,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _Segmented(
                      isIncome: _isIncome,
                      onChange: (value) {
                        setState(() {
                          _isIncome = value;
                          _dirty = true;
                        });
                      },
                    ),
                    const SizedBox(height: AppLayout.sectionGap),
                    _AmountCard(
                      controller: _amountController,
                      onPresetTap: (yuan) {
                        _suppressDirty = true;
                        _amountController.text = yuan.toString();
                        _suppressDirty = false;
                        _markDirty();
                      },
                    ),
                    const SizedBox(height: AppLayout.sectionGap),
                    StreamBuilder<List<AccountBook>>(
                      stream: AppDatabaseScope.of(context).accountBooksDao
                          .watchAll(),
                      builder: (context, snapshot) {
                        final books = snapshot.data ?? const <AccountBook>[];
                        return _FormCard(
                          bookName: _resolveBookName(books),
                          personName: displayPersonName,
                          eventName: _eventName.trim().isEmpty
                              ? (_bookContextLocked ? '未设置' : '请选择')
                              : _eventName,
                          dateLabel: _formatDate(_occurredAt),
                          bookLocked: _bookContextLocked,
                          metadataLocked: _occurredAtLockedByBookTime,
                          onTapBook: _pickBook,
                          onTapPerson: _pickPerson,
                          onTapReason: _pickReason,
                          onTapDate: _pickDate,
                        );
                      },
                    ),
                    const SizedBox(height: AppLayout.sectionGap),
                    _NoteCard(
                      controller: _noteController,
                      attachments: _attachments,
                      onAddImage: _pickAttachmentImage,
                      onRemoveImage: _removeAttachmentAt,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadRecordFromDrift(String recordId) async {
    try {
      final db = AppDatabaseScope.of(context);
      final record = await db.giftRecordsDao.findById(recordId);
      if (!mounted) return;
      if (record == null) {
        setState(() => _recordLoadError = '记录不存在');
        return;
      }
      final person = await db.personsDao.findById(record.personId);
      final book = await db.accountBooksDao.findById(record.bookId);
      if (!mounted) return;
      _suppressDirty = true;
      setState(() {
        _isIncome = record.direction != '支出';
        _bookId = (book?.isDefault == 1)
            ? _defaultBookSelectionId
            : record.bookId;
        _personId = record.personId;
        _personName = person?.name ?? '';
        _eventName = (record.eventName ?? '').trim().isEmpty
            ? ''
            : record.eventName!.trim();
        _occurredAt = DateTime.fromMillisecondsSinceEpoch(
          (book != null && book.isDefault != 1)
              ? book.bookTime
              : record.occurredAt,
        );
        _occurredAtLockedByBookTime = book != null && book.isDefault != 1;
        _amountController.text = _formatAmountInput(record.amountCent);
        _noteController.text = record.note ?? '';
        _attachments = List<String>.from(
          record.attachments ?? const <String>[],
        );
        _dirty = false;
      });
    } catch (_) {
      if (mounted) setState(() => _recordLoadError = '记录加载失败，请返回重试');
    } finally {
      _suppressDirty = false;
      if (mounted) setState(() => _recordLoaded = true);
    }
  }

  Future<void> _pickAttachmentImage() async {
    final result = await AppPlatform.instance.pickFiles(
      allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: false,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;
    final next = List<String>.from(_attachments);
    try {
      for (final file in result.files) {
        final path = file.path;
        if (path == null || path.trim().isEmpty) continue;
        final stored = await _mediaStorageService.saveAttachmentFromPath(path);
        next.add(stored);
      }
      if (!mounted) return;
      setState(() {
        _attachments = next;
        _dirty = true;
      });
    } catch (e) {
      if (!mounted) return;
      AppNotifier.error(context, '添加附件失败：$e');
    }
  }

  Future<void> _removeAttachmentAt(int index) async {
    if (index < 0 || index >= _attachments.length) return;
    // 只修改草稿，保存前不能删除数据库仍然引用的文件。
    if (!mounted) return;
    setState(() {
      _attachments = List<String>.from(_attachments)..removeAt(index);
      _dirty = true;
    });
  }

  Future<String> _resolveDbBookId(AppDatabase db, String selectedBookId) async {
    if (selectedBookId != _defaultBookSelectionId) return selectedBookId;
    return _defaultBookService.ensureDefaultBookId(db);
  }

  Future<void> _initDefaultsFromDrift() async {
    final db = AppDatabaseScope.of(context);
    final initialId = widget.initialPersonId;
    final initialPerson = initialId == null
        ? null
        : await db.personsDao.findById(initialId);
    if (!mounted) return;
    if (_personId == null &&
        initialPerson != null &&
        initialPerson.deletedAt == null) {
      _personId = initialPerson.personId;
      _personName = initialPerson.name;
    }
    final dbBookId = widget.lockedBookId ?? await _resolveDbBookId(db, _bookId);
    final book = await db.accountBooksDao.findById(dbBookId);
    if (!mounted) return;
    if (_bookContextLocked && (book == null || book.deletedAt != null)) {
      setState(() => _recordLoadError = '账簿不存在或已删除');
      return;
    }
    if (book != null) {
      if (book.isDefault == 1 && !_bookContextLocked) {
        _occurredAtLockedByBookTime = false;
      } else {
        _occurredAt = DateTime.fromMillisecondsSinceEpoch(book.bookTime);
        _eventName = book.reasonType;
        _occurredAtLockedByBookTime = true;
      }
    }
    final reasons = (await db.reasonsDao.listAll())
        .where((reason) => reason.enabled)
        .toList();
    if (!mounted) return;
    if (!_bookContextLocked &&
        _eventName.trim().isEmpty &&
        reasons.isNotEmpty) {
      _eventName = reasons.first.name;
    }
    setState(() => _bookDefaultsReady = true);
  }

  void _closeAfterSave() {
    final route = ModalRoute.of(context);
    if (route != null) {
      Navigator.of(context).removeRoute(route);
      return;
    }
    Navigator.of(context).pop();
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.saving,
    required this.onClose,
    required this.onSave,
  });

  final String title;
  final bool saving;
  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return FHeader.nested(
      title: Text(title),
      prefixes: [
        FButton.icon(
          variant: .ghost,
          semanticsLabel: '关闭',
          onPress: onClose,
          child: const Icon(AppIcons.x),
        ),
      ],
      suffixes: [
        FButton(
          size: .sm,
          mainAxisSize: MainAxisSize.min,
          onPress: saving ? null : onSave,
          child: Text(saving ? '保存中' : '保存'),
        ),
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.isIncome, required this.onChange});

  final bool isIncome;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: PressableScale(
              onTap: () => onChange(true),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isIncome ? colors.surfaceCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isIncome ? AppShadows.sm : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '收礼',
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: isIncome ? colors.brandPrimary : colors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: PressableScale(
              onTap: () => onChange(false),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: !isIncome ? colors.surfaceCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isIncome ? AppShadows.sm : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '送礼',
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: !isIncome
                        ? colors.brandPrimary
                        : colors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.controller, required this.onPresetTap});

  final TextEditingController controller;
  final ValueChanged<int> onPresetTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      padding: AppLayout.pagePadding,
      radius: AppRadii.br2xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '金额 (元)',
            style: AppTypography.base(
              fontSize: 12,
              fontWeight: AppTypography.regular,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.borderDivider, width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '¥',
                    style: AppTypography.base(
                      fontSize: 30,
                      fontWeight: AppTypography.bold,
                      color: colors.textPrimary,
                      height: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: FTextField(
                    control: FTextFieldControl.managed(controller: controller),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [_AmountInputFormatter()],
                    hint: '0',
                    style: .delta(
                      color: .delta([.all(Colors.transparent)]),
                      border: .delta([.all(forui_material.InputBorder.none)]),
                      contentPadding: .value(EdgeInsets.zero),
                      contentTextStyle: .delta([
                        .all(
                          .delta(
                            fontSize: 36,
                            fontWeight: AppTypography.bold,
                            color: colors.textPrimary,
                            height: 1,
                          ),
                        ),
                      ]),
                      hintTextStyle: .delta([
                        .all(
                          .delta(
                            fontSize: 36,
                            fontWeight: AppTypography.bold,
                            color: colors.textMuted,
                            height: 1,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _PresetChip(
                  label: '200',
                  selected: controller.text.trim() == '200',
                  onTap: () => onPresetTap(200),
                ),
                const SizedBox(width: 8),
                _PresetChip(
                  label: '500',
                  selected: controller.text.trim() == '500',
                  onTap: () => onPresetTap(500),
                ),
                const SizedBox(width: 8),
                _PresetChip(
                  label: '1000',
                  selected: controller.text.trim() == '1000',
                  onTap: () => onPresetTap(1000),
                ),
                const SizedBox(width: 8),
                _PresetChip(
                  label: '2000',
                  selected: controller.text.trim() == '2000',
                  onTap: () => onPresetTap(2000),
                ),
                const SizedBox(width: 8),
                _PresetChip(
                  label: '5000',
                  selected: controller.text.trim() == '5000',
                  onTap: () => onPresetTap(5000),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.brandSoft : colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.borderFocus : colors.borderSubtle,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.base(
              fontSize: 12,
              fontWeight: AppTypography.medium,
              color: selected ? colors.brandOnSoft : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.bookName,
    required this.personName,
    required this.eventName,
    required this.dateLabel,
    required this.onTapBook,
    required this.onTapPerson,
    required this.onTapReason,
    required this.onTapDate,
    this.bookLocked = false,
    this.metadataLocked = false,
  });

  final String bookName;
  final String personName;
  final String eventName;
  final String dateLabel;
  final VoidCallback onTapBook;
  final VoidCallback onTapPerson;
  final VoidCallback onTapReason;
  final VoidCallback onTapDate;
  final bool bookLocked;
  final bool metadataLocked;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          _FormRow(
            iconBg: AppColors.gray100,
            iconColor: AppColors.textSecondary,
            icon: AppIcons.bookOpen,
            label: '账簿',
            value: bookName,
            chevron: true,
            onTap: bookLocked ? null : onTapBook,
            locked: bookLocked,
          ),
          const AppDivider(color: AppColors.borderDivider),
          _FormRow(
            iconBg: AppColors.indigo50,
            iconColor: AppColors.indigo600,
            icon: AppIcons.userRound,
            label: '联系人',
            value: personName,
            chevron: true,
            onTap: onTapPerson,
          ),
          const AppDivider(color: AppColors.borderDivider),
          _FormRow(
            iconBg: AppColors.orange50,
            iconColor: AppColors.orange500,
            icon: AppIcons.gift,
            label: '事由',
            value: eventName,
            chevron: false,
            onTap: metadataLocked ? null : onTapReason,
            locked: metadataLocked,
          ),
          const AppDivider(color: AppColors.borderDivider),
          _FormRow(
            iconBg: AppColors.blue50,
            iconColor: AppColors.blue500,
            icon: AppIcons.calendar,
            label: '日期',
            value: dateLabel,
            chevron: true,
            borderBottom: false,
            onTap: metadataLocked ? null : onTapDate,
            locked: metadataLocked,
          ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.value,
    required this.chevron,
    required this.onTap,
    this.borderBottom = true,
    this.locked = false,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String label;
  final String value;
  final bool chevron;
  final VoidCallback? onTap;
  final bool locked;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      label: locked ? '$label，已锁定' : null,
      child: AppPressableRow(
        onTap: onTap,
        borderBottom: borderBottom,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.softFor(iconBg),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 12,
                color: colors.foregroundFor(iconColor),
              ),
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
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.base(
                      fontSize: 14,
                      fontWeight: AppTypography.medium,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (locked)
              Icon(AppIcons.lock, size: 14, color: colors.textMuted)
            else if (chevron)
              Icon(AppIcons.chevronRight, size: 10, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.controller,
    required this.attachments,
    required this.onAddImage,
    required this.onRemoveImage,
  });

  final TextEditingController controller;
  final List<String> attachments;
  final VoidCallback onAddImage;
  final Future<void> Function(int index) onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      padding: AppLayout.pagePadding,
      radius: AppRadii.br2xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppForuiBoundary(
            child: FTextField(
              control: FTextFieldControl.managed(controller: controller),
              maxLines: null,
              minLines: 2,
              hint: '添加备注...',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < attachments.length; i++)
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AppNetworkImage(
                        url: 'file://${attachments[i]}',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemoveImage(i),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.scrimBlack30,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              AppIcons.x,
                              size: 10,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              GestureDetector(
                onTap: onAddImage,
                child: DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                    dashPattern: const [6, 4],
                    strokeWidth: 1,
                    color: colors.borderDefault,
                    radius: const Radius.circular(12),
                    padding: EdgeInsets.zero,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppIcons.camera,
                          color: colors.textMuted,
                          size: 16,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '添加图片',
                          style: AppTypography.base(
                            fontSize: 10,
                            fontWeight: AppTypography.regular,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _PersonPickerAction { pick, add, manage }

class _PersonPickerResult {
  const _PersonPickerResult._({required this.action, this.personId});

  final _PersonPickerAction action;
  final String? personId;

  factory _PersonPickerResult.pick(String personId) {
    return _PersonPickerResult._(
      action: _PersonPickerAction.pick,
      personId: personId,
    );
  }

  factory _PersonPickerResult.add() {
    return const _PersonPickerResult._(action: _PersonPickerAction.add);
  }

  factory _PersonPickerResult.manage() {
    return const _PersonPickerResult._(action: _PersonPickerAction.manage);
  }
}

class _ReasonPickerSheet extends StatefulWidget {
  const _ReasonPickerSheet({
    required this.reasons,
    required this.selectedReasonName,
    required this.reasonIcon,
    required this.reasonIconBgColor,
    required this.reasonIconColor,
  });

  static const String manageAction = '__manage_reason__';

  final List<Reason> reasons;
  final String selectedReasonName;
  final IconData Function(String) reasonIcon;
  final Color Function(String) reasonIconBgColor;
  final Color Function(String) reasonIconColor;

  @override
  State<_ReasonPickerSheet> createState() => _ReasonPickerSheetState();
}

class _ReasonPickerSheetState extends State<_ReasonPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
            color: colors.surfaceCard,
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
                  color: colors.borderDefault,
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
                          color: colors.textPrimary,
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
                            color: colors.textMuted,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 2.6,
                            ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final r = filtered[index];
                          final selected = widget.selectedReasonName == r.name;
                          return Material(
                            color: colors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).pop(r.name),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? colors.borderFocus
                                        : colors.borderSubtle,
                                    width: selected ? 1.4 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: colors.softFor(
                                          widget.reasonIconBgColor(r.name),
                                        ),
                                        borderRadius: BorderRadius.circular(17),
                                      ),
                                      child: Icon(
                                        widget.reasonIcon(r.name),
                                        size: 20,
                                        color: colors.foregroundFor(
                                          widget.reasonIconColor(r.name),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        r.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.body().copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                          .pop(_ReasonPickerSheet.manageAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonPickerSheet extends StatefulWidget {
  const _PersonPickerSheet({
    required this.persons,
    required this.selectedPersonId,
  });

  final List<Person> persons;
  final String? selectedPersonId;

  @override
  State<_PersonPickerSheet> createState() => _PersonPickerSheetState();
}

class _PersonPickerSheetState extends State<_PersonPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final filtered = widget.persons.where((person) {
      final key = _keyword.trim().toLowerCase();
      if (key.isEmpty) return true;
      return person.name.toLowerCase().contains(key) ||
          person.relationshipType.toLowerCase().contains(key);
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
            color: colors.surfaceCard,
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
                  color: colors.borderDefault,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '选择联系人',
                        style: AppTypography.base(
                          fontSize: 18,
                          fontWeight: AppTypography.bold,
                          color: colors.textPrimary,
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
                  hintText: '搜索姓名、关系',
                  onChanged: (v) => setState(() => _keyword = v),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          widget.persons.isEmpty ? '暂无联系人' : '没有匹配结果',
                          style: AppTypography.base(
                            fontSize: 13,
                            fontWeight: AppTypography.regular,
                            color: colors.textMuted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final person = filtered[index];
                          return AppPressableRow(
                            borderBottom: index != filtered.length - 1,
                            onTap: () => Navigator.of(context)
                                .pop(_PersonPickerResult.pick(person.personId)),
                            child: PersonDisplayRow(
                              name: person.name,
                              subtitle: person.relationshipType,
                              avatarUrl: person.avatarUri,
                              trailing:
                                  widget.selectedPersonId == person.personId
                                  ? Icon(
                                      AppIcons.check,
                                      size: 14,
                                      color: colors.brandSecondary,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: '管理联系人',
                        onTap: () =>
                            Navigator.of(context)
                                .pop(_PersonPickerResult.manage()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppPrimaryButton(
                        label: '添加联系人',
                        icon: AppIcons.userRoundPlus,
                        onTap: () =>
                            Navigator.of(context)
                                .pop(_PersonPickerResult.add()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountInputFormatter extends TextInputFormatter {
  const _AmountInputFormatter();

  static final RegExp _reg = RegExp(r'^\d{0,12}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (text.startsWith('.')) return oldValue;
    if (!_reg.hasMatch(text)) return oldValue;
    return newValue;
  }
}

int? _parseAmountCent(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(t)) return null;
  final parts = t.split('.');
  final intPart = int.tryParse(parts[0]);
  if (intPart == null) return null;
  var frac = '';
  if (parts.length > 1) frac = parts[1];
  if (frac.length == 1) frac = '${frac}0';
  if (frac.isEmpty) frac = '00';
  if (frac.length == 2) {
    final fracPart = int.tryParse(frac);
    if (fracPart == null) return null;
    return intPart * 100 + fracPart;
  }
  return null;
}

String _formatAmountInput(int cent) {
  final v = (cent.abs() / 100).toStringAsFixed(2);
  var s = v;
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
  }
  return s;
}

String _formatDate(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(dt.year, dt.month, dt.day);
  final diff = target.difference(today).inDays;

  String suffix = '';
  if (diff == 0) {
    suffix = ' 今天';
  } else if (diff == -1) {
    suffix = ' 昨天';
  } else if (diff == 1) {
    suffix = ' 明天';
  }

  return '${DateUtil.format(dt)}$suffix';
}
