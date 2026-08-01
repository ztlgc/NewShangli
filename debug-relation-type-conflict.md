# Debug Session: relation-type-conflict
- **Status**: [OPEN]
- **Issue**: Supabase 云同步时报 `duplicate key value violates unique constraint "idx_relation_type_name"`，表象发生在“上传/同步”阶段。
- **Debug Server**: Pending
- **Log File**: .dbg/trae-debug-log-relation-type-conflict.ndjson

## Reproduction Steps
1. 登录已配置 Supabase 的账号。
2. 触发云同步/上传流程。
3. 在同步过程中出现 `PostgrestException(message: duplicate key value violates unique constraint "idx_relation_type_name", code: 23505, details: Conflict, hint: null)`。

## Hypotheses & Verification
| ID | Hypothesis | Likelihood | Effort | Evidence |
|----|------------|------------|--------|----------|
| A | 云端 `relation_type` 对 `LOWER(name)` 唯一，但当前上行 `upsert` 仍按 `type_id`，导致“同名不同 id”冲突 | High | Low | Pending |
| B | 本地存在大小写不同但归一化后相同的关系类型，云端索引按 `LOWER(name)` 合并后冲突 | High | Low | Pending |
| C | 之前只修了 `reason` 表，同样的问题在 `relation_type` 表复现 | High | Low | Pending |
| D | 错误被页面统一包装成“附件上传失败”，实际失败点发生在附件上传之前的表同步阶段 | Medium | Low | Pending |
| E | Supabase/PostgREST `upsert` 未显式指定正确的 `onConflict` 字段，默认冲突目标与云端唯一索引不一致 | Medium | Medium | Pending |

## Log Evidence
- 本地 `relation_type` 表主键是 `type_id`，唯一索引是名称大小写不敏感唯一：
  - `lib/data/local/drift/tables.dart:219-223`
- 云端 `relation_type` 表也对 `LOWER(name)` 建了唯一索引：
  - `supabase/migrations/create_local_aligned_tables.sql:143-144`
- 当前上行同步 `relation_type` 仍然是直接：
  - `await _supabase.from('relation_type').upsert(relationTypesData);`
  - 位置：`lib/backup/supabase_sync_service.dart` 的关系类型同步段
- Supabase 官方文档说明：`.upsert()` 是否更新取决于 `onConflict` 指定的列；不指定时不会自动按别的唯一列推断冲突目标。
- PostgREST 官方文档说明：可以通过 `on_conflict` 指向“有 UNIQUE 约束/唯一索引的列”来让 upsert 按该列判重。

## Verification Conclusion
- **A Confirmed**：`relation_type` 与 `reason` 是同类问题，云端唯一性按 `LOWER(name)`，当前 upsert 仍按主键路径工作。
- **B Confirmed**：只要本地和云端有“同名不同 type_id”或大小写不同但归一化后相同的名称，就会触发 `idx_relation_type_name`。
- **C Confirmed**：上次只修了 `reason`，`relation_type` 的同步逻辑还没做同样的兼容。
- **D Likely**：页面把同步阶段异常包装成“上传失败”，但真实失败点发生在关系类型上行。
- **E Confirmed**：按官方文档，当前调用缺少与唯一名称约束对齐的冲突目标/预处理逻辑。
