# 事由管理标准接口（本地实现）

本项目的“事由管理”目前以 `AppData`（内存态 + SharedPreferences 持久化）作为权威数据源。账簿新增/编辑页需要实时获取“已启用”的事由列表时，应统一通过该接口读取。

## 数据结构

`ReasonData` 字段约定：

- `id`：字符串 ID（内部生成，持久稳定）
- `name`：事由名称（用户可编辑；大小写不敏感去重）
- `description`：描述（可选）
- `enabled`：是否启用（仅启用项对账簿选择器可见）
- `createdAt / updatedAt`：创建/更新时间

## 读接口

- `AppData.reasons`：返回全部事由（包含未启用项）
- `AppData.enabledReasons`：返回全部已启用事由（账簿选择器必须使用该列表）
- `AppData.findReason(id)`：按 ID 查找事由（找不到返回 null）

## 写接口

- `AppData.createReason(name, description?)`：创建事由（默认 `enabled=true`）
- `AppData.updateReason(id, name, description?)`：更新事由（不改变 enabled）
- `AppData.setReasonEnabled(id, enabled)`：启用/停用事由
- `AppData.deleteReason(id)`：删除事由
- `AppData.ensureReasonExists(name)`：确保某个名称的事由存在（用于兼容历史数据）

## 约束与一致性规则

- 名称唯一：创建/更新时按 `trim + toLowerCase` 去重。
- 至少一个启用：若发生“全部停用”的状态，系统会自动确保至少保留一个启用项。
- 账簿字段校验：账簿 `reasonType` 只能取自 `enabledReasons.name`，禁止手工输入。

