# 礼记 1.2.4 数据库备份恢复独立审计

日期：2026-11-04，修复复核 2026-11-05。范围：`lib/backup/` 全部五个文件；仅当前 1.2.4（`1.2.4+2007`，数据库 schema 15），不验证历史版本兼容。与主线程导入导出、数据库 Provider 生命周期测试分开统计。

## 修复后状态（2026-11-05）

B01–B04 已修复并在同一套独立测试中通过。备份恢复专项现为 **83 项，全部通过**，最新完整运行输出 `01:03 +83: All tests passed!`，退出码 0；`dart analyze` 对三个修复文件及测试输出 `No issues found!`。原有 4 个失败断言没有删除、跳过或放宽，测试名仍保留 `DEFECT:` 前缀作为回归标记。

修复后新增的 6 项回归覆盖：超限 manifest 精确预检且无快照/半成品残留；`includeMedia=false` 不因超大媒体目录误报；空媒体 ZIP 可恢复并清空媒体字段与目标媒体树；保护副本媒体损坏时在任何 live 数据库改写前拒绝，修复保护副本后可正常回退；缺少 CHECK 的当前 schema 被拒绝；PUT 响应正文停滞按请求期限超时。原 77 项断言全部保留并通过，因此 83 项结果不是靠删减失败场景取得。

修复内容：

- **B01**：`DataBackupService` 在读取媒体内容前先用文件大小做展开体积预检，打包前再按数据库 + 媒体 + manifest 的最终大小复核；读取时再次核对文件长度，超过与恢复端共享的 128 MiB/256 MiB/20,000 文件限制时抛出 `BackupException`，并清理快照与未完成 ZIP。没有静默丢弃媒体。
- **B02**：`RestoreSafety` 对 staged 当前版本数据库校验表定义、CHECK、列类型/非空/主键/默认值、字段存储类型与关键值范围、空主键、外键签名、`reason`/`relation_type` 的 `normalized_name` 唯一索引，并拒绝触发器；校验仍在触碰 live 数据前完成。
- **B03**：`RestoreSafety.begin` 在 journal 中记录保护目录全部文件的大小与 SHA256；`recoverIfNeeded` 先验证保护数据库、媒体目录和完整文件清单，全部通过后才改写 live 数据库或媒体。
- **B04**：`WebDavClient` 的请求期限覆盖响应正文读取；超时会中止请求，GET 先写入 `.part_*` 临时文件，成功后原子改名，失败时删除部分下载并关闭句柄。

修复文件：`lib/backup/data_backup_service.dart`、`lib/backup/restore_safety.dart`、`lib/backup/webdav_client.dart`。未提交 Git。

## 独立性与运行环境

- 新测试：`test/independent_audit_20261104/backup_restore_audit_test.dart`。未读取、导入、复制或依赖 `test/`、`integration_test/` 的已有案例。只读取产品实现、依赖配置与依赖包 ZIP 解码实现。
- 修复前没有修改产品源码；修复阶段只改动了上节列出的三个备份实现文件，没有提交。所有数据库、源 CSV/ZIP、日志、媒体、恢复目录、损坏样本均在每项测试新建的 `Directory.systemTemp.createTemp('liji_backup_audit_20261104_')` 下，测试结束递归清理。
- Flutter 3.47.5 / Dart 3.13.4，Windows 10。SQLite 使用真实原生库；Windows 优先使用项目已有构建中的 `build/navigation_probe/build/windows/x64/runner/Release/sqlite3.dll`，可通过 `BACKUP_AUDIT_SQLITE_DLL` 指定；没有替换数据库实现。
- 通过 `AppDatabase.forTesting(NativeDatabase(tempFile))` 创建实际当前 schema，再独立插入复杂样本。全表快照从 SQLite 直接读取，动态枚举全部非 `sqlite_%` 表，并断言恰好覆盖八张应用表。
- 样本覆盖账簿、全局联系人、收入/支出、金额上界、多币种、逻辑删除、追加备注、关系/事由与联系人关系、导入任务的全部列；附件覆盖绝对/相对/反斜杠/Unicode 路径、HTTP URL、无引用文件及空文件。
- 每次要求数据保全的失败场景比较所有行的所有字段和全部媒体文件的 SHA256。正常恢复仅允许明确列出的变化：媒体路径重映射、无媒体模式的媒体字段清空、未完成导入任务变为 `canceled`；其余字段完整比较。备份中的原始 SQLite 快照要求全字段完全一致，不允许这些恢复变化。
- WebDAV 使用 `HttpServer.bind(InternetAddress.loopbackIPv4, 0)` 与实际 `HttpClient`，不使用请求 mock。Flutter binding 默认注入的 HTTP 400 拦截被测试显式解除；验证服务端确实收到方法、路径、Basic Authorization、User-Agent、PUT 内容与后续 GET。
- SharedPreferences 使用内存 mock，避免真实设置写入。设置边界测试仅证明包内容/恢复服务不会携带或覆盖这些键，不等同对原生设置插件或编辑保护 UI 的端到端测试。

