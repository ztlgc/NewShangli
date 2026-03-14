import 'package:lunar/lunar.dart';

class DateUtil {
  /// 格式化日期为“YYYY年MM月DD日（农历月日）”
  static String format(DateTime date) {
    final lunar = Lunar.fromDate(date);
    
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    
    // 农历月份（如：正、二、闰四）
    final lunarMonth = lunar.getMonthInChinese();
    // 农历日期（如：初一、十五）
    final lunarDay = lunar.getDayInChinese();
    
    return '$y年$m月$d日（$lunarMonth月$lunarDay）';
  }
}
