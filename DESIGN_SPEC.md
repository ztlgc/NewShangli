# 设计规范文档

## 1. 技术架构规范

### 1.1 架构模式
采用"Flutter 分层架构 + 响应式数据流"，在保证关注点分离的前提下保持轻量灵活。

- **UI 层**：使用 Flutter Widget 构建界面，StatefulWidget / StatelessWidget 负责渲染与交互派发；页面状态通过 `StreamBuilder` / `ValueListenableBuilder` 订阅 Drift 实时流获取。
- **数据层**：Drift 提供类型安全的 ORM，DAO 负责数据库读写与实时流暴露；业务逻辑内聚在各 Service（如 `DataImportService`、`DataExportService`、`DataBackupService` 等）中。
- **状态管理**：Provider（`ChangeNotifierProvider` / `InheritedWidget`）用于全局会话与账簿作用域注入；页面内状态使用 `setState` + Drift 实时流驱动。

> **说明**：项目没有引入独立 Domain/UseCase 层。简单 CRUD 由页面直接调用 DAO；涉及组合逻辑的场景（如数据导入解析、统计计算、备份/恢复）封装在对应 Service 中。如后续需求膨胀，可考虑抽取 UseCase 层。

**关键约束**：
- **账簿是一级上下文**：核心数据（关系人、收支记录）必须归属 `book_id`，所有查询/写入必须在账簿范围内执行。
- **备份走 WebDAV**：备份能力封装在 `DataBackupService` + `WebDavClient`（基于 HTTP），统一管理配置、上传、下载与恢复。

### 1.2 技术栈与依赖

| 类别 | 技术选型 | 说明 |
| --- | --- | --- |
| **语言** | Dart 3.10+ | Flutter SDK ^3.10 |
| **框架** | Flutter | Material 3 |
| **数据库 ORM** | Drift 2.26+ | 类型安全 SQL，实时流驱动 |
| **底层 SQLite** | sqflite + sqlite3_flutter_libs | 本地 SQLite 引擎 |
| **状态管理** | Provider 6.x | ChangeNotifier + InheritedWidget |
| **本地配置** | shared_preferences | 简单 KV 存储 |
| **导航** | 手动路由（`Navigator` 封装） | `AppNav` 工具类 |
| **图表** | fl_chart | 统计页柱状图/饼图 |
| **日历/农历** | lunar | 农历日期支持 |
| **拼音索引** | lpinyin + azlistview | 联系人 A-Z 索引 |
| **数据导出** | excel / csv / archive | Excel/CSV/ZIP 导出 |
| **文件选择** | file_picker | 导入文件选取 |
| **分享** | share_plus | 系统分享 |
| **UUID** | uuid | 主键生成 |

### 1.3 数据流模式
- **数据层**：DAO 返回 `Stream`（Drift 实时流）用于列表实时更新，写入操作使用 `Future` 函数。
- **Service 层**：封装复杂业务逻辑（导入解析、统计聚合、备份上传等），返回 `Future<Result>` 或直接操作 DAO。
- **UI 层**：页面通过 `StreamBuilder` 监听 Drift 实时流实现自动刷新；一次性操作（保存、删除）调用 DAO/Service 后弹出 Toast 反馈。

### 1.4 项目目录结构

```
lib/
  main.dart                       # 应用入口
  ui/
    app.dart                      # MaterialApp 根组件
    app_data.dart                 # 旧数据兼容层（AppData）
    app_database_scope.dart       # Drift 数据库作用域注入
    app_session.dart              # 会话状态管理
    app_theme.dart                # Material 3 主题定义
    app_tokens.dart               # 设计令牌（颜色/字号/间距/阴影）
    app_toast.dart                # Toast 通知
    app_scaffold.dart             # 通用页面脚手架
    components.dart               # 通用 UI 组件
    contact_avatar.dart           # 联系人头像组件
    lunar_date_picker.dart        # 农历日期选择器
    navigation.dart               # 路由导航工具
    pages/                        # 全部页面
    widgets/                      # 可复用小部件
    stats/                        # 统计页视图模型
  data/
    local/
      drift/
        tables.dart               # Drift 表定义
        app_database.dart         # 数据库配置与迁移
        app_database.g.dart       # Drift 生成代码
        converters.dart           # 类型转换器
        reason_relation_migrator.dart  # 事由/关系数据迁移
        daos/                     # 数据访问对象
  backup/                         # WebDAV 备份模块
  export/                         # 数据导出模块
  import/                         # 数据导入模块
  media/                          # 媒体存储服务
  stats/                          # 统计引擎与数据仓库
  utils/                          # 工具函数
```

