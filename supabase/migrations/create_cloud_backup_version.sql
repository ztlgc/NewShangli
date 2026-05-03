CREATE TABLE IF NOT EXISTS public.cloud_backup_version (
  backup_id UUID PRIMARY KEY,
  kind TEXT NOT NULL CHECK(kind IN ('manual', 'auto')),
  storage_bucket TEXT NOT NULL DEFAULT 'backups',
  storage_path TEXT NOT NULL,
  size_bytes BIGINT NOT NULL DEFAULT 0,
  created_at BIGINT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE public.cloud_backup_version ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own cloud_backup_version"
ON public.cloud_backup_version
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own cloud_backup_version"
ON public.cloud_backup_version
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cloud_backup_version"
ON public.cloud_backup_version
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cloud_backup_version"
ON public.cloud_backup_version
FOR DELETE
USING (auth.uid() = user_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_cloud_backup_auto_unique
ON public.cloud_backup_version(user_id)
WHERE kind = 'auto';

CREATE INDEX IF NOT EXISTS idx_cloud_backup_user_time
ON public.cloud_backup_version(user_id, created_at DESC);
