import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lunar/lunar.dart';

import '../../data/local/drift/app_database.dart';
import '../../import/default_book_service.dart';
import '../../media/media_storage_service.dart';
import '../app_database_scope.dart';
import '../app_dialog.dart';
import '../app_notifier.dart';
import '../app_notification_tokens.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../contact_avatar.dart';
import '../components.dart';
import '../edit_protection_guard.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import '../lunar_date_picker.dart';

/// 页面：关系人管理 - 编辑/新增
/// 对照原型：prototype/index.html -> "编辑/新增"
class PersonEditPage extends StatefulWidget {
  const PersonEditPage({super.key, this.personId});

  final String? personId;

  @override
  State<PersonEditPage> createState() => _PersonEditPageState();
}

const int _kNoteMaxLen = 500;

class _PersonEditPageState extends State<PersonEditPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _noteFocus = FocusNode();

  bool _inited = false;
  bool _saving = false;
  bool _authorized = false;
  bool _authChecked = false;
  String _relationship = '';
  static const String _defaultBookSelectionId = 'book_default';
  String _personBookId = _defaultBookSelectionId;
  String? _avatarUrl;
  DateTime? _birthday;
  bool _isLunarBirthday = false;

  bool _nameEditing = false;
  bool _phoneEditing = false;
  bool _noteEditing = false;

  String? _nameError;
  String? _phoneError;
  String? _noteError;

  String _savedName = '';
  String _savedPhone = '';
  String _savedNote = '';
  final DefaultBookService _defaultBookService = DefaultBookService();
  final MediaStorageService _mediaStorageService = MediaStorageService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    _authorized = widget.personId == null;
    _nameCtrl.text = '';
    _phoneCtrl.text = '';
    _noteCtrl.text = '';
    _savedName = _nameCtrl.text.trim();
    _savedPhone = _phoneCtrl.text.trim();
    _savedNote = _noteCtrl.text.trim();
    _avatarUrl = null;
    _birthday = null;
    _isLunarBirthday = false;
    _relationship = '朋友';
    _loadDefaultRelationshipFromDrift();
    if (widget.personId != null) {
      _loadPersonFromDrift(widget.personId!);
    }
    if (widget.personId != null && !_authChecked) {
      _authChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        final ok = await requireEditProtectionPassword(context, title: '编辑联系人');
        if (!mounted) return;
        if (!ok) {
          navigator.pop();
          return;
        }
        setState(() => _authorized = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.personId != null && !_authorized) {
      return const AppScaffold(
        backgroundColor: AppColors.surfaceApp,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.appColors.surfaceCard,
              border: Border(
                bottom: BorderSide(
                  color: context.appColors.surfaceSubtle,
                  width: 1,
                ),
              ),
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
                        color: _saving
                            ? AppColors.textMuted
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.personId == null ? '新增关系人' : '编辑关系人',
                      style: AppTypography.base(
                        fontSize: 18,
                        fontWeight: AppTypography.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                PressableScale(
                  onTap: _saving ? null : _onSave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _AvatarEditor(
                  avatarUrl: _avatarUrl,
                  nameForFallback: _nameCtrl.text.trim().isEmpty
                      ? '—'
                      : _nameCtrl.text.trim(),
                  onTap: () {
                    if (_saving || !_authorized) return;
                    _pickAvatar();
                  },
                ),
                const SizedBox(height: 24),
                _BasicInfoCard(
                  nameCtrl: _nameCtrl,
                  nameFocus: _nameFocus,
                  nameEditing: _nameEditing,
                  nameErrorText: _nameError,
                  onTapName: _saving
                      ? null
                      : () => _startEditing(_InlineEditField.name),
                  onNameChanged: _saving ? null : _onNameChanged,
                  onNameSubmitted: _saving ? null : _commitName,
                  onNameFocusChange: _saving ? null : _onNameFocusChange,
                  relationship: _relationship,
                  phone: _phoneCtrl.text,
                  onPickRelationship: _saving ? null : _pickRelationship,
                  phoneCtrl: _phoneCtrl,
                  phoneFocus: _phoneFocus,
                  phoneEditing: _phoneEditing,
                  phoneErrorText: _phoneError,
                  onTapPhone: _saving
                      ? null
                      : () => _startEditing(_InlineEditField.phone),
                  onPhoneChanged: _saving ? null : _onPhoneChanged,
                  onPhoneSubmitted: _saving ? null : _commitPhone,
                  onPhoneFocusChange: _saving ? null : _onPhoneFocusChange,
                  birthday: _birthday,
                  isLunarBirthday: _isLunarBirthday,
                  onPickBirthday: _saving ? null : _pickBirthday,
                  onLunarBirthdayChanged: _saving
                      ? null
                      : (v) => setState(() => _isLunarBirthday = v),
                ),
                const SizedBox(height: 24),
                const _SectionOverline(title: '其他信息'),
                const SizedBox(height: 12),
                _NoteCard(
                  noteCtrl: _noteCtrl,
                  noteFocus: _noteFocus,
                  noteEditing: _noteEditing,
                  noteErrorText: _noteError,
                  onTap: _saving
                      ? null
                      : () => _startEditing(_InlineEditField.note),
                  onNoteChanged: _saving ? null : _onNoteChanged,
                  onNoteSubmitted: _saving ? null : _commitNote,
                  onNoteFocusChange: _saving ? null : _onNoteFocusChange,
                ),
                const SizedBox(height: 24),
                if (widget.personId != null)
                  _DeleteButton(onTap: _saving ? null : _confirmDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    if (widget.personId != null) {
      final ok = await requireEditProtectionPassword(context, title: '编辑联系人');
      if (!ok) return;
      if (!mounted) return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _nameEditing = false;
      _phoneEditing = false;
      _noteEditing = false;
    });

    if (!_validateAll()) {
      _toast(context, '请修正后再保存');
      return;
    }

    final db = AppDatabaseScope.of(context);
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final note = _noteCtrl.text.trim();
    setState(() => _saving = true);
    try {
      if (phone.isNotEmpty &&
          await _isPhoneExistsInDrift(db, phone, excludeId: widget.personId)) {
        if (!mounted) return;
        setState(() {
          _phoneError = '该手机号已存在';
          _saving = false;
        });
        return;
      }
      final dbBookId = await _resolveDbBookId(db, _personBookId);
      final now = DateTime.now().millisecondsSinceEpoch;
      String targetId;
      if (widget.personId == null) {
        targetId = await db.personsDao.insertOne(
          PersonsCompanion.insert(
            bookId: dbBookId,
            name: name,
            relationshipType: Value(
              _relationship.trim().isEmpty ? '朋友' : _relationship.trim(),
            ),
            phone: Value(phone.isEmpty ? null : phone),
            birthday: Value(_birthday?.toIso8601String()),
            avatarUri: Value(
              _avatarUrl?.trim().isEmpty == true ? null : _avatarUrl?.trim(),
            ),
            note: Value(note.isEmpty ? null : note),
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        targetId = widget.personId!;
        final existing = await db.personsDao.findById(targetId);
        if (existing == null) {
          throw StateError('联系人不存在');
        }
        final updated = existing.copyWith(
          name: name,
          relationshipType: _relationship.trim().isEmpty
              ? existing.relationshipType
              : _relationship.trim(),
          phone: Value(phone.isEmpty ? null : phone),
          birthday: Value(_birthday?.toIso8601String()),
          avatarUri: Value(
            _avatarUrl?.trim().isEmpty == true ? null : _avatarUrl?.trim(),
          ),
          note: Value(note.isEmpty ? null : note),
        );
        await db.personsDao.updateOne(updated);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      _toast(context, '已保存');
    } catch (e) {
      if (!mounted) return;
      if (e is ArgumentError && e.name == 'name') {
        setState(() => _nameError = '姓名不能为空');
      }
      _toast(context, '保存失败：$e');
      setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'webp'],
      withData: false,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null || path.trim().isEmpty) {
      _toast(context, '无法读取头像文件路径');
      return;
    }
    try {
      final stored = await _mediaStorageService.saveAvatarFromPath(
        path,
        oldStoredPath: _avatarUrl,
      );
      if (!mounted) return;
      setState(() => _avatarUrl = stored);
      _toast(context, '头像已更新');
    } catch (e) {
      if (!mounted) return;
      _toast(context, '头像更新失败：$e');
    }
  }

  bool _validateAll() {
    final nameErr = _validateName(_nameCtrl.text);
    final phoneErr = _validatePhone(_phoneCtrl.text);
    final noteErr = _validateNote(_noteCtrl.text);
    final ok = nameErr == null && phoneErr == null && noteErr == null;
    setState(() {
      _nameError = nameErr;
      _phoneError = phoneErr;
      _noteError = noteErr;
    });
    return ok;
  }

  String? _validateName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '姓名不能为空';
    if (trimmed.characters.length < 2 || trimmed.characters.length > 20) {
      return '姓名长度需为2-20个字符';
    }
    return null;
  }

  String? _validatePhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    var digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('86') && digits.length == 13) {
      digits = digits.substring(2);
    }
    // 支持 +86 或纯数字，简单的正则校验
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(digits)) {
      return '手机号格式不正确';
    }

    return null;
  }

  String? _validateNote(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.characters.length > _kNoteMaxLen) {
      return '备注最多$_kNoteMaxLen字';
    }
    return null;
  }

  void _startEditing(_InlineEditField field) {
    setState(() {
      _nameEditing = field == _InlineEditField.name;
      _phoneEditing = field == _InlineEditField.phone;
      _noteEditing = field == _InlineEditField.note;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (field) {
        case _InlineEditField.name:
          _nameFocus.requestFocus();
          break;
        case _InlineEditField.phone:
          _phoneFocus.requestFocus();
          break;
        case _InlineEditField.note:
          _noteFocus.requestFocus();
          break;
      }
    });
  }

  void _onNameChanged(String v) {
    setState(() {
      _nameError = _validateName(v);
    });
  }

  void _onPhoneChanged(String v) {
    setState(() {
      _phoneError = _validatePhone(v);
    });
  }

  void _onNoteChanged(String v) {
    setState(() {
      _noteError = _validateNote(v);
    });
  }

  void _onNameFocusChange(bool hasFocus) {
    if (hasFocus) return;
    if (!_nameEditing) return;
    _commitName();
  }

  void _onPhoneFocusChange(bool hasFocus) {
    if (hasFocus) return;
    if (!_phoneEditing) return;
    _commitPhone();
  }

  void _onNoteFocusChange(bool hasFocus) {
    if (hasFocus) return;
    if (!_noteEditing) return;
    _commitNote();
  }

  void _commitName() {
    final err = _validateName(_nameCtrl.text);
    setState(() {
      _nameError = err;
      if (err == null) _nameEditing = false;
    });
    if (err != null) {
      _nameFocus.requestFocus();
      return;
    }
    _saveInlineField(_InlineEditField.name);
  }

  void _commitPhone() {
    final err = _validatePhone(_phoneCtrl.text);
    setState(() {
      _phoneError = err;
      if (err == null) _phoneEditing = false;
    });
    if (err != null) {
      _phoneFocus.requestFocus();
      return;
    }
    _saveInlineField(_InlineEditField.phone);
  }

  void _commitNote() {
    final err = _validateNote(_noteCtrl.text);
    setState(() {
      _noteError = err;
      if (err == null) _noteEditing = false;
    });
    if (err != null) {
      _noteFocus.requestFocus();
      return;
    }
    _saveInlineField(_InlineEditField.note);
  }

  Future<void> _saveInlineField(_InlineEditField field) async {
    if (widget.personId == null) return;
    final db = AppDatabaseScope.of(context);

    final name = (field == _InlineEditField.name ? _nameCtrl.text : _savedName)
        .trim();
    final phone =
        (field == _InlineEditField.phone ? _phoneCtrl.text : _savedPhone)
            .trim();
    final note = (field == _InlineEditField.note ? _noteCtrl.text : _savedNote)
        .trim();

    final nameErr = _validateName(name);
    final phoneErr = field == _InlineEditField.phone
        ? _validatePhone(phone)
        : null;
    final noteErr = field == _InlineEditField.note ? _validateNote(note) : null;

    if (nameErr != null || phoneErr != null || noteErr != null) {
      setState(() {
        _nameError = nameErr;
        if (field == _InlineEditField.phone) _phoneError = phoneErr;
        if (field == _InlineEditField.note) _noteError = noteErr;
      });
      return;
    }

    final changed = switch (field) {
      _InlineEditField.name => name != _savedName,
      _InlineEditField.phone => phone != _savedPhone,
      _InlineEditField.note => note != _savedNote,
    };
    if (!changed) return;

    try {
      if (field == _InlineEditField.phone &&
          phone.isNotEmpty &&
          await _isPhoneExistsInDrift(db, phone, excludeId: widget.personId)) {
        if (!mounted) return;
        setState(() => _phoneError = '该手机号已存在');
        return;
      }
      final existing = await db.personsDao.findById(widget.personId!);
      if (existing == null) return;
      final updated = existing.copyWith(
        name: name,
        relationshipType: _relationship.trim().isEmpty
            ? existing.relationshipType
            : _relationship.trim(),
        phone: Value(phone.isEmpty ? null : phone),
        birthday: Value(_birthday?.toIso8601String()),
        avatarUri: Value(
          _avatarUrl?.trim().isEmpty == true ? null : _avatarUrl?.trim(),
        ),
        note: Value(note.isEmpty ? null : note),
      );
      await db.personsDao.updateOne(updated);
      if (field == _InlineEditField.name) _savedName = name;
      if (field == _InlineEditField.phone) _savedPhone = phone;
      if (field == _InlineEditField.note) _savedNote = note;
    } catch (e) {
      if (!mounted) return;
      if (e is ArgumentError && e.name == 'name') {
        setState(() => _nameError = '姓名不能为空');
      }
      _toast(context, '保存失败：$e');
    }
  }

  Future<void> _confirmDelete() async {
    final okAuth = await requireEditProtectionPassword(context, title: '删除联系人');
    if (!okAuth) return;
    if (!mounted) return;
    final db = AppDatabaseScope.of(context);
    final name = _nameCtrl.text.trim().isEmpty ? '该联系人' : _nameCtrl.text.trim();
    final ok = await AppDialog.confirm(
      context,
      title: '删除联系人',
      message: '确认删除「$name」？删除后将进入回收站。',
      confirmLabel: '删除',
      cancelLabel: '取消',
      tone: AppNotificationTone.error,
    );
    if (!mounted || ok != true) return;
    await db.personsDao.deleteById(widget.personId!);
    if (!mounted) return;
    Navigator.of(context).pop(true);
    AppNotifier.success(context, '已移入回收站');
  }

  Future<void> _loadPersonFromDrift(String personId) async {
    try {
      final db = AppDatabaseScope.of(context);
      final person = await db.personsDao.findById(personId);
      if (person == null || !mounted) return;
      setState(() {
        _nameCtrl.text = person.name;
        _phoneCtrl.text = person.phone ?? '';
        _noteCtrl.text = person.note ?? '';
        _savedName = _nameCtrl.text.trim();
        _savedPhone = _phoneCtrl.text.trim();
        _savedNote = _noteCtrl.text.trim();
        _relationship = person.relationshipType;
        _avatarUrl = person.avatarUri;
        _birthday = DateTime.tryParse(person.birthday ?? '');
        _personBookId = person.bookId;
      });
    } catch (_) {}
  }

  Future<String> _resolveDbBookId(AppDatabase db, String selectedBookId) async {
    if (selectedBookId != _defaultBookSelectionId) return selectedBookId;
    return _defaultBookService.ensureDefaultBookId(db);
  }

  Future<bool> _isPhoneExistsInDrift(
    AppDatabase db,
    String raw, {
    String? excludeId,
  }) async {
    String clean(String s) {
      var d = s.replaceAll(RegExp(r'\D'), '');
      if (d.startsWith('86') && d.length == 13) {
        d = d.substring(2);
      }
      return d;
    }

    final target = clean(raw);
    if (target.isEmpty) return false;
    final all = await db.select(db.persons).get();
    for (final p in all) {
      if (p.personId == excludeId) continue;
      final normalized = clean(p.phone ?? '');
      if (normalized.isNotEmpty && normalized == target) {
        return true;
      }
    }
    return false;
  }

  Future<void> _pickRelationship() async {
    final db = AppDatabaseScope.of(context);
    final types = await db.relationTypesDao.listAll();
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
          child: Container(
            decoration: BoxDecoration(
              color: context.appColors.surfaceCard,
              borderRadius: AppRadii.br2xl,
              boxShadow: AppShadows.lg,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceCard,
                    border: Border(
                      bottom: BorderSide(
                        color: context.appColors.surfaceSubtle,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '选择关系类型',
                          style: AppTypography.base(
                            fontSize: 14,
                            fontWeight: AppTypography.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      PrototypeIconButton(
                        icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                        backgroundColor: context.appColors.surfaceSubtle,
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
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      for (final t in types)
                        PrototypePressableRow(
                          onTap: () => Navigator.of(context).pop(t.name),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.name,
                                  style: AppTypography.base(
                                    fontSize: 14,
                                    fontWeight: AppTypography.medium,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (t.name == _relationship)
                                const FaIcon(
                                  FontAwesomeIcons.check,
                                  size: 14,
                                  color: AppColors.indigo600,
                                ),
                            ],
                          ),
                        ),
                      PrototypePressableRow(
                        onTap: () => Navigator.of(context).pop('__custom__'),
                        child: Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.plus,
                              size: 14,
                              color: AppColors.blue600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '自定义...',
                              style: AppTypography.base(
                                fontSize: 14,
                                fontWeight: AppTypography.medium,
                                color: AppColors.blue600,
                              ),
                            ),
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
    if (!mounted || picked == null) return;
    if (picked == '__custom__') {
      _inputCustomRelationship();
    } else {
      setState(() => _relationship = picked);
    }
  }

  Future<void> _inputCustomRelationship() async {
    final input = await AppDialog.showInput(
      context,
      title: '自定义关系类型',
      fields: [
        AppDialogField(
          id: 'value',
          label: '关系名称',
          hint: '请输入关系名称',
        ),
      ],
      confirmLabel: '确定',
      cancelLabel: '取消',
    );
    if (!mounted) return;
    final ok = input?['value']?.trim() ?? '';
    if (ok.isNotEmpty) {
      try {
        final db = AppDatabaseScope.of(context);
        await db.relationTypesDao.create(name: ok);
      } catch (_) {}
      if (!mounted) return;
      setState(() => _relationship = ok);
    }
  }

  Future<void> _loadDefaultRelationshipFromDrift() async {
    try {
      final db = AppDatabaseScope.of(context);
      final types = await db.relationTypesDao.listAll();
      if (!mounted || types.isEmpty) return;
      final prefer = types.any((e) => e.name == '朋友') ? '朋友' : types.first.name;
      setState(() => _relationship = prefer);
    } catch (_) {}
  }

  Future<void> _pickBirthday() async {
    final picked = await showLunarDatePicker(
      context: context,
      initialDate: _birthday,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  void _toast(BuildContext context, String message) {
    AppNotifier.info(context, message);
  }
}

enum _InlineEditField { name, phone, note }

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({
    required this.avatarUrl,
    required this.nameForFallback,
    required this.onTap,
  });

  final String? avatarUrl;
  final String nameForFallback;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PressableScale(
          onTap: onTap,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: context.appColors.surfaceDisabled,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.appColors.surfaceCard,
                width: 4,
              ),
              boxShadow: AppShadows.sm,
            ),
            clipBehavior: Clip.antiAlias,
            child: ContactAvatar(
              name: nameForFallback,
              avatarUrl: avatarUrl,
              size: 96,
              shape: ContactAvatarShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '点击更换头像',
          style: AppTypography.base(
            fontSize: 12,
            fontWeight: AppTypography.medium,
            color: AppColors.indigo600,
          ),
        ),
      ],
    );
  }
}

class _BasicInfoCard extends StatelessWidget {
  const _BasicInfoCard({
    required this.nameCtrl,
    required this.nameFocus,
    required this.nameEditing,
    required this.nameErrorText,
    required this.onTapName,
    required this.onNameChanged,
    required this.onNameSubmitted,
    required this.onNameFocusChange,
    required this.relationship,
    required this.phone,
    required this.onPickRelationship,
    required this.phoneCtrl,
    required this.phoneFocus,
    required this.phoneEditing,
    required this.phoneErrorText,
    required this.onTapPhone,
    required this.onPhoneChanged,
    required this.onPhoneSubmitted,
    required this.onPhoneFocusChange,
    required this.birthday,
    required this.isLunarBirthday,
    required this.onPickBirthday,
    required this.onLunarBirthdayChanged,
  });

  final TextEditingController nameCtrl;
  final FocusNode nameFocus;
  final bool nameEditing;
  final String? nameErrorText;
  final VoidCallback? onTapName;
  final ValueChanged<String>? onNameChanged;
  final VoidCallback? onNameSubmitted;
  final ValueChanged<bool>? onNameFocusChange;
  final String relationship;
  final String phone;
  final VoidCallback? onPickRelationship;
  final TextEditingController phoneCtrl;
  final FocusNode phoneFocus;
  final bool phoneEditing;
  final String? phoneErrorText;
  final VoidCallback? onTapPhone;
  final ValueChanged<String>? onPhoneChanged;
  final VoidCallback? onPhoneSubmitted;
  final ValueChanged<bool>? onPhoneFocusChange;
  final DateTime? birthday;
  final bool isLunarBirthday;
  final VoidCallback? onPickBirthday;
  final ValueChanged<bool>? onLunarBirthdayChanged;

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
          _InlineEditableRow(
            label: '姓名',
            requiredMark: true,
            displayValue: nameCtrl.text.trim().isEmpty
                ? '未设置'
                : nameCtrl.text.trim(),
            controller: nameCtrl,
            focusNode: nameFocus,
            editing: nameEditing,
            hintText: '请输入姓名',
            errorText: nameErrorText,
            onTap: onTapName,
            onChanged: onNameChanged,
            onSubmitted: onNameSubmitted,
            onFocusChange: onNameFocusChange,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            borderBottom: true,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _EditableRow(
            label: '关系类型',
            requiredMark: false,
            value: relationship.trim().isEmpty ? '未设置' : relationship.trim(),
            onTap: onPickRelationship,
            borderBottom: true,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _InlineEditableRow(
            label: '手机号',
            requiredMark: false,
            displayValue: _formatPhone(phone.trim()),
            controller: phoneCtrl,
            focusNode: phoneFocus,
            editing: phoneEditing,
            hintText: '请输入手机号（可选）',
            errorText: phoneErrorText,
            onTap: onTapPhone,
            onChanged: onPhoneChanged,
            onSubmitted: onPhoneSubmitted,
            onFocusChange: onPhoneFocusChange,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            borderBottom: true,
          ),
          const PrototypeDivider(color: AppColors.borderDivider),
          _BirthdayRow(
            birthday: birthday,
            isLunar: isLunarBirthday,
            onTap: onPickBirthday,
            onLunarChanged: onLunarBirthdayChanged,
          ),
        ],
      ),
    );
  }
}

