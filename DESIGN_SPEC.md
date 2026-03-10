# 设计规范文档

## 1. 技术架构规范

### 1.1 架构模式
采用“轻量 Clean Architecture + MVVM”，在保证边界清晰的前提下避免过度分层。

- **Presentation（UI + ViewModel）**：UI 只负责渲染与交互意图派发；页面状态使用 `UiState(loading/data/error)` 统一表达；一次性事件（Toast、导航、弹窗）使用 `UiEvent`；ViewModel 负责状态聚合与调用用例/仓库。
- **Domain**：承载业务规则与跨模块组合逻辑；仅对“有业务口径/需要组合/需要复用”的场景引入 UseCase；简单 CRUD 允许 ViewModel 直接调用 Repository（避免样板代码膨胀）；Domain 内仅定义实体与业务接口，不依赖 Android 框架与实现细节。
- **Data**：实现 Repository；包含本地存储（Room）、配置存储（DataStore/加密存储）、文件系统导出、以及 WebDAV 备份等基础设施适配；所有协议/IO 仅通过 Data 的基础设施适配实现。

**关键约束**：
- **账簿是一级上下文**：核心数据（关系人、收支记录、提醒）必须归属 `book_id`，所有查询/写入必须在账簿范围内执行。
- **备份走 WebDAV**：备份能力作为 Data 层基础设施适配（WebDAV Client），通过 Domain 暴露 `BackupRepository` 能力；WorkManager 只负责调度与调用用例，不在 Worker 内写业务规则。

### 1.2 Jetpack 组件
- Room、ViewModel、LiveData 或 StateFlow、Navigation、DataStore、WorkManager、Paging 3、Hilt

### 1.3 协程与 Flow 使用场景
- **数据层**：DAO 返回 Flow 用于实时列表更新，网络调用使用 suspend 函数
- **业务层**：UseCase 暴露 Flow<Result> 用于组合计算与错误统一处理
- **表现层**：ViewModel 将 Flow 转换为 StateFlow 提供给 UI
- **后台任务**：WorkManager 调度提醒与数据同步

### 1.4 层级接口规范与依赖关系
- UI 层仅依赖 Presentation 输出的 `UiState/UiEvent` 与 ViewModel
- Presentation 层仅依赖 Domain 接口与模型
- Domain 层仅声明业务接口与模型，不依赖 Android 或 Data 实现
- Data 层实现 Repository，依赖 LocalDataSource 与 Infrastructure（如 WebDAV、文件系统导出等）
- LocalDataSource 只访问 Room；Infrastructure 仅负责协议/IO（WebDAV/文件/加密存储），不包含业务口径
- 错误统一封装为 Result 或 AppError

**建议目录结构**：
```
app/
  src/main/java/...
    presentation/
      ui/
      viewmodel/
    domain/
    data/
    data/local/
    data/infrastructure/
```

### 1.5 技术栈与依赖管理
- **语言**：Kotlin 1.9+
- **构建工具**：Gradle 8.0+
- **最低 SDK**：API 24 (Android 7.0)
- **目标 SDK**：API 34 (Android 14)
- **依赖注入**：Hilt
- **网络**：Retrofit + OkHttp + Kotlinx Serialization（WebDAV 备份同样基于 OkHttp 实现）
- **图片加载**：Coil
- **日志**：Timber

### 1.6 错误处理策略
- 网络错误：统一封装为 NetworkError，包含错误码和友好提示
- 数据库错误：封装为 DatabaseError，记录详细日志
- 业务错误：封装为 BusinessError，包含错误类型和处理建议
- 未知错误：统一封装为 UnknownError，记录堆栈信息

## 2. 数据模型定义

### 2.1 账簿表 account_book

