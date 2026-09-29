-- 新安装及尚未发布的开发环境：联系人按 ID 全局共享。
-- 仅生成脚本；本轮未连接或修改任何云端数据库。
BEGIN;
ALTER TABLE public.person DROP CONSTRAINT IF EXISTS person_book_id_fkey;
COMMENT ON COLUMN public.person.book_id IS '创建来源元数据，不是联系人归属或生命周期约束';
ALTER TABLE public.gift_record DROP CONSTRAINT IF EXISTS gift_record_amount_cent_check;
ALTER TABLE public.gift_record ADD CONSTRAINT gift_record_amount_cent_check
  CHECK (amount_cent BETWEEN 1 AND 99999999999999);
CREATE INDEX IF NOT EXISTS idx_person_user_name ON public.person(user_id, name);
COMMIT;
