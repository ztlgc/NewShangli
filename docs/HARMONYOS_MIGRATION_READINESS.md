# 鸿蒙迁移准备与当前边界

更新：2026-10-11。当前目标仍为 Android，保留 Flutter/Forui 风格。此轮只准备可替换接口和共同数据契约，不创建鸿蒙工程，不声明已有鸿蒙设备支持。

## 已落地的边界

| 模块 | 当前入口 | 迁移时处理 |
| --- | --- | --- |
| 文件选择与目录选择 | `AppPlatformAdapter.pickFiles/pickDirectory` | 实现目标平台选择器；取消返回 null，保留文件名、路径和可选字节。 |
| 系统分享 | `AppPlatformAdapter.shareFile` | 由目标平台实现系统分享，业务页不引用插件参数。 |
| 应用文档/临时目录 | `AppPlatform.documentsDirectory/temporaryDirectory` | 统一目录来源；现有服务仍可注入测试目录。 |
| 页面图标 | `AppIcons` 的 73 个映射 | 维持语义和图形；当前 Lucide 源不变。 |
| 标识资源 | `AppAssets` 与 SVG 源文件 | 从同一源生成 Android/鸿蒙资源，不重新绘制品牌标识。 |
| 页面和反馈 | AppScaffold、AppLayout、AppDialog、AppBottomSheet、AppNotifier | 保留布局、取消/确认、busy/失败/重试语义，验证安全区与输入法。 |
| 本地数据 | Drift schemaVersion 15、UUID、整数分 | 新库不含支付方式字段，不提供历史版本数据迁移；用同一份夹具验证导入、查询、导出、恢复。 |

`flutter_platform_adapter.dart` 集中实现 file_picker、share_plus、path_provider。将来可替换 `AppPlatform.instance`，纯契约位于 platform_contract.dart，接口参数不包含这些插件类型。新的实现必须保持当前选择文件、分享取消和目录错误的语义，不能在页面里增加平台分支。

现有导入和媒体流程需要可读的本地文件路径。若目标平台仅返回字节或 URI，适配器须先落盘到受控临时目录，再返回路径；页面无需处理平台 URI。

## 明确保留的边界

SQLite/FFI、dart:io、SharedPreferences 配置存储、WebDAV HttpClient、农历库和 Forui 所依赖的 Flutter 版本还没有做鸿蒙适配。平台接口不意味着这些模块已兼容；WebDAV 继续使用现有完整 ZIP 备份和校验恢复链路。

现有 WebDAV URL、目录、凭据和历史记录键保持兼容。旧 BackupTarget.cloud 值用于 WebDAV 远端备份，不能直接改键名导致历史状态丢失。账号、Supabase 初始化、同步服务与运行依赖已移除；根目录已有个人配置以及历史 SQL 仅保留在本地/仓库历史参考范围，不再打包或加载。

## 鸿蒙进入计划后的最小验证

1. 先确定目标设备、HarmonyOS SDK、发行版本和 Flutter 适配分支，核对 Dart/Forui 与 SQLite 插件兼容矩阵，单独固定工具链，避免影响 Android 主线。
2. 用隔离目录与测试数据完成新建联系人、记一笔、联系人/账簿查询、重启后读回。
3. 完成文件选择、CSV/Excel 导入和系统分享；验证取消、无权限、中文文件名、长路径及字节/路径提供方式。
4. 完成本地 ZIP 备份、WebDAV 上传/下载、恢复和重启读回；覆盖断网、错误凭据、损坏备份、schema 不兼容与恢复失败回滚。
5. 验证中文、大字体、明暗模式、软键盘、安全区、系统返回和中断恢复，再检查包签名与安装。

如适配分支的核心依赖不能满足要求，再评估 ArkTS/ArkUI。原生重实现可复用业务规则、设计规范、SVG、数据协议和验收夹具；Flutter 页面与 Drift 代码不会自动变成 ArkUI 代码。

## 日常检查

- `flutter analyze --no-pub --no-fatal-infos`：当前源码和测试的错误/警告必须清零，既有风格 info 单独记录。
- `flutter test --no-pub --concurrency=4`：保留本地数据完整性、备份恢复、导入导出与 23 页布局/交互回归。
- 生成隔离 UI 预览：`UPDATE_FORUI_PREVIEWS=true、FORUI_PREVIEW_FONT=可读中文字体路径` 配合 `test/ui/forui_main_tabs_test.dart`、`test/ui/forui_secondary_pages_responsive_test.dart`；预览和测试不读取真实礼账。
- 真机与鸿蒙适配记录独立于单元测试和构建结果。