| 字段 | 类型 | 约束 | 默认值 | 说明 | 索引 |
| --- | --- | --- | --- | --- | --- |
| book_id | TEXT | 主键 | UUID | 账簿唯一标识 | 主键 |
| name | TEXT | 非空 | - | 账簿名称 | - |
| reason_type | TEXT | 非空 | 结婚礼金 | 事由类型（从事由管理中选择） | - |
| theme_color | TEXT | 非空 | #312E81 | 主题色（Hex） | - |
| icon | TEXT | 可空 | - | 图标名称 | - |
| description | TEXT | 可空 | - | 备注描述 | - |
| is_default | INTEGER | 非空 | 0 | 是否默认账簿 (0/1) | - |
| created_at | INTEGER | 非空 | 当前时间 | 创建时间 | - |
| updated_at | INTEGER | 非空 | 当前时间 | 更新时间 | - |

### 2.2 关系人表 person

| 字段 | 类型 | 约束 | 默认值 | 说明 | 索引 |
| --- | --- | --- | --- | --- | --- |
| person_id | TEXT | 主键 | UUID | 关系人唯一标识 | 主键 |
| book_id | TEXT | 外键 | - | 所属账簿 | book_id |
| name | TEXT | 非空 | - | 姓名 | name |
| relationship_type | TEXT | 非空 | 其他 | 关系类型 | relationship_type |
| phone | TEXT | 可空 | - | 手机号 | phone |
| birthday | TEXT | 可空 | - | 生日（ISO 8601） | birthday |
| anniversary | TEXT | 可空 | - | 纪念日 | - |
| avatar_uri | TEXT | 可空 | - | 头像路径 | - |
| note | TEXT | 可空 | - | 备注 | - |
| created_at | INTEGER | 非空 | 当前时间 | 创建时间 | - |
| updated_at | INTEGER | 非空 | 当前时间 | 更新时间 | - |

### 2.3 礼金记录表 gift_record

| 字段 | 类型 | 约束 | 默认值 | 说明 | 索引 |
| --- | --- | --- | --- | --- | --- |
| record_id | TEXT | 主键 | UUID | 记录唯一标识 | 主键 |
| book_id | TEXT | 外键 | - | 所属账簿 | book_id |
| person_id | TEXT | 外键 | - | 关联关系人 | person_id |
| reminder_id | TEXT | 外键 | 可空 | 关联提醒 | reminder_id |
| direction | TEXT | 非空 | 收入 | 收/支类型 | direction |
| amount_cent | INTEGER | 非空 | 0 | 金额（分） | amount_cent |
| currency | TEXT | 非空 | CNY | 币种 | currency |
| event_name | TEXT | 可空 | - | 事由 | event_name |
| occurred_at | INTEGER | 非空 | 当前时间 | 发生时间 | occurred_at |
| payment_method | TEXT | 可空 | - | 支付方式 | payment_method |
| note | TEXT | 可空 | - | 备注 | - |
| attachments | TEXT | 可空 | - | 附件 URI 列表 | - |
| created_at | INTEGER | 非空 | 当前时间 | 创建时间 | - |
| updated_at | INTEGER | 非空 | 当前时间 | 更新时间 | - |

### 2.4 事件提醒表 event_reminder

| 字段 | 类型 | 约束 | 默认值 | 说明 | 索引 |
| --- | --- | --- | --- | --- | --- |
| reminder_id | TEXT | 主键 | UUID | 提醒唯一标识 | 主键 |
| book_id | TEXT | 外键 | - | 所属账簿 | book_id |
| person_id | TEXT | 外键 | 可空 | 关联关系人 | person_id |
| reminder_type | TEXT | 非空 | 自定义 | 类型 | reminder_type |
| target_date | TEXT | 非空 | - | 目标日期（ISO 8601） | target_date |
| remind_at | INTEGER | 非空 | - | 提醒触发时间 | remind_at |
| repeat_rule | TEXT | 非空 | none | 重复规则 | repeat_rule |
| status | TEXT | 非空 | active | 状态 | status |
| channel | TEXT | 非空 | notification | 通知渠道 | channel |
| note | TEXT | 可空 | - | 备注 | - |
| created_at | INTEGER | 非空 | 当前时间 | 创建时间 | - |
| updated_at | INTEGER | 非空 | 当前时间 | 更新时间 | - |

