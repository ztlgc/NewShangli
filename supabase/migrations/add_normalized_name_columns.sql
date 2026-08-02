-- 修复远端库与本地 Drift 结构不一致的问题。
-- 现象：上传报错 PGRST 204 "Could not find the 'normalized_name' column of 'reason' in the schema cache"
-- 原因：远端 reason / relation_type 表由旧版建表脚本创建，缺少后加的 normalized_name 列；
--       旧脚本使用 CREATE TABLE IF NOT EXISTS，重跑也不会为已存在的表补列。
-- 本脚本幂等（可重复执行），在 Supabase Dashboard → SQL Editor 中运行即可。

-- =========================
-- 1. 补充缺失列
-- =========================
ALTER TABLE public.reason ADD COLUMN IF NOT EXISTS normalized_name TEXT;
ALTER TABLE public.reason ADD COLUMN IF NOT EXISTS enabled BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.relation_type ADD COLUMN IF NOT EXISTS normalized_name TEXT;

-- account_book 若也为旧版本表，一并补列（book_time / attachments 为后加字段）
ALTER TABLE public.account_book ADD COLUMN IF NOT EXISTS book_time BIGINT NOT NULL DEFAULT 0;
ALTER TABLE public.account_book ADD COLUMN IF NOT EXISTS attachments JSONB;

-- =========================
-- 2. 回填 normalized_name
--    与客户端 _normalizeUniqueName 保持一致（trim + toLowerCase）
-- =========================
UPDATE public.reason
SET normalized_name = lower(trim(name))
WHERE normalized_name IS NULL OR normalized_name = '';

UPDATE public.relation_type
SET normalized_name = lower(trim(name))
WHERE normalized_name IS NULL OR normalized_name = '';

-- =========================
-- 3. 大小写重复行去重：保留最早一行，其余追加序号
--    避免唯一索引创建失败；只改 normalized_name 不删行，不影响 contact_relation 外键
-- =========================
WITH ranked AS (
  SELECT reason_id,
         row_number() OVER (PARTITION BY normalized_name ORDER BY reason_id) AS rn
  FROM public.reason
)
UPDATE public.reason r
SET normalized_name = left(r.normalized_name, 60) || '-' || ranked.rn
FROM ranked
WHERE r.reason_id = ranked.reason_id AND ranked.rn > 1;

WITH ranked AS (
  SELECT type_id,
         row_number() OVER (PARTITION BY normalized_name ORDER BY type_id) AS rn
  FROM public.relation_type
)
UPDATE public.relation_type r
SET normalized_name = left(r.normalized_name, 60) || '-' || ranked.rn
FROM ranked
WHERE r.type_id = ranked.type_id AND ranked.rn > 1;

-- =========================
-- 4. 设置 NOT NULL
-- =========================
ALTER TABLE public.reason ALTER COLUMN normalized_name SET NOT NULL;
ALTER TABLE public.relation_type ALTER COLUMN normalized_name SET NOT NULL;

-- =========================
-- 5. 与本地结构一致的索引
-- =========================
CREATE UNIQUE INDEX IF NOT EXISTS idx_reason_normalized_name
ON public.reason(normalized_name);

CREATE UNIQUE INDEX IF NOT EXISTS idx_relation_type_normalized_name
ON public.relation_type(normalized_name);

CREATE INDEX IF NOT EXISTS idx_reason_updated_at
ON public.reason(updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_relation_type_updated_at
ON public.relation_type(updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_reason_user_id
ON public.reason(user_id);

CREATE INDEX IF NOT EXISTS idx_relation_type_user_id
ON public.relation_type(user_id);

-- =========================
-- 6. 刷新 PostgREST schema cache
--    兜底处理缓存未自动刷新的情况
-- =========================
NOTIFY pgrst, 'reload schema';
