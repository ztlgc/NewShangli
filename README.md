# 尚礼 NewShangli

尚礼是一款基于 Flutter 开发的礼账与人情往来管理应用，适用于婚礼、满月、乔迁、生日、商务往来等需要长期维护收礼、送礼、关系人和回礼状态的场景。

项目当前以 Android 端为主要运行目标，采用本地优先的数据方案，默认将核心数据保存在 SQLite 数据库中，同时提供导入导出、统计分析、备份恢复和可选云同步能力。

## 项目简介

如果你希望把礼尚往来从零散的纸笔记录、聊天记录或表格中整理出来，尚礼可以提供一套更完整的管理方式：

- 以账簿为核心，按婚礼、乔迁、生日、商务等场景独立管理礼账数据。
- 以关系人为中心，持续追踪联系人资料、往来明细、回礼状态和历史记录。
- 以本地优先为基础，兼顾数据导入导出、备份恢复与可选云同步能力。
- 以统计分析为补充，帮助快速查看时间趋势、金额占比、排行和往来结构。

## 核心能力概览

- 本地优先：基于 Drift + SQLite 保存核心业务数据，适合个人长期稳定使用。
- 礼账管理：支持独立账簿、默认账簿、自定义场景和多类型往来记录。
- 关系追踪：围绕联系人、关系类型、事由和往来历史构建完整的人情记录链路。
- 数据流转：支持 CSV、Excel 导入，以及 Excel、ZIP 导出和本地媒体文件打包。
- 安全备份：支持本地备份恢复、WebDAV 远程备份和 Supabase 云同步扩展。
- 图表分析：支持趋势、占比、排行等统计视图，便于复盘礼账结构和往来情况。

## 功能特性

- 礼账管理：按婚礼、生日、乔迁、商务等场景创建独立账簿，支持默认账簿和自定义账簿。
- 收支记录：记录收礼、送礼、金额、日期、事由、支付方式、备注和附件。
- 关系人管理：维护联系人资料、关系类型、头像、电话和备注，支持拼音索引与快速检索。
- 往来明细：在联系人、账簿和记录维度查看历史往来，辅助判断回礼和关系维护。
- 统计分析：按时间范围、账簿、联系人和事由查看金额趋势、占比和排行。
- 数据导入：支持 CSV、Excel 导入，可按字段映射、任务进度和错误日志处理批量数据。
- 数据导出：支持 Excel 和 ZIP 导出，可携带头像、附件等本地媒体文件。
- 备份恢复：支持本地备份、恢复和 WebDAV 远程备份配置。
- 云同步：内置 Supabase 同步服务与数据库迁移脚本，可用于多端数据同步方案。
- 回收站：核心数据使用软删除机制，降低误删风险。
- 日期支持：提供农历日期选择能力，适配传统礼俗记录习惯。

## 技术栈

| 类别 | 技术 |
| --- | --- |
| 应用框架 | Flutter / Material |
| 语言 | Dart 3.10+ |
| 本地数据库 | Drift + SQLite |
| 状态与依赖注入 | Provider / InheritedWidget |
| 图表 | fl_chart |
| 导入导出 | excel / csv / archive |
| 文件与分享 | file_picker / path_provider / share_plus |
| 日期 | lunar |
| 拼音索引 | lpinyin / azlistview |
| 云服务 | Supabase |
| 备份 | WebDAV |

## 项目结构

```text
lib/
  main.dart                       # 应用入口
  ui/                             # 页面、主题、组件和导航
    pages/                        # 业务页面
    widgets/                      # 可复用 UI 组件
    stats/                        # 统计页视图模型
  data/local/drift/               # Drift 表定义、DAO、数据库迁移
  stats/                          # 统计模型、仓库和计算逻辑
  import/                         # CSV / Excel 导入服务
  export/                         # Excel / ZIP 导出服务
  backup/                         # 本地备份、WebDAV、Supabase 同步
  media/                          # 头像和附件存储
  utils/                          # 通用工具

test/                             # 单元测试与 Widget 测试
integration_test/                 # 集成测试
supabase/migrations/              # Supabase 数据库迁移脚本
assets/images/                    # 应用资源
```

## 本地开发

### 环境要求

- Flutter SDK：需包含 Dart 3.10.1 或更高版本
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
flutter build apk --release
```

构建产物位于：

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 云同步与配置说明

项目包含 Supabase 同步服务和 `supabase/migrations/` 下的数据库迁移脚本。当前应用入口会初始化 Supabase 客户端；如果你准备公开发布或二次部署，建议将 Supabase URL、anon key 等客户端配置改为 `--dart-define`、本地配置文件或安全的构建环境注入方式。

WebDAV 备份配置由用户在应用内填写并保存在本机偏好设置中。请避免在代码仓库中提交个人 WebDAV 地址、账号、密码或真实备份文件。

## 数据与隐私

- 主要业务数据保存在应用本地 SQLite 数据库中。
- 用户主动导出时会生成 Excel 或 ZIP 文件。
- 用户启用 WebDAV 或 Supabase 同步后，相关数据才会上传到对应远程服务。
- 头像、附件等媒体文件可能被打包进导出 ZIP 或备份文件，请在分享前确认内容。

## 开源前检查清单

- 确认根目录 `LICENSE` 文件、README 说明与仓库实际授权协议保持一致。
- 将 Supabase 配置迁移到环境变量或构建参数。
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

对于涉及数据库结构的变更，请同步更新 Drift migration、相关测试和 `supabase/migrations/` 中对应脚本。

## 许可证

本项目当前采用 `MIT License`，许可证全文见根目录 [LICENSE](file:///e:/NewShangli/LICENSE)。

MIT 是宽松型开源许可证，允许个人和组织自由使用、复制、修改、分发以及商用，但需保留原始版权声明和许可证文本。
