import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/local/drift/app_database.dart';
import '../app_database_scope.dart';
import '../app_scaffold.dart';
import '../app_tokens.dart';
import '../navigation.dart';
import '../prototype_kit.dart';
import '../../utils/date_util.dart';

/// 页面：账簿记录
///
/// 入口：
/// - 从“账簿管理”页面点击某个账簿卡片进入
///
/// 职责：
/// - 按 bookId 加载该账簿下的所有礼金记录
/// - 以列表方式展示：关系人、收支方向、金额、发生时间等
class AccountBookRecordsPage extends StatelessWidget {
  const AccountBookRecordsPage({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.isDefaultBook,
  });

  final String bookId;
  final String bookName;
  final bool isDefaultBook;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.surfaceApp,
      body: _Canvas(bookId: bookId, bookName: bookName, isDefaultBook: isDefaultBook),
    );
  }
}

class _Canvas extends StatefulWidget {
  const _Canvas({
    required this.bookId,
    required this.bookName,
    required this.isDefaultBook,
  });

  final String bookId;
  final String bookName;
  final bool isDefaultBook;

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabaseScope.of(context);
    final stream = widget.isDefaultBook
        ? db.giftRecordsDao.watchAllWithPersonInAllBooks()
        : db.giftRecordsDao.watchAllWithPersonInBook(widget.bookId);

    return Column(
      children: [
        _TopBar(
          title: widget.bookName,
          onBack: () => AppNav.pop(context),
        ),
        Expanded(
          child: StreamBuilder<List<GiftRecordWithPerson>>(
            stream: stream,
            builder: (context, snapshot) {
              final list = snapshot.data ?? const <GiftRecordWithPerson>[];
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    widget.isDefaultBook ? '暂无记录' : '该账簿暂无记录',
                    style: AppTypography.base(
                      fontSize: AppTypography.fs14,
                      fontWeight: AppTypography.regular,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final item = list[i];
                  return _RecordCard(record: item.record, person: item.person);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

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
            icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            onPressed: onBack,
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
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.person,
  });

  final GiftRecord record;
  final Person person;

  @override
  Widget build(BuildContext context) {
    final isIncome = record.direction != '支出';
    final amountText = _formatAmountCent(record.amountCent);
    final timeText = _formatDateTime(DateTime.fromMillisecondsSinceEpoch(record.occurredAt));
    final title = (record.eventName ?? '').trim().isEmpty ? '礼金往来' : record.eventName!.trim();
    final relationText = person.relationshipType.trim().isEmpty ? '其他' : person.relationshipType.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.gray100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isIncome ? AppColors.indigo50 : AppColors.orange50,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: FaIcon(
                  isIncome ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp,
                  size: 16,
                  color: isIncome ? AppColors.indigo700 : AppColors.orange600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: AppTypography.base(
                        fontSize: 16,
                        fontWeight: AppTypography.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$relationText · $title',
                      style: AppTypography.base(
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    (isIncome ? '+' : '-') + amountText,
                    style: AppTypography.base(
                      fontSize: 16,
                      fontWeight: AppTypography.bold,
                      color: isIncome ? AppColors.indigo700 : AppColors.orange600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: AppTypography.base(
                      fontSize: 12,
                      fontWeight: AppTypography.regular,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if ((record.note ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.borderDivider),
            const SizedBox(height: 12),
            Text(
              record.note!.trim(),
              style: AppTypography.base(
                fontSize: 12,
                fontWeight: AppTypography.regular,
                color: AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// 将“分”转换成“元”并保留 2 位小数。
String _formatAmountCent(int cent) {
  final v = cent / 100.0;
  return v.toStringAsFixed(2);
}

/// 将时间格式化为 YYYY-MM-DD HH:mm。
String _formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${DateUtil.format(dt)} ${two(dt.hour)}:${two(dt.minute)}';
}