## 实跑命令与结果

以下为**修复前基线**：完整矩阵实跑 **77项，73项通过、4项失败**，退出码1，耗时约68秒。四个失败用例分别对应B01–B04；无skip或预期失败。修复后同一测试文件扩至83项并全部通过，结果见文首。

```text
flutter test test/independent_audit_20261104/backup_restore_audit_test.dart --no-pub --reporter expanded
Shell: AUDIT oversized media=268435457 zip=1178757 expandedLimit=268435456
00:12 +10 -1: producer and consumer limits DEFECT: backup must reject media beyond its own restore expansion limit [E]
00:23 +21 -2: recovery protection validation DEFECT: missing saved media must be detected before replacing any live database [E]
00:56 +51 -3: damaged archive and current-schema invalid data DEFECT: current-schema marker cannot admit missing account-book constraints [E]
01:06 +69 -4: WebDAV real loopback HTTP DEFECT: stalled GET response body must respect configured request timeout [E]
01:08 +73 -4: Some tests failed.
退出码1；77项，无skip。

上一轮完整矩阵：01:02 +72 -3: Some tests failed.（75项；追加超限包与设置边界前）

flutter test test/independent_audit_20261104/backup_restore_audit_test.dart --no-pub --reporter expanded --plain-name 'WebDAV real loopback HTTP'
00:12 +19: All tests passed!（追加响应体停滞复现前的19项基础场景）

flutter test test/independent_audit_20261104/backup_restore_audit_test.dart --no-pub --reporter expanded --plain-name 'producer and consumer limits'
Shell: AUDIT oversized media=268435457 zip=1178756 expandedLimit=268435456
00:04 +0 -1: Some tests failed.
Expected: <Instance of 'BackupException'>
Actual: <null>

 dart analyze E:/NewShangli/test/independent_audit_20261104/backup_restore_audit_test.dart
Analyzing backup_restore_audit_test.dart...
No issues found!
```

初轮还遇到 Flutter 测试框架默认 HTTP 400 的环境问题，已修复测试配置并确认真实回环请求通过，没有将框架拦截计为产品缺陷。初轮对“仅中央目录 CRC 损坏”的严格拒绝预期，经正文、本地头 CRC 与数据库 SHA 均完整的对照后，归类为 ZIP 元数据校验边界；未降低任何业务字段或媒体字节保留断言。最终失败用例都使用真实产品路径，未跳过或标为预期失败。

## 逐场景矩阵

以下编号只用于报告；一个表格行对应一个 `test`。同一行括号中的多个实用限制是该项内部独立断言。表中结果保留修复前77项基线的原始记录；B01–B04 对应行另注明修复后状态，当前该文件完整83项全部通过。

### 本地快照与保留（10项）

| 编号 | 场景 | 结果 |
|---|---|---|
| L01 | WAL 中已提交但未人工 checkpoint 的修改进入快照；全八表相等；manifest DB SHA/大小/schema/文件清单/媒体计数正确；每个媒体 SHA256 相等；临时快照清理；不包含 WAL/SHM | 通过 |
| L02 | 原目录恢复，所有列、回收站、六条追加备注完整恢复，额外目标媒体移除 | 通过 |
| L03 | 跨两个独立文档目录恢复；账簿附件、礼金附件、头像路径正确重映射；其余全字段及媒体 SHA256 完整 | 通过 |
| L04 | `includeMedia=false`：包不含媒体；恢复清空附件/头像字段和目标媒体树；其余全表保留 | 通过（实现边界） |
| L05 | 源没有媒体目录且引用为 NULL；恢复到空目标后全表完全相等 | 通过 |
| L06 | running/pending/paused/failed 导入任务取消；completed/canceled 状态和所有其余任务列、业务表保留 | 通过（实现边界） |
| L07 | 自定义本地输出目录、可写探针清理、文件占据输出目录时失败 | 通过 |
| L08 | 缺少源数据库时报错，不产生新空数据库 | 通过 |
| L09 | 快照执行器写入半成品后抛错；源全表不变，半成品清理 | 通过 |
| L10 | 执行器产出空快照时拒绝 | 通过 |

