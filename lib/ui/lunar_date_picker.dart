import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';

import 'app_tokens.dart';
import 'prototype_kit.dart';

typedef AppSelectableDayPredicate = bool Function(DateTime day);

Future<DateTime?> showLunarDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  AppSelectableDayPredicate? selectableDayPredicate,
}) {
  final now = DateTime.now();
  final init = _dateOnly(initialDate ?? now);
  final first = _dateOnly(firstDate ?? DateTime(2000, 1, 1));
  final last = _dateOnly(lastDate ?? DateTime(now.year + 10, 12, 31));
  final clampedInit = _clampDate(init, first: first, last: last);

  return showGeneralDialog<DateTime?>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.scrimBlack30,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, anim, secondary) {
      return SafeArea(
        child: Center(
          child: _LunarDatePickerDialog(
            initialDate: clampedInit,
            firstDate: first,
            lastDate: last,
            selectableDayPredicate: selectableDayPredicate,
          ),
        ),
      );
    },
    transitionBuilder: (context, anim, secondary, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1).animate(curve), child: child),
      );
    },
  );
}

class _LunarDatePickerDialog extends StatefulWidget {
  const _LunarDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.selectableDayPredicate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final AppSelectableDayPredicate? selectableDayPredicate;

  @override
  State<_LunarDatePickerDialog> createState() => _LunarDatePickerDialogState();
}

