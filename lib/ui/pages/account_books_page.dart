import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../../import/default_book_service.dart';
import '../app_data.dart';
import '../app_database_scope.dart';
import '../app_tokens.dart';
import '../app_scaffold.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import 'account_book_edit_page.dart';
import 'account_book_records_page.dart';

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
    final recordsBookId = (book.isDefault == 1) ? AppData.defaultBookId : book.bookId;
    AppNav.push(
      context,
      AccountBookRecordsPage(
        bookId: recordsBookId,
        bookName: book.name,
        isDefaultBook: book.isDefault == 1,
      ),
      requiresLogin: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
          ),
          child: Row(
            children: [
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                onPressed: () => AppNav.pop(context),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '账簿管理',
                    style: AppTypography.base(
                      fontSize: 18,
                      fontWeight: AppTypography.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              PrototypeIconButton(
                icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                onPressed: () async {
                  await AppNav.push<bool>(context, const AccountBookEditPage(), requiresLogin: true);
                  if (!context.mounted) return;
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<String>(
            future: DefaultBookService().ensureDefaultBookId(AppDatabaseScope.of(context)),
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
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: books.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final b = books[i];
                      return _BookCardDb(
                        db: AppDatabaseScope.of(context),
                        book: b,
                        onOpen: () => _openBook(b),
                        onEdit: () async {
                          await AppNav.push<bool>(context, AccountBookEditPage(bookId: b.bookId), requiresLogin: true);
                          if (!context.mounted) return;
                          setState(() {});
                        },
                        onSwitch: () {
                          AppDatabaseScope.of(context).accountBooksDao.setDefaultBook(b.bookId);
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
    required this.onSwitch,
  });

  final AppDatabase db;
  final AccountBook book;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final isDefault = book.isDefault == 1;
    final data = AppDataScope.of(context);

    final theme = _parseHexColorOrNull(book.themeColor) ?? AppColors.indigo900;
    final icon = _iconByReasonType(book.reasonType);
    final iconBg = theme.withValues(alpha: 0.14);
    final iconFg = theme;

    final subtitle = (book.description ?? '').trim().isEmpty ? '点击查看该账簿记录' : book.description!.trim();

    return PressableScale(
      onTap: onOpen,
      child: Container(
        key: ValueKey<String>('book_card_${book.bookId}'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.sm,
          border: Border.all(
            color: isDefault ? theme : AppColors.gray100,
            width: isDefault ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (isDefault)
              Positioned(
                top: -16,
                right: -16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: const BoxDecoration(
                    color: AppColors.indigo600,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
                  ),
                  child: Text(
                    '当前使用',
                    style: AppTypography.base(
                      fontSize: 10,
                      fontWeight: AppTypography.regular,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: FaIcon(icon, size: 20, color: iconFg),
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
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTypography.base(
                              fontSize: 12,
                              fontWeight: AppTypography.regular,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: AppColors.borderDivider),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Builder(
                      builder: (context) {
                        final count = isDefault
                            ? data.records.length
                            : data.records.where((r) => data.resolveBookId(r.bookId) == book.bookId).length;
                        return Text(
                          '$count 条记录',
                          style: AppTypography.base(
                            fontSize: 12,
                            fontWeight: AppTypography.regular,
                            color: AppColors.textTertiary,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    if (!isDefault) ...[
                      _MiniTextButton(
                        label: '切换',
                        fg: AppColors.textMuted,
                        bg: AppColors.gray50,
                        onTap: onSwitch,
                      ),
                      const SizedBox(width: 8),
                    ],
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
  if (v.contains('婚') || v.contains('宴') || v.contains('喜')) return FontAwesomeIcons.heart;
  if (v.contains('商务') || v.contains('公司') || v.contains('企业')) return FontAwesomeIcons.briefcase;
  return FontAwesomeIcons.book;
}

Color? _parseHexColorOrNull(String hex) {
  final v = hex.trim();
  if (v.isEmpty) return null;
  final clean = v.replaceAll('#', '');
  if (clean.length != 6 && clean.length != 8) return null;
  final full = clean.length == 6 ? 'FF$clean' : clean;
  return Color(int.parse(full, radix: 16));
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
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(
          label,
          style: AppTypography.base(
            fontSize: 12,
            fontWeight: AppTypography.medium,
            color: fg,
          ),
        ),
      ),
    );
  }
}