### 2.5 数据实体与 DTO 转换规则
- Entity 用于本地存储，DTO 用于网络或导出
- 金额统一使用分为单位，DTO 输出时可转换为元
- 日期统一使用 ISO 8601，时区在 DTO 中明确
- 本地字段（如 attachments、本地路径）在 DTO 中以可选字段表示
- attachments 以 JSON 数组字符串存储，DTO 输出为数组

### 2.6 数据校验与默认值策略
- 金额必须大于 0
- 姓名长度 1-32 字符
- 手机号符合本地手机号规则
- 提醒时间不得早于当前时间
- direction 默认收入，currency 默认 CNY，repeat_rule 默认 none
- book_id 必填且必须存在
- **账簿校验**：每个用户至少有一个默认账簿；删除账簿时需级联删除关联的记录、关系人、提醒（或软删除）。

### 2.7 数据库版本管理
- 使用 Room 的 Migration 机制处理数据库升级
- 每个版本变更需记录详细的迁移脚本
- 支持降级策略，确保数据完整性

### 2.8 索引与查询建议
- person：索引 (book_id, name)
- gift_record：索引 (book_id, occurred_at)、(book_id, person_id)
- event_reminder：索引 (book_id, remind_at)、(book_id, target_date)

## 3. UI/UX 标准

### 3.1 Material Design 3 规范

#### 3.1.1 核心色彩系统 (Color System)
| Token | 色值 (Hex) | 用途说明 |
| --- | --- | --- |
| **Primary** | `#312E81` (indigo-900) | 核心品牌色，用于主要按钮、导航选中态、重要文字 |
| **Secondary** | `#4F46E5` (indigo-600) | 次级品牌色，用于装饰元素、进度条、次要状态 |
| **Surface** | `#EEF2FF` (indigo-50) | 背景底色，用于页面背景、卡片背景、选中状态底色 |
| **Error** | `#EF4444` (red-500) | 错误/支出状态，用于支出金额、删除按钮、错误提示 |
| **Success** | `#22C55E` (green-500) | 成功/收入状态，用于收入金额、完成标记 |
| **Text Main** | `#111827` (gray-900) | 主要文字，用于标题、正文 |
| **Text Sub** | `#6B7280` (gray-500) | 次要文字，用于说明、日期、未选中态 |
| **Border** | `#F3F4F6` (gray-100) | 边框/分割线 |

#### 3.1.2 排版规范 (Typography)
| 样式名称 | 字号 | 字重 | 用途 |
| --- | --- | --- | --- |
| **Headline 1** | 24px (text-2xl) | Bold (700) | 页面大标题 |
| **Headline 2** | 20px (text-xl) | Bold (700) | 模块/卡片标题 |
| **Headline 3** | 18px (text-lg) | Bold (700) | 次级模块标题 |
| **Body Medium** | 16px (text-base) | Medium (500) | 重要正文、列表项主文本 |
| **Body Regular** | 14px (text-sm) | Regular (400) | 普通正文、输入框文字 |
| **Caption** | 12px (text-xs) | Regular (400) | 辅助说明、日期、底部标签 |
| **Overline** | 10px | Regular (400) | 微小标签、极小提示 |

#### 3.1.3 组件样式特征 (Shape & Elevation)
- **圆角 (Corner Radius)**：
  - 页面/大容器：`45px` (iPhone 屏幕模拟)
  - 卡片/弹窗：`16px` (rounded-2xl)
  - 按钮：`12px` (rounded-xl)
  - 标签/Chip：`999px` (rounded-full)
- **阴影 (Elevation)**：
  - 低层级（卡片）：`shadow-sm`
  - 高层级（悬浮按钮/弹窗）：`shadow-lg`
- **间距 (Spacing)**：
  - 页面边距：`16px` (p-4)
  - 模块间距：`24px` (space-y-6)
  - 内容间距：`12px` (gap-3)

#### 3.1.4 交互状态 (Interaction)
- **点击态 (Active)**：
  - 按钮：`scale-95` (轻微缩小) + `bg-indigo-800` (颜色加深)
  - 列表项：`bg-gray-50` (背景变灰)
