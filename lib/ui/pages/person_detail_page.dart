import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_data.dart';
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

/// 页面：关系人管理 - 详情页
/// 对照原型：prototype/index.html -> "详情页"
class PersonDetailPage extends StatelessWidget {
  const PersonDetailPage({super.key, this.personId});

  final String? personId;

  @override
  Widget build(BuildContext context) {
    final data = AppDataScope.of(context);
    final person = personId == null ? null : data.findPerson(personId!);
    if (personId != null && person == null) {
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
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: _Canvas(personId: personId, person: person),
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas({required this.personId, required this.person});

  final String? personId;
  final PersonData? person;

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
                onPressed: () => AppNav.push(context, PersonEditPage(personId: personId), requiresLogin: true),
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
                  _Hero(person: person),
                  _InfoCards(person: person),
                  const _RecordsHeader(),
                  const _RecordsCard(),
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

class _Hero extends StatelessWidget {
  const _Hero({required this.person});

  final PersonData? person;

  @override
  Widget build(BuildContext context) {
    final name = person?.name.trim().isNotEmpty == true ? person!.name.trim() : '未知';
    final relationship = person?.relationship.trim().isNotEmpty == true ? person!.relationship.trim() : '未设置';
    final phone = person?.phone?.trim().isNotEmpty == true ? person!.phone!.trim() : '未设置';
    final avatarUrl = person?.avatarUrl?.trim();
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
              children: const [
                _StatCell(
                  label: '收礼',
                  value: '¥2,000',
                  valueColor: AppColors.green600,
                ),
                _VerticalDivider(),
                _StatCell(
                  label: '送礼',
                  value: '¥800',
                  valueColor: AppColors.red500,
                ),
                _VerticalDivider(),
                _StatCell(
                  label: '差额',
                  value: '+1,200',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      child: PrototypeCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const _InfoRow(
              iconBg: AppColors.pink50,
              iconFg: AppColors.pink500,
              icon: FontAwesomeIcons.cakeCandles,
              label: '生日',
              value: '1990年8月15日 (农历七月廿六)',
              trailing: _Badge(text: '5天后', bg: AppColors.pink100, fg: AppColors.pink600),
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
  const _RecordsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.br2xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: const [
          _RecordRow(
            iconBg: AppColors.green100,
            iconFg: AppColors.green600,
            icon: FontAwesomeIcons.gift,
            title: '结婚礼金',
            amount: '+2,000',
            amountColor: AppColors.green600,
            subtitleLeft: '收礼 - 微信',
            subtitleRight: '2026-02-10',
          ),
          PrototypeDivider(color: AppColors.borderDivider),
          _RecordRow(
            iconBg: AppColors.red100,
            iconFg: AppColors.red600,
            icon: FontAwesomeIcons.handHoldingHeart,
            title: '孩子满月',
            amount: '-800',
            amountColor: AppColors.red500,
            subtitleLeft: '送礼 - 现金',
            subtitleRight: '2025-08-12',
          ),
          PrototypeDivider(color: AppColors.borderDivider),
          _RecordRow(
            iconBg: AppColors.green100,
            iconFg: AppColors.green600,
            icon: FontAwesomeIcons.envelopeOpenText,
            title: '乔迁红包',
            amount: '+600',
            amountColor: AppColors.green600,
            subtitleLeft: '收礼 - 支付宝',
            subtitleRight: '2024-12-01',
            borderBottom: false,
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.iconBg,
    required this.iconFg,
    required this.icon,
    required this.title,
    required this.amount,
    required this.amountColor,
    required this.subtitleLeft,
    required this.subtitleRight,
    this.borderBottom = true,
  });

  final Color iconBg;
  final Color iconFg;
  final IconData icon;
  final String title;
  final String amount;
  final Color amountColor;
  final String subtitleLeft;
  final String subtitleRight;
  final bool borderBottom;

  @override
  Widget build(BuildContext context) {
    return PrototypePressableRow(
      onTap: () => AppNav.push(context, const RecordDetailPage(recordId: 'r_20260210_zw')),
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
                        title,
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

