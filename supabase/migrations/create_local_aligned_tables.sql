-- 根据本地 Drift / SQLite 结构创建 Supabase 云端表。
-- 设计说明：
-- 1. 业务主键统一使用 TEXT，避免本地字符串主键与云端 UUID 类型冲突。
-- 2. 在云端额外增加 user_id，用于按登录用户隔离数据并配合 RLS。
-- 3. 尽量保持与本地表字段、索引、约束一致，便于后续双向同步。

-- =========================
-- 核心业务表
-- =========================

CREATE TABLE IF NOT EXISTS public.account_book (
  book_id TEXT PRIMARY KEY,
  name TEXT NOT NULL CHECK(length(name) BETWEEN 1 AND 32),
  reason_type TEXT NOT NULL DEFAULT '',
  theme_color TEXT NOT NULL DEFAULT '#312E81',
  icon TEXT,
  description TEXT,
  attachments JSONB,
  book_time BIGINT NOT NULL,
  is_default INTEGER NOT NULL DEFAULT 0 CHECK(is_default IN (0, 1)),
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.person (
  person_id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL REFERENCES public.account_book(book_id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK(length(name) BETWEEN 1 AND 32),
  relationship_type TEXT NOT NULL DEFAULT '其他',
  phone TEXT,
  birthday TEXT,
  anniversary TEXT,
  avatar_uri TEXT,
  note TEXT,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.gift_record (
  record_id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL REFERENCES public.account_book(book_id) ON DELETE CASCADE,
  person_id TEXT NOT NULL REFERENCES public.person(person_id) ON DELETE CASCADE,
  direction TEXT NOT NULL DEFAULT '收入' CHECK(direction IN ('收入', '支出')),
  amount_cent BIGINT NOT NULL CHECK(amount_cent > 0),
  currency TEXT NOT NULL DEFAULT 'CNY',
  event_name TEXT,
  occurred_at BIGINT NOT NULL,
  payment_method TEXT,
  note TEXT,
  attachments JSONB,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.reason (
  reason_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.relation_type (
  type_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.contact_relation (
  relation_id TEXT PRIMARY KEY,
  person_a_id TEXT NOT NULL REFERENCES public.person(person_id) ON DELETE CASCADE,
  person_b_id TEXT NOT NULL REFERENCES public.person(person_id) ON DELETE CASCADE,
  type_id TEXT NOT NULL REFERENCES public.relation_type(type_id) ON DELETE RESTRICT,
  note TEXT,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.data_import_job (
  job_id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL REFERENCES public.account_book(book_id) ON DELETE CASCADE,
  file_path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_hash TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  format TEXT NOT NULL,
  status TEXT NOT NULL,
  import_kind TEXT NOT NULL,
  mapping_json TEXT,
  total_rows INTEGER,
  processed_rows INTEGER NOT NULL DEFAULT 0,
  success_rows INTEGER NOT NULL DEFAULT 0,
  skipped_rows INTEGER NOT NULL DEFAULT 0,
  failed_rows INTEGER NOT NULL DEFAULT 0,
  byte_offset BIGINT NOT NULL DEFAULT 0,
  last_row_index INTEGER NOT NULL DEFAULT 0,
  error_log_path TEXT,
  started_at BIGINT NOT NULL,
  finished_at BIGINT,
  updated_at BIGINT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.entity_remark (
  remark_id TEXT PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at BIGINT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- =========================
-- 索引
-- =========================

CREATE INDEX IF NOT EXISTS idx_person_book_name
ON public.person(book_id, name);

CREATE INDEX IF NOT EXISTS idx_gift_record_book_occurred
ON public.gift_record(book_id, occurred_at);

CREATE INDEX IF NOT EXISTS idx_gift_record_book_person
ON public.gift_record(book_id, person_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_reason_name
ON public.reason(LOWER(name));

CREATE INDEX IF NOT EXISTS idx_reason_updated_at
ON public.reason(updated_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS idx_relation_type_name
ON public.relation_type(LOWER(name));

CREATE INDEX IF NOT EXISTS idx_relation_type_updated_at
ON public.relation_type(updated_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS idx_contact_relation_pair_type
ON public.contact_relation(person_a_id, person_b_id, type_id);

CREATE INDEX IF NOT EXISTS idx_contact_relation_updated_at
ON public.contact_relation(updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_import_job_book_started
ON public.data_import_job(book_id, started_at);

CREATE INDEX IF NOT EXISTS idx_import_job_status_updated
ON public.data_import_job(status, updated_at);

CREATE INDEX IF NOT EXISTS idx_entity_remark_entity_time
ON public.entity_remark(entity_type, entity_id, created_at DESC);

-- 按用户维度增加查询索引，便于 RLS 下的常见过滤。
CREATE INDEX IF NOT EXISTS idx_account_book_user_id
ON public.account_book(user_id);

CREATE INDEX IF NOT EXISTS idx_person_user_id
ON public.person(user_id);

CREATE INDEX IF NOT EXISTS idx_gift_record_user_id
ON public.gift_record(user_id);

CREATE INDEX IF NOT EXISTS idx_reason_user_id
ON public.reason(user_id);

CREATE INDEX IF NOT EXISTS idx_relation_type_user_id
ON public.relation_type(user_id);

CREATE INDEX IF NOT EXISTS idx_contact_relation_user_id
ON public.contact_relation(user_id);

CREATE INDEX IF NOT EXISTS idx_data_import_job_user_id
ON public.data_import_job(user_id);

CREATE INDEX IF NOT EXISTS idx_entity_remark_user_id
ON public.entity_remark(user_id);

-- =========================
-- 行级安全策略（RLS）
-- =========================

ALTER TABLE public.account_book ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.person ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gift_record ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reason ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.relation_type ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_relation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.data_import_job ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.entity_remark ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own account_book" ON public.account_book;
DROP POLICY IF EXISTS "Users can insert their own account_book" ON public.account_book;
DROP POLICY IF EXISTS "Users can update their own account_book" ON public.account_book;
DROP POLICY IF EXISTS "Users can delete their own account_book" ON public.account_book;

CREATE POLICY "Users can view their own account_book"
ON public.account_book
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own account_book"
ON public.account_book
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own account_book"
ON public.account_book
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own account_book"
ON public.account_book
FOR DELETE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their own person" ON public.person;
DROP POLICY IF EXISTS "Users can insert their own person" ON public.person;
DROP POLICY IF EXISTS "Users can update their own person" ON public.person;
DROP POLICY IF EXISTS "Users can delete their own person" ON public.person;

CREATE POLICY "Users can view their own person"
ON public.person
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own person"
ON public.person
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own person"
ON public.person
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own person"
ON public.person
FOR DELETE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their own gift_record" ON public.gift_record;
DROP POLICY IF EXISTS "Users can insert their own gift_record" ON public.gift_record;
DROP POLICY IF EXISTS "Users can update their own gift_record" ON public.gift_record;
DROP POLICY IF EXISTS "Users can delete their own gift_record" ON public.gift_record;

CREATE POLICY "Users can view their own gift_record"
ON public.gift_record
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own gift_record"
ON public.gift_record
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own gift_record"
ON public.gift_record
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own gift_record"
ON public.gift_record
FOR DELETE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their own reason" ON public.reason;
DROP POLICY IF EXISTS "Users can insert their own reason" ON public.reason;
DROP POLICY IF EXISTS "Users can update their own reason" ON public.reason;
DROP POLICY IF EXISTS "Users can delete their own reason" ON public.reason;

CREATE POLICY "Users can view their own reason"
ON public.reason
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own reason"
ON public.reason
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reason"
ON public.reason
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reason"
ON public.reason
FOR DELETE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their own relation_type" ON public.relation_type;
DROP POLICY IF EXISTS "Users can insert their own relation_type" ON public.relation_type;
DROP POLICY IF EXISTS "Users can update their own relation_type" ON public.relation_type;
DROP POLICY IF EXISTS "Users can delete their own relation_type" ON public.relation_type;

CREATE POLICY "Users can view their own relation_type"
ON public.relation_type
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own relation_type"
ON public.relation_type
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own relation_type"
ON public.relation_type
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own relation_type"
ON public.relation_type
FOR DELETE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their own contact_relation" ON public.contact_relation;
DROP POLICY IF EXISTS "Users can insert their own contact_relation" ON public.contact_relation;
DROP POLICY IF EXISTS "Users can update their own contact_relation" ON public.contact_relation;
DROP POLICY IF EXISTS "Users can delete their own contact_relation" ON public.contact_relation;

CREATE POLICY "Users can view their own contact_relation"
ON public.contact_relation
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own contact_relation"
ON public.contact_relation
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own contact_relation"
ON public.contact_relation
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own contact_relation"
ON public.contact_relation
FOR DELETE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their own data_import_job" ON public.data_import_job;
DROP POLICY IF EXISTS "Users can insert their own data_import_job" ON public.data_import_job;
DROP POLICY IF EXISTS "Users can update their own data_import_job" ON public.data_import_job;
DROP POLICY IF EXISTS "Users can delete their own data_import_job" ON public.data_import_job;

CREATE POLICY "Users can view their own data_import_job"
ON public.data_import_job
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own data_import_job"
ON public.data_import_job
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own data_import_job"
ON public.data_import_job
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own data_import_job"
ON public.data_import_job
FOR DELETE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their own entity_remark" ON public.entity_remark;
DROP POLICY IF EXISTS "Users can insert their own entity_remark" ON public.entity_remark;
DROP POLICY IF EXISTS "Users can update their own entity_remark" ON public.entity_remark;
DROP POLICY IF EXISTS "Users can delete their own entity_remark" ON public.entity_remark;

CREATE POLICY "Users can view their own entity_remark"
ON public.entity_remark
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own entity_remark"
ON public.entity_remark
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own entity_remark"
ON public.entity_remark
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own entity_remark"
ON public.entity_remark
FOR DELETE
USING (auth.uid() = user_id);