- **禁用态 (Disabled)**：
  - 透明度 `opacity-50`，禁止点击响应

### 3.2 界面原型清单

#### 3.2.1 主页面（首页）
**布局结构**：
- **顶部应用栏**：应用标题 + 搜索图标 + 更多菜单
- **Tab 导航**：收支记录 | 关系人 | 统计 | 设置
- **内容区域**：对应 Tab 的内容列表
- **悬浮操作按钮**：添加收支记录

**收支记录 Tab**：
- 顶部：日期/月份筛选栏
- 列表项：左侧头像、姓名、事由、金额（收入绿色/支出红色）、时间、支付方式
- 底部：无统计卡片（已移除，简化布局）

#### 3.2.2 收支录入页
**布局结构**：
- **顶部应用栏**：标题"记录收支" + 保存按钮 + 关闭按钮
- **表单区域**：
  - 类型切换：收礼/送礼（分段控制器）
  - 金额输入：大字号输入框 + 快捷金额按钮
  - 关系人选择：列表选择或搜索
  - 事由输入：文本框 + 常用事由标签
  - 日期选择：日期选择器，默认当天
  - 支付方式：选择器（微信/支付宝/现金等）
  - 备注：多行文本框
  - 附件：图片上传区域

#### 3.2.3 收支详情页
**布局结构**：
- **顶部应用栏**：标题"记录详情" + 更多操作（编辑/删除）
- **金额卡片**：大字号展示金额，区分收/支颜色
- **详细信息列表**：关系人、事由、时间、支付方式
- **备注区域**：展示详细备注文本
- **附件区域**：展示图片缩略图

#### 3.2.4 关系人列表页
**布局结构**：
- **顶部应用栏**：标题"关系人" + 添加按钮
- **搜索栏**：支持姓名/手机号搜索
- **列表区域**：
  - 首字母索引导航（A-Z）
  - 分组展示联系人
  - 列表项：头像、姓名、关系类型

#### 3.2.5 关系人详情页
**布局结构**：
- **顶部应用栏**：返回按钮 + 编辑按钮
- **头部信息卡片**：
  - 头像（支持点击查看大图）
  - 姓名、关系类型、联系方式
  - 悬浮统计：总收礼/总送礼/差额
- **信息列表**：生日、纪念日、备注
- **历史记录**：按时间倒序展示往来记录
- **底部操作栏**：设提醒、记一笔

#### 3.2.6 关系人编辑页
**布局结构**：
- **顶部应用栏**：标题"编辑关系人" + 保存按钮
- **表单区域**：
  - 头像上传：点击更换
  - 基础信息：姓名、关系类型、手机号
  - 重要日期：生日、纪念日
  - 备注信息
- **底部操作**：删除联系人按钮

#### 3.2.7 统计图表页
**布局结构**：
- **顶部应用栏**：标题"统计分析" + 导出/分享按钮
- **筛选区域**：时间范围（本年/半年/本月）
- **概览卡片**：总收入、总支出
- **图表区域**：
  - 收支趋势（柱状图）
  - 支出分类占比（饼图）
- **排行榜**：人情往来 Top 5 列表

#### 3.2.8 事件提醒页
**布局结构**：
- **顶部应用栏**：标题"事件提醒" + 添加按钮
- **筛选 Tab**：全部 | 生日 | 回礼 | 纪念日
- **列表区域**：
  - 本周紧急提醒（高亮显示）
  - 未来提醒列表
  - 支持一键标记完成

#### 3.2.9 设置页
**布局结构**：
- **顶部应用栏**：标题"设置"
- **个人信息卡片**：头像、昵称
- **设置列表**：
  - 账簿管理
  - 通知提醒、隐私安全
  - 数据备份、导出数据
  - 关于应用
- **底部操作**：退出登录

#### 3.2.10 账簿管理页
**布局结构**：
- **顶部应用栏**：标题"账簿管理" + 添加按钮
- **账簿列表**：
  - 展示所有账簿卡片
  - 标记"当前使用"状态
  - 包含统计信息（记录数）
  - 操作按钮：切换、编辑

