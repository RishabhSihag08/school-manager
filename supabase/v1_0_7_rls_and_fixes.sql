-- ============================================================================
-- School Manager v1.0.7 Migration: Enable Full Anon Access & Table Policies
-- Run this script in the Supabase Project SQL Editor (Dashboard -> SQL Editor)
-- ============================================================================

-- 1. Enable Row Level Security and grant full CRUD permissions to anon & authenticated
DO $$
DECLARE
  tbl text;
  tables text[] := ARRAY[
    'academic_years',
    'app_versions',
    'profiles',
    'class_sections',
    'subjects',
    'subject_allocations',
    'students',
    'attendance',
    'timetables',
    'syllabi',
    'homeworks',
    'homework_completions',
    'announcements',
    'exams',
    'exam_results',
    'exam_student_summaries'
  ];
BEGIN
  FOREACH tbl IN ARRAY tables LOOP
    -- Ensure table exists before modifying
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = tbl AND table_schema = 'public') THEN
      EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', tbl);
      EXECUTE format('DROP POLICY IF EXISTS "Anon full access on %s" ON %I;', tbl, tbl);
      EXECUTE format('CREATE POLICY "Anon full access on %s" ON %I FOR ALL TO anon USING (true) WITH CHECK (true);', tbl, tbl);
      EXECUTE format('DROP POLICY IF EXISTS "Authenticated full access on %s" ON %I;', tbl, tbl);
      EXECUTE format('CREATE POLICY "Authenticated full access on %s" ON %I FOR ALL TO authenticated USING (true) WITH CHECK (true);', tbl, tbl);
    END IF;
  END LOOP;
END $$;

-- 2. Add Result Declaration Date and Selected Subjects to Exams table
ALTER TABLE exams ADD COLUMN IF NOT EXISTS result_declaration_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE exams ADD COLUMN IF NOT EXISTS included_subjects JSONB DEFAULT '[]'::jsonb;

-- 3. Cascade Deletion on Foreign Keys
ALTER TABLE students DROP CONSTRAINT IF EXISTS students_class_section_id_fkey;
ALTER TABLE students
  ADD CONSTRAINT students_class_section_id_fkey
  FOREIGN KEY (class_section_id) REFERENCES class_sections(id) ON DELETE CASCADE;

ALTER TABLE timetables DROP CONSTRAINT IF EXISTS timetables_class_section_id_fkey;
ALTER TABLE timetables
  ADD CONSTRAINT timetables_class_section_id_fkey
  FOREIGN KEY (class_section_id) REFERENCES class_sections(id) ON DELETE CASCADE;

ALTER TABLE syllabi DROP CONSTRAINT IF EXISTS syllabi_class_section_id_fkey;
ALTER TABLE syllabi
  ADD CONSTRAINT syllabi_class_section_id_fkey
  FOREIGN KEY (class_section_id) REFERENCES class_sections(id) ON DELETE CASCADE;

ALTER TABLE subject_allocations DROP CONSTRAINT IF EXISTS subject_allocations_class_section_id_fkey;
ALTER TABLE subject_allocations
  ADD CONSTRAINT subject_allocations_class_section_id_fkey
  FOREIGN KEY (class_section_id) REFERENCES class_sections(id) ON DELETE CASCADE;

ALTER TABLE announcements DROP CONSTRAINT IF EXISTS announcements_target_class_section_id_fkey;
ALTER TABLE announcements
  ADD CONSTRAINT announcements_target_class_section_id_fkey
  FOREIGN KEY (target_class_section_id) REFERENCES class_sections(id) ON DELETE CASCADE;

-- 4. Ensure an active Academic Year is seeded
INSERT INTO academic_years (id, name, is_active)
VALUES ('00000000-0000-0000-0000-000000000001', '2026-2027', true)
ON CONFLICT (name) DO UPDATE SET is_active = true;

-- 5. Reload Schema Cache for PostgREST
NOTIFY pgrst, 'reload schema';
