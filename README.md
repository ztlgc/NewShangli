# 礼记 NewShangli

当前版本：[礼记 1.2.2](https://github.com/ztlgc/NewShangli/releases/tag/1.2.2)。Android ARM64 安装包及 SHA-256 校验文件见发布页面；变更与验证记录见 [1.2.2 发布说明](docs/releases/1.2.2.md)。

礼记是一款基于 Flutter 开发的礼账与人情往来管理应用，适用于婚礼、满月、乔迁、生日、商务往来等需要长期维护收礼、送礼、关系人和回礼状态的场景。

项目当前以 Android 端为主要运行目标，采用本地优先的数据方案，默认将核心数据保存在 SQLite 数据库中，同时提供导入导出、统计分析、备份恢复和 WebDAV 备份能力。

## 项目简介

如果你希望把礼尚往来从零散的纸笔记录、聊天记录或表格中整理出来，礼记可以提供一套更完整的管理方式：

- 以账簿为核心，按婚礼、乔迁、生日、商务等场景独立管理礼账数据。
- 以关系人为中心，持续追踪联系人资料、往来明细、回礼状态和历史记录。
- 以本地优先为基础，兼顾数据导入导出、备份恢复与 WebDAV 备份能力。
- 以统计分析为补充，帮助快速查看时间趋势、金额占比、排行和往来结构。

## 核心能力概览

- 本地优先：基于 Drift + SQLite 保存核心业务数据，适合个人长期稳定使用。
- 礼账管理：支持独立账簿、默认账簿、自定义场景和多类型往来记录。
- 关系追踪：围绕联系人、关系类型、事由和往来历史构建完整的人情记录链路。
- 数据流转：支持 CSV、Excel 导入，以及 Excel、ZIP 导出和本地媒体文件打包。
- 安全备份：支持本地备份恢复、WebDAV 远程备份。
- 图表分析：支持趋势、占比、排行等统计视图，便于复盘礼账结构和往来情况。

## 功能特性

- 礼账管理：按婚礼、生日、乔迁、商务等场景创建独立账簿，支持默认账簿和自定义账簿。
- 收支记录：记录收礼、送礼、金额、日期、事由、备注和附件。账簿详情支持弹窗新增，沿用并锁定当前账簿、事由和日期。
- 关系人管理：维护联系人资料、关系类型、头像、电话和备注，支持拼音索引与快速检索。
- 往来明细：在联系人、账簿和记录维度查看历史往来，辅助判断回礼和关系维护。
- 统计分析：按时间范围、账簿、联系人和事由查看金额趋势、占比和排行。
- 数据导入：支持 CSV、Excel 导入，可按字段映射、任务进度和错误日志处理批量数据。
- 数据导出：支持 Excel 和 ZIP 导出，可携带头像、附件等本地媒体文件。
- 账簿 PDF：进入账簿详情，点击右上角菜单中的“导出 PDF”，生成后会打开系统分享，也可从同一菜单再次分享。采用 A4 竖向四列（序号、名字、金额、备注），首页展示事由、账簿日期、记录数量和金额合计；支出以负数表示，长备注自动换行，多页重复表头。导出全部有效收支记录，默认账簿沿用详情页的汇总范围；文件保存在应用文档目录的 `exports/pdf/`。
  PDF 导出使用设备系统字体渲染中文，离线可用，不内置或下载 PDF 字体。文字以 216 DPI 图片写入 PDF，不能直接选中复制。
- 备份恢复：支持本地备份、恢复和 WebDAV 远程备份配置。
- 回收站：核心数据使用软删除机制，降低误删风险。
- 日期支持：提供农历日期选择能力，适配传统礼俗记录习惯。

## 技术栈

| 类别 | 技术 |
| --- | --- |
| 应用框架 | Flutter / Forui / Material |
| 语言 | Dart 3.10+ |
| 本地数据库 | Drift + SQLite |
| 状态与依赖注入 | Provider / InheritedWidget |
| 图表 | fl_chart |
| 导入导出 | excel / csv / archive |
| 文件与分享 | file_picker / path_provider / share_plus |
| 日期 | lunar |
| 拼音索引 | lpinyin / azlistview |
| 备份 | WebDAV |

## 项目结构

```text
lib/
  main.dart                       # 应用入口
  ui/                             # 页面、主题、组件和导航
    pages/                        # 业务页面
    widgets/                      # 可复用 UI 组件
    stats/                        # 统计页视图模型
  data/local/drift/               # Drift 表定义、DAO、数据库初始化
  stats/                          # 统计模型、仓库和计算逻辑
  import/                         # CSV / Excel 导入服务
  export/                         # Excel / ZIP / 账簿 PDF 导出服务
  backup/                         # 本地备份恢复与 WebDAV 备份
  platform/                       # 文件选择、系统分享与目录的平台接口
  media/                          # 头像和附件存储
  utils/                          # 通用工具

test/                             # 单元测试与 Widget 测试
integration_test/                 # 集成测试
supabase/migrations/              # 停用的历史云迁移脚本
assets/images/                    # 应用资源
```

## 本地开发

### 环境要求

- Flutter SDK：需包含 Dart 3.13.0 或更高版本
- Android Studio 或可用的 Android SDK
- 一台 Android 设备或模拟器

### 安装依赖

```bash
flutter pub get
```

### 生成 Drift 代码

仓库中已包含生成后的 `app_database.g.dart`。如果修改了 Drift 表、DAO 或数据库定义，重新生成代码：

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 运行应用

```bash
flutter run
```

### 运行测试

```bash
flutter test
```

如需运行集成测试，请先连接设备或启动模拟器：

```bash
flutter test integration_test
```

### 构建 Android 安装包

```bash
flutter build apk --split-per-abi --target-platform android-arm64 --release
```

构建产物位于：

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## 备份与恢复

应用无需账号即可使用。通过设置中的数据备份页面保存或恢复完整本地备份，也可配置自己的 WebDAV 地址进行整包备份。WebDAV 不执行双向数据同步；恢复前须确认覆盖操作。自动备份后台调度尚未实现，入口保持禁用。

当前设计规范见 `DESIGN_SPEC.md`，本轮验证记录见 `docs/LOCAL_ONLY_UI_VERIFICATION.md`，鸿蒙迁移准备和验证清单见 `docs/HARMONYOS_MIGRATION_READINESS.md`。历史 Supabase SQL 和本地配置未参与运行与打包，不再作为功能入口；无需配置云服务即可启动。

## 数据与隐私

- 主要业务数据保存在应用本地 SQLite 数据库中。
- 用户主动导出时会生成 Excel 或 ZIP 文件。
- 用户启用 WebDAV 备份后，相关数据才会上传到对应远程服务。
- 头像、附件等媒体文件可能被打包进导出 ZIP 或备份文件，请在分享前确认内容。

## 开源前检查清单

- 确认根目录 `LICENSE` 文件、README 说明与仓库实际授权协议保持一致。
- 检查仓库中是否包含真实用户数据、备份文件、截图或私有配置。
- 运行 `flutter test`，确认核心测试通过。
- 如需发布安装包，使用正式签名并避免提交 keystore 与签名密码。

## 贡献

欢迎通过 Issue 和 Pull Request 参与改进。提交代码前建议先执行：

```bash
dart format lib test integration_test
flutter analyze
flutter test
```

当前数据库结构版本为 15，仅支持新建数据库，不提供历史版本数据升级或偏好设置迁移。旧版安装需清除应用数据后重新使用；备份恢复仅支持当前数据库结构。涉及结构变更时，请同步更新新库初始化、相关测试和备份恢复校验。

## 许可证

本项目当前采用 `MIT License`，许可证全文见根目录 [LICENSE](file:///e:/NewShangli/LICENSE)。

MIT 是宽松型开源许可证，允许个人和组织自由使用、复制、修改、分发以及商用，但需保留原始版权声明和许可证文本。
