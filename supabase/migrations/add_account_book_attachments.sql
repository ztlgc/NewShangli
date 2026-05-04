ALTER TABLE public.account_book
ADD COLUMN IF NOT EXISTS attachments JSONB;