### 生产/恢复限制与导入历史边界（2项）

| 编号 | 场景 | 结果 |
|---|---|---|
| P01 | 256 MiB+1 全零媒体；备份应拒绝产生自身无法恢复的包 | 修复前**失败，B01**；修复后通过 |
| I01 | 全新目标保留 `file_path`、`mapping_json.__media_zip_path__`、`error_log_path` 旧路径；不携带 imports/import_logs；删除源设备目录后这些文件确实不可用；暂停任务取消 | 通过（实现边界） |

### 失败回滚与中断恢复（11项）

| 编号 | 场景 | 结果 |
|---|---|---|
| R01 | “正在恢复数据库”进度回调抛错；全表/媒体原样回滚，journal 清理 | 通过 |
| R02 | 已替换数据库后“正在恢复媒体文件”回调抛错；全表/媒体回滚 | 通过 |
| R03 | 包含 `media/collision` 文件及 `media/collision/child.bin`，真实文件/目录冲突导致媒体部分写入失败；数据库与媒体回滚 | 通过 |
| R04 | 第一次恢复失败；回到数据库不存在、媒体目录不存在 | 通过 |
| R05 | 原 WAL/SHM 保存并逐字节恢复；哨兵 sidecar 清理后全表仍相等 | 通过（sidecar 字节协议测试） |
| R06 | 保存保护副本与 journal 后人为模拟数据库替换、媒体部分写入；启动恢复全表/媒体完全回退；二次恢复幂等 | 通过 |
| R07 | 恢复入口先回退已有未完成替换，再拒绝新的损坏 ZIP | 通过 |
| R08 | 原数据不存在时的启动恢复删除半成品数据库/媒体 | 通过 |
| R09 | journal 指向保护目录之外时拒绝，live 全表和媒体不变 | 通过 |
| R10 | 保护数据库缺失时拒绝，live 全表和媒体不变 | 通过 |
| R11 | 保护媒体缺失时，应先完整验证保护数据再改写 live 数据库 | 修复前**失败，B03**；修复后通过 |

### 损坏包与当前 schema 无效数据（31项）

C01–C25 均要求拒绝，且目标完整全表快照、媒体 SHA256、无 pending journal 均与原状态一致。

| 编号 | 场景 | 结果 |
|---|---|---|
| C01 | 非 ZIP 字节 | 通过 |
| C02 | 缺 manifest | 通过 |
| C03 | manifest 为数组 | 通过 |
| C04 | manifest JSON 截断 | 通过 |
| C05 | 缺数据库 | 通过 |
| C06 | dbSha256 错误 | 通过 |
| C07 | formatVersion 非当前格式 | 通过 |
| C08 | manifest schemaVersion 非当前 schema | 通过 |
| C09 | `../` 路径穿越条目 | 通过 |
| C10 | 绝对路径条目 | 通过 |
| C11 | Windows 驱动器路径条目 | 通过 |
| C12 | 反斜杠路径穿越条目 | 通过 |
| C13 | 大小写等价的重复条目 | 通过 |
| C14 | 媒体引用存在但包内对应文件缺失 | 通过 |
| C15 | 垃圾 SQLite 内容且重新计算 DB SHA256 | 通过 |
| C16 | SQLite user_version 不正确且 SHA256 正确 | 通过 |
| C17 | 当前版本 SQLite 缺少必要表 | 通过 |
| C18 | 当前版本 SQLite 缺少必要列 | 通过 |
| C19 | 礼金外键指向不存在的联系人 | 通过 |
| C20 | 金额为0，绕过写入端 CHECK 后重新打包 | 通过 |
| C21 | 非法方向，绕过写入端 CHECK 后重新打包 | 通过 |
| C22 | 附件 JSON 无法解析 | 通过 |
| C23 | 附件为 JSON 对象而非列表 | 通过 |
| C24 | 附件列表包含非字符串 | 通过 |
| C25 | 本地媒体引用包含 `..` | 通过 |
| C26 | 仅中央目录 CRC 被修改，本地头 CRC、正文、DB SHA 完整；恢复正文和所有媒体 SHA 均正确 | 通过（接受的 ZIP 元数据边界） |
| C27 | 实际媒体 payload 单字节翻转，保留原始 CRC，不重算 DB SHA | 通过（拒绝且旧数据保全） |
| C28 | 本地文件头 CRC 被修改 | 通过（拒绝且旧数据保全） |
| C29 | 符号链接、声明展开体积>256 MiB、文件数>20,000、输入 ZIP>128 MiB 的安全函数限制 | 通过（四组独立断言；非全部为端到端磁盘包） |
| C30 | 人为替换媒体再重新打包得到有效 CRC；媒体无签名/manifest SHA 认证，包被接受 | 通过（信任边界，未认定为字节损坏漏检） |
| C31 | 保持 schema 15/列名/有效外键，但移除 account_book 约束，name=''、is_default=7，重新计算 DB SHA | 修复前**失败，B02**；修复后通过 |