#### 3.2.11 账簿编辑页
**布局结构**：
- **顶部应用栏**：标题"编辑账簿" + 保存按钮
- **图标预览**：动态展示所选颜色和图标
- **表单区域**：
  - 账簿名称
  - 事由类型选择
  - 主题色选择器
  - 备注描述
  - "设为默认账簿"开关
- **底部操作**：删除账簿按钮

#### 3.2.12 数据备份页
**布局结构**：
- **顶部应用栏**：标题"数据备份"
- **WebDAV 配置**：
  - 服务器地址（`https://`）
  - 用户名
  - 密码/应用专用密码（输入框需遮罩）
  - 远程目录（可选，默认 `NewShangli/`）
  - 连接测试按钮（展示成功/失败原因）
- **备份状态**：展示上次备份时间、备份文件大小、立即备份按钮
- **备份策略**：自动备份开关、频率设置（仅 Wi‑Fi 可选）、保留份数
- **历史备份列表**：按时间展示备份文件，支持恢复/删除

#### 3.2.13 数据导出页
**布局结构**：
- **顶部应用栏**：标题"导出数据"
- **格式选择**：Excel / PDF
- **筛选条件**：开始日期、结束日期
- **导出选项**：包含内容（收支记录、关系人）、是否包含图片
- **底部操作**：确认导出按钮

### 3.3 无障碍适配
- 支持系统字体缩放与最小 1.3 倍字号
- TalkBack 读屏标签覆盖主要控件
- 对比度满足 WCAG 4.5:1
- 支持高对比度模式
- 提供文字替代方案（图片内容）

### 3.4 响应式设计
- 适配不同屏幕尺寸（手机/平板）
- 支持横竖屏切换
- 适配折叠屏设备
- 支持分屏多任务

## 4. 测试与质量要求

### 4.1 单元测试
- 覆盖率 ≥ 60%，业务关键模块 ≥ 80%
- 覆盖 ViewModel、Repository、UseCase 与关键校验逻辑
- 重点测试业务逻辑和数据转换
- 使用 JUnit 4 和 MockK 框架

### 4.2 UI 自动化测试
- 使用 Espresso 覆盖核心路径，必要时配合 UIAutomator
- 覆盖录入收支、查看关系人详情、查看统计、处理提醒
- 测试不同屏幕尺寸和分辨率
- 包含异常流程测试

### 4.3 性能基准
- 冷启动 ≤ 1.5s（中端机型，P95）
- 列表滑动帧率 ≥ 55fps（中端机型）
- 数据库查询 ≤ 200ms（P95，常用查询）
- 内存占用 ≤ 250MB（正常使用）
- 电池消耗优化（后台任务限制）

### 4.4 代码质量要求
- 遵循 Kotlin 编码规范
- 静态代码分析（Detekt + KtLint）
- 复杂度控制（圈复杂度 ≤ 10）
- 公共 API 与复杂业务逻辑需提供清晰说明

## 5. 安全与隐私

### 5.1 数据安全
- 本地数据加密存储（SQLCipher）
- 敏感信息不记录日志
- 网络传输加密（HTTPS/TLS 1.2+）
- 生物识别认证（可选）
- **WebDAV 凭据安全**：WebDAV 账号/密码（或应用专用密码）必须加密存储（Android Keystore + 加密存储）；网络请求与错误日志中不得包含凭据、完整 URL 查询参数或远端目录结构。

### 5.2 隐私保护
- 最小权限原则
- 用户数据本地优先
- 提供数据导出和删除功能
- 遵循本地隐私法规与合规要求（如 GDPR 等）

## 6. 部署与运维

### 6.1 版本管理
- 语义化版本号（Semantic Versioning）
- 使用远程配置/功能开关进行功能灰度
- 灰度发布策略
- 版本回滚机制（商店回滚/禁用问题版本）

### 6.2 监控与 analytics
- 崩溃日志收集（可插拔方案，脱敏）
- 性能监控（可插拔方案，指标采样）
- 用户行为分析（匿名化，提供开关）
- 自定义事件追踪（最小化采集）
