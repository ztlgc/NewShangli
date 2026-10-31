import 'package:flutter/material.dart';

import '../../data/local/drift/app_database.dart';
import '../app_database_scope.dart';
import '../app_dialog.dart';
import '../app_icons.dart';
import '../app_notification_tokens.dart';
import '../app_notifier.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../components.dart';
import '../contact_avatar.dart';
import '../edit_protection_guard.dart';
import '../navigation.dart';
import '../ui_kit.dart';
import '../widgets/swipe_action_row.dart';

class RecycleBinPage extends StatelessWidget {
  const RecycleBinPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const AppScaffold(body: _RecycleBinContent());
}

class _RecycleBinContent extends StatefulWidget {
  const _RecycleBinContent();

  @override
  State<_RecycleBinContent> createState() => _RecycleBinContentState();
}

class _RecycleBinContentState extends State<_RecycleBinContent> {
  final _searchController = TextEditingController();
  final _selectedIds = <String>{};
  AppDatabase? _db;
  late Stream<List<DeletedGiftRecordWithPerson>> _recordsStream;
  late Stream<List<Person>> _personsStream;
  late Stream<List<AccountBook>> _booksStream;
  bool _personsTab = false;
  bool _selecting = false;
  bool _busy = false;
  bool _executing = false;
  String _keyword = '';
  String? _openSwipeId;
  int _retry = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = AppDatabaseScope.of(context);
    if (identical(_db, db)) return;
    _db = db;
    _subscribe();
    _selectedIds.clear();
    _selecting = false;
  }

  void _subscribe() {
    _recordsStream = _db!.giftRecordsDao.watchDeletedWithPerson();
    _personsStream = _db!.personsDao.watchDeleted();
    _booksStream = _db!.accountBooksDao.watchAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exitSelection() {
    if (_busy) return;
    setState(() {
      _selecting = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    if (_busy) return;
    setState(() {
      _selecting = true;
      _openSwipeId = null;
      if (!_selectedIds.add(id)) _selectedIds.remove(id);
    });
  }

  void _switchTab(bool persons) {
    if (_personsTab == persons || _busy) return;
    setState(() {
      _personsTab = persons;
      _selecting = false;
      _selectedIds.clear();
      _keyword = '';
      _openSwipeId = null;
      _searchController.clear();
    });
  }

  void _back() {
    if (_busy) return;
    if (_selecting) {
      _exitSelection();
    } else if (_openSwipeId != null) {
      _closeSwipe();
    } else {
      AppNav.pop(context);
    }
  }

  void _closeSwipe() {
    if (_openSwipeId != null) setState(() => _openSwipeId = null);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_selecting && !_busy && _openSwipeId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) {
          if (_selecting) {
            _exitSelection();
          } else {
            _closeSwipe();
          }
        }
      },
      child: StreamBuilder<List<DeletedGiftRecordWithPerson>>(
        key: ValueKey(_retry),
        stream: _recordsStream,
        builder: (context, recordSnapshot) => StreamBuilder<List<Person>>(
          stream: _personsStream,
          builder: (context, personSnapshot) => StreamBuilder<List<AccountBook>>(
            stream: _booksStream,
            builder: (context, bookSnapshot) {
              final records = recordSnapshot.data ?? const [];
              final persons = personSnapshot.data ?? const [];
              final books = {
                for (final book in bookSnapshot.data ?? <AccountBook>[])
                  book.bookId: book.name,
              };
              final relatedCounts = <String, int>{};
              for (final item in records) {
                relatedCounts.update(
                  item.record.personId,
                  (value) => value + 1,
                  ifAbsent: () => 1,
                );
              }
              final allItems = _personsTab
                  ? persons
                        .map(
                          (p) => _RecycleItem.person(
                            p,
                            relatedCounts[p.personId] ?? 0,
                          ),
                        )
                        .toList()
                  : records
                        .map(
                          (r) => _RecycleItem.record(
                            r,
                            books[r.record.bookId] ?? '原账簿',
                          ),
                        )
                        .toList();
              final items = allItems
                  .where(
                    (item) => item.searchText.toLowerCase().contains(_keyword),
                  )
                  .toList();
              final selected = items
                  .where((item) => _selectedIds.contains(item.id))
                  .toList();
              final error =
                  (_personsTab ? personSnapshot.error : recordSnapshot.error) ??
                  (!_personsTab ? bookSnapshot.error : null);
              final loading = _personsTab
                  ? !personSnapshot.hasData && !personSnapshot.hasError
                  : (!recordSnapshot.hasData && !recordSnapshot.hasError) ||
                        (!bookSnapshot.hasData && !bookSnapshot.hasError);
              final groupCounts = <String, int>{};
              for (final item in items) {
                groupCounts.update(
                  _groupLabel(item.deletedAt),
                  (n) => n + 1,
                  ifAbsent: () => 1,
                );
              }
              return AbsorbPointer(
                absorbing: _busy,
                child: Column(
                  children: [
                    AppTopBar(
                      title: _selecting ? '已选择 ${selected.length} 项' : '回收站',
                      left: AppIconButton(
                        icon: Icon(
                          _selecting ? AppIcons.x : AppIcons.arrowLeft,
                          size: 18,
                        ),
                        size: AppTokens.tapTargetMin,
                        backgroundColor: Colors.transparent,
                        semanticLabel: _selecting ? '退出选择' : '返回',
                        onPressed: _back,
                      ),
                      right: TextButton(
                        onPressed: _selecting
                            ? _exitSelection
                            : error != null || loading || items.isEmpty
                            ? null
                            : () => setState(() {
                                _selecting = true;
                                _openSwipeId = null;
                              }),
                        child: Text(_selecting ? '取消' : '管理'),
                      ),
                    ),
                    _RecycleTabs(
                      persons: _personsTab,
                      recordCount: recordSnapshot.hasData
                          ? records.length
                          : null,
                      personCount: personSnapshot.hasData
                          ? persons.length
                          : null,
                      onChanged: _switchTab,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: AppSearchField(
                        controller: _searchController,
                        hintText: _personsTab ? '搜索姓名、关系、电话' : '搜索姓名、事由、账簿',
                        onChanged: (value) => setState(() {
                          _keyword = value.trim().toLowerCase();
                          _selectedIds.clear();
                          _openSwipeId = null;
                        }),
                      ),
                    ),
                    if (_selecting || _keyword.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _keyword.isEmpty
                                    ? '选择要处理的内容'
                                    : '找到 ${items.length} 项',
                                style: _textStyle(context, 12, secondary: true),
                              ),
                            ),
                            if (_selecting)
                              TextButton.icon(
                                onPressed: items.isEmpty
                                    ? null
                                    : () => setState(() {
                                        if (selected.length == items.length) {
                                          _selectedIds.clear();
                                        } else {
                                          _selectedIds
                                            ..clear()
                                            ..addAll(
                                              items.map((item) => item.id),
                                            );
                                        }
                                      }),
                                icon: Icon(
                                  selected.length == items.length
                                      ? AppIcons.check
                                      : AppIcons.square,
                                  size: 16,
                                ),
                                label: Text(
                                  selected.length == items.length
                                      ? '取消全选'
                                      : _keyword.isEmpty
                                      ? '全选'
                                      : '全选结果',
                                ),
                              )
                            else
                              const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    Expanded(
                      child: NotificationListener<ScrollStartNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.axis == Axis.vertical &&
                              notification.dragDetails != null) {
                            _closeSwipe();
                          }
                          return false;
                        },
                        child: CustomScrollView(
                          key: ValueKey(_personsTab),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          slivers: [
                            if (error != null)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _StateMessage(
                                  icon: AppIcons.triangleAlert,
                                  title: '加载失败',
                                  message: '暂时无法读取已删除内容，请重试',
                                  action: TextButton(
                                    onPressed: () => setState(() {
                                      _subscribe();
                                      _retry++;
                                    }),
                                    child: const Text('重新加载'),
                                  ),
                                ),
                              )
                            else if (loading)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else if (items.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _StateMessage(
                                  icon: _keyword.isNotEmpty
                                      ? AppIcons.search
                                      : _personsTab
                                      ? AppIcons.usersRound
                                      : AppIcons.packageOpen,
                                  title: _keyword.isNotEmpty
                                      ? '没有找到相关内容'
                                      : _personsTab
                                      ? '暂无已删除联系人'
                                      : '暂无已删除收支记录',
                                  message: _keyword.isNotEmpty
                                      ? '试试其他关键词，或清除搜索条件'
                                      : _personsTab
                                      ? '删除后的联系人会显示在这里'
                                      : '删除后的收支记录会显示在这里',
                                  action: _keyword.isEmpty
                                      ? null
                                      : TextButton(
                                          onPressed: () => setState(() {
                                            _searchController.clear();
                                            _keyword = '';
                                            _selectedIds.clear();
                                            _openSwipeId = null;
                                          }),
                                          child: const Text('清除搜索'),
                                        ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  24,
                                ),
                                sliver: SliverList.builder(
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    final group = _groupLabel(item.deletedAt);
                                    final first =
                                        index == 0 ||
                                        _groupLabel(
                                              items[index - 1].deletedAt,
                                            ) !=
                                            group;
                                    final last =
                                        index == items.length - 1 ||
                                        _groupLabel(
                                              items[index + 1].deletedAt,
                                            ) !=
                                            group;
                                    return Column(
                                      key: ValueKey(item.id),
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (first)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 18,
                                              bottom: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    group,
                                                    style: _textStyle(
                                                      context,
                                                      12,
                                                      secondary: true,
                                                      bold: true,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '${groupCounts[group]} ${_personsTab ? '位联系人' : '条记录'}',
                                                  style: _textStyle(
                                                    context,
                                                    11,
                                                    secondary: true,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        _RecycleRow(
                                          key: ValueKey(
                                            'recycle-row-${item.id}',
                                          ),
                                          item: item,
                                          selecting: _selecting,
                                          selected: _selectedIds.contains(
                                            item.id,
                                          ),
                                          first: first,
                                          last: last,
                                          swipeActive: _openSwipeId == item.id,
                                          onActivateSwipe: () => setState(
                                            () => _openSwipeId = item.id,
                                          ),
                                          onCloseSwipe: () {
                                            if (_openSwipeId == item.id) {
                                              _closeSwipe();
                                            }
                                          },
                                          onSelect: () =>
                                              _toggleSelection(item.id),
                                          onRestore: () =>
                                              _perform([item], purge: false),
                                          onPurge: () =>
                                              _perform([item], purge: true),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_executing) const LinearProgressIndicator(minHeight: 2),
                    if (_selecting)
                      _SelectionBar(
                        count: selected.length,
                        busy: _executing,
                        onRestore:
                            error != null ||
                                loading ||
                                selected.isEmpty ||
                                _busy
                            ? null
                            : () => _perform(selected, purge: false),
                        onPurge:
                            error != null ||
                                loading ||
                                selected.isEmpty ||
                                _busy
                            ? null
                            : () => _perform(selected, purge: true),
                      )
                    else if (items.isNotEmpty && error == null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Text(
                          '左滑显示恢复与删除，长按可多选',
                          textAlign: TextAlign.center,
                          style: _textStyle(context, 11, secondary: true),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _perform(List<_RecycleItem> items, {required bool purge}) async {
    if (_busy || items.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _openSwipeId = null;
    });
    final db = _db!;
    final persons = items.first.person != null;
    final ids = items.map((item) => item.id).toSet();
    try {
      final authorized = await requireEditProtectionPassword(
        context,
        title: purge
            ? '彻底删除${persons ? '联系人' : '记录'}'
            : '恢复${persons ? '联系人' : '记录'}',
      );
      if (!mounted || !authorized) return;

      final related = persons && purge
          ? await (db.select(
              db.giftRecords,
            )..where((t) => t.personId.isIn(ids))).get()
          : <GiftRecord>[];
      if (!mounted) return;
      if (purge) {
        final activeCount = related.where((r) => r.deletedAt == null).length;
        final confirmed = await AppDialog.confirm(
          context,
          title: '彻底删除这 ${items.length} ${persons ? '位联系人' : '条记录'}？',
          message: '删除后无法恢复，请确认已不再需要。',
          confirmLabel: '彻底删除',
          danger: true,
          tone: AppNotificationTone.error,
          icon: AppIcons.trash2,
          content: _PurgeDetails(
            items: items,
            impact: persons
                ? '将同时彻底删除关联的 ${related.length} 条记录${activeCount > 0 ? '（包含 $activeCount 条未删除记录）' : ''}及联系人关系，无法恢复。'
                : '对应联系人将保留。',
          ),
        );
        if (!mounted || confirmed != true) return;
      } else if (persons) {
        final confirmed = await AppDialog.confirm(
          context,
          title: '恢复这 ${items.length} 位联系人？',
          message: '仅恢复联系人，相关收支记录仍留在回收站，可在「收支记录」中单独恢复。',
          confirmLabel: '恢复联系人',
          tone: AppNotificationTone.info,
          icon: AppIcons.rotateCcw,
        );
        if (!mounted || confirmed != true) return;
      } else {
        final personIds = items
            .map((item) => item.record!.record.personId)
            .toSet();
        final deletedPersons =
            await (db.select(db.persons)
                  ..where((t) => t.personId.isIn(personIds))
                  ..where((t) => t.deletedAt.isNotNull()))
                .get();
        if (!mounted) return;
        if (deletedPersons.isNotEmpty) {
          final names = deletedPersons
              .take(3)
              .map((p) => '「${p.name}」')
              .join('、');
          final confirmed = await AppDialog.confirm(
            context,
            title: '同时恢复关联联系人？',
            message:
                '恢复这 ${items.length} 条记录时，将同时恢复$names${deletedPersons.length > 3 ? '等 ${deletedPersons.length} 位联系人' : ''}。其他已删除记录不会恢复。',
            confirmLabel: '同时恢复',
            tone: AppNotificationTone.info,
            icon: AppIcons.rotateCcw,
          );
          if (!mounted || confirmed != true) return;
        }
      }

      setState(() => _executing = true);
      final count = await db.transaction(() async {
        // 联系人的级联删除范围必须与刚确认的内容一致。
        if (persons && purge) {
          final current = await (db.select(
            db.giftRecords,
          )..where((t) => t.personId.isIn(ids))).get();
          final expected = {for (final r in related) r.recordId: r.deletedAt};
          if (current.length != expected.length ||
              current.any(
                (r) =>
                    !expected.containsKey(r.recordId) ||
                    expected[r.recordId] != r.deletedAt,
              )) {
            throw StateError('关联记录已变化，请重新确认');
          }
        }
        var changed = 0;
        for (final item in items) {
          if (persons) {
            final current = await db.personsDao.findByIdAny(item.id);
            if (current?.deletedAt == null) continue;
            changed += purge
                ? await db.personsDao.purgeById(item.id)
                : await db.personsDao.restoreById(item.id);
          } else {
            final current = await db.giftRecordsDao.findByIdAny(item.id);
            if (current?.deletedAt == null) continue;
            changed += purge
                ? await db.giftRecordsDao.purgeById(item.id)
                : await db.giftRecordsDao.restoreById(item.id);
          }
        }
        return changed;
      });
      if (!mounted) return;
      setState(() {
        _selectedIds.clear();
        _selecting = false;
      });
      if (count == 0) {
        AppNotifier.info(context, '所选内容已变化，请查看最新列表');
      } else {
        AppNotifier.success(
          context,
          '已${purge ? '彻底删除' : '恢复'} $count ${persons ? '位联系人' : '条记录'}',
        );
      }
    } catch (error) {
      if (!mounted) return;
      AppNotifier.error(context, '${purge ? '彻底删除' : '恢复'}失败，请重试：$error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _executing = false;
        });
      }
    }
  }
}

class _RecycleItem {
  _RecycleItem.record(DeletedGiftRecordWithPerson value, String book)
    : record = value,
      person = null,
      relatedCount = 0,
      bookName = book;

  _RecycleItem.person(Person value, this.relatedCount)
    : person = value,
      record = null,
      bookName = '';

  final DeletedGiftRecordWithPerson? record;
  final Person? person;
  final String bookName;
  final int relatedCount;

  String get id => person?.personId ?? record!.record.recordId;
  String get name =>
      person?.name ??
      ((record!.personName ?? '').trim().isEmpty
          ? '已删除联系人'
          : record!.personName!.trim());
  String? get avatar => person?.avatarUri ?? record?.personAvatarUri;
  int? get deletedAt => person?.deletedAt ?? record?.record.deletedAt;
  String get event => (record!.record.eventName ?? '').trim().isEmpty
      ? '未设置事由'
      : record!.record.eventName!.trim();
  String get direction => record!.record.direction == '收入' ? '收礼' : '送礼';
  String get amount => _formatAmount(
    record!.record.amountCent,
    record!.record.direction == '收入' ? '+' : '−',
  );
  String get searchText => person != null
      ? '$name ${person!.relationshipType} ${person!.phone ?? ''}'
      : '$name $event $bookName';
}

class _RecycleTabs extends StatelessWidget {
  const _RecycleTabs({
    required this.persons,
    required this.recordCount,
    required this.personCount,
    required this.onChanged,
  });
  final bool persons;
  final int? recordCount, personCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      color: colors.surfaceCard,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final isPerson in [false, true]) ...[
            if (isPerson) const SizedBox(width: 24),
            Flexible(
              child: Semantics(
                selected: persons == isPerson,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: persons == isPerson
                            ? colors.brandPrimary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => onChanged(isPerson),
                    style: TextButton.styleFrom(
                      foregroundColor: persons == isPerson
                          ? colors.textPrimary
                          : colors.textTertiary,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: Text(
                      '${isPerson ? '联系人' : '收支记录'}  ${isPerson ? personCount ?? '—' : recordCount ?? '—'}',
                      style: AppTypography.base(
                        fontSize: 15,
                        fontWeight: persons == isPerson
                            ? AppTypography.semibold
                            : AppTypography.regular,
                        color: persons == isPerson
                            ? colors.textPrimary
                            : colors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecycleRow extends StatelessWidget {
  const _RecycleRow({
    super.key,
    required this.item,
    required this.selecting,
    required this.selected,
    required this.first,
    required this.last,
    required this.swipeActive,
    required this.onActivateSwipe,
    required this.onCloseSwipe,
    required this.onSelect,
    required this.onRestore,
    required this.onPurge,
  });
  final _RecycleItem item;
  final bool selecting, selected, first, last, swipeActive;
  final VoidCallback onActivateSwipe,
      onCloseSwipe,
      onSelect,
      onRestore,
      onPurge;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final border = BorderSide(color: colors.borderDefault);
    final radius = BorderRadius.vertical(
      top: first ? AppRadii.r2xl : Radius.zero,
      bottom: last ? AppRadii.r2xl : Radius.zero,
    );
    final record = item.record?.record;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border(
          top: first ? border : BorderSide.none,
          left: border,
          right: border,
          bottom: last ? border : BorderSide.none,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SwipeActionRow(
          active: swipeActive,
          enabled: !selecting,
          onActivate: onActivateSwipe,
          onClose: onCloseSwipe,
          onRestore: onRestore,
          onDelete: onPurge,
          child: ColoredBox(
            color: selected ? colors.surfaceSubtle : colors.surfaceCard,
            child: AppPressableRow(
              onTap: selecting ? onSelect : onCloseSwipe,
              onLongPress: onSelect,
              borderBottom: false,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Semantics(
                      selected: selecting ? selected : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selecting)
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: Checkbox(
                                value: selected,
                                onChanged: (_) => onSelect(),
                                semanticLabel: '选择${item.name}',
                                activeColor: colors.brandPrimary,
                                checkColor: colors.textInverse,
                                side: BorderSide(color: colors.borderDefault),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: ContactAvatar(
                                name: item.name,
                                avatarUrl: item.avatar,
                                size: 36,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final compact =
                                    constraints.maxWidth < 235 ||
                                    (record != null &&
                                        item.amount.length > 14) ||
                                    MediaQuery.textScalerOf(context).scale(16) >
                                        22;
                                final phone = item.person?.phone?.trim() ?? '';
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (record == null || compact) ...[
                                      Text(
                                        item.name,
                                        style: _textStyle(
                                          context,
                                          16,
                                          bold: true,
                                        ),
                                      ),
                                      if (record != null) ...[
                                        const SizedBox(height: 4),
                                        _Amount(item: item),
                                      ],
                                    ] else
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              style: _textStyle(
                                                context,
                                                16,
                                                bold: true,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _Amount(item: item),
                                        ],
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            record != null
                                                ? '${item.direction} · ${item.event}'
                                                : '${item.person!.relationshipType}${phone.isEmpty ? '' : ' · $phone'}',
                                            style: _textStyle(
                                              context,
                                              12,
                                              secondary: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Semantics(
                                          label: _deletedTime(item.deletedAt),
                                          excludeSemantics: true,
                                          child: Text(
                                            _deletedClock(item.deletedAt),
                                            style: _textStyle(
                                              context,
                                              11,
                                              secondary: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      record != null
                                          ? '${item.bookName} · ${_shortDate(record.occurredAt)}'
                                          : item.relatedCount > 0
                                          ? '关联 ${item.relatedCount} 条已删除记录'
                                          : '无已删除的关联记录',
                                      style: _textStyle(
                                        context,
                                        11,
                                        secondary: true,
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
                  ),
                  if (!last)
                    Padding(
                      padding: const EdgeInsets.only(left: 62, right: 14),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.borderSubtle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.item});
  final _RecycleItem item;

  @override
  Widget build(BuildContext context) => Text(
    item.amount,
    style: AppTypography.base(
      fontSize: 16,
      fontWeight: AppTypography.semibold,
      color: item.record!.record.direction == '收入'
          ? context.appColors.stateSuccess
          : context.appColors.stateDanger,
    ),
  );
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.busy,
    required this.onRestore,
    required this.onPurge,
  });
  final int count;
  final bool busy;
  final VoidCallback? onRestore;
  final VoidCallback? onPurge;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final delete = OutlinedButton.icon(
            onPressed: onPurge,
            icon: const Icon(AppIcons.trash2, size: 16),
            label: const Text('彻底删除'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.stateDangerStrong,
              minimumSize: const Size(0, 48),
              side: BorderSide(color: colors.stateDangerSoft),
              shape: RoundedRectangleBorder(borderRadius: AppRadii.brLg),
            ),
          );
          final restore = AppPrimaryButton(
            label: busy ? '正在处理…' : '恢复 $count 项',
            icon: busy ? null : AppIcons.rotateCcw,
            onTap: onRestore,
          );
          if (constraints.maxWidth < 320 ||
              MediaQuery.textScalerOf(context).scale(14) > 20) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [restore, const SizedBox(height: 8), delete],
            );
          }
          return Row(
            children: [
              Expanded(flex: 2, child: delete),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: restore),
            ],
          );
        },
      ),
    );
  }
}

class _PurgeDetails extends StatelessWidget {
  const _PurgeDetails({required this.items, required this.impact});
  final List<_RecycleItem> items;
  final String impact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appColors.surfaceSubtle,
          borderRadius: AppRadii.brLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < items.take(5).length; index++) ...[
              if (index > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: AppDivider(),
                ),
              Text(
                items[index].record == null
                    ? items[index].name
                    : '${items[index].name} · ${items[index].event}',
                style: _textStyle(context, 14, bold: true),
              ),
              const SizedBox(height: 4),
              Text(
                items[index].record == null
                    ? items[index].person!.relationshipType
                    : '${items[index].direction} ¥${_formatAmount(items[index].record!.record.amountCent, '')}',
                style: _textStyle(context, 13, secondary: true),
              ),
            ],
            if (items.length > 5) ...[
              const SizedBox(height: 12),
              Text(
                '另有 ${items.length - 5} 项，共 ${items.length} 项',
                style: _textStyle(context, 12, secondary: true),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(impact, style: _textStyle(context, 13, secondary: true)),
    ],
  );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: context.appColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: _textStyle(context, 16, bold: true),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: _textStyle(context, 13, secondary: true),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    ),
  );
}

TextStyle _textStyle(
  BuildContext context,
  double size, {
  bool secondary = false,
  bool bold = false,
}) => AppTypography.base(
  fontSize: size,
  fontWeight: bold ? AppTypography.semibold : AppTypography.regular,
  color: secondary
      ? context.appColors.textTertiary
      : context.appColors.textPrimary,
);

String _formatAmount(int cent, String sign) {
  final yuan = cent.abs() ~/ 100;
  final fraction = (cent.abs() % 100).toString().padLeft(2, '0');
  final grouped = yuan.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '$sign$grouped.$fraction';
}

String _shortDate(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

String _groupLabel(int? timestamp) {
  if (timestamp == null) return '删除时间未知';
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final now = DateTime.now();
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) return '今天删除';
  if (day == DateTime(now.year, now.month, now.day - 1)) return '昨天删除';
  return '${_shortDate(timestamp)} 删除';
}

String _deletedTime(int? timestamp) {
  if (timestamp == null) return '删除时间未知';
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final group = _groupLabel(timestamp);
  final clock =
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  if (group == '今天删除') return '今天 $clock 删除';
  if (group == '昨天删除') return '昨天 $clock 删除';
  return '${_shortDate(timestamp)} $clock 删除';
}

String _deletedClock(int? timestamp) {
  if (timestamp == null) return '时间未知';
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
