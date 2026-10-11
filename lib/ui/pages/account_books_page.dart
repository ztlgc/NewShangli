import 'package:flutter/material.dart';

import '../../data/local/drift/app_database.dart';
import '../../import/default_book_service.dart';
import '../../utils/date_util.dart';
import '../app_database_scope.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../components.dart';
import '../edit_protection_guard.dart';
import '../navigation.dart';
import '../ui_kit.dart';
import 'account_book_detail_page.dart';
import 'account_book_edit_page.dart';

import '../app_icons.dart';

import '../app_layout.dart';

/// 页面：系统设置 - 账簿管理
/// 对照原型：prototype/index.html -> "账簿管理"
class AccountBooksPage extends StatelessWidget {
  const AccountBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: _Canvas(),
    );
  }
}

class _Canvas extends StatefulWidget {
  const _Canvas();

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _openBook(AccountBook book) async {
    // 账簿列表点击后统一进入详情页，再由详情页承接后续操作入口。
    AppNav.push(context, AccountBookDetailPage(bookId: book.bookId));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        AppTopBar(
          title: '账簿管理',
          left: AppIconButton(
            icon: const Icon(AppIcons.arrowLeft, size: 18),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            onPressed: () => AppNav.pop(context),
          ),
          right: AppIconButton(
            icon: const Icon(AppIcons.plus, size: 16),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            onPressed: () async {
              await AppNav.push<bool>(context, const AccountBookEditPage());
              if (!context.mounted) return;
              setState(() {});
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<String>(
            future: DefaultBookService().ensureDefaultBookId(
              AppDatabaseScope.of(context),
            ),
            builder: (context, _) {
              return StreamBuilder<List<AccountBook>>(
                stream: AppDatabaseScope.of(context).accountBooksDao.watchAll(),
                builder: (context, snapshot) {
                  final books = snapshot.data ?? const <AccountBook>[];
                  if (books.isEmpty) {
                    return Center(
                      child: Text(
                        '暂无账簿',
                        style: AppTypography.base(
                          fontSize: AppTypography.fs14,
                          fontWeight: AppTypography.regular,
                          color: colors.textSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: AppLayout.pagePadding,
                    itemCount: books.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final b = books[i];
                      return _BookCardDb(
                        db: AppDatabaseScope.of(context),
                        book: b,
                        onOpen: () => _openBook(b),
                        onEdit: () async {
                          final ok = await requireEditProtectionPassword(
                            context,
                            title: '编辑账簿',
                          );
                          if (!ok) return;
                          if (!context.mounted) return;
                          await AppNav.push<bool>(
                            context,
                            AccountBookEditPage(bookId: b.bookId),
                          );
                          if (!context.mounted) return;
                          setState(() {});
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BookCardDb extends StatelessWidget {
  const _BookCardDb({
    required this.db,
    required this.book,
    required this.onOpen,
    required this.onEdit,
  });

  final AppDatabase db;
  final AccountBook book;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDefault = book.isDefault == 1;

    final theme =
        _parseHexColorOrNull(book.themeColor) ?? AppColors.brandPrimary;
    final themeForeground = colors.foregroundFor(theme);
    final themeSoft = theme.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.28 : 0.14,
    );
    final icon = _iconByReasonType(book.reasonType);

    final subtitle = (book.description ?? '').trim().isEmpty
        ? '点击查看账簿详情'
        : book.description!.trim();

    return PressableScale(
      onTap: onOpen,
      child: Container(
        key: ValueKey<String>('book_card_${book.bookId}'),
        padding: AppLayout.pagePadding,
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.sm,
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDefault) ...[
                  const Align(
                    alignment: Alignment.centerRight,
                    child: AppPill(
                      label: '当前使用',
                      background: AppColors.gray100,
                      foreground: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: themeSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, size: 20, color: themeForeground),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.name,
                            style: AppTypography.base(
                              fontSize: 16,
                              fontWeight: AppTypography.bold,
                              color: colors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTypography.base(
                              fontSize: 12,
                              fontWeight: AppTypography.regular,
                              color: colors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '账簿时间：${_formatBookTime(book.bookTime)}',
                            style: AppTypography.base(
                              fontSize: 11,
                              fontWeight: AppTypography.regular,
                              color: colors.textTertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.brandSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '事由：${isDefault ? '全部事由' : book.reasonType}',
                              style: AppTypography.base(
                                fontSize: 11,
                                fontWeight: AppTypography.medium,
                                color: colors.brandOnSoft,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: colors.borderDivider),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StreamBuilder<int>(
                      stream: isDefault
                          ? db.giftRecordsDao.watchCountInDefaultScope(
                              book.bookId,
                            )
                          : db.giftRecordsDao.watchCountInBook(book.bookId),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Text(
                          '$count 条记录',
                          style: AppTypography.base(
                            fontSize: 12,
                            fontWeight: AppTypography.regular,
                            color: colors.textTertiary,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    _MiniTextButton(
                      label: '编辑',
                      fg: AppColors.indigo600,
                      bg: AppColors.indigo50,
                      onTap: onEdit,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconByReasonType(String reasonType) {
  final v = reasonType.trim();
  if (v.contains('婚') || v.contains('宴') || v.contains('喜')) {
    return AppIcons.heart;
  }
  if (v.contains('商务') || v.contains('公司') || v.contains('企业')) {
    return AppIcons.briefcaseBusiness;
  }
  return AppIcons.bookOpen;
}

Color? _parseHexColorOrNull(String hex) {
  final v = hex.trim();
  if (v.isEmpty) return null;
  final clean = v.replaceAll('#', '');
  if (clean.length != 6 && clean.length != 8) return null;
  final full = clean.length == 6 ? 'FF$clean' : clean;
  return Color(int.parse(full, radix: 16));
}

String _formatBookTime(int timestamp) {
  return DateUtil.format(DateTime.fromMillisecondsSinceEpoch(timestamp));
}

class _MiniTextButton extends StatelessWidget {
  const _MiniTextButton({
    required this.label,
    required this.fg,
    required this.bg,
    this.onTap,
  });

  final String label;
  final Color fg;
  final Color bg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.softFor(bg),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTypography.base(
            fontSize: 12,
            fontWeight: AppTypography.medium,
            color: colors.foregroundFor(fg),
          ),
        ),
      ),
    );
  }
}