### WebDAV 真实 HTTP（20项）

| 编号 | 场景 | 结果 |
|---|---|---|
| W01 | PROPFIND、两级 MKCOL、PUT 上传、GET 远程恢复；认证/路径/UA/完整包字节/成功历史；全表与媒体 SHA256；下载临时目录清理 | 通过 |
| W02 | PROPFIND 401，不上传、不写成功历史 | 通过 |
| W03 | PROPFIND 403，同上 | 通过 |
| W04 | PROPFIND 404，同上 | 通过 |
| W05 | PROPFIND 405，同上 | 通过 |
| W06 | PROPFIND 302，同上 | 通过 |
| W07 | PROPFIND 500，同上 | 通过 |
| W08 | MKCOL 409，失败且无成功历史 | 通过 |
| W09 | MKCOL 403，失败且无成功历史 | 通过 |
| W10 | PUT 403，失败且全表/媒体不变，无成功历史 | 通过 |
| W11 | PUT 500，同上 | 通过 |
| W12 | PUT 307，同上 | 通过 |
| W13 | GET 401，目标全表/媒体不变，下载目录清理 | 通过 |
| W14 | GET 403，同上 | 通过 |
| W15 | GET 404，同上 | 通过 |
| W16 | GET 500，同上 | 通过 |
| W17 | HTTP 200 但内容不是 ZIP，拒绝且旧数据保全 | 通过 |
| W18 | GET 302 后跟随到正确地址，下载131,073字节，进度最终字节数准确 | 通过 |
| W19 | 响应头立即发送，正文发送1字节后停滞；请求超时应结束下载 | 修复前**失败，B04**；修复后通过 |
| W20 | PROPFIND 响应头延迟，配置请求超时返回清楚的超时错误 | 通过 |

### 配置与本地设置边界（3项）

| 编号 | 场景 | 结果 |
|---|---|---|
| S01 | ZIP不包含 SharedPreferences 的设置/编辑保护/WebDAV密码/历史；全新设置不恢复，现有目标设置也不被覆盖 | 通过（实现边界；内存preferences） |
| S02 | 服务器地址规范化、去查询参数；无效 URL 和远程目录穿越校验 | 通过 |
| S03 | 历史只保留最新20项；本地/云端失败状态互相独立 | 通过 |

## 已确认缺陷与复现

### B01：成功生成同版本无法恢复的备份（高优先级）

测试：`backup_restore_audit_test.dart:317`，名称含 `DEFECT: backup must reject media beyond its own restore expansion limit`。

复现：临时 documents 的 media 下创建长度268,435,457字节的全零文件，调用正常 `buildLocalBackupZip(includeMedia:true)`。实际成功输出约1.12 MiB ZIP（最终完整运行1,178,757字节）；随后正常恢复在展开体积检查处拒绝，目标数据保持不变。失败断言要求备份端在无法满足自身恢复限制时抛出 `BackupException`，避免把不可用包报告为成功。

定位：`lib/backup/data_backup_service.dart:297` 的 `_addMediaToArchive` 和 `:174` 的 `_createBackupZip` 没有与恢复端一致的体积预检；`lib/backup/restore_safety.dart:10`–`:23` 将 ZIP/展开体积分别限制为128/256 MiB。即使 ZIP 很小也会触发。云端 run 沿用同一打包过程，但本例没有实际上传大型样本，因此不声称已实跑大包云端成功状态。

