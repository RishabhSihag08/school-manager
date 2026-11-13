-- ============================================================================
-- School Manager v1.0.7 Migration: Enable Full Anon Access & Table Policies
-- Run this script in the Supabase Project SQL Editor (Dashboard -> SQL Editor)
-- ============================================================================

-- 1. Enable Row Level Security & Grant Full Access for Anon and Authenticated Roles
-- (Note: The marks table is "exam_results" and summary table is "exam_student_summaries")

ALTER TABLE IF EXISTS academic_years ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on academic_years" ON academic_years;
CREATE POLICY "Anon full access on academic_years" ON academic_years FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on academic_years" ON academic_years;
CREATE POLICY "Authenticated full access on academic_years" ON academic_years FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS app_versions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on app_versions" ON app_versions;
CREATE POLICY "Anon full access on app_versions" ON app_versions FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on app_versions" ON app_versions;
CREATE POLICY "Authenticated full access on app_versions" ON app_versions FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on profiles" ON profiles;
CREATE POLICY "Anon full access on profiles" ON profiles FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on profiles" ON profiles;
CREATE POLICY "Authenticated full access on profiles" ON profiles FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS class_sections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on class_sections" ON class_sections;
CREATE POLICY "Anon full access on class_sections" ON class_sections FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on class_sections" ON class_sections;
CREATE POLICY "Authenticated full access on class_sections" ON class_sections FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS subjects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on subjects" ON subjects;
CREATE POLICY "Anon full access on subjects" ON subjects FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on subjects" ON subjects;
CREATE POLICY "Authenticated full access on subjects" ON subjects FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS subject_allocations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on subject_allocations" ON subject_allocations;
CREATE POLICY "Anon full access on subject_allocations" ON subject_allocations FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on subject_allocations" ON subject_allocations;
CREATE POLICY "Authenticated full access on subject_allocations" ON subject_allocations FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS students ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on students" ON students;
CREATE POLICY "Anon full access on students" ON students FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on students" ON students;
CREATE POLICY "Authenticated full access on students" ON students FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on attendance" ON attendance;
CREATE POLICY "Anon full access on attendance" ON attendance FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on attendance" ON attendance;
CREATE POLICY "Authenticated full access on attendance" ON attendance FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS timetables ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on timetables" ON timetables;
CREATE POLICY "Anon full access on timetables" ON timetables FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on timetables" ON timetables;
CREATE POLICY "Authenticated full access on timetables" ON timetables FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS syllabi ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on syllabi" ON syllabi;
CREATE POLICY "Anon full access on syllabi" ON syllabi FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on syllabi" ON syllabi;
CREATE POLICY "Authenticated full access on syllabi" ON syllabi FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS homeworks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on homeworks" ON homeworks;
CREATE POLICY "Anon full access on homeworks" ON homeworks FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on homeworks" ON homeworks;
CREATE POLICY "Authenticated full access on homeworks" ON homeworks FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS homework_completions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on homework_completions" ON homework_completions;
CREATE POLICY "Anon full access on homework_completions" ON homework_completions FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on homework_completions" ON homework_completions;
CREATE POLICY "Authenticated full access on homework_completions" ON homework_completions FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS announcements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on announcements" ON announcements;
CREATE POLICY "Anon full access on announcements" ON announcements FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on announcements" ON announcements;
CREATE POLICY "Authenticated full access on announcements" ON announcements FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS exams ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on exams" ON exams;
CREATE POLICY "Anon full access on exams" ON exams FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on exams" ON exams;
CREATE POLICY "Authenticated full access on exams" ON exams FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS exam_results ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on exam_results" ON exam_results;
CREATE POLICY "Anon full access on exam_results" ON exam_results FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on exam_results" ON exam_results;
CREATE POLICY "Authenticated full access on exam_results" ON exam_results FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS exam_student_summaries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anon full access on exam_student_summaries" ON exam_student_summaries;
CREATE POLICY "Anon full access on exam_student_summaries" ON exam_student_summaries FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated full access on exam_student_summaries" ON exam_student_summaries;
CREATE POLICY "Authenticated full access on exam_student_summaries" ON exam_student_summaries FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 2. Add Cascade Deletion on Students when Class is Deleted
ALTER TABLE students DROP CONSTRAINT IF EXISTS students_class_section_id_fkey;
ALTER TABLE students
  ADD CONSTRAINT students_class_section_id_fkey
  FOREIGN KEY (class_section_id) REFERENCES class_sections(id) ON DELETE CASCADE;

-- 3. Add Custom Exam Wizard Columns
ALTER TABLE exams ADD COLUMN IF NOT EXISTS result_declaration_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE exams ADD COLUMN IF NOT EXISTS included_subjects JSONB DEFAULT '[]'::jsonb;

-- 4. Reload PostgREST Schema Cache
NOTIFY pgrst, 'reload schema';
