# 统计分析页

统计页按已确认的设计实现：时间选择 → 收支概览 → 收支趋势 → 送礼事由 → 往来排行。沿用现有 Flutter / Forui 主题、四个主导航入口和全部账簿统计口径。

- `lib/ui/pages/stats_page.dart` 管理月份、年份和自定义日期选择。月份可通过左右箭头或月份弹层切换，年份保留“全部年份”，自定义截止日期包含当天。
- `lib/ui/stats/stats_cards.dart` 渲染白底收支概览、收礼/送礼双柱图、事由环图及金额占比、往来前五位。排名按收礼与送礼合计金额排序，同时显示双方金额。
- `StatsViewModel.dataRange` 与成功加载的快照一同发布。切换时段后仅显示与当前时段匹配的数据，过期请求结果会被丢弃；刷新失败可重试。
- 月统计对比上月，年统计对比去年，自定义范围对比上一等长时段；完整自然月/自然年的范围由现有统计服务识别。全部年份不显示对比百分比。
- 小屏、长金额和放大字体下，金额区、事由列表和排行自动改为纵向排列。趋势时段较多时允许横向滚动，长姓名/事由可通过长按提示查看全文。
- 空数据仍显示零金额概览，并分别说明暂无收礼/送礼记录、送礼事由及往来记录。配色跟随当前明暗主题。

## 验证与截图

`test/stats/stats_page_flow_test.dart` 使用隔离的内存数据库和真实统计聚合，覆盖月/年切换、全部年份、自定义日期确认与取消、错误重试，以及 393px、360px 放大字体、宽屏和深色模式。示例数据见 `test/support/stats_preview_data.dart`，不读取用户账簿。

```powershell
flutter test --no-pub --concurrency=4
flutter analyze --no-pub --no-fatal-infos

# 使用本机中文字体生成实际页面截图，字体不会打包到应用。
$env:UPDATE_FORUI_PREVIEWS = 'true'
$env:FORUI_PREVIEW_FONT = 'C:\Windows\Fonts\msyh.ttc'
$env:STATS_PREVIEW_DIR = 'artifacts/stats-redesign/implemented'
flutter test --no-pub --concurrency=1 test/stats/stats_page_flow_test.dart
```

截图保存在上述输出目录。Widget 截图与 Android 编译检查分别记录，不代替真机字体、触控和系统安全区验收。

2026-10-26 验证结果：全量 197 项测试通过；静态分析无错误、无警告，保留项目原有的 38 条 info 提示；Android ARM64 调试 APK 构建成功。浅色、深色、360px 放大字体和宽屏截图已检查，未进行真机验收。
