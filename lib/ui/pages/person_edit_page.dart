import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../app_data.dart';
import '../contact_avatar.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';

/// 页面：关系人管理 - 编辑/新增
/// 对照原型：prototype/index.html -> "编辑/新增"
class PersonEditPage extends StatefulWidget {
  const PersonEditPage({super.key, this.personId});

  final String? personId;

  @override
  State<PersonEditPage> createState() => _PersonEditPageState();
}

class _PersonEditPageState extends State<PersonEditPage> {
  static const int _kNoteMaxLen = 200;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _noteFocus = FocusNode();

  bool _inited = false;
  bool _saving = false;
  String _relationship = '';
  String? _avatarUrl;

  bool _nameEditing = false;
  bool _phoneEditing = false;
  bool _noteEditing = false;

  String? _nameError;
  String? _phoneError;
  String? _noteError;

  String _savedName = '';
  String _savedPhone = '';
  String _savedNote = '';

  Timer? _nameDebounce;
  Timer? _phoneDebounce;
  Timer? _noteDebounce;

  @override
  void dispose() {
    _nameDebounce?.cancel();
    _phoneDebounce?.cancel();
    _noteDebounce?.cancel();
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
    final data = AppDataScope.of(context);
    final person = widget.personId == null ? null : data.findPerson(widget.personId!);
    _nameCtrl.text = person?.name ?? '';
    _phoneCtrl.text = person?.phone ?? '';
    _noteCtrl.text = person?.note ?? '';
    _savedName = _nameCtrl.text.trim();
    _savedPhone = _phoneCtrl.text.trim();
    _savedNote = _noteCtrl.text.trim();
    _avatarUrl = person?.avatarUrl;
    if (person != null) {
      _relationship = person.relationship;
    } else {
      final prefer = data.relationTypes.any((e) => e.name == '朋友') ? '朋友' : (data.relationTypes.isEmpty ? '朋友' : data.relationTypes.first.name);
      _relationship = prefer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = AppDataScope.of(context);
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
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
                        color: _saving ? AppColors.textMuted : AppColors.textTertiary,
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
                  onTap: _saving ? null : () => _onSave(data),
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _AvatarEditor(
                  avatarUrl: _avatarUrl,
                  nameForFallback: _nameCtrl.text.trim().isEmpty ? '—' : _nameCtrl.text.trim(),
                  onTap: () => _toast(context, '仅原型展示：更换头像未实现'),
                ),
                const SizedBox(height: 24),
                _BasicInfoCard(
                  nameCtrl: _nameCtrl,
                  nameFocus: _nameFocus,
                  nameEditing: _nameEditing,
                  nameErrorText: _nameError,
                  onTapName: _saving ? null : () => _startEditing(_InlineEditField.name),
                  onNameChanged: _saving ? null : (v) => _onNameChanged(data, v),
                  onNameSubmitted: _saving ? null : () => _commitName(data),
                  onNameFocusChange: _saving ? null : (hasFocus) => _onNameFocusChange(data, hasFocus),
                  relationship: _relationship,
                  phone: _phoneCtrl.text,
                  onPickRelationship: _saving ? null : () => _pickRelationship(data),
                  phoneCtrl: _phoneCtrl,
                  phoneFocus: _phoneFocus,
                  phoneEditing: _phoneEditing,
                  phoneErrorText: _phoneError,
                  onTapPhone: _saving ? null : () => _startEditing(_InlineEditField.phone),
                  onPhoneChanged: _saving ? null : (v) => _onPhoneChanged(data, v),
                  onPhoneSubmitted: _saving ? null : () => _commitPhone(data),
                  onPhoneFocusChange: _saving ? null : (hasFocus) => _onPhoneFocusChange(data, hasFocus),
                ),
                const SizedBox(height: 24),
                const _SectionOverline(title: '其他信息'),
                const SizedBox(height: 12),
                _NoteCard(
                  noteCtrl: _noteCtrl,
                  noteFocus: _noteFocus,
                  noteEditing: _noteEditing,
                  noteErrorText: _noteError,
                  onTap: _saving ? null : () => _startEditing(_InlineEditField.note),
                  onNoteChanged: _saving ? null : (v) => _onNoteChanged(data, v),
                  onNoteSubmitted: _saving ? null : () => _commitNote(data),
                  onNoteFocusChange: _saving ? null : (hasFocus) => _onNoteFocusChange(data, hasFocus),
                ),
                const SizedBox(height: 24),
                if (widget.personId != null)
                  _DeleteButton(
                    onTap: _saving ? null : () => _confirmDelete(data),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave(AppData data) async {
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

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final note = _noteCtrl.text.trim();
    setState(() => _saving = true);
    try {
      if (widget.personId == null) {
        data.createPerson(
          name: name,
          relationship: _relationship,
          phone: phone.isEmpty ? null : phone,
          note: note.isEmpty ? null : note,
          avatarUrl: _avatarUrl,
        );
      } else {
        data.updatePerson(
          id: widget.personId!,
          name: name,
          relationship: _relationship,
          phone: phone.isEmpty ? null : phone,
          note: note.isEmpty ? null : note,
          avatarUrl: _avatarUrl,
        );
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
    if (raw.trim().isEmpty) return '姓名不能为空';
    return null;
  }

  String? _validatePhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    var digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('86') && digits.length == 13) {
      digits = digits.substring(2);
    }
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
  }

  void _onNameChanged(AppData data, String v) {
    _nameDebounce?.cancel();
    setState(() {
      _nameError = _validateName(v);
    });
    if (_nameError != null) return;
    _scheduleNameSave(data);
  }

  void _onPhoneChanged(AppData data, String v) {
    _phoneDebounce?.cancel();
    setState(() {
      _phoneError = _validatePhone(v);
    });
    if (_phoneError != null) return;
    _schedulePhoneSave(data);
  }

  void _onNoteChanged(AppData data, String v) {
    _noteDebounce?.cancel();
    setState(() {
      _noteError = _validateNote(v);
    });
    if (_noteError != null) return;
    _scheduleNoteSave(data);
  }

  void _scheduleNameSave(AppData data) {
    _nameDebounce?.cancel();
    _nameDebounce = Timer(const Duration(milliseconds: 450), () => _saveInlineField(data, _InlineEditField.name));
  }

  void _schedulePhoneSave(AppData data) {
    _phoneDebounce?.cancel();
    _phoneDebounce = Timer(const Duration(milliseconds: 450), () => _saveInlineField(data, _InlineEditField.phone));
  }

  void _scheduleNoteSave(AppData data) {
    _noteDebounce?.cancel();
    _noteDebounce = Timer(const Duration(milliseconds: 450), () => _saveInlineField(data, _InlineEditField.note));
  }

  void _onNameFocusChange(AppData data, bool hasFocus) {
    if (hasFocus) return;
    if (!_nameEditing) return;
    _commitName(data);
  }

  void _onPhoneFocusChange(AppData data, bool hasFocus) {
    if (hasFocus) return;
    if (!_phoneEditing) return;
    _commitPhone(data);
  }

  void _onNoteFocusChange(AppData data, bool hasFocus) {
    if (hasFocus) return;
    if (!_noteEditing) return;
    _commitNote(data);
  }

  void _commitName(AppData data) {
    _nameDebounce?.cancel();
    final err = _validateName(_nameCtrl.text);
    setState(() {
      _nameError = err;
      if (err == null) _nameEditing = false;
    });
    if (err != null) {
      _nameFocus.requestFocus();
      return;
    }
    _saveInlineField(data, _InlineEditField.name);
  }

  void _commitPhone(AppData data) {
    _phoneDebounce?.cancel();
    final err = _validatePhone(_phoneCtrl.text);
    setState(() {
      _phoneError = err;
      if (err == null) _phoneEditing = false;
    });
    if (err != null) {
      _phoneFocus.requestFocus();
      return;
    }
    _saveInlineField(data, _InlineEditField.phone);
  }

  void _commitNote(AppData data) {
    _noteDebounce?.cancel();
    final err = _validateNote(_noteCtrl.text);
    setState(() {
      _noteError = err;
      if (err == null) _noteEditing = false;
    });
    if (err != null) {
      _noteFocus.requestFocus();
      return;
    }
    _saveInlineField(data, _InlineEditField.note);
  }

  Future<void> _saveInlineField(AppData data, _InlineEditField field) async {
    if (widget.personId == null) return;

    final name = (field == _InlineEditField.name ? _nameCtrl.text : _savedName).trim();
    final phone = (field == _InlineEditField.phone ? _phoneCtrl.text : _savedPhone).trim();
    final note = (field == _InlineEditField.note ? _noteCtrl.text : _savedNote).trim();

    final nameErr = _validateName(name);
    final phoneErr = field == _InlineEditField.phone ? _validatePhone(phone) : null;
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
      data.updatePerson(
        id: widget.personId!,
        name: name,
        relationship: _relationship,
        phone: phone.isEmpty ? null : phone,
        note: note.isEmpty ? null : note,
        avatarUrl: _avatarUrl,
      );
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

  Future<void> _confirmDelete(AppData data) async {
    final name = _nameCtrl.text.trim().isEmpty ? '该联系人' : _nameCtrl.text.trim();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除联系人'),
          content: Text('确认删除「$name」？删除后将进入回收站。'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
          ],
        );
      },
    );
    if (ok != true) return;
    data.trashPerson(widget.personId!);
    if (!mounted) return;
    Navigator.of(context).pop(true);
    _toast(context, '已移入回收站');
  }

  Future<void> _pickRelationship(AppData data) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        final types = data.relationTypes.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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
    setState(() => _relationship = picked);
  }

