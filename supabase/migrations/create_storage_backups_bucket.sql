INSERT INTO storage.buckets (id, name, public)
VALUES ('backups', 'backups', FALSE)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "backups_select_own" ON storage.objects;
DROP POLICY IF EXISTS "backups_insert_own" ON storage.objects;
DROP POLICY IF EXISTS "backups_update_own" ON storage.objects;
DROP POLICY IF EXISTS "backups_delete_own" ON storage.objects;

CREATE POLICY "backups_select_own"
ON storage.objects
FOR SELECT
USING (
  bucket_id = 'backups'
  AND auth.uid()::text = split_part(name, '/', 1)
);

CREATE POLICY "backups_insert_own"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'backups'
  AND auth.uid()::text = split_part(name, '/', 1)
);

CREATE POLICY "backups_update_own"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'backups'
  AND auth.uid()::text = split_part(name, '/', 1)
)
WITH CHECK (
  bucket_id = 'backups'
  AND auth.uid()::text = split_part(name, '/', 1)
);

CREATE POLICY "backups_delete_own"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'backups'
  AND auth.uid()::text = split_part(name, '/', 1)
);
