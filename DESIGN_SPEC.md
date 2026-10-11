# 尚礼统一设计与交互规范

本规范以当前代码为准。项目继续使用 Flutter、Forui 和现有明暗配色，不重做视觉风格，不增加账号体系。核心功能为本地礼账、关系人、统计、导入导出、本地备份恢复及 WebDAV 整包备份。

## 设计资源的唯一入口

| 资源 | 入口 | 规则 |
| --- | --- | --- |
| 颜色、字号、圆角、阴影、间距 | `lib/ui/app_tokens.dart` | 使用 AppColors、AppTypography、AppRadii、AppShadows、AppTokens；不另建配色体系。 |
| Forui 主题 | `app_forui_theme.dart`、`app_theme.dart` | 保留当前 FTheme.neutral 基础、品牌和状态色，明暗模式跟随系统。 |
| 页面留白与主导航间距 | `app_layout.dart` | 页面水平留白 16、分组间距 24；主页面沿用 96 的内容底部预留。 |
| 页面图标 | `app_icons.dart` | 页面引用 AppIcons；Lucide 的原有图形和名称不变，第三方图标仅在目录内映射。 |
| 应用标识 | `app_assets.dart`、`assets/images/logo*.svg` | 原有 logo 与 Android 自适应图标保持不变；由 `tool/generate_app_icon.py` 生成密度资源，不单独修改 PNG。 |

## 页面与交互

- 保留记录、关系、统计、设置四个一级页面及 IndexedStack 状态保持。设置页面保留原有分组卡片和图标色块，移除用户卡片、登录、退出与云同步入口。
- 所有业务页沿用 AppScaffold；标题、返回、卡片、搜索、输入、选择器、按钮通过现有共享组件呈现。列表与表单用既有单列布局；不按设计稿比例缩小文字和触控区域。
- 主导航在系统底部安全区上方显示；键盘打开时不抢占表单输入空间。选择模式仍由 TabShellScope 控制导航显隐。
- 页面使用 AppTopBar、AppIconButton、AppPressableRow 等共享组件。最低触控区域由 AppTokens.tapTargetMin 统一控制；保留当前尺寸和图形，不通过新依赖改变样式。
- 对话框、底部弹层、结果反馈统一经 AppDialog、AppBottomSheet、AppNotifier。异步动作保留 busy 状态、重复操作保护、失败重试和 mounted 检查；取消不写入数据，失败不提示成功。
- 编辑保护密码是本地修改保护，与登录无关。本地查询、导入、导出、备份恢复不检查账号状态。
- 收礼/送礼和危险操作同时使用文字标识，含义不单靠颜色。长姓名、金额、键盘和放大字体必须覆盖真实路径。

## 反馈尺寸与时长

尺寸和时长以 AppNotificationTokens 为唯一代码入口，保持既有反馈样式。

| 项目 | 当前值 |
| --- | --- |
| 通知容器 / 对话框 / 底部弹层顶部圆角 | 12 / 16 / 24 |
| Toast 安全边距 / 顶部偏移 / 最大宽度 | 16 / 16 / 420 |
| 对话框水平留白 / 内容垂直留白 / 最大宽度 | 24 / 20 / 360 |
| 底部弹层最大高度 | 屏幕的 90%，同时避让键盘 |
| 对话框按钮高度 / 间距 | 44 / 10 |
| Toast 入场 / 退场 | 250 / 200 ms |
| 对话框入场 / 退场 | 200 / 150 ms |
| Toast 信息成功 / 警告 / 错误或带操作 | 2 / 3.5 / 5 s |
| SnackBar 默认 / 带操作 | 4 / 6 s |

## 数据与备份契约

- 联系人为全局实体，记录归属账簿；联系人来源账簿不控制其生命周期。金额使用整数分，主键保持 UUID。数据库 schemaVersion 15；仅支持当前结构的新建数据库，不提供旧版升级或旧偏好设置数据迁移。支付方式字段和功能已移除。
- WebDAV 只上传/下载完整 ZIP 备份，不执行双向同步、冲突合并或应用账号体系。旧配置和历史记录键保留兼容，包括既有 BackupTarget.cloud 存储值；该值代表 WebDAV 远端备份。
- 继续使用一致性 SQLite 快照、manifest、SHA-256、schema/外键验证和恢复失败回滚。Excel/CSV 业务导出不能代替完整备份。
- 自动备份后台调度尚未实现，不把开关或历史频率显示当作已具备后台备份。

## 平台边界

文件选择、系统分享、应用目录通过 `lib/platform/app_platform.dart` 的接口调用。`flutter_platform_adapter.dart` 实现当前 Flutter 插件，业务页不导入 file_picker、share_plus、path_provider。保留服务已有的目录与数据库测试注入点。

这是迁移准备，不是鸿蒙适配完成。Dart IO、SQLite/FFI、配置存储、WebDAV 网络栈及系统权限仍需要目标平台验证；详见迁移准备文档。

## 验证

修改后格式化实际变更文件，运行静态分析与相关 Flutter 测试。大范围 UI 整理需运行完整测试及 23 页预览/响应式检查。预览使用隔离数据库和临时目录，不使用真实数据。Android 真机键盘、系统安全区和鸿蒙设备验证分别记录，不从构建成功推断。
