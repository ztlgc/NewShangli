import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../app_data.dart';
import '../app_database_scope.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../contact_avatar.dart';
import '../components.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import 'person_edit_page.dart';
import 'record_add_page.dart';
import 'record_detail_page.dart';
import 'reminders_page.dart';
import '../../utils/date_util.dart';

/// 页面：关系人管理 - 详情页
/// 对照原型：prototype/index.html -> "详情页"
class PersonDetailPage extends StatelessWidget {
  const PersonDetailPage({super.key, this.personId});

  final String? personId;

  @override
  Widget build(BuildContext context) {
    if (personId == null) {
      return _buildNotFound(context);
    }
    return FutureBuilder<_PersonDetailView?>(
      future: _loadView(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppScaffold(
            backgroundColor: AppColors.surfaceApp,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final view = snapshot.data;
        if (view == null) {
          return _buildNotFound(context);
        }
        return AppScaffold(
          backgroundColor: AppColors.surfaceApp,
          body: _Canvas(view: view),
        );
      },
    );
  }

  Future<_PersonDetailView?> _loadView(BuildContext context) async {
    return _loadFromDb(context);
  }

  Future<_PersonDetailView?> _loadFromDb(BuildContext context) async {
    final id = personId;
    if (id == null || id.trim().isEmpty) return null;
    try {
      final db = AppDatabaseScope.maybeOf(context);
      if (db == null) return null;
      final Person? person = await db.personsDao.findById(id);
      if (person == null) return null;
      final records = await (db.select(db.giftRecords)
            ..where((t) => t.personId.equals(id))
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
          .get();
      var incomeCent = 0;
      var expenseCent = 0;
      final recordItems = <_PersonRecordView>[];
      for (final r in records) {
        final isIncome = r.direction != '支出';
        if (isIncome) {
          incomeCent += r.amountCent;
        } else {
          expenseCent += r.amountCent;
        }
        recordItems.add(
          _PersonRecordView(
            recordId: r.recordId,
            eventName: (r.eventName ?? '').trim().isEmpty ? '未设置事由' : r.eventName!.trim(),
            isIncome: isIncome,
            amountCent: r.amountCent,
            paymentMethod: (r.paymentMethod ?? '').trim().isEmpty ? '未设置' : r.paymentMethod!.trim(),
            occurredAt: DateTime.fromMillisecondsSinceEpoch(r.occurredAt),
          ),
        );
      }
      return _PersonDetailView(
        person: PersonData(
          id: person.personId,
          name: person.name,
          relationship: person.relationshipType,
          phone: person.phone,
          note: person.note,
          avatarUrl: person.avatarUri,
          birthday: DateTime.tryParse(person.birthday ?? ''),
          isLunarBirthday: false,
          birthdayReminder: false,
          createdAt: DateTime.fromMillisecondsSinceEpoch(person.createdAt),
        ),
        incomeCent: incomeCent,
        expenseCent: expenseCent,
        records: recordItems,
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildNotFound(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.brandPrimary,
            child: Row(
              children: [
                PrototypeIconButton(
                  icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.white,
                  onPressed: () => AppNav.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '详情',
                      style: AppTypography.base(
                        fontSize: 18,
                        fontWeight: AppTypography.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '联系人已删除或不存在',
                style: AppTypography.base(
                  fontSize: 14,
                  fontWeight: AppTypography.medium,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas({required this.view});

  final _PersonDetailView view;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.brandPrimary,
          child: Row(
            children: [
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.white,
                onPressed: () => AppNav.pop(context),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '详情',
                    style: AppTypography.base(
                      fontSize: 18,
                      fontWeight: AppTypography.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.pen, size: 14),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.white,
                onPressed: () => AppNav.push(context, PersonEditPage(personId: view.person.id), requiresLogin: true),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.only(bottom: 83 + 16),
                children: [
                  _Hero(view: view),
                  _InfoCards(person: view.person),
                  const _RecordsHeader(),
                  _RecordsCard(records: view.records),
                  const SizedBox(height: 24),
                ],
              ),
              const Positioned(left: 0, right: 0, bottom: 0, child: _BottomActions()),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonDetailView {
  const _PersonDetailView({
    required this.person,
    required this.incomeCent,
    required this.expenseCent,
    required this.records,
  });

  final PersonData person;
  final int incomeCent;
  final int expenseCent;
  final List<_PersonRecordView> records;
}

class _PersonRecordView {
  const _PersonRecordView({
    required this.recordId,
    required this.eventName,
    required this.isIncome,
    required this.amountCent,
    required this.paymentMethod,
    required this.occurredAt,
  });

  final String recordId;
  final String eventName;
  final bool isIncome;
  final int amountCent;
  final String paymentMethod;
  final DateTime occurredAt;
}

class _Hero extends StatelessWidget {
  const _Hero({required this.view});

  final _PersonDetailView view;

  @override
  Widget build(BuildContext context) {
    final person = view.person;
    final name = person.name.trim().isEmpty ? '未知' : person.name.trim();
    final relationship = person.relationship.trim().isEmpty ? '未设置' : person.relationship.trim();
    final phone = person.phone?.trim().isNotEmpty == true ? person.phone!.trim() : '未设置';
    final avatarUrl = person.avatarUrl?.trim();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          decoration: const BoxDecoration(
            color: AppColors.brandPrimary,
            borderRadius: BorderRadius.only(
              bottomLeft: AppRadii.heroBottom,
              bottomRight: AppRadii.heroBottom,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 4),
                  boxShadow: AppShadows.lg,
                ),
                clipBehavior: Clip.antiAlias,
                child: ContactAvatar(
                  name: name,
                  avatarUrl: avatarUrl,
                  size: 96,
                  shape: ContactAvatarShape.circle,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: AppTypography.base(
                  fontSize: 24,
                  fontWeight: AppTypography.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.white20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      relationship,
                      style: AppTypography.base(
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                        color: AppColors.indigo100,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: AppTypography.base(
                      fontSize: 14,
                      fontWeight: AppTypography.regular,
                      color: AppColors.indigo100,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    phone,
                    style: AppTypography.base(
                      fontSize: 14,
                      fontWeight: AppTypography.regular,
                      color: AppColors.indigo100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -32,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadii.br2xl,
              boxShadow: AppShadows.lg,
            ),
            child: Row(
              children: [
                _StatCell(
                  label: '收礼',
                  value: _formatCurrency(view.incomeCent),
                  valueColor: AppColors.green600,
                ),
                _VerticalDivider(),
                _StatCell(
                  label: '送礼',
                  value: _formatCurrency(view.expenseCent),
                  valueColor: AppColors.red500,
                ),
                _VerticalDivider(),
                _StatCell(
                  label: '差额',
                  value: _formatSigned(view.incomeCent - view.expenseCent),
                  valueColor: AppColors.indigo600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.gray100);
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
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
              fontSize: 18,
              fontWeight: AppTypography.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCards extends StatelessWidget {
  const _InfoCards({required this.person});

  final PersonData? person;

  @override
  Widget build(BuildContext context) {
    final note = person?.note?.trim().isNotEmpty == true ? person!.note!.trim() : '未设置';
    
    String birthdayValue = '未设置';
    Widget? birthdayTrailing;

    if (person?.birthday != null) {
      final b = person!.birthday!;
      birthdayValue = DateUtil.format(b);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      DateTime nextBirthday = DateTime(now.year, b.month, b.day);
      if (nextBirthday.isBefore(today)) {
        nextBirthday = DateTime(now.year + 1, b.month, b.day);
      }
      
      final diffDays = nextBirthday.difference(today).inDays;
      String badgeText = diffDays == 0 ? '今天' : '$diffDays天后';
      birthdayTrailing = _Badge(text: badgeText, bg: AppColors.pink100, fg: AppColors.pink600);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      child: PrototypeCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(
              iconBg: AppColors.pink50,
              iconFg: AppColors.pink500,
              icon: FontAwesomeIcons.cakeCandles,
              label: '生日',
              value: birthdayValue,
              trailing: birthdayTrailing,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              iconBg: AppColors.gray50,
              iconFg: AppColors.textTertiary,
              icon: FontAwesomeIcons.noteSticky,
              label: '备注',
              value: note,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.iconBg,
    required this.iconFg,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final Color iconBg;
  final Color iconFg;
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: FaIcon(icon, size: 14, color: iconFg),
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
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.base(
                  fontSize: 14,
                  fontWeight: AppTypography.medium,
                  color: AppColors.gray800,
                ),
              ),
            ],
          ),
        ),
        ...(trailing == null ? const <Widget>[] : <Widget>[trailing!]),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
      child: Text(
        text,
        style: AppTypography.base(
          fontSize: 12,
          fontWeight: AppTypography.regular,
          color: fg,
        ),
      ),
    );
  }
}

class _RecordsHeader extends StatelessWidget {
  const _RecordsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '往来记录',
            style: AppTypography.base(
              fontSize: 18,
              fontWeight: AppTypography.bold,
              color: AppColors.gray800,
            ),
          ),
          const Spacer(),
          Text(
            '全部',
            style: AppTypography.base(
              fontSize: 12,
              fontWeight: AppTypography.medium,
              color: AppColors.indigo600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordsCard extends StatelessWidget {
  const _RecordsCard({required this.records});

  final List<_PersonRecordView> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadii.br2xl,
          boxShadow: AppShadows.sm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '暂无往来记录',
            style: AppTypography.base(
              fontSize: 14,
              fontWeight: AppTypography.regular,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          for (var i = 0; i < records.length; i++)
            _RecordRow(
              record: records[i],
              borderBottom: i != records.length - 1,
            ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record, this.borderBottom = true});

  final _PersonRecordView record;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    final isIncome = record.isIncome;
    final iconBg = isIncome ? AppColors.green100 : AppColors.red100;
    final iconFg = isIncome ? AppColors.green600 : AppColors.red600;
    final icon = isIncome ? FontAwesomeIcons.gift : FontAwesomeIcons.handHoldingHeart;
    final amountColor = isIncome ? AppColors.green600 : AppColors.red500;
    final amount = _formatSignedAmount(record.amountCent, isIncome: isIncome);
    final subtitleLeft = (record.paymentMethod == '未设置' || record.paymentMethod.isEmpty) 
        ? '${isIncome ? '收礼' : '送礼'}' 
        : '${isIncome ? '收礼' : '送礼'} - ${record.paymentMethod}';
    final subtitleRight = DateUtil.format(record.occurredAt);
    return PrototypePressableRow(
      onTap: () => AppNav.push(context, RecordDetailPage(recordId: record.recordId), requiresLogin: true),
      borderBottom: borderBottom,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: FaIcon(icon, size: 16, color: iconFg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.eventName,
                        style: AppTypography.base(
                          fontSize: 14,
                          fontWeight: AppTypography.medium,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      amount,
                      style: AppTypography.base(
                        fontSize: 14,
                        fontWeight: AppTypography.bold,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitleLeft,
                        style: AppTypography.base(
                          fontSize: 12,
                          fontWeight: AppTypography.regular,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Text(
                      subtitleRight,
                      style: AppTypography.base(
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray100, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              bg: AppColors.indigo50,
              fg: AppColors.indigo700,
              icon: FontAwesomeIcons.bell,
              label: '设提醒',
              shadow: false,
              onTap: () => AppNav.push(context, const RemindersPage(), requiresLogin: true),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              bg: AppColors.brandPrimary,
              fg: AppColors.white,
              icon: FontAwesomeIcons.plus,
              label: '记一笔',
              shadow: true,
              onTap: () => AppNav.push(context, const RecordAddPage(), requiresLogin: true),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(int cent) {
  final absCent = cent.abs();
  final yuan = (absCent / 100).toStringAsFixed(2);
  final parts = yuan.split('.');
  final intPart = parts[0];
  final fracPart = parts[1];
  final grouped = intPart.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '¥$grouped.$fracPart';
}

String _formatSigned(int cent) {
  final symbol = cent >= 0 ? '+' : '-';
  return '$symbol${_formatCurrency(cent).replaceFirst('¥', '')}';
}

String _formatSignedAmount(int cent, {required bool isIncome}) {
  final symbol = isIncome ? '+' : '-';
  final value = (cent.abs() / 100).toStringAsFixed(2);
  final parts = value.split('.');
  final grouped = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '$symbol$grouped.${parts[1]}';
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.label,
    required this.shadow,
    required this.onTap,
  });

  final Color bg;
  final Color fg;
  final IconData icon;
  final String label;
  final bool shadow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: shadow ? AppShadows.brandSoft : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 16, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.base(
                fontSize: 14,
                fontWeight: AppTypography.medium,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