### 1.5 错误处理策略
- 数据库错误：DAO 层 try-catch 捕获，通过 `AppToast` 反馈用户
- 业务错误：Service 层统一返回结果枚举或抛出业务异常
- 网络错误（WebDAV）：`WebDavClient` 内部封装 HTTP 错误码处理
- 未知错误：全局 Flutter ErrorWidget 兜底

## 2. 数据模型定义

### 2.1 账簿表 account_book

| 字段 | 类型 | 约束 | 默认值 | 说明 | 索引 |
| --- | --- | --- | --- | --- | --- |
| book_id | TEXT | 主键 | UUID | 账簿唯一标识 | 主键 |
| name | TEXT | 非空, 1-32字符 | - | 账簿名称 | - |
| reason_type | TEXT | 非空 | 结婚礼金 | 事由类型 | - |
| theme_color | TEXT | 非空 | #312E81 | 主题色（Hex） | - |
| icon | TEXT | 可空 | - | 图标名称 | - |
| description | TEXT | 可空 | - | 备注描述 | - |
| is_default | INTEGER | 非空, CHECK(0/1) | 0 | 是否默认账簿 | - |
| created_at | INTEGER | 非空 | - | 创建时间戳 | - |
| updated_at | INTEGER | 非空 | - | 更新时间戳 | - |
| deleted_at | INTEGER | 可空 | NULL | 软删除时间戳 | - |

### 2.2 关系人表 person

| 字段 | 类型 | 约束 | 默认值 | 说明 | 索引 |
| --- | --- | --- | --- | --- | --- |
| person_id | TEXT | 主键 | UUID | 关系人唯一标识 | 主键 |
| book_id | TEXT | 外键→account_book, CASCADE | - | 所属账簿 | idx_person_book_name |
| name | TEXT | 非空, 1-32字符 | - | 姓名 | idx_person_book_name |
| relationship_type | TEXT | 非空 | 其他 | 关系类型 | - |
| phone | TEXT | 可空 | - | 手机号 | - |
| birthday | TEXT | 可空 | - | 生日 | - |
| anniversary | TEXT | 可空 | - | 纪念日 | - |
| avatar_uri | TEXT | 可空 | - | 头像路径 | - |
| note | TEXT | 可空 | - | 备注 | - |
| created_at | INTEGER | 非空 | - | 创建时间戳 | - |
| updated_at | INTEGER | 非空 | - | 更新时间戳 | - |
| deleted_at | INTEGER | 可空 | NULL | 软删除时间戳 | - |

### 2.3 礼金记录表 gift_record

| 字段 | 类型 | 约束 | 默认值 | 说明 | 索引 |
| --- | --- | --- | --- | --- | --- |
| record_id | TEXT | 主键 | UUID | 记录唯一标识 | 主键 |
| book_id | TEXT | 外键→account_book, CASCADE | - | 所属账簿 | idx…book_occurred |
| person_id | TEXT | 外键→person, CASCADE | - | 关联关系人 | idx…book_person |
| direction | TEXT | 非空, CHECK('收入'/'支出') | 收入 | 收/支类型 | - |
| amount_cent | INTEGER | 非空, CHECK(>0) | - | 金额（分） | - |
| currency | TEXT | 非空 | CNY | 币种 | - |
| event_name | TEXT | 可空 | - | 事由 | - |
| occurred_at | INTEGER | 非空 | - | 发生时间戳 | idx…book_occurred |
| payment_method | TEXT | 可空 | - | 支付方式 | - |
| note | TEXT | 可空 | - | 备注 | - |
| attachments | TEXT | 可空 | - | 附件路径列表（JSON数组） | - |
| created_at | INTEGER | 非空 | - | 创建时间戳 | - |
| updated_at | INTEGER | 非空 | - | 更新时间戳 | - |
| deleted_at | INTEGER | 可空 | NULL | 软删除时间戳 | - |