建议修复方向：打包前统一计算媒体及数据库预计展开体积，备份与恢复复用同一限制契约，超限在生成/上传成功前明确报错。不要静默丢弃媒体。

修复后：媒体枚举只取 `length()` 并累计预检，打包前按最终 manifest 大小再次校验，读取时复核文件长度；超限抛出 `BackupException`，快照和未完成 ZIP 在 `finally` 中删除。原失败用例现要求并得到 `BackupException`。

### B02：当前 schema 验证只检查列名，可接受缺少约束的数据库及非法账簿值（中优先级）

测试：`backup_restore_audit_test.dart:932`，名称含 `DEFECT: current-schema marker cannot admit missing account-book constraints`。

复现：从真实 schema 15 快照建立相同列的 `account_book` 副本，删除原表并重命名副本，额外建立 book_id 唯一索引以保持 SQLite 外键检查有效；设置 `name=''`、`is_default=7`；保持 user_version=15，重新计算 manifest DB SHA256。恢复没有报错，非法数据库取代目标。

定位：`lib/backup/restore_safety.dart:176`–`:192` 使用 `PRAGMA table_info` 只验证列集合，未校验 NOT NULL/类型/主键/必要 CHECK；显式语义检查只覆盖 gift_record 金额/方向/孤立记录。实际当前 schema 在 `lib/data/local/drift/tables.dart:18`–`:20` 和 `:40`–`:42` 对账簿名和默认标记有 CHECK。

这是构造同版本异常数据库时的防御校验缺口，不是声称正常产品能自然写出这些非法值，也不是要求兼容历史 schema。损坏 dbSHA、正常约束表中非法金额/方向、缺列/缺表和外键孤立等已有检查均通过。

建议修复方向：验证必要结构约束和关键字段值；在 staged DB 中拒绝非法当前 schema，保证触碰 live DB 前失败。

修复后：`_validateCurrentStructure` 校验表 SQL/CHECK、列类型与非空、主键、默认值、字段存储类型、关键值范围、空主键、外键签名、名称唯一索引及禁止触发器；原非法账簿数据库在 staged 阶段被拒绝，目标全表与媒体保持不变。

### B03：保护媒体缺失时先替换 live DB，之后才发现无法完整回退（中优先级）

测试：`backup_restore_audit_test.dart:626`，名称含 `DEFECT: missing saved media must be detected before replacing any live database`。

复现：保存完整 guard 和 journal；模拟一次中断后 live 数据库已经变化；删除 guard/media，保留 guard DB。调用 `recoverIfNeeded` 会抛出“恢复保护媒体缺失”，journal 保留，但 live DB 已先被 guard DB 覆盖，媒体未同步回退。完整全表比较失败，备注由中断状态变回旧值，数据库和媒体不再对应同一个阶段。

定位：`lib/backup/restore_safety.dart:294`–`:309` 先复制 DB/WAL/SHM；`:312` 才检查 `hadMedia` 对应的保护目录是否存在。

前提明确：需要保护数据自身不完整。普通回调异常、真实媒体写入冲突以及完整保护副本下的中断恢复均已验证成功，不能把这一项扩展为“所有回滚失败”。

建议修复方向：先验证整套 guard 存在、有效且可完整恢复，再改写任何 live 文件；恢复中断仍需可重入。

修复后：journal 记录 guard 全文件清单（相对路径、大小、SHA256）；恢复前核对数据库、媒体目录和每个文件，任一缺失或不一致即抛错，live 数据库与媒体不改动。新增损坏媒体用例验证拒绝及修复后可回退。

### B04：WebDAV GET 请求超时不覆盖响应正文（中优先级）

测试：`backup_restore_audit_test.dart:1164`，名称含 `DEFECT: stalled GET response body must respect configured request timeout`。

复现：本地真实 HTTP 服务立即返回200/Content-Length=128，发送1字节并 flush 后保持连接；客户端配置 `requestTimeout=40ms`，在服务端确认已发出正文后再等180ms，下载仍未完成。测试随后强制关闭客户端并释放服务端，避免留下挂起资源，再保留失败断言。

