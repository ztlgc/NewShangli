import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' show Value;
import 'package:dotted_border/dotted_border.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../../import/default_book_service.dart';
import '../app_data.dart';
import '../app_database_scope.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../lunar_date_picker.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import 'person_list_page.dart';
import 'reason_manage_page.dart';

import '../../utils/date_util.dart';

/// 页面：收支记录 - 收支录入
/// 对照原型：prototype/index.html -> "收支录入"
class RecordAddPage extends StatefulWidget {
  const RecordAddPage({super.key, this.recordId});

  final String? recordId;

  @override
  State<RecordAddPage> createState() => _RecordAddPageState();
}

class _RecordAddPageState extends State<RecordAddPage> {
  static const String _defaultBookSelectionId = 'book_default';
  bool _isIncome = true;
  String _bookId = _defaultBookSelectionId;
  String? _personId;
  String _eventName = '';
  String _paymentMethod = '微信支付';
  DateTime _occurredAt = DateTime.now();
  bool _dirty = false;
  bool _saving = false;
  bool _loaded = false;
  bool _suppressDirty = false;
  String _personName = '';
  final DefaultBookService _defaultBookService = DefaultBookService();

  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
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
  }

  void _markDirty() {
    if (_suppressDirty) return;
    if (_dirty) return;
    setState(() => _dirty = true);
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_dirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('放弃编辑？'),
          content: const Text('当前修改尚未保存，确认放弃？'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('放弃')),
          ],
        );
      },
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
    await _ensureRequiredDefaults();
    final amountCent = _parseAmountCent(_amountController.text);
    if (amountCent == null || amountCent <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入正确金额')));
      return;
    }
    final pid = _personId;
    if (pid == null || pid.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择关系人')));
      return;
    }
    final eventName = _eventName.trim();
    if (eventName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择事由')));
      return;
    }
    final payment = _paymentMethod.trim();
    if (payment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择支付方式')));
      return;
    }

    final db = AppDatabaseScope.maybeOf(context);
    if (db == null) {
      final data = _appDataMaybe(context);
      if (data != null) {
        if (widget.recordId == null) {
          data.createRecord(
            bookId: _bookId,
            personId: pid,
            direction: _isIncome ? RecordDirection.income : RecordDirection.expense,
            amountCent: amountCent,
            eventName: eventName,
            paymentMethod: payment,
            occurredAt: _occurredAt,
            note: _noteController.text,
          );
        } else {
          data.updateRecord(
            id: widget.recordId!,
            bookId: _bookId,
            personId: pid,
            direction: _isIncome ? RecordDirection.income : RecordDirection.expense,
            amountCent: amountCent,
            eventName: eventName,
            paymentMethod: payment,
            occurredAt: _occurredAt,
            note: _noteController.text,
          );
        }
      }
      if (!mounted) return;
      _dirty = false;
      _closeAfterSave();
      return;
    }
    setState(() => _saving = true);
    try {
      final dbBookId = await _resolveDbBookId(db, _bookId);
      final now = DateTime.now().millisecondsSinceEpoch;
      if (widget.recordId == null) {
        await db.giftRecordsDao.insertOne(
          GiftRecordsCompanion.insert(
            bookId: dbBookId,
            personId: pid,
            amountCent: amountCent,
            direction: Value(_isIncome ? '收入' : '支出'),
            eventName: Value(eventName),
            paymentMethod: Value(payment),
            occurredAt: _occurredAt.millisecondsSinceEpoch,
            note: Value(_noteController.text.trim().isEmpty ? null : _noteController.text.trim()),
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        final existing = await db.giftRecordsDao.findById(widget.recordId!);
        if (existing == null) {
          throw StateError('记录不存在');
        }
        await db.giftRecordsDao.updateOne(
          existing.copyWith(
            bookId: dbBookId,
            personId: pid,
            amountCent: amountCent,
            direction: _isIncome ? '收入' : '支出',
            eventName: Value(eventName),
            paymentMethod: Value(payment),
            occurredAt: _occurredAt.millisecondsSinceEpoch,
            note: Value(_noteController.text.trim().isEmpty ? null : _noteController.text.trim()),
            deletedAt: const Value(null),
          ),
        );
      }
      if (!mounted) return;
      _dirty = false;
      _closeAfterSave();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败：$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPerson() async {
    final db = AppDatabaseScope.maybeOf(context);
    if (db == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据库未初始化')));
      return;
    }
    final persons = await db.select(db.persons).get();
    persons.sort((a, b) => a.name.compareTo(b.name));
    if (persons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('暂无关系人，请先添加')));
      return;
    }
    final picked = await showModalBottomSheet<Person>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('选择关系人', style: AppTypography.h2().copyWith(fontSize: 16)),
              ),
              for (final p in persons)
                ListTile(
                  title: Text(p.name),
                  subtitle: Text(p.relationshipType),
                  trailing: (_personId == p.personId) ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(p),
                ),
              const Divider(height: 1),
              ListTile(
                title: const Text('管理关系人'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  AppNav.push(context, const PersonListPage());
                },
              ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _personId = picked.personId;
      _personName = picked.name;
      _dirty = true;
    });
  }

  Future<void> _pickBook() async {
    final db = AppDatabaseScope.maybeOf(context);
    if (db == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据库未初始化')));
      return;
    }
    final books = await db.select(db.accountBooks).get();
    if (!mounted) return;
    if (books.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('暂无账簿，请先创建')));
      return;
    }
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
                          '选择所属账簿',
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
                      for (final b in books)
                        PrototypePressableRow(
                          onTap: () {
                            final id = (b.isDefault == 1) ? _defaultBookSelectionId : b.bookId;
                            Navigator.of(context).pop(id);
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  b.name,
                                  style: AppTypography.base(
                                    fontSize: 14,
                                    fontWeight: AppTypography.medium,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (((b.isDefault == 1) ? _defaultBookSelectionId : b.bookId) == _bookId)
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
      _bookId = picked;
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

  Future<void> _pickReason() async {
    final db = AppDatabaseScope.maybeOf(context);
    if (db == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据库未初始化')));
      return;
    }
    final reasons = (await db.reasonsDao.listAll())
        .where((e) => e.enabled)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('选择事由', style: AppTypography.h2().copyWith(fontSize: 16)),
              ),
              for (final r in reasons)
                ListTile(
                  title: Text(r.name),
                  trailing: (_eventName == r.name) ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(r.name),
                ),
              const Divider(height: 1),
              ListTile(
                title: const Text('自定义事由'),
                trailing: const Icon(Icons.edit),
                onTap: () => Navigator.of(context).pop('__custom__'),
              ),
              ListTile(
                title: const Text('管理事由'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  AppNav.push(context, const ReasonManagePage());
                },
              ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    if (picked == '__custom__') {
      final input = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController(text: _eventName);
          return AlertDialog(
            title: const Text('自定义事由'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: '请输入事由名称'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
              TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('确定')),
            ],
          );
        },
      );
      final v = input?.trim();
      if (v == null || v.isEmpty) return;
      setState(() {
        _eventName = v;
        _dirty = true;
      });
      return;
    }
    setState(() {
      _eventName = picked;
      _dirty = true;
    });
  }

  Future<void> _pickDate() async {
    final initialDate = DateTime(_occurredAt.year, _occurredAt.month, _occurredAt.day);
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

  Future<void> _pickPaymentMethod() async {
    const methods = ['微信支付', '支付宝', '现金', '银行卡', '其他'];
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('选择支付方式', style: AppTypography.h2().copyWith(fontSize: 16)),
              ),
              for (final m in methods)
                ListTile(
                  title: Text(m),
                  trailing: (_paymentMethod == m) ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(m),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    if (picked == '其他') {
      final input = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController(text: _paymentMethod);
          return AlertDialog(
            title: const Text('自定义支付方式'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: '请输入支付方式'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
              TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('确定')),
            ],
          );
        },
      );
      final v = input?.trim();
      if (v == null || v.isEmpty) return;
      setState(() {
        _paymentMethod = v;
        _dirty = true;
      });
      return;
    }
    setState(() {
      _paymentMethod = picked;
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayPersonName = _personName.trim().isNotEmpty
        ? _personName.trim()
        : '请选择';
    final title = widget.recordId == null ? '记录收支' : '编辑收支';
    return WillPopScope(
      onWillPop: _confirmDiscardIfNeeded,
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
              child: ListView(
                padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 24),
                  _AmountCard(
                    controller: _amountController,
                    onPresetTap: (yuan) {
                      _suppressDirty = true;
                      _amountController.text = yuan.toString();
                      _suppressDirty = false;
                      _markDirty();
                    },
                  ),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (context) {
                      final db = AppDatabaseScope.maybeOf(context);
                      if (db == null) {
                        final name = _bookId == _defaultBookSelectionId ? '默认账簿' : '未选择';
                        return _FormCard(
                          bookName: name,
                          personName: displayPersonName,
                          eventName: _eventName.trim().isEmpty ? '请选择' : _eventName,
                          dateLabel: _formatDate(_occurredAt),
                          paymentMethod: _paymentMethod.trim().isEmpty ? '请选择' : _paymentMethod,
                          onTapBook: () {},
                          onTapPerson: _pickPerson,
                          onTapReason: _pickReason,
                          onTapDate: _pickDate,
                          onTapPayment: _pickPaymentMethod,
                        );
                      }
                      return StreamBuilder<List<AccountBook>>(
                        stream: db.accountBooksDao.watchAll(),
                        builder: (context, snapshot) {
                          final books = snapshot.data ?? const <AccountBook>[];
                          return _FormCard(
                            bookName: _resolveBookName(books),
                            personName: displayPersonName,
                            eventName: _eventName.trim().isEmpty ? '请选择' : _eventName,
                            dateLabel: _formatDate(_occurredAt),
                            paymentMethod: _paymentMethod.trim().isEmpty ? '请选择' : _paymentMethod,
                            onTapBook: _pickBook,
                            onTapPerson: _pickPerson,
                            onTapReason: _pickReason,
                            onTapDate: _pickDate,
                            onTapPayment: _pickPaymentMethod,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _NoteCard(controller: _noteController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadRecordFromDrift(String recordId) async {
    try {
      final db = AppDatabaseScope.maybeOf(context);
      if (db == null) {
        final data = _appDataMaybe(context);
        final record = data?.findRecord(recordId);
        if (record != null && mounted) {
          setState(() {
            _isIncome = record.direction == RecordDirection.income;
            _bookId = record.bookId ?? _defaultBookSelectionId;
            _personId = record.personId;
            _personName = record.personName;
            _eventName = record.eventName;
            _paymentMethod = record.paymentMethod;
            _occurredAt = record.occurredAt;
            _amountController.text = _formatAmountInput(record.amountCent);
            _noteController.text = record.note ?? '';
            _dirty = false;
          });
        }
        return;
      }
      final record = await db.giftRecordsDao.findById(recordId);
      if (record == null || !mounted) return;
      final person = await db.personsDao.findById(record.personId);
      final book = await db.accountBooksDao.findById(record.bookId);
      if (!mounted) return;
      _suppressDirty = true;
      setState(() {
        _isIncome = record.direction != '支出';
        _bookId = (book?.isDefault == 1) ? _defaultBookSelectionId : record.bookId;
        _personId = record.personId;
        _personName = person?.name ?? '';
        _eventName = (record.eventName ?? '').trim().isEmpty ? '' : record.eventName!.trim();
        _paymentMethod = (record.paymentMethod ?? '').trim().isEmpty ? '微信支付' : record.paymentMethod!.trim();
        _occurredAt = DateTime.fromMillisecondsSinceEpoch(record.occurredAt);
        _amountController.text = _formatAmountInput(record.amountCent);
        _noteController.text = record.note ?? '';
        _dirty = false;
      });
    } finally {
      _suppressDirty = false;
    }
  }

  Future<String> _resolveDbBookId(AppDatabase db, String selectedBookId) async {
    if (selectedBookId != _defaultBookSelectionId) return selectedBookId;
    return _defaultBookService.ensureDefaultBookId(db);
  }

  Future<void> _initDefaultsFromDrift() async {
    final db = AppDatabaseScope.maybeOf(context);
    if (db == null) {
      final data = _appDataMaybe(context);
      if (data == null) return;
      if (_personId == null && data.persons.isNotEmpty) {
        _personId = data.persons.first.id;
        _personName = data.persons.first.name;
      }
      if (_eventName.trim().isEmpty && data.reasons.isNotEmpty) {
        _eventName = data.reasons.first.name;
      }
      if (mounted) {
        setState(() {});
      }
      return;
    }
    final persons = await (db.select(db.persons)..limit(1)).get();
    if (!mounted) return;
    if (_personId == null && persons.isNotEmpty) {
      _personId = persons.first.personId;
      _personName = persons.first.name;
    }
    final reasons = await db.reasonsDao.listAll();
    if (!mounted) return;
    if (_eventName.trim().isEmpty && reasons.isNotEmpty) {
      _eventName = reasons.first.name;
    }
    setState(() {});
  }

  Future<void> _ensureRequiredDefaults() async {
    if (_personId != null && _personId!.trim().isNotEmpty && _eventName.trim().isNotEmpty) {
      return;
    }
    await _initDefaultsFromDrift();
  }

  AppData? _appDataMaybe(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<AppDataScope>();
    final widget = element?.widget;
    if (widget is! AppDataScope) return null;
    return widget.notifier;
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
      ),
      child: Row(
        children: [
          PrototypeIconButton(
            icon: const FaIcon(FontAwesomeIcons.xmark, size: 18),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            onPressed: onClose,
            radius: 9999,
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
            onTap: saving ? null : onSave,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: saving ? AppColors.gray300 : AppColors.brandPrimary,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: saving ? null : AppShadows.sm,
              ),
              child: Text(
                saving ? '保存中' : '保存',
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
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.isIncome,
    required this.onChange,
  });

  final bool isIncome;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.gray200,
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
                  color: isIncome ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isIncome ? AppShadows.sm : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '收礼',
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: isIncome ? AppColors.brandPrimary : AppColors.textTertiary,
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
                  color: !isIncome ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isIncome ? AppShadows.sm : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '送礼',
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: !isIncome ? AppColors.brandPrimary : AppColors.textTertiary,
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
  const _AmountCard({
    required this.controller,
    required this.onPresetTap,
  });

  final TextEditingController controller;
  final ValueChanged<int> onPresetTap;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      radius: AppRadii.br2xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '金额 (元)',
            style: AppTypography.base(
              fontSize: 12,
              fontWeight: AppTypography.regular,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
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
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [_AmountInputFormatter()],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: '0',
                    ),
                    style: AppTypography.base(
                      fontSize: 36,
                      fontWeight: AppTypography.bold,
                      color: AppColors.textPrimary,
                      height: 1,
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
                _PresetChip(label: '200', selected: controller.text.trim() == '200', onTap: () => onPresetTap(200)),
                const SizedBox(width: 8),
                _PresetChip(label: '500', selected: controller.text.trim() == '500', onTap: () => onPresetTap(500)),
                const SizedBox(width: 8),
                _PresetChip(label: '1000', selected: controller.text.trim() == '1000', onTap: () => onPresetTap(1000)),
                const SizedBox(width: 8),
                _PresetChip(label: '2000', selected: controller.text.trim() == '2000', onTap: () => onPresetTap(2000)),
                const SizedBox(width: 8),
                _PresetChip(label: '5000', selected: controller.text.trim() == '5000', onTap: () => onPresetTap(5000)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap, this.selected = false});

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.indigo50 : AppColors.gray50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.indigo100 : AppColors.gray100, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.base(
              fontSize: 12,
              fontWeight: AppTypography.medium,
              color: selected ? AppColors.indigo700 : AppColors.textSecondary,
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
    required this.paymentMethod,
    required this.onTapBook,
    required this.onTapPerson,
    required this.onTapReason,
    required this.onTapDate,
    required this.onTapPayment,
  });

  final String bookName;
  final String personName;
  final String eventName;
  final String dateLabel;
  final String paymentMethod;
  final VoidCallback onTapBook;
  final VoidCallback onTapPerson;
  final VoidCallback onTapReason;
  final VoidCallback onTapDate;
  final VoidCallback onTapPayment;

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
          _FormRow(
            iconBg: AppColors.gray100,
            iconColor: AppColors.textSecondary,
            icon: FontAwesomeIcons.book,
            label: '账簿',
            value: bookName,
            chevron: true,
            onTap: onTapBook,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _FormRow(
            iconBg: AppColors.indigo50,
            iconColor: AppColors.indigo600,
            icon: FontAwesomeIcons.user,
            label: '关系人',
            value: personName,
            chevron: true,
            onTap: onTapPerson,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _FormRow(
            iconBg: AppColors.orange50,
            iconColor: AppColors.orange500,
            icon: FontAwesomeIcons.gift,
            label: '事由',
            value: eventName,
            chevron: false,
            onTap: onTapReason,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _FormRow(
            iconBg: AppColors.blue50,
            iconColor: AppColors.blue500,
            icon: FontAwesomeIcons.calendar,
            label: '日期',
            value: dateLabel,
            chevron: true,
            onTap: onTapDate,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _FormRow(
            iconBg: AppColors.green50,
            iconColor: AppColors.green500,
            icon: FontAwesomeIcons.wallet,
            label: '支付方式',
            value: paymentMethod,
            chevron: true,
            borderBottom: false,
            onTap: onTapPayment,
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
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String label;
  final String value;
  final bool chevron;
  final VoidCallback onTap;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    return PrototypePressableRow(
      onTap: onTap,
      borderBottom: borderBottom,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: FaIcon(icon, size: 12, color: iconColor),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.base(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (chevron)
            const FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 10,
              color: AppColors.gray300,
            ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      radius: AppRadii.br2xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            maxLines: null,
            minLines: 2,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '添加备注...',
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: AppTypography.base(
              fontSize: 14,
              fontWeight: AppTypography.regular,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  dashPattern: const [6, 4],
                  strokeWidth: 1,
                  color: AppColors.gray300,
                  radius: const Radius.circular(12),
                  padding: EdgeInsets.zero,
                ),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(FontAwesomeIcons.camera, color: AppColors.textMuted, size: 16),
                      const SizedBox(height: 4),
                      Text(
                        '添加图片',
                        style: AppTypography.base(
                          fontSize: 10,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
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

class _AmountInputFormatter extends TextInputFormatter {
  const _AmountInputFormatter();

  static final RegExp _reg = RegExp(r'^\d{0,12}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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
  if (frac.length == 0) frac = '00';
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