### 2.4 事由表 reason

| 字段 | 类型 | 约束 | 默认值 | 说明 | 索引 |
| --- | --- | --- | --- | --- | --- |
| reason_id | TEXT | 主键 | - | 事由唯一标识 | 主键 |
| name | TEXT | 非空, 1-64字符 | - | 事由名称 | UNIQUE idx_reason_name |
| description | TEXT | 可空 | - | 事由描述 | - |
| enabled | INTEGER(BOOL) | 非空 | true | 是否启用 | - |
| created_at | INTEGER | 非空 | - | 创建时间戳 | - |
| updated_at | INTEGER | 非空 | - | 更新时间戳 | idx_reason_updated_at |

### 2.5 关系类型表 relation_type

| 字段 | 类型 | 约束 | 默认值 | 说明 | 索引 |
| --- | --- | --- | --- | --- | --- |
| type_id | TEXT | 主键 | - | 类型唯一标识 | 主键 |
| name | TEXT | 非空, 1-64字符 | - | 类型名称 | UNIQUE idx_relation_type_name |
| created_at | INTEGER | 非空 | - | 创建时间戳 | - |
| updated_at | INTEGER | 非空 | - | 更新时间戳 | idx_relation_type_updated_at |

### 2.6 联系人关系表 contact_relation

| 字段 | 类型 | 约束 | 默认值 | 说明 | 索引 |
| --- | --- | --- | --- | --- | --- |
| relation_id | TEXT | 主键 | - | 关系唯一标识 | 主键 |
| person_a_id | TEXT | 外键→person, CASCADE | - | 关系人A | UNIQUE idx…pair_type |
| person_b_id | TEXT | 外键→person, CASCADE | - | 关系人B | UNIQUE idx…pair_type |
| type_id | TEXT | 外键→relation_type, RESTRICT | - | 关系类型 | UNIQUE idx…pair_type |
| note | TEXT | 可空 | - | 备注 | - |
| created_at | INTEGER | 非空 | - | 创建时间戳 | - |
| updated_at | INTEGER | 非空 | - | 更新时间戳 | idx…updated_at |

### 2.7 数据导入任务表 data_import_job

| 字段 | 类型 | 约束 | 默认值 | 说明 | 索引 |
| --- | --- | --- | --- | --- | --- |
| job_id | TEXT | 主键 | UUID | 任务唯一标识 | 主键 |
| book_id | TEXT | 外键→account_book, CASCADE | - | 目标账簿 | idx…book_started |
| file_path | TEXT | 非空 | - | 文件路径 | - |
| file_name | TEXT | 非空 | - | 文件名 | - |
| file_hash | TEXT | 非空 | - | 文件哈希 | - |
| file_size | INTEGER | 非空 | - | 文件大小 | - |
| format | TEXT | 非空 | - | 文件格式 | - |
| status | TEXT | 非空 | - | 任务状态 | idx…status_updated |
| import_kind | TEXT | 非空 | - | 导入类型 | - |
| mapping_json | TEXT | 可空 | - | 列映射规则（JSON） | - |
| total_rows | INTEGER | 可空 | - | 总行数 | - |
| processed_rows | INTEGER | 非空 | 0 | 已处理行数 | - |
| success_rows | INTEGER | 非空 | 0 | 成功行数 | - |
| skipped_rows | INTEGER | 非空 | 0 | 跳过行数 | - |
| failed_rows | INTEGER | 非空 | 0 | 失败行数 | - |
| byte_offset | INTEGER | 非空 | 0 | 字节偏移量 | - |
| last_row_index | INTEGER | 非空 | 0 | 上次行索引 | - |
| error_log_path | TEXT | 可空 | - | 错误日志路径 | - |
| started_at | INTEGER | 非空 | - | 开始时间戳 | idx…book_started |
| finished_at | INTEGER | 可空 | - | 完成时间戳 | - |
| updated_at | INTEGER | 非空 | - | 更新时间戳 | idx…status_updated |

### 2.8 数据实体与转换规则
- 金额统一使用**分**为单位（`amount_cent`），CHECK 约束确保 > 0
- 时间统一使用 **Unix 时间戳**（毫秒级 INTEGER）
- attachments 使用 `JsonStringListConverter` 存储为 JSON 数组字符串
- 软删除通过 `deleted_at` 实现（`account_book`、`person`、`gift_record` 支持软删除）

