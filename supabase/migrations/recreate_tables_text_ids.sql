-- 说明：
-- - 本项目本地 Drift 的主键均为 TEXT（即使内容是 UUID 也以 TEXT 存储），并且部分表（如 reason）主键可能是非 UUID 格式字符串。
-- - 之前版本将主键定义为 UUID 会导致同步时 Postgrest 报错：invalid input syntax for type uuid。
-- - 该迁移采用“删除并重建”的方式修复（当前处于接入早期阶段，允许清理已有不完整的云端数据）。

-- 先移除旧表（包含外键依赖）
DROP TABLE IF EXISTS public.contact_relation CASCADE;
DROP TABLE IF EXISTS public.gift_record CASCADE;
DROP TABLE IF EXISTS public.person CASCADE;
DROP TABLE IF EXISTS public.reason CASCADE;
DROP TABLE IF EXISTS public.relation_type CASCADE;
DROP TABLE IF EXISTS public.account_book CASCADE;

-- 重新创建表：所有业务主键均改为 TEXT
CREATE TABLE IF NOT EXISTS public.account_book (
  book_id TEXT PRIMARY KEY,
  name TEXT NOT NULL CHECK(length(name) BETWEEN 1 AND 64),
  reason_type TEXT DEFAULT '',
  theme_color TEXT DEFAULT '#312E81',
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
  name TEXT NOT NULL CHECK(length(name) BETWEEN 1 AND 64),
  relationship_type TEXT DEFAULT '其他',
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
  currency TEXT DEFAULT 'CNY',
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
  name TEXT NOT NULL CHECK(length(name) BETWEEN 1 AND 64),
  normalized_name TEXT NOT NULL CHECK(length(normalized_name) BETWEEN 1 AND 64),
  description TEXT,
  enabled BOOLEAN DEFAULT TRUE,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.relation_type (
  type_id TEXT PRIMARY KEY,
  name TEXT NOT NULL CHECK(length(name) BETWEEN 1 AND 64),
  normalized_name TEXT NOT NULL CHECK(length(normalized_name) BETWEEN 1 AND 64),
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

-- 启用 RLS
ALTER TABLE public.account_book ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.person ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gift_record ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reason ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.relation_type ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_relation ENABLE ROW LEVEL SECURITY;

-- 重新创建策略
CREATE POLICY "Users can view their own account_book" ON public.account_book FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own account_book" ON public.account_book FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own account_book" ON public.account_book FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own account_book" ON public.account_book FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own person" ON public.person FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own person" ON public.person FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own person" ON public.person FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own person" ON public.person FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own gift_record" ON public.gift_record FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own gift_record" ON public.gift_record FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own gift_record" ON public.gift_record FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own gift_record" ON public.gift_record FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own reason" ON public.reason FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own reason" ON public.reason FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own reason" ON public.reason FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own reason" ON public.reason FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own relation_type" ON public.relation_type FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own relation_type" ON public.relation_type FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own relation_type" ON public.relation_type FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own relation_type" ON public.relation_type FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own contact_relation" ON public.contact_relation FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own contact_relation" ON public.contact_relation FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own contact_relation" ON public.contact_relation FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own contact_relation" ON public.contact_relation FOR DELETE USING (auth.uid() = user_id);
