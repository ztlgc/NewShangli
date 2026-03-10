import 'package:newshangli/ui/app_data.dart';

Future<void> waitAppDataReady(AppData data) async {
  // 说明：
  // - widget test 环境下不建议用 Future.delayed 等“基于计时器”的等待方式，
  //   否则可能因为测试时钟/调度机制差异导致等待无法推进而卡住；
  // - 这里用事件队列让出执行权，给 AppData 内部的异步初始化（SharedPreferences 读写等）机会完成。
  for (var i = 0; i < 5000; i++) {
    if (data.reasonsReady && data.relationsReady) return;
    await Future<void>(() {});
  }
}