### 2.9 数据校验策略
- 金额必须大于 0（数据库 CHECK 约束）
- 姓名/账簿名长度 1-32 字符（数据库 CHECK 约束）
- direction 仅允许 '收入' / '支出'（数据库 CHECK 约束）
- is_default 仅允许 0 / 1（数据库 CHECK 约束）
- 外键级联规则：account_book 删除时 CASCADE 关联数据；person 删除时 CASCADE 记录
- 每个用户至少保留一个默认账簿

### 2.10 数据库版本管理
- 使用 Drift 的 `MigrationStrategy` 处理 schema 升级
- 当前版本：**schema version 8**
- 迁移历史：v1（核心四表）→ v2（data_import_job）→ v3（reason_type 重命名）→ v7（软删除 deleted_at）→ v8（reason/relation_type/contact_relation 表）
- `beforeOpen` 统一开启 `PRAGMA foreign_keys = ON`、`journal_mode = WAL`、`synchronous = NORMAL`

### 2.11 索引策略
- person：`(book_id, name)`
- gift_record：`(book_id, occurred_at)`、`(book_id, person_id)`
- reason：`UNIQUE (name COLLATE NOCASE)`、`(updated_at DESC)`
- relation_type：`UNIQUE (name COLLATE NOCASE)`、`(updated_at DESC)`
- contact_relation：`UNIQUE (person_a_id, person_b_id, type_id)`、`(updated_at DESC)`
- data_import_job：`(book_id, started_at)`、`(status, updated_at)`

## 3. UI/UX 标准

### 3.1 Material Design 3 规范

#### 3.1.1 核心色彩系统 (Color System)

| Token | 色值 (Hex) | 用途说明 |
| --- | --- | --- |
| **brandPrimary** | `#312E81` (indigo-900) | 核心品牌色，用于主要按钮、导航选中态 |
| **brandSecondary** | `#4F46E5` (indigo-600) | 次级品牌色，用于装饰元素、进度条 |
| **brandSoft** | `#EEF2FF` (indigo-50) | 品牌浅色底，用于选中态背景 |
| **surfaceApp** | `#F9FAFB` (gray-50) | 全局页面背景色 |
| **surfaceCard** | `#FFFFFF` (white) | 卡片背景色 |
| **surfaceSubtle** | `#F3F4F6` (gray-100) | 次级背景色 |
| **textPrimary** | `#111827` (gray-900) | 主要文字 |
| **textSecondary** | `#4B5563` (gray-600) | 次要文字 |
| **textTertiary** | `#6B7280` (gray-500) | 三级文字 |
| **textMuted** | `#9CA3AF` (gray-400) | 弱化文字 |
| **stateSuccess** | `#16A34A` (green-600) | 收入/成功色 |
| **stateDanger** | `#EF4444` (red-500) | 支出/错误色 |
| **stateWarning** | `#F97316` (orange-500) | 警告色 |
| **borderDefault** | `#E5E7EB` (gray-200) | 默认边框色 |
| **borderSubtle** | `#F3F4F6` (gray-100) | 轻微分割线 |

支持暗色模式（Dark Theme），暗色下主色调调整为 indigo-500，背景使用 gray-800/gray-900。

#### 3.1.2 排版规范 (Typography)

| 样式名称 | 字号 | 字重 | 用途 |
| --- | --- | --- | --- |
| **h1** | 24px | Bold (700) | 页面大标题 |
| **h2** | 20px | Bold (700) | 模块/卡片标题 |
| **h3** | 18px | Bold (700) | 次级模块标题 |
| **bodyStrong** | 16px | Medium (500) | 重要正文 |
| **body** | 14px | Regular (400) | 普通正文 |
| **caption** | 12px | Regular (400) | 辅助说明 |
| **overline** | 10px | Bold (700) | 微小标签 |

字体族：`Noto Sans SC`，回退：`Noto Sans CJK SC` → `Noto Sans` → `Roboto` → `sans-serif`

附加字号：30px、36px 用于金额等大数字展示。

