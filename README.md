# 尚礼 NewShangli

尚礼是一款基于 Flutter 开发的礼账与人情往来记录应用，面向婚礼、满月、乔迁、商务往来等需要长期追踪收礼、送礼、关系人和回礼状态的场景。

项目当前以 Android 端为主要运行目标，数据优先保存在本地 SQLite 数据库中，并提供导入导出、备份恢复、统计分析和可选的云同步能力。

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

- 补充 `LICENSE` 文件，并在下方许可证章节写明协议。
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

当前仓库尚未包含开源许可证。正式开源前请根据你的发布目标补充 `LICENSE` 文件，例如 MIT、Apache-2.0 或 GPL 系列协议。
