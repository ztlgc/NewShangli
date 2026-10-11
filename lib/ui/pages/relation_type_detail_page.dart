import 'package:flutter/material.dart';

import '../../data/local/drift/app_database.dart';
import '../app_database_scope.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../navigation.dart';
import '../ui_kit.dart';
import '../widgets/person_display_row.dart';
import 'person_detail_page.dart';

import '../app_icons.dart';

class RelationTypeDetailPage extends StatelessWidget {
  const RelationTypeDetailPage({super.key, required this.type});

  final RelationType type;

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: Column(
        children: [
          AppTopBar(
            title: type.name,
            left: AppIconButton(
              icon: const Icon(AppIcons.chevronLeft, size: 14),
              backgroundColor: AppColors.gray100,
              foregroundColor: AppColors.textSecondary,
              onPressed: () => AppNav.pop(context),
              radius: 12,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Person>>(
              stream: db.personsDao.watchAllInAllBooks(),
              builder: (context, snapshot) {
                final contacts = _contactsForType(snapshot.data ?? const []);
                if (snapshot.connectionState == ConnectionState.waiting &&
                    contacts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (contacts.isEmpty) {
                  return _EmptyTypeContacts(typeName: type.name);
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
                  itemCount: contacts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                        child: Text(
                          '${contacts.length} 位联系人',
                          style: AppTypography.base(
                            fontSize: 12,
                            fontWeight: AppTypography.semibold,
                            color: context.appColors.textTertiary,
                            letterSpacing: 1,
                          ),
                        ),
                      );
                    }
                    final contact = contacts[index - 1];
                    return _TypeContactRow(
                      person: contact,
                      borderBottom: index != contacts.length,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Person> _contactsForType(List<Person> persons) {
    final key = type.name.trim().toLowerCase();
    final contacts = persons
        .where((person) => person.relationshipType.trim().toLowerCase() == key)
        .toList();
    contacts.sort((a, b) => a.name.compareTo(b.name));
    return contacts;
  }
}

class _EmptyTypeContacts extends StatelessWidget {
  const _EmptyTypeContacts({required this.typeName});

  final String typeName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        AppCard(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                '暂无$typeName联系人',
                style: AppTypography.base(
                  fontSize: 14,
                  fontWeight: AppTypography.medium,
                  color: context.appColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeContactRow extends StatefulWidget {
  const _TypeContactRow({required this.person, required this.borderBottom});

  final Person person;
  final bool borderBottom;

  @override
  State<_TypeContactRow> createState() => _TypeContactRowState();
}

class _TypeContactRowState extends State<_TypeContactRow> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => AppNav.push(
        context,
        PersonDetailPage(personId: widget.person.personId),
      ),
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        color: _pressed ? colors.surfacePressed : Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: widget.borderBottom
                ? Border(
                    bottom: BorderSide(color: colors.borderDivider, width: 1),
                  )
                : null,
          ),
          child: PersonDisplayRow(
            name: widget.person.name,
            subtitle: widget.person.relationshipType,
            avatarUrl: widget.person.avatarUri,
          ),
        ),
      ),
    );
  }
}
