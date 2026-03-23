-- 说明：
-- - Supabase Storage 的 Bucket 创建与访问策略应在服务端配置，而不是由前端（anon key）在运行时创建。
-- - 本迁移创建名为 `media` 的私有 Bucket，并为 `storage.objects` 配置 RLS 策略：
--   仅允许已登录用户访问自己目录（对象路径第一段为 auth.uid()）下的文件。

-- 创建 Bucket（若已存在则忽略）
INSERT INTO storage.buckets (id, name, public)
VALUES ('media', 'media', FALSE)
ON CONFLICT (id) DO NOTHING;

-- 重新创建策略（避免重复）
DROP POLICY IF EXISTS "media_select_own" ON storage.objects;
DROP POLICY IF EXISTS "media_insert_own" ON storage.objects;
DROP POLICY IF EXISTS "media_update_own" ON storage.objects;
DROP POLICY IF EXISTS "media_delete_own" ON storage.objects;

-- 读取：只能读取自己目录下的对象
CREATE POLICY "media_select_own"
ON storage.objects
FOR SELECT
USING (
  bucket_id = 'media'
  AND auth.uid()::text = split_part(name, '/', 1)
);

-- 写入：只能写入自己目录下的对象
CREATE POLICY "media_insert_own"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'media'
  AND auth.uid()::text = split_part(name, '/', 1)
);

-- 更新（upsert 需要）：只能更新自己目录下的对象
CREATE POLICY "media_update_own"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'media'
  AND auth.uid()::text = split_part(name, '/', 1)
)
WITH CHECK (
  bucket_id = 'media'
  AND auth.uid()::text = split_part(name, '/', 1)
);

-- 删除：只能删除自己目录下的对象
CREATE POLICY "media_delete_own"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'media'
  AND auth.uid()::text = split_part(name, '/', 1)
);

