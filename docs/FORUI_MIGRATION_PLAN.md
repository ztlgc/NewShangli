# 尚礼 Forui UI 历史迁移记录

> 本文记录此前 26 页的迁移过程与旧制品证据。当前已移除云同步、登录、个人资料三页，保留 23 页；现行规范以 `DESIGN_SPEC.md` 和 `HARMONYOS_MIGRATION_READINESS.md` 为准。下文的旧页面与 APK 说明不代表本次新增验证。

本文以迁移时 `lib/ui` 实现为准。迁移目标是在保留页面功能、数据库读写和导航参数的前提下，将全部业务页面统一到 Forui 主题、Lucide 图标、共享布局与反馈组件。

## 完成范围

- `lib/ui/pages` 下 26 个业务页面已统一使用 `AppScaffold`、Forui 明暗主题和共享设计令牌。
- 四个一级页面使用 Forui 底部导航，并保留 `IndexedStack` 状态、多选模式和原有入口。
- 文本输入、选择器、开关、按钮、对话框、Toast 与底部弹层已使用 Forui 或项目共享封装。
- 页面代码已清除 Material 按钮、输入框、开关、下拉框、旧 `Icons.*` 以及直接调用的 `showModalBottomSheet`。
- 旧 `Prototype*` 类名、旧图标兼容层和 `font_awesome_flutter` 依赖已移除；共享组件归入 `ui_kit.dart`，组件展示页归入 `ui_gallery.dart`。
- 统计图表、农历选择器、数据表格和金额格式化属于业务专用控件，继续保留定制实现，并使用统一颜色、圆角、间距与文字层级。

## 统一规则

| 维度 | 当前实现 |
| --- | --- |
| 主题 | `FTheme.neutral` 明暗主题作为基础，品牌色和成功、警告、危险色由项目令牌统一提供。 |
| 语言资源 | 统一使用 `AppLocalizations`，同时保留 Flutter SDK 和 Forui 的语言代理，覆盖中文系统下的原生弹层。 |
| 布局 | 页面使用 `AppScaffold`；内容区采用统一水平留白、卡片圆角、分组间距和安全区处理。 |
| 导航 | 一级页面使用 Forui 底部导航；二级页面统一返回、居中标题和右侧操作。 |
| 组件 | 通用卡片、列表行、标签、搜索、按钮、对话框、Toast 和底部弹层由共享组件实现。 |
| 图标 | 页面统一使用 `FLucideIcons`，颜色与尺寸由语义和组件层级决定。 |
| 表单 | 使用 `FTextField`、`FSelect`、`FSwitch` 等 Forui 控件；保留校验、默认值、保存状态和输入格式化。 |
| 反馈 | 删除、覆盖、恢复等危险操作使用统一确认对话框；轻量结果通过统一 Toast 呈现。 |
| 适配 | 自动测试覆盖 360 × 800、1.3 倍字体的全部页面，以及 430 × 900 的深色四主页面。 |

## 页面与功能边界

| 页面组 | 页面 | 保留的核心行为 |
| --- | --- | --- |
| 一级页面 | 记录、关系人、统计、设置 | 搜索、筛选、统计、入口导航和状态保持。 |
| 记录与关系 | 记录新增/详情，关系人新增/详情，联系人关系编辑 | 新增、查看、编辑、删除、人物选择、事由与支付方式选择。 |
| 账簿 | 账簿管理、新增/编辑、详情、记录、数据导入 | 账簿增改查、账簿内记录定位和导入流程。 |
| 字典与安全 | 事由、关系类型、编辑保护、回收站 | 字典管理、编辑保护、恢复和彻底删除语义。 |
| 数据与账户 | 导入、导出、备份、云同步、登录、个人资料 | 映射预览、导出范围、备份恢复、同步与账号状态。 |

## 自动验证与视觉证据

- `test/ui/forui_main_tabs_test.dart` 验证四个一级页面的导航、窄屏、大字体和深色模式。
- `test/ui/forui_secondary_pages_responsive_test.dart` 在 360 × 800、1.3 倍字体下依次渲染 22 个二级页面，并可生成页面预览。
- `test/ui/notifications/app_bottom_sheet_test.dart` 覆盖统一底部弹层、选中状态和复杂内容路由。
- `docs/forui-preview/` 包含全部 26 个页面的 430 × 900 浅色预览；`dark/` 包含四个一级页面的深色预览。预览使用隔离的内存数据库和测试目录，不读写用户数据。
- 预览生成命令：`$env:UPDATE_FORUI_PREVIEWS='true'; flutter test --update-goldens --concurrency=1 test/ui/forui_main_tabs_test.dart test/ui/forui_secondary_pages_responsive_test.dart`。

## 发布边界

- Android 正式构建只使用：`flutter build apk --split-per-abi --target-platform android-arm64 --release`。
- 当前制品：`newshangli-arm64-2026-10-03-localization-fix.apk`，版本 `1.2.1`（APK versionCode `4004`），26,582,210 字节，SHA-256 `AEE6A7CAD1388E079355A2D10567436CDDC820FA538C7335E08F6BB377149864`。制品只包含 `arm64-v8a`，`zipalign` 与 `apksigner` 校验通过。
- 中文环境下点击弹层无响应的根因、修复及 Release 对照证据见 [NAVIGATION_LOCALIZATION_FIX.md](NAVIGATION_LOCALIZATION_FIX.md)；修复后完整测试 153 项通过。
- 自动测试和桌面渲染不能替代 Android 真机上的键盘、安全区、系统字体和触控手感检查。
- 当前 Android 配置仍使用调试证书签署 Release APK，包名仍为 `com.example.newshangli`。对外发布前需要由项目所有者确定正式包名并提供正式签名密钥。