class _LunarDatePickerDialogState extends State<_LunarDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _visibleMonth;

  late DateTime _baseMonth;
  late int _pageCount;
  late final PageController _controller;

  final Map<int, Map<int, _LunarCellInfo>> _monthCache = <int, Map<int, _LunarCellInfo>>{};

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);

    _baseMonth = DateTime(widget.firstDate.year, widget.firstDate.month, 1);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month, 1);
    _pageCount = _monthsBetween(_baseMonth, lastMonth) + 1;

    final initialPage = _monthsBetween(_baseMonth, _visibleMonth).clamp(0, _pageCount - 1);
    _controller = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final dialogW = math.min(353.0, screenW - 40);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: dialogW,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadii.brXl,
          boxShadow: AppShadows.xl,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: _Header(month: _visibleMonth),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              child: _WeekHeader(),
            ),
            SizedBox(
              height: 52 * 6,
              child: PageView.builder(
                controller: _controller,
                itemCount: _pageCount,
                onPageChanged: (index) => setState(() => _visibleMonth = _addMonths(_baseMonth, index)),
                itemBuilder: (context, index) {
                  final month = _addMonths(_baseMonth, index);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _MonthGrid(
                      month: month,
                      selectedDate: _selectedDate,
                      firstDate: widget.firstDate,
                      lastDate: widget.lastDate,
                      selectableDayPredicate: widget.selectableDayPredicate,
                      cellInfoFor: _cellInfoFor,
                      onSelect: (d) => setState(() => _selectedDate = d),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _Actions(
                onCancel: () => Navigator.of(context).pop<DateTime?>(null),
                onConfirm: () => Navigator.of(context).pop<DateTime?>(_selectedDate),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _LunarCellInfo _cellInfoFor(DateTime day) {
    final monthKey = day.year * 100 + day.month;
    final dayKey = day.day;
    final byMonth = _monthCache.putIfAbsent(monthKey, () => <int, _LunarCellInfo>{});
    return byMonth.putIfAbsent(dayKey, () => _computeLunarCellInfo(day));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            '${month.month}月',
            style: AppTypography.base(
              fontSize: AppTypography.fs36,
              fontWeight: AppTypography.bold,
              color: AppColors.textPrimary,
              height: 1.05,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            '${month.year}',
            style: AppTypography.base(
              fontSize: AppTypography.fs16,
              fontWeight: AppTypography.medium,
              color: AppColors.textSecondary,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();

  static const _labels = <String>['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth / 7;
        return Row(
          children: [
            for (final t in _labels)
              SizedBox(
                width: w,
                height: 26,
                child: Center(
                  child: Text(
                    t,
                    style: AppTypography.base(
                      fontSize: AppTypography.fs14,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.selectableDayPredicate,
    required this.cellInfoFor,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final AppSelectableDayPredicate? selectableDayPredicate;
  final _LunarCellInfo Function(DateTime day) cellInfoFor;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;

    return LayoutBuilder(
      builder: (context, c) {
        final cellW = c.maxWidth / 7;
        const cellH = 52.0;

        return Column(
          children: [
            for (var row = 0; row < 6; row++)
              Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    _DayCell(
                      width: cellW,
                      height: cellH,
                      month: month,
                      dayNumber: row * 7 + col - leadingEmpty + 1,
                      daysInMonth: daysInMonth,
                      selectedDate: selectedDate,
                      firstDate: firstDate,
                      lastDate: lastDate,
                      selectableDayPredicate: selectableDayPredicate,
                      cellInfoFor: cellInfoFor,
                      onSelect: onSelect,
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.width,
    required this.height,
    required this.month,
    required this.dayNumber,
    required this.daysInMonth,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.selectableDayPredicate,
    required this.cellInfoFor,
    required this.onSelect,
  });

  final double width;
  final double height;
  final DateTime month;
  final int dayNumber;
  final int daysInMonth;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final AppSelectableDayPredicate? selectableDayPredicate;
  final _LunarCellInfo Function(DateTime day) cellInfoFor;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return SizedBox(width: width, height: height);
    }

    final day = DateTime(month.year, month.month, dayNumber);
    final enabled = _isEnabled(day);
    final selected = _isSameDay(day, selectedDate);
    final today = _isSameDay(day, _dateOnly(DateTime.now()));

    final info = cellInfoFor(day);

    final bg = selected ? AppColors.brandSoft : Colors.transparent;
    final border = selected
        ? const Border.fromBorderSide(BorderSide(color: AppColors.borderFocus, width: 1))
        : (today ? const Border.fromBorderSide(BorderSide(color: AppColors.gray200, width: 1)) : null);

    final dayColor = !enabled
        ? AppColors.gray300
        : (selected ? AppColors.textBrand : AppColors.textPrimary);

    final lunarColor = !enabled ? AppColors.gray300 : info.color;

    return SizedBox(
      width: width,
      height: height,
      child: PressableScale(
        onTap: enabled ? () => onSelect(day) : null,
        pressedScale: 0.98,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadii.brXl,
            border: border,
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNumber',
                  style: AppTypography.base(
                    fontSize: AppTypography.fs16,
                    fontWeight: selected ? AppTypography.bold : AppTypography.semibold,
                    color: dayColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.base(
                    fontSize: AppTypography.fs10,
                    fontWeight: AppTypography.regular,
                    color: lunarColor,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isEnabled(DateTime day) {
    if (day.isBefore(firstDate) || day.isAfter(lastDate)) return false;
    final predicate = selectableDayPredicate;
    if (predicate != null && !predicate(day)) return false;
    return true;
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onCancel, required this.onConfirm});

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: PressableScale(
              onTap: onCancel,
              pressedScale: 0.98,
              duration: const Duration(milliseconds: 120),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '取消',
                  style: AppTypography.base(
                    fontSize: AppTypography.fs18,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: PressableScale(
              onTap: onConfirm,
              pressedScale: 0.98,
              duration: const Duration(milliseconds: 120),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '确定',
                  style: AppTypography.base(
                    fontSize: AppTypography.fs18,
                    fontWeight: AppTypography.medium,
                    color: AppColors.blue600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LunarCellInfo {
  const _LunarCellInfo({required this.text, required this.color});

  final String text;
  final Color color;
}

_LunarCellInfo _computeLunarCellInfo(DateTime day) {
  final solar = Solar.fromDate(day);
  final lunar = Lunar.fromDate(day);

  final jq = lunar.getJieQi();
  if (jq.isNotEmpty) {
    return _LunarCellInfo(text: jq, color: AppColors.blue600);
  }

  final solarFestivals = solar.getFestivals();
  if (solarFestivals.isNotEmpty) {
    return _LunarCellInfo(text: solarFestivals.first, color: AppColors.textSecondary);
  }

  final lunarFestivals = lunar.getFestivals();
  if (lunarFestivals.isNotEmpty) {
    return _LunarCellInfo(text: lunarFestivals.first, color: AppColors.textSecondary);
  }

  final dayText = lunar.getDayInChinese();
  if (dayText == '初一') {
    final m = lunar.getMonthInChinese();
    return _LunarCellInfo(text: '$m月', color: AppColors.textMuted);
  }
  return _LunarCellInfo(text: dayText, color: AppColors.textMuted);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _clampDate(DateTime d, {required DateTime first, required DateTime last}) {
  if (d.isBefore(first)) return first;
  if (d.isAfter(last)) return last;
  return d;
}

int _monthsBetween(DateTime a, DateTime b) => (b.year - a.year) * 12 + (b.month - a.month);

DateTime _addMonths(DateTime monthStart, int months) {
  final y = monthStart.year * 12 + (monthStart.month - 1) + months;
  final year = y ~/ 12;
  final month = y % 12 + 1;
  return DateTime(year, month, 1);
}