#### 3.1.3 组件样式特征 (Shape & Elevation)
- **圆角 (Corner Radius)**：
  - sm: `2px` | md: `6px` | lg: `8px`
  - xl: `12px`（按钮）| 2xl: `16px`（卡片/弹窗）
  - 3xl: `24px` | heroBottom: `30px`（顶部英雄区底部）
  - pill: `9999px`（标签/Chip）
- **阴影 (Elevation)**：
  - sm：轻阴影（卡片）
  - lg：中层级阴影
  - xl：高层级阴影（悬浮按钮/弹窗）
  - brandSoft/brandFab：品牌色调阴影（FAB）
- **间距 (Spacing)**：
  - 基础间距：4px (space1) → 8px (space2) → 12px (space3) → 16px (space4) → 20px (space5) → 24px (space6) → 32px (space8) → 40px (space10) → 48px (space12) → 64px (space16)
  - 页面边距：16px
  - 模块间距：24px
  - 内容间距：12px
  - 最小点击区域：44px

#### 3.1.4 交互状态 (Interaction)
- 全局禁用 InkSplash（`NoSplash.splashFactory`）
- 全局禁用 highlight / hover 效果（透明色）
- 页面切换动画：250ms 淡入+微滑（0.06 水平偏移），200ms 反向

### 3.2 界面原型清单

#### 3.2.1 主页面（首页 → record_home_page）
**布局结构**：
- **顶部应用栏**：应用标题 + 搜索 + 更多菜单
- **Tab 导航**：收支记录 | 关系人 | 统计 | 设置
- **内容区域**：对应 Tab 的内容列表
- **悬浮操作按钮**：添加收支记录

**收支记录 Tab**：
- 顶部：月份分组筛选
- 列表项：头像、姓名、事由、金额（收入绿色/支出红色）、时间
- 支持搜索、详情跳转

#### 3.2.2 收支录入页（record_add_page）
**布局结构**：
- **顶部应用栏**：标题"记录收支" + 保存按钮 + 关闭按钮
- **表单区域**：
  - 类型切换：收礼/送礼（分段控制器）
  - 金额输入：大字号输入框 + 快捷金额按钮
  - 关系人选择：列表选择或搜索
  - 事由输入：文本框 + 常用事由标签
  - 日期选择：日期选择器（含农历），默认当天
  - 支付方式：选择器
  - 备注：多行文本框
  - 附件：图片上传区域

#### 3.2.3 收支详情页（record_detail_page）
**布局结构**：
- **顶部应用栏**：标题"记录详情" + 编辑/删除操作
- **金额卡片**：大字号展示金额，区分收/支颜色
- **详细信息列表**：关系人、事由、时间、支付方式
- **备注区域**：展示备注文本
- **附件区域**：展示附件

#### 3.2.4 关系人列表页（person_list_page）
**布局结构**：
- **顶部应用栏**：标题"关系人" + 添加按钮
- **搜索栏**：支持姓名搜索
- **列表区域**：
  - 首字母索引导航（A-Z，azlistview）
  - 按拼音首字母分组展示
  - 列表项：头像、姓名、关系类型

#### 3.2.5 关系人详情页（person_detail_page）
**布局结构**：
- **顶部应用栏**：返回按钮 + 编辑按钮
- **头部信息卡片**：头像、姓名、关系类型、联系方式
- **统计信息**：总收礼/总送礼/差额（从 Drift 实时计算）
- **信息列表**：生日（含农历）、纪念日、备注
- **历史记录**：按时间倒序展示往来记录
- **底部操作栏**：记一笔

#### 3.2.6 关系人编辑页（person_edit_page）
**布局结构**：
- **顶部应用栏**：标题"编辑关系人" + 保存按钮
- **表单区域**：
  - 头像上传：点击更换（MediaStorageService）
  - 基础信息：姓名、关系类型、手机号
  - 重要日期：生日（含农历选择器）、纪念日
  - 备注信息
- **底部操作**：删除联系人按钮

#### 3.2.7 统计图表页（stats_page）
**布局结构**：
- **顶部应用栏**：标题"统计分析"
- **筛选区域**：月度 / 年度 / 自定义日期范围（左对齐展示）
- **概览卡片**：总收入、总支出
- **图表区域**：
  - 收支趋势（柱状图，fl_chart）
  - 支出分类占比（饼图）
- **排行榜**：人情往来 Top 列表