  void _toast(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
              color: AppColors.gray200,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 4),
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
          _InlineEditableRow(
            label: '姓名',
            requiredMark: true,
            displayValue: nameCtrl.text.trim().isEmpty ? '未设置' : nameCtrl.text.trim(),
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
            borderBottom: false,
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
          color: noteErrorText == null ? Colors.transparent : AppColors.stateDangerSoft,
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
                        noteCtrl.text.trim().isEmpty ? '未设置' : noteCtrl.text.trim(),
                        style: AppTypography.base(
                          fontSize: 14,
                          fontWeight: AppTypography.regular,
                          color: noteCtrl.text.trim().isEmpty ? AppColors.textMuted : AppColors.textPrimary,
                        ),
                      )
                    else
                      Focus(
                        focusNode: noteFocus,
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
              const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray100, width: 1),
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
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.red500),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.base(
                    fontSize: 16,
                    fontWeight: requiredMark ? AppTypography.medium : AppTypography.regular,
                    color: value == '未设置' ? AppColors.textMuted : AppColors.textPrimary,
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
        color: errorText == null ? Colors.transparent : AppColors.stateDangerSoft,
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
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(color: AppColors.red500),
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
                        fontWeight: requiredMark ? AppTypography.medium : AppTypography.regular,
                        color: isUnset ? AppColors.textMuted : AppColors.textPrimary,
                      ),
                    )
                  else
                    Focus(
                      focusNode: focusNode,
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
                          fontWeight: requiredMark ? AppTypography.medium : AppTypography.regular,
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
            const FaIcon(FontAwesomeIcons.chevronRight, size: 10, color: AppColors.gray300),
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