定位：`lib/backup/webdav_client.dart:174` 仅给 `req.close()` 加超时，该 Future 在响应头到达后结束；`:193` 的响应体 `await for` 没有超时。`DataRestoreService.restoreFromRemote` 使用同一 getFile，因此服务器正文停滞会一直阻塞恢复下载阶段；本测试直接验证 getFile 的真实行为，没有实际等待默认5分钟。

建议修复方向：让请求期限或明确的正文空闲超时覆盖整个响应流，并正确关闭连接、输出文件和下载临时目录。

修复后：`_RequestDeadline` 覆盖请求打开、正文读取和响应排空；GET 写入 `.part_*`，成功后才改名，超时中止请求并清理临时文件。原 40ms 停滞正文用例现按期限结束并抛出 `TimeoutException`，目标文件不存在。

## 实现边界，不能误读成通过了其他能力

1. 包范围是 SQLite+`media/`+manifest。SharedPreferences 设置、编辑保护开关/盐/密码哈希、WebDAV账号/密码/自动备份配置、备份历史、首选备份目录均不在包中。新设备恢复后不会恢复这些配置；现有设备设置也不被 ZIP 覆盖。本次不评价该产品范围是否应扩展。
2. 无媒体模式恢复会将所有 account_book/gift_record 附件字段、person.avatar_uri 清空，包括 HTTP URL，而不只是重映射本地路径；目标已有 media 整树会被替换为空目录。业务备注、回收站和其他列仍完整。报告将此作为当前明确分支行为，不将其含混表述成“所有字段零变化”。
3. running/pending/paused/failed 导入任务恢复后主动变为 canceled。源CSV/XLSX、导入用媒体ZIP、错误日志位于 imports/import_logs 等非 media 路径时不打包；数据库中的旧绝对路径和 mapping_json 内 ZIP 路径保留。全新设备无法凭这些路径继续任务。测试验证实际文件缺失和状态；`lib/import/data_import_service.dart:182`–`:184` 还会拒绝 canceled 任务启动，本测试未跨入导入服务重新跑任务。
4. ZIP 的原始 payload 翻转且保留 CRC、缺失已引用媒体会被拒绝，旧数据保全。中央目录 CRC 与本地头不一致但正文完整时可被接受。重打包并重算 CRC 的媒体可被接受；manifest 没有媒体 SHA 清单/签名，数据库 SHA 本身也不提供来源认证。这两项不作为严重数据完整性缺陷。
5. guard 目录在成功/失败后通常仍保留，测试只验证 pending journal 清理；没有验证长期空间清理策略。失败校验在创建 guard 后发生，也可能留下空或含 incoming.sqlite 的 guard。
6. 路径重映射测试覆盖本地实际 Windows 路径、反斜杠、相对路径和Unicode目录；没有证明 Android/iOS/macOS 沙箱权限及所有媒体URI协议兼容。

## 未覆盖的限制

- 没有读取旧测试，没有验证历史版本升级/跨 schema 恢复，也没有检查 UI 文案、文件选择器、真实用户目录。
- 未在手机真机或其他操作系统上运行；未用进程强杀/断电复现 fsync 和原子 rename 的平台行为。中断恢复使用真实磁盘文件和手工构造的协议阶段，不等同真实进程崩溃压力测试。
- rollback sidecar 用确定性哨兵验证精确复制；WAL快照用真实已提交WAL验证。没有同时保持生产连接写入并执行恢复；Provider关闭重开的验证由主线程负责，不能计入本文件通过数。
- 无远程公网 WebDAV 服务、TLS证书、Digest挑战、代理、跨域鉴权重定向、多GB传输或设备掉线压力测试。真实回环测试覆盖了主要方法、HTTP错误、头部超时、正文停滞；没有穷尽所有状态码和网络异常。
- 文件数/符号链接/巨型输入 ZIP 上限的一部分直接验证安全函数；未把所有极限都构造成磁盘ZIP。已单独用产品备份生成超过展开上限的真实高压缩包，不分配随机巨型数据。
- 现有 schema 业务规则不等同完整恶意 SQLite 安全审计；未穷举触发器、虚表、异常索引、所有字段类型和关系语义。B02仅报告已实际复现的约束/账簿值漏洞。
- SharedPreferences 是内存 mock；没有实际原生设置存储备份、加密或编辑密码验证测试。
