# 本地功能与 UI 整理验证记录

完成日期：2026-10-11。改动保留在 E:\NewShangli。继续使用现有 Flutter、Forui 视觉风格及记录、关系、统计、设置四个一级页面。

## 完成的整理

- 使用既有颜色、字号、圆角和控件体系；页面留白、分组间距与主导航预留统一通过 AppLayout 管理。
- AppIcons 汇总 73 个原有 Lucide 图标映射，图形保持不变。AppAssets 登记现有 SVG 标识源，原生启动图标没有重新绘制。
- DESIGN_SPEC.md 对齐实际主题与页面，统一弹窗、底部弹层、反馈尺寸/时长、取消、忙碌和失败行为。
- 主导航避开底部安全区；键盘或选择模式开启时隐藏并停止接收点击，关闭后恢复。四个主页面保留 IndexedStack 状态。
- 应用根部持有并释放 AppSession/AppData，避免根部重建时重复创建状态。
- 移除登录、个人资料、云同步页面，Supabase 初始化、同步服务、账号检查及运行依赖；锁文件减少 25 个相关依赖。
- 保留本地完整备份、WebDAV 整包备份、导入导出、回收站、编辑保护。WebDAV 不执行双向同步；自动备份后台调度仍未实现。
- 文件选择、目录选择、系统分享和文档/临时目录集中到 AppPlatformAdapter。纯接口和值类型位于 platform_contract.dart；Flutter 插件集中到 flutter_platform_adapter.dart。
- 联系人全局归属、整数分金额、UUID、备份快照/校验/恢复回滚和既有 WebDAV 配置键保留。当前 schemaVersion 为 15，仅支持新建数据库和同版本备份，不提供旧版数据升级；本次没有清理设备上的真实数据。
- 删除支付方式的录入、详情、列表、搜索、统计、数据库字段及 Excel/CSV/PDF 导入导出列；删除旧版偏好设置迁入 Drift、13→14 表升级和统计库旧版升级代码。

## 验证结果

| 检查 | 结果 |
| --- | --- |
| flutter pub get | 成功移除云相关依赖，没有升级无关依赖 |
| flutter test --no-pub --concurrency=4 --reporter expanded | 完整 143 项测试通过 |
| flutter analyze --no-pub --no-fatal-infos | 退出码 0，无 error/warning；40 条既有风格及弃用 info |
| flutter build apk --debug --no-pub --target-platform android-arm64 | Android ARM64 调试编译成功 |
| 页面预览与响应式检查 | 23 页浅色及四个主页面暗色；窄屏、放大字体、中文选择器路径通过 |
| 平台接口行为 | CSV 选择后的预览及取消均验证，确认执行导入前不写入礼账 |
| 导出页行为 | 实际打开页面，检查本地/WebDAV 备份提示并切换 Excel/ZIP |
| 安装包资产 | 不包含停用的 supabase.local.json 配置 |

预览位于 docs/forui-preview。图标使用应用真实字体；中文截图使用显式指定的本机字体，只用于测试，没有把 Windows 字体加入应用。预览使用隔离数据库和临时目录。旧登录/个人资料/云同步截图保留为历史参考，不属于当前 23 页。

## 迁移与验收边界

迁移准备详见 docs/HARMONYOS_MIGRATION_READINESS.md。当前尚未创建鸿蒙工程，也没有验证鸿蒙设备。SQLite/FFI、Dart IO、配置存储、WebDAV 网络栈、权限、系统返回、真实输入法和安装仍需目标平台验证。

Android 调试包用于编译核验，没有完成真机安装验收，也没有生成或发布正式签名版本。构建仍提示现有 Gradle、AGP、Kotlin 版本未来需要升级；本轮保持工具链版本。

历史 Supabase SQL 与已有本地配置保留作参考，不再由应用加载或打包。没有变更远程服务或远程数据。项目原有未提交改动保留；本轮没有提交或推送。

调试构建产物：E:\NewShangli\build\app\outputs\flutter-apk\app-debug.apk

SHA-256：426ffaacc1e5f6b132a1c3c5a83a31a74ad0b3fc9bd12ce236e83da843a8b014
