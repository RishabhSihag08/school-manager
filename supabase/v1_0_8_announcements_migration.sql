-- ============================================================================
-- School Manager v1.0.8 Migration: Announcement Expiration & Author Roles
-- Run this script in the Supabase Project SQL Editor (Dashboard -> SQL Editor)
-- ============================================================================

-- 1. Add expiration date/time, author role, and author name to announcements
ALTER TABLE IF EXISTS announcements ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;
ALTER TABLE IF EXISTS announcements ADD COLUMN IF NOT EXISTS author_id UUID;
ALTER TABLE IF EXISTS announcements ADD COLUMN IF NOT EXISTS author_role TEXT DEFAULT 'admin';
ALTER TABLE IF EXISTS announcements ADD COLUMN IF NOT EXISTS author_name TEXT;

-- 2. Reload PostgREST Schema Cache
NOTIFY pgrst, 'reload schema';