#### 3.2.8 设置页（settings_home_page）
**布局结构**：
- **顶部应用栏**：标题"设置"
- **设置列表**：
  - 账簿管理
  - 事由管理
  - 关系类型管理
  - 数据备份
  - 数据导出
  - 数据导入
  - 回收站

#### 3.2.12 账簿管理页（account_books_page）
**布局结构**：
- **顶部应用栏**：标题"账簿管理" + 添加按钮
- **账簿列表**：
  - 展示所有账簿卡片
  - 标记"当前使用"状态
  - 包含记录数统计
  - 操作按钮：切换、编辑

#### 3.2.13 账簿编辑页（account_book_edit_page）
**布局结构**：
- **顶部应用栏**：标题"编辑账簿" + 保存按钮
- **表单区域**：
  - 账簿名称
  - 事由类型选择（从 Drift reason 表读取）
  - 主题色选择器
  - 备注描述
  - "设为默认账簿"开关
- **底部操作**：删除账簿按钮

#### 3.2.14 账簿详情页（account_book_detail_page）
**布局结构**：
- 展示账簿基本信息
- 统计概览
- 快捷操作入口

#### 3.2.15 账簿记录页（account_book_records_page）
**布局结构**：
- 账簿下的收支记录列表
- 筛选与排序功能

#### 3.2.16 事由管理页（reason_manage_page + reason_detail_page）
**布局结构**：
- **列表页**：展示所有事由，支持启用/禁用
- **详情页**：编辑事由名称、描述

#### 3.2.17 关系类型管理页（relation_type_manage_page）
**布局结构**：
- **列表页**：展示所有关系类型
- **操作**：添加/编辑/删除类型（唯一性约束，UNIQUE name）

#### 3.2.18 联系人关系编辑页（contact_relation_edit_page）
**布局结构**：
- 选择两位联系人
- 选择关系类型
- 添加备注
- 保存关系

#### 3.2.19 数据备份页（data_backup_page）
**布局结构**：
- **WebDAV 配置**：服务器地址、用户名、密码（遮罩）、远程目录、连接测试
- **备份状态**：上次备份时间、文件大小、立即备份
- **备份策略**：自动备份开关、频率设置
- **历史备份列表**：支持恢复/删除

#### 3.2.20 数据导出页（data_export_page）
**布局结构**：
- **格式选择**：Excel / CSV
- **筛选条件**：日期范围
- **导出选项**：选择内容范围
- **底部操作**：确认导出

#### 3.2.21 数据导入页（data_import_page + account_book_data_import_page）
**布局结构**：
- **文件选择**：从设备选取文件（file_picker）
- **格式识别**：自动检测 Excel/CSV 格式
- **列映射**：字段映射配置
- **导入进度**：行数统计（成功/跳过/失败）
- **导入历史**：data_import_job 记录

#### 3.2.22 回收站页（recycle_bin_page）
**布局结构**：
- **Tab 切换**：联系人 / 收支记录
- **列表展示**：已软删除的数据项
- **操作**：恢复 / 彻底删除

### 3.3 无障碍适配
- 支持系统字体缩放
- 语义化 Widget（Semantics）覆盖主要控件
- 对比度满足 WCAG 4.5:1

### 3.4 响应式设计
- 设计基准尺寸：393 × 852（iPhone 14 Pro 级别）
- 沉浸式状态栏（`SystemUiMode.immersiveSticky`）

### 3.5 通知系统规范

为消除不同模块通知方式不一致的问题，所有应用内通知统一收敛为 4 类，各司其职。

#### 3.5.1 四类通知总览

| 类别 | 适用场景 | 形态 | 是否阻塞 | 默认时长 | API 入口 |
| --- | --- | --- | --- | --- | --- |
| **Toast** | 轻量提示（成功/失败/字段校验/网络状态/路由拦截） | 屏幕顶部悬浮卡片 | 否 | success/info 2s；warning/error 3.5s；带主操作 5s | `AppNotifier.toast(context, ...)` |
| **SnackBar** | 与具体页面强关联的反馈（删除 N 项成功/失败、Undo） | Scaffold 底部浮动条带 | 否 | 4s；带操作 6s | `AppNotifier.snack(context, ...)` |
| **Dialog** | 阻塞式确认/表单/告警（删除二次确认、密码验证、必填表单输入） | 屏幕中央模态卡片 | 是 | 直至用户操作 | `AppDialog.confirm/showInput/showAlert(...)` |
| **BottomSheet** | 选择/筛选/详情（关系类型选择、原因选择、备份频率、文件选择） | 屏幕底部抽屉 | 半阻塞 | 直至用户操作 | `AppBottomSheet.show/showPicker<T>(...)` |

