# 中文环境弹层无响应：原因与修复

## 根因

Forui 迁移后，`MaterialApp` 同时改用了 `FLocalizations.supportedLocales` 和
`FLocalizations.localizationsDelegates`。Forui 0.27.3 的这组代理来自
`material_ui`、`cupertino_ui` 和 Flutter Widgets；其中前两者的资源类型并非
`package:flutter/material.dart` 和 `package:flutter/cupertino.dart` 的资源类型。

本项目的 `showModalBottomSheet`、`showDialog` 等仍来自 Flutter SDK。中文系统
选中 `zh` 后，这些 API 取不到 Flutter 原生 `MaterialLocalizations`。点击事件
已经到达、回调也已经执行，但创建路由时抛出异常，界面上没有弹层。

旧 commit 未开启多语言支持，`MaterialApp` 默认使用英文资源，因此原生弹层可用。
之前的测试也默认使用英文，未覆盖中文系统语言解析，导致未能发现这一回归。

## 可复现证据

隔离诊断程序使用项目相同的主题、点击行和弹层封装，在 Windows Release AOT 下
设置 `Locale('zh', 'CN')`，合成触控按下/抬起事件。它不访问业务数据库和云端。

修复前的结果保存在 `artifacts/navigation-regression/release-before.json`：

| 操作 | 点击回调 | 内容显示 |
| --- | --- | --- |
| 账簿选择器 | 已执行 | 失败 |
| 关系人弹层 | 已执行 | 失败 |
| WebDAV 所用的 Material 弹窗 API | 已执行 | 失败 |
| 普通页面导航 | 已执行 | 成功 |

前三项均报 `Null check operator used on a null value`，首帧栈为
`MaterialLocalizations.of`，随后进入 `showModalBottomSheet` 或 `DialogRoute`。
中文环境的实际“设置 → 数据备份 → WebDAV 配置”Widget 测试也在修复前失败，
报 `No MaterialLocalizations found`，见 `artifacts/navigation-regression/debug-before.log`。

## 修复

- 新增 `AppLocalizations`，同时注册 Flutter SDK 原生和 Forui 所需的语言代理。
- `NewShangliApp` 统一使用该配置；显式声明 `flutter_localizations` SDK 依赖。
- 撤回此前将 `AppPressableRow` 改为 `InkWell` 的猜测性改动，恢复原有点击组件。
- 回归测试通过 `platformDispatcher.localesTestValue` 模拟系统语言列表，并确认
  应用实际解析为中文；覆盖首页打开记录选择器和设置页打开 WebDAV 配置。

## 验证

- 修复后的同一 Release 诊断程序：4 项全部显示，异常数组为空。
  结果见 `artifacts/navigation-regression/release-after.json`。
- 完整 `flutter test --no-pub --concurrency=4`：153 项全部通过。
  日志见 `artifacts/navigation-regression/tests-after.log`。
- 修改的应用配置、共享组件和回归测试通过定向 `flutter analyze --no-pub`。
- 源码版本升为 `1.2.1+2004`，用以区分先前两个未解决问题的包。
- Android ARM64 Release 构建完成；APK 实际 `versionName=1.2.1`、`versionCode=4004`
  （按 ABI 拆分构建在源码构建号上增加偏移），`zipalign` 与 `apksigner` 校验通过。
- Release 复现与修复验证在 Windows 完成；当前没有连接 Android 真机，手机安装验证仍待完成。

## 安装包

- 文件：`newshangli-arm64-2026-10-03-localization-fix.apk`
- 大小：26,582,210 字节。
- SHA-256：`AEE6A7CAD1388E079355A2D10567436CDDC820FA538C7335E08F6BB377149864`。
- 保持原包名和签名，使用覆盖安装；先前的 `picker-fix` 和 `navigation-fix` 包未解决此问题。
