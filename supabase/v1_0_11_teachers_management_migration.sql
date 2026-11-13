-- ============================================================================
-- School Manager v1.0.11 Migration: Faculty & Teachers Management
-- Run this script in the Supabase Project SQL Editor (Dashboard -> SQL Editor)
-- ============================================================================

-- 1. Ensure `email` and proper column types exist on `profiles`
ALTER TABLE IF EXISTS profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE IF EXISTS profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE IF EXISTS profiles ADD COLUMN IF NOT EXISTS pin_hash TEXT;

-- 2. Ensure case-insensitive uniqueness and indexes on login_code & role
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_login_code ON profiles(login_code);
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_login_code_lower 
  ON profiles(LOWER(TRIM(login_code))) 
  WHERE login_code IS NOT NULL;

-- 3. Fix foreign key constraints for safe account deletion
-- Allow homeworks.teacher_id and timetables.teacher_id to be NULL so deleting a teacher succeeds without FK violation
ALTER TABLE IF EXISTS homeworks ALTER COLUMN teacher_id DROP NOT NULL;
ALTER TABLE IF EXISTS timetables ALTER COLUMN teacher_id DROP NOT NULL;

-- Ensure ON DELETE SET NULL on class_sections.class_teacher_id
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'class_sections_class_teacher_id_fkey' 
    AND table_name = 'class_sections'
  ) THEN
    ALTER TABLE class_sections DROP CONSTRAINT class_sections_class_teacher_id_fkey;
    ALTER TABLE class_sections 
      ADD CONSTRAINT class_sections_class_teacher_id_fkey 
      FOREIGN KEY (class_teacher_id) REFERENCES profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Ensure ON DELETE CASCADE on subject_allocations.teacher_id
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'subject_allocations_teacher_id_fkey' 
    AND table_name = 'subject_allocations'
  ) THEN
    ALTER TABLE subject_allocations DROP CONSTRAINT subject_allocations_teacher_id_fkey;
    ALTER TABLE subject_allocations 
      ADD CONSTRAINT subject_allocations_teacher_id_fkey 
      FOREIGN KEY (teacher_id) REFERENCES profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

-- 4. Enable Row Level Security (RLS) & Grant Permissions
ALTER TABLE IF EXISTS profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS class_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS subject_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS subjects ENABLE ROW LEVEL SECURITY;

-- Profiles: Grant SELECT, INSERT, UPDATE, DELETE to anon and authenticated
DROP POLICY IF EXISTS "Anon full access on profiles" ON profiles;
CREATE POLICY "Anon full access on profiles" ON profiles FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on profiles" ON profiles;
CREATE POLICY "Authenticated full access on profiles" ON profiles FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Class Sections: Grant SELECT, INSERT, UPDATE, DELETE to anon and authenticated
DROP POLICY IF EXISTS "Anon full access on class_sections" ON class_sections;
CREATE POLICY "Anon full access on class_sections" ON class_sections FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on class_sections" ON class_sections;
CREATE POLICY "Authenticated full access on class_sections" ON class_sections FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Subject Allocations: Grant SELECT, INSERT, UPDATE, DELETE to anon and authenticated
DROP POLICY IF EXISTS "Anon full access on subject_allocations" ON subject_allocations;
CREATE POLICY "Anon full access on subject_allocations" ON subject_allocations FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on subject_allocations" ON subject_allocations;
CREATE POLICY "Authenticated full access on subject_allocations" ON subject_allocations FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Subjects: Grant SELECT, INSERT, UPDATE, DELETE to anon and authenticated
DROP POLICY IF EXISTS "Anon full access on subjects" ON subjects;
CREATE POLICY "Anon full access on subjects" ON subjects FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on subjects" ON subjects;
CREATE POLICY "Authenticated full access on subjects" ON subjects FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 5. Stored Procedure for Atomic Safe Teacher Deletion (Optional RPC)
CREATE OR REPLACE FUNCTION delete_teacher_cascade(target_teacher_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 1. Unassign from any homeroom classes
  UPDATE class_sections 
  SET class_teacher_id = NULL 
  WHERE class_teacher_id = target_teacher_id;

  -- 2. Remove all subject allocations
  DELETE FROM subject_allocations 
  WHERE teacher_id = target_teacher_id;

  -- 3. Set teacher_id to NULL on any timetables and homeworks
  UPDATE timetables 
  SET teacher_id = NULL 
  WHERE teacher_id = target_teacher_id;

  UPDATE homeworks 
  SET teacher_id = NULL 
  WHERE teacher_id = target_teacher_id;

  -- 4. Delete the profile record
  DELETE FROM profiles 
  WHERE id = target_teacher_id AND role = 'teacher';
END;
$$;

-- 6. Helper View for Fast Admin Teacher Directory Inspection
CREATE OR REPLACE VIEW teachers_directory_view AS
SELECT 
  p.id,
  p.full_name,
  p.login_code,
  p.phone,
  p.email,
  p.pin_hash AS pin,
  p.avatar_url,
  p.created_at,
  cs.id AS homeroom_class_id,
  CASE 
    WHEN cs.id IS NOT NULL THEN 'Class ' || cs.grade || '-' || cs.section 
    ELSE NULL 
  END AS homeroom_class_name,
  cs.class_code AS homeroom_class_code,
  (
    SELECT s.name 
    FROM subject_allocations sa 
    JOIN subjects s ON s.id = sa.subject_id 
    WHERE sa.teacher_id = p.id 
    LIMIT 1
  ) AS subject_name,
  (
    SELECT s.code 
    FROM subject_allocations sa 
    JOIN subjects s ON s.id = sa.subject_id 
    WHERE sa.teacher_id = p.id 
    LIMIT 1
  ) AS subject_code,
  COALESCE(
    (
      SELECT json_agg(sa.class_section_id)
      FROM subject_allocations sa 
      WHERE sa.teacher_id = p.id
    ),
    '[]'::json
  ) AS teaching_class_ids
FROM profiles p
LEFT JOIN class_sections cs ON cs.class_teacher_id = p.id
WHERE p.role = 'teacher'
ORDER BY p.full_name ASC;

-- 7. Reload PostgREST Schema Cache
NOTIFY pgrst, 'reload schema';
