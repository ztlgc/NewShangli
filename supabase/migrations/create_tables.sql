-- Create account_book table
CREATE TABLE IF NOT EXISTS public.account_book (
  book_id UUID PRIMARY KEY,
  name TEXT NOT NULL CHECK(length(name) BETWEEN 1 AND 64),
  reason_type TEXT DEFAULT '',
  theme_color TEXT DEFAULT '#312E81',
  icon TEXT,
  description TEXT,
  is_default INTEGER NOT NULL DEFAULT 0 CHECK(is_default IN (0, 1)),
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create person table
CREATE TABLE IF NOT EXISTS public.person (
  person_id UUID PRIMARY KEY,
  book_id UUID NOT NULL REFERENCES public.account_book(book_id) ON DELETE CASCADE,
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

-- Create gift_record table
CREATE TABLE IF NOT EXISTS public.gift_record (
  record_id UUID PRIMARY KEY,
  book_id UUID NOT NULL REFERENCES public.account_book(book_id) ON DELETE CASCADE,
  person_id UUID NOT NULL REFERENCES public.person(person_id) ON DELETE CASCADE,
  reminder_id UUID,
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

-- Create event_reminder table
CREATE TABLE IF NOT EXISTS public.event_reminder (
  reminder_id UUID PRIMARY KEY,
  book_id UUID NOT NULL REFERENCES public.account_book(book_id) ON DELETE CASCADE,
  person_id UUID REFERENCES public.person(person_id) ON DELETE SET NULL,
  relation_person_ids TEXT DEFAULT '[]',
  reminder_type TEXT DEFAULT '自定义',
  title TEXT DEFAULT '',
  target_date TEXT NOT NULL,
  remind_at BIGINT NOT NULL,
  repeat_rule TEXT DEFAULT 'none',
  status TEXT DEFAULT 'active',
  channel TEXT DEFAULT 'notification',
  note TEXT,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create reason table
CREATE TABLE IF NOT EXISTS public.reason (
  reason_id UUID PRIMARY KEY,
  name TEXT NOT NULL CHECK(length(name) BETWEEN 1 AND 64),
  description TEXT,
  enabled BOOLEAN DEFAULT TRUE,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create relation_type table
CREATE TABLE IF NOT EXISTS public.relation_type (
  type_id UUID PRIMARY KEY,
  name TEXT NOT NULL CHECK(length(name) BETWEEN 1 AND 64),
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create contact_relation table
CREATE TABLE IF NOT EXISTS public.contact_relation (
  relation_id UUID PRIMARY KEY,
  person_a_id UUID NOT NULL REFERENCES public.person(person_id) ON DELETE CASCADE,
  person_b_id UUID NOT NULL REFERENCES public.person(person_id) ON DELETE CASCADE,
  type_id UUID NOT NULL REFERENCES public.relation_type(type_id) ON DELETE RESTRICT,
  note TEXT,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create reminder_type table
CREATE TABLE IF NOT EXISTS public.reminder_type (
  type_id UUID PRIMARY KEY,
  book_id UUID NOT NULL REFERENCES public.account_book(book_id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_custom BOOLEAN DEFAULT FALSE,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Enable RLS for all tables
ALTER TABLE public.account_book ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.person ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gift_record ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_reminder ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reason ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.relation_type ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_relation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminder_type ENABLE ROW LEVEL SECURITY;

-- Create policies for account_book
CREATE POLICY "Users can view their own account_book" ON public.account_book FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own account_book" ON public.account_book FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own account_book" ON public.account_book FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own account_book" ON public.account_book FOR DELETE USING (auth.uid() = user_id);

-- Create policies for person
CREATE POLICY "Users can view their own person" ON public.person FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own person" ON public.person FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own person" ON public.person FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own person" ON public.person FOR DELETE USING (auth.uid() = user_id);

-- Create policies for gift_record
CREATE POLICY "Users can view their own gift_record" ON public.gift_record FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own gift_record" ON public.gift_record FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own gift_record" ON public.gift_record FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own gift_record" ON public.gift_record FOR DELETE USING (auth.uid() = user_id);

-- Create policies for event_reminder
CREATE POLICY "Users can view their own event_reminder" ON public.event_reminder FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own event_reminder" ON public.event_reminder FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own event_reminder" ON public.event_reminder FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own event_reminder" ON public.event_reminder FOR DELETE USING (auth.uid() = user_id);

-- Create policies for reason
CREATE POLICY "Users can view their own reason" ON public.reason FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own reason" ON public.reason FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own reason" ON public.reason FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own reason" ON public.reason FOR DELETE USING (auth.uid() = user_id);

-- Create policies for relation_type
CREATE POLICY "Users can view their own relation_type" ON public.relation_type FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own relation_type" ON public.relation_type FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own relation_type" ON public.relation_type FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own relation_type" ON public.relation_type FOR DELETE USING (auth.uid() = user_id);

-- Create policies for contact_relation
CREATE POLICY "Users can view their own contact_relation" ON public.contact_relation FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own contact_relation" ON public.contact_relation FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own contact_relation" ON public.contact_relation FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own contact_relation" ON public.contact_relation FOR DELETE USING (auth.uid() = user_id);

-- Create policies for reminder_type
CREATE POLICY "Users can view their own reminder_type" ON public.reminder_type FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own reminder_type" ON public.reminder_type FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own reminder_type" ON public.reminder_type FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own reminder_type" ON public.reminder_type FOR DELETE USING (auth.uid() = user_id);
