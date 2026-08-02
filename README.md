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

## 接入 Supabase（云同步）

应用内置于可选的 Supabase 云同步能力，支持账簿、关系人、礼金记录、附件等数据的云端备份与多端恢复。

### 1. 创建 Supabase 项目

在 [supabase.com](https://supabase.com) 注册并创建一个项目。免费套餐包含 500 MB 数据库和 1 GB 存储空间，满足个人使用。

### 2. 获取连接信息

进入项目控制台，点击左侧 **Settings → API**，复制：

- **Project URL**（例如 `https://xxxxx.supabase.co`）
- **anon public key**（以 `eyJ` 开头的 JWT token）

### 3. 配置本地连接文件

在项目根目录创建 `supabase.local.json`（已加入 `.gitignore`，不会提交到仓库）：

```json
{
  "url": "https://你的项目ID.supabase.co",
  "anonKey": "你的 anon public key"
}
```

应用启动时会自动加载该文件并初始化 Supabase 客户端。

### 4. 开启认证方式

应用通过 Supabase Auth 进行用户身份认证。进入 **Authentication → Providers**，至少开启一种登录方式：

- **Email**：最简方式，开启后用户可通过邮箱注册和登录。建议关闭"确认邮件"以简化开发测试（生产环境建议开启）。

### 5. 运行数据库迁移

以下 SQL 脚本需要在 Supabase 控制台的 **SQL Editor** 中依次执行。这些脚本会创建云同步所需的数据库表和存储桶访问策略。

#### 5.1 核心数据表

按顺序执行：

| 顺序 | 文件 | 说明 |
| --- | --- | --- |
| 1 | `supabase/migrations/create_tables.sql` | 创建核心业务表（账簿、关系人、礼金记录、事由、关系类型、联系人关系） |
| 2 | `supabase/migrations/create_local_aligned_tables.sql` | 对齐本地数据库结构，添加 user_id 字段和 RLS 策略 |
| 3 | `supabase/migrations/add_account_book_attachments.sql` | 账簿表增加 attachments 字段 |
| 4 | `supabase/migrations/add_book_time_to_account_book.sql` | 账簿表增加 book_time 字段 |
| 5 | `supabase/migrations/change_book_time_to_date.sql` | 调整 book_time 字段类型 |
| 6 | `supabase/migrations/add_normalized_name_columns.sql` | 添加 normalized_name 字段，支持大小写不敏感去重 |

#### 5.2 存储桶与 RLS 策略（必须）

上传附件和备份文件前必须创建存储桶并配置访问策略，否则上传会失败（403 RLS violation）：

| 文件 | 说明 |
| --- | --- |
| `supabase/migrations/create_storage_media_bucket.sql` | 创建 `media` 私有存储桶，配置 RLS 策略——仅允许已登录用户读写自己 ID 前缀下的文件 |
| `supabase/migrations/create_storage_backups_bucket.sql` | 创建 `backups` 私有存储桶，配置同上 |

#### 5.3 云备份版本记录

| 文件 | 说明 |
| --- | --- |
| `supabase/migrations/create_cloud_backup_version.sql` | 创建云备份版本记录表，用于追踪自动/手动备份历史 |

### 6. 开启 Storage 功能

在 Supabase 控制台左侧 **Storage** 中确认 `media` 和 `backups` 两个存储桶已显示。如果运行了 5.2 中的迁移脚本，它们会自动创建。如果没有看到，可以在 SQL Editor 中手动执行对应迁移。

### 7. 验证

启动应用后进入云同步页面，登录账号并执行一次同步。如果附件上传成功（不再报 RLS 错误），说明配置完成。

### 迁移文件说明

所有迁移脚本位于 `supabase/migrations/` 目录下。脚本使用 `INSERT ... ON CONFLICT DO NOTHING` 和 `DROP POLICY IF EXISTS` 等幂等语法，即使在已有数据的项目上重复执行也是安全的。

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
