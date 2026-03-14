import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/utils/date_util.dart';

void main() {
  group('DateUtil', () {
    test('格式化普通日期', () {
      final date = DateTime(2026, 2, 17);
      // 2026年2月17日是农历正月初一（2026年春节是2月17日）
      expect(DateUtil.format(date), '2026年02月17日（正月初一）');
    });

    test('格式化其他日期', () {
      final date = DateTime(2024, 1, 1);
      // 2024年1月1日是农历冬月二十
      expect(DateUtil.format(date), '2024年01月01日（冬月二十）');
    });
    
    test('格式化闰月日期', () {
      // 2025年有闰六月
      // 2025-07-25 是农历闰六月初一
      
      final date = DateTime(2025, 7, 25);
      expect(DateUtil.format(date), '2025年07月25日（闰六月初一）');
    });
  });
}