> **强制约束**：禁止再使用 Material 默认 `SnackBar`、`AlertDialog`、`showModalBottomSheet` 与旧的 `AppToast.show`；所有新增通知必须经由 `AppNotifier` / `AppDialog` / `AppBottomSheet` 入口。

#### 3.5.2 Toast 规范

- **位置**：屏幕顶部 `SafeArea` 下方 16px；居中；最大宽度 420px；水平边距 16px
- **样式**：
  - 容器：白底（暗色 `surfaceCard`），圆角 12px，`AppShadows.lg`，1px `borderSubtle` 边框
  - 左侧 4px 状态色竖条
  - 24px 圆形软色图标头 + 14px FA 图标
  - 可选标题（16px Bold）+ 必选正文（14px Regular）
  - 可选主操作按钮（文本按钮，颜色 = 状态色）
- **语义态 → 状态色**：
  - `success` → `stateSuccess`
  - `error` → `stateDanger`
  - `warning` → `stateWarning`
  - `info` → `brandPrimary`
  - `neutral` → `neutralAccent`
- **动效**：入场 250ms `Curves.easeOutCubic`（从 `Offset(0, -0.2)` 淡入下滑）；退场 200ms `Curves.easeIn`
- **多消息策略**：**后入覆盖**（连续触发时新消息立即替换旧消息，旧消息不堆叠）
- **可访问性**：文本节点 `IgnorePointer` + `Semantics(liveRegion: true)`；主操作按钮保留点击

#### 3.5.3 SnackBar 规范

- **位置**：Scaffold 底部，水平边距 16px，距 FAB / BottomNav 自动避让
- **样式**：
  - 容器：暗色 `surfaceSubtle` / 亮色 `AppColors.gray900`，圆角 12px，`AppShadows.lg`
  - 可选 18px FA 图标
  - 14px Medium 文本（亮色模式白色，暗色模式 `textPrimary`）
  - 可选操作按钮：14px Semibold 文本按钮，颜色 = `AppColors.indigo200`
- **动效**：Material 默认 SnackBar 动画（不破坏用户预期）
- **多消息策略**：通过 `ScaffoldMessenger.hideCurrentSnackBar()` 实现后入覆盖

#### 3.5.4 Dialog 规范

- **位置**：屏幕居中，水平 24px 内边距；最大宽度 360px
- **样式**：
  - 容器：白底（暗色 `surfaceCard`），圆角 16px (`AppRadii.br2xl`)，`AppShadows.lg` 阴影，1px `borderSubtle` 边框
  - 可选 40px 圆角软色图标头 + 16px FA 图标
  - 标题 18px Bold；副标题/描述 14px Regular `textSecondary`
  - 按钮：底部一行双按钮等宽，高度 44px；次按钮 = `surfaceSubtle` 底 + `textSecondary` 文；主按钮 = `brandPrimary` 底 + 白色文；危险主按钮 = `stateDanger` 底
- **动效**：入场 200ms `Curves.easeOutBack`（缩放 0.9→1.0 + 淡入）；退场 150ms 淡出 + 缩放至 0.95
- **横屏适配**：`MediaQuery.orientation == landscape` 时自动切换为 BottomSheet 形态，避免过窄
- **可访问性**：标题用 `Semantics(header: true)`；主按钮 `autofocus: true` 默认聚焦
- **API 形态**：
  - `AppDialog.confirm(context, title, message, confirmLabel, cancelLabel, danger, tone, icon)` → `Future<bool?>`
  - `AppDialog.showInput(context, title, fields, confirmLabel, cancelLabel, tone, icon)` → `Future<Map<String, String>?>`
  - `AppDialog.showAlert(context, title, message, closeLabel, tone, icon)` → `Future<void>`

#### 3.5.5 BottomSheet 规范