class _SectionOverline extends StatelessWidget {
  const _SectionOverline({required this.title});

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

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.noteCtrl,
    required this.noteFocus,
    required this.noteEditing,
    required this.noteErrorText,
    required this.onTap,
    required this.onNoteChanged,
    required this.onNoteSubmitted,
    required this.onNoteFocusChange,
  });

  final TextEditingController noteCtrl;
  final FocusNode noteFocus;
  final bool noteEditing;
  final String? noteErrorText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onNoteChanged;
  final VoidCallback? onNoteSubmitted;
  final ValueChanged<bool>? onNoteFocusChange;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: EdgeInsets.zero,
      child: PrototypePressableRow(
        onTap: noteEditing ? null : onTap,
        borderBottom: false,
        child: Container(
          color: noteErrorText == null
              ? Colors.transparent
              : AppColors.stateDangerSoft,
          child: Row(
            children: [
              Expanded(
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
                    const SizedBox(height: 6),
                    if (!noteEditing)
                      Text(
                        noteCtrl.text.trim().isEmpty
                            ? '未设置'
                            : noteCtrl.text.trim(),
                        style: AppTypography.base(
                          fontSize: 14,
                          fontWeight: AppTypography.regular,
                          color: noteCtrl.text.trim().isEmpty
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                      )
                    else
                      Focus(
                        onFocusChange: onNoteFocusChange,
                        child: TextField(
                          controller: noteCtrl,
                          focusNode: noteFocus,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.done,
                          maxLines: 6,
                          minLines: 3,
                          onChanged: onNoteChanged,
                          onSubmitted: (_) => onNoteSubmitted?.call(),
                          style: AppTypography.base(
                            fontSize: 14,
                            fontWeight: AppTypography.regular,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: '补充说明（可选）',
                            hintStyle: AppTypography.base(
                              fontSize: 14,
                              fontWeight: AppTypography.regular,
                              color: AppColors.textMuted,
                            ),
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    if (noteEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${noteCtrl.text.length}/$_kNoteMaxLen',
                            style: AppTypography.base(
                              fontSize: 11,
                              fontWeight: AppTypography.regular,
                              color: noteCtrl.text.length > _kNoteMaxLen
                                  ? AppColors.stateDangerStrong
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    if (noteErrorText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        noteErrorText!,
                        style: AppTypography.base(
                          fontSize: 12,
                          fontWeight: AppTypography.regular,
                          color: AppColors.stateDangerStrong,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 10,
                color: AppColors.gray300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
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
          '删除联系人',
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

class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.label,
    required this.requiredMark,
    required this.value,
    required this.onTap,
    this.borderBottom = true,
  });

  final String label;
  final bool requiredMark;
  final String value;
  final VoidCallback? onTap;
  final bool borderBottom;

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
                          style: TextStyle(
                            color: context.appColors.stateDanger,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.base(
                    fontSize: 16,
                    fontWeight: requiredMark
                        ? AppTypography.medium
                        : AppTypography.regular,
                    color: value == '未设置'
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
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

class _InlineEditableRow extends StatelessWidget {
  const _InlineEditableRow({
    required this.label,
    required this.requiredMark,
    required this.displayValue,
    required this.controller,
    required this.focusNode,
    required this.editing,
    required this.hintText,
    required this.errorText,
    required this.onTap,
    required this.onChanged,
    required this.onSubmitted,
    required this.onFocusChange,
    required this.keyboardType,
    required this.textInputAction,
    this.borderBottom = true,
  });

  final String label;
  final bool requiredMark;
  final String displayValue;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool editing;
  final String hintText;
  final String? errorText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final ValueChanged<bool>? onFocusChange;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    final isUnset = displayValue == '未设置';
    return PrototypePressableRow(
      onTap: editing ? null : onTap,
      borderBottom: borderBottom,
      child: Container(
        color: errorText == null
            ? Colors.transparent
            : AppColors.stateDangerSoft,
        child: Row(
          children: [
            Expanded(
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
                            style: TextStyle(
                              color: context.appColors.stateDanger,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!editing)
                    Text(
                      displayValue,
                      style: AppTypography.base(
                        fontSize: 16,
                        fontWeight: requiredMark
                            ? AppTypography.medium
                            : AppTypography.regular,
                        color: isUnset
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    )
                  else
                    Focus(
                      onFocusChange: onFocusChange,
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType: keyboardType,
                        textInputAction: textInputAction,
                        maxLines: 1,
                        onChanged: onChanged,
                        onSubmitted: (_) => onSubmitted?.call(),
                        style: AppTypography.base(
                          fontSize: 16,
                          fontWeight: requiredMark
                              ? AppTypography.medium
                              : AppTypography.regular,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: hintText,
                          hintStyle: AppTypography.base(
                            fontSize: 16,
                            fontWeight: AppTypography.regular,
                            color: AppColors.textMuted,
                          ),
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  if (errorText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      errorText!,
                      style: AppTypography.base(
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                        color: AppColors.stateDangerStrong,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 10,
              color: AppColors.gray300,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\s+'), '');
  if (digits.isEmpty) return '未设置';
  if (digits.length == 11) {
    return '${digits.substring(0, 3)} ${digits.substring(3, 7)} ${digits.substring(7)}';
  }
  return raw;
}

class _BirthdayRow extends StatelessWidget {
  const _BirthdayRow({
    required this.birthday,
    required this.isLunar,
    required this.onTap,
    required this.onLunarChanged,
  });

  final DateTime? birthday;
  final bool isLunar;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onLunarChanged;

  @override
  Widget build(BuildContext context) {
    String display = '未设置';
    String? ageInfo;

    if (birthday != null) {
      if (isLunar) {
        final lunar = Lunar.fromDate(birthday!);
        display = '农历 ${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
      } else {
        display =
            '${birthday!.year}-${birthday!.month.toString().padLeft(2, '0')}-${birthday!.day.toString().padLeft(2, '0')}';
      }

      // Calculate age
      final now = DateTime.now();
      var age = now.year - birthday!.year;
      if (now.month < birthday!.month ||
          (now.month == birthday!.month && now.day < birthday!.day)) {
        age--;
      }
      if (age >= 0) {
        ageInfo = '$age岁';
      }
    }

    return PrototypePressableRow(
      onTap: onTap,
      borderBottom: false,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '生日',
                      style: AppTypography.base(
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          display,
                          style: AppTypography.base(
                            fontSize: 16,
                            fontWeight: AppTypography.regular,
                            color: birthday == null
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (ageInfo != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.indigo50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ageInfo,
                              style: AppTypography.base(
                                fontSize: 11,
                                fontWeight: AppTypography.medium,
                                color: AppColors.indigo600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 10,
                color: AppColors.gray300,
              ),
            ],
          ),
          if (birthday != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _SwitchItem(
                  label: '农历',
                  value: isLunar,
                  onChanged: onLunarChanged,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 20,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: value ? colors.brandPrimary : colors.surfaceDisabled,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: context.appColors.surfaceCard,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.sm,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.base(
              fontSize: 14,
              fontWeight: AppTypography.regular,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
