-- 说明：
-- - 本项目“账簿时间”字段为 book_time（毫秒时间戳），用于统一账簿内收礼记录的发生时间（occurred_at）。
-- - 早期云端表结构可能缺少该字段，导致云端数据与本地规则不一致。
-- - 本迁移将为 public.account_book 增加 book_time，并为存量数据进行回填。

ALTER TABLE public.account_book
ADD COLUMN IF NOT EXISTS book_time BIGINT;

-- 设置默认值，避免未来插入/更新时漏传 book_time 导致写入失败。
ALTER TABLE public.account_book
ALTER COLUMN book_time
SET DEFAULT ((extract(epoch from now()) * 1000)::bigint);

-- 回填历史数据：优先使用 updated_at，其次使用 created_at，最后使用当前时间。
UPDATE public.account_book
SET book_time = COALESCE(book_time, updated_at, created_at, (extract(epoch from now()) * 1000)::bigint)
WHERE book_time IS NULL;

-- 强制非空，确保与本地 Drift 约束一致。
ALTER TABLE public.account_book
ALTER COLUMN book_time
SET NOT NULL;