- **位置**：屏幕底部；圆角顶部 24px；最大高度 = 屏高 × 0.9
- **样式**：
  - 容器：白底（暗色 `surfaceCard`），顶部圆角 24px，`AppShadows.lg` 阴影
  - 顶部 drag handle（48×4px，`borderDefault`）居中顶部 8px
  - 可选 56px 标题栏：18px Bold 标题 + 关闭按钮
  - 内容：16px 内边距；高度自适应（内容不足时不强制全高）
- **动效**：Material 默认 BottomSheet 动画
- **关闭**：drag handle 下拉 / 点遮罩 / 点关闭按钮 / 选中结果后自动 `Navigator.pop`
- **API 形态**：
  - `AppBottomSheet.show<T>(context, title, child)` → `Future<T?>`
  - `AppBottomSheet.showPicker<T>(context, title, options)` → `Future<T?>`（点击项自动 pop）

#### 3.5.6 动效时长表

| 元素 | 入场 | 退场 | 缓动 |
| --- | --- | --- | --- |
| Toast | 250ms | 200ms | `Curves.easeOutCubic` / `Curves.easeIn` |
| SnackBar | Material 默认 450ms | Material 默认 | Material |
| Dialog | 200ms | 150ms | `Curves.easeOutBack` / `Curves.easeIn` |
| BottomSheet | Material 默认 300ms | Material 默认 | Material |

#### 3.5.7 兼容性与平台适配

- **不同 Android 版本**：仅使用 Flutter Material API，避免平台 Channel；`SafeArea` + `MediaQuery.viewPadding` 处理刘海/挖孔
- **不同屏幕尺寸**：
  - Toast / SnackBar 水平 16px 边距 + 最大宽 420px
  - Dialog 最大宽 360px
  - BottomSheet 最大高度 90% 屏高
- **字体缩放**：通知文本使用 `AppTypography.base`，允许系统字号缩放
- **方向旋转**：Dialog 在 `landscape` 时切换为 BottomSheet 形式
- **状态栏**：Toast `SafeArea` 顶部对齐，不抢占 `AppScaffold` 顶部应用栏

#### 3.5.8 新增通知场景的执行清单

1. 确认通知类别（Toast / SnackBar / Dialog / BottomSheet），无把握时在 PR 描述中说明选择理由
2. 选择语义态（success / error / warning / info / neutral）并匹配状态色
3. 通过 `AppNotifier` / `AppDialog` / `AppBottomSheet` 调用，禁止再使用 Material 默认组件
4. 若新增图标，使用 `FontAwesomeIcons` 命名规范，避免重复
5. 同步更新本章节的"四类通知总览"表格

## 4. 测试与质量要求

### 4.1 单元测试
- 使用 `flutter_test` + `integration_test` 框架
- 覆盖 DAO 层数据操作、Service 层业务逻辑
- Drift 支持内存数据库用于测试（`AppDatabase.forTesting`）

### 4.2 UI 自动化测试
- 使用 `integration_test` 覆盖核心路径
- 覆盖录入收支、查看关系人详情、查看统计

### 4.3 静态分析
- 使用 `flutter_lints` 6.x 提供的 lint 规则集
- 配置在 `analysis_options.yaml` 中

### 4.4 代码质量要求
- 遵循 Dart 编码规范（Effective Dart）
- Drift 生成代码通过 `build_runner` 维护
- 公共 API 与复杂业务逻辑需提供清晰注释

## 5. 安全与隐私

### 5.1 数据安全
- 本地 SQLite 数据存储（文件：`newshangli_drift.sqlite`）
- WebDAV 凭据建议加密存储
- 网络传输加密（HTTPS）
- 日志中不得包含凭据信息

### 5.2 隐私保护
- 最小权限原则
- 用户数据本地优先
- 提供数据导出和删除功能（含回收站与彻底删除）
- 软删除机制保护用户免于误操作

## 6. 部署与运维

### 6.1 版本管理
- 当前版本：`1.0.0+2002`
- 语义化版本号（Semantic Versioning）
- 数据库 schema 版本独立管理（当前 v8）

### 6.2 构建与发布
- 使用 Flutter 标准构建流程
- 支持 Android 平台（`android/` 目录）
- 开发调试：`flutter run`
- 生产构建：`flutter build apk` / `flutter build appbundle`
