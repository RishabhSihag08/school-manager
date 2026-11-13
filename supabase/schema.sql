-- CampusVibe Indian School Management System
-- Database Schema & Initial Demo Data Migration

-- 1. Custom Enums
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('admin', 'teacher', 'student');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE house_color AS ENUM ('red', 'blue', 'green', 'yellow');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE attendance_status AS ENUM ('present', 'absent', 'late', 'leave');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE announcement_category AS ENUM ('holiday', 'exam', 'event', 'urgent', 'general', 'class_notice');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE exam_type AS ENUM ('unit_test_1', 'half_yearly', 'unit_test_2', 'annual_finals', 'full_year');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE result_status AS ENUM ('present', 'absent', 'medical_leave');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- 2. Academic Years
CREATE TABLE IF NOT EXISTS academic_years (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE, -- e.g. '2026-2027'
  is_active BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. App Versions & OTA Updates Control Table
CREATE TABLE IF NOT EXISTS app_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform TEXT NOT NULL DEFAULT 'android', -- 'android', 'ios', 'web'
  min_version TEXT NOT NULL, -- Minimum required version e.g. '1.0.0'
  current_version TEXT NOT NULL DEFAULT '1.0.0',
  patch_version INT NOT NULL DEFAULT 1,
  patch_download_url TEXT, -- Direct APK download link or GitHub asset URL
  is_forced_update BOOLEAN DEFAULT false,
  release_notes TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. User Profiles (Teachers, Admins, Student Auth Accounts)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role user_role NOT NULL,
  full_name TEXT NOT NULL,
  login_code TEXT UNIQUE, -- e.g. 'T-RAMESH', 'ADMIN-OFFICE'
  phone TEXT,
  pin_hash TEXT NOT NULL, -- 4-digit PIN or password
  avatar_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Class Sections
CREATE TABLE IF NOT EXISTS class_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  grade INT NOT NULL CHECK (grade BETWEEN 1 AND 12),
  section TEXT NOT NULL, -- 'A', 'B', 'C', 'D'
  class_teacher_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  class_code TEXT NOT NULL UNIQUE, -- e.g. '8B-K9X2'
  is_code_locked BOOLEAN DEFAULT false,
  timetable_file_url TEXT,
  UNIQUE (academic_year_id, grade, section),
  UNIQUE (academic_year_id, class_teacher_id)
);
CREATE INDEX IF NOT EXISTS idx_class_sections_code ON class_sections(class_code);

-- 6. Subjects
CREATE TABLE IF NOT EXISTS subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE, -- 'MATH', 'SCI', 'ENG', 'HIN', 'SST', 'COMP'
  theme_color_hex TEXT DEFAULT '#4F46E5',
  is_practical BOOLEAN DEFAULT false
);

-- 7. Subject Allocations
CREATE TABLE IF NOT EXISTS subject_allocations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_section_id UUID NOT NULL REFERENCES class_sections(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  UNIQUE (class_section_id, subject_id)
);

-- 8. Students
CREATE TABLE IF NOT EXISTS students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  admission_no TEXT UNIQUE,
  roll_no INT NOT NULL,
  full_name TEXT NOT NULL,
  class_section_id UUID NOT NULL REFERENCES class_sections(id) ON DELETE RESTRICT,
  parent_name TEXT NOT NULL,
  parent_phone TEXT NOT NULL,
  date_of_birth DATE,
  house house_color DEFAULT 'blue',
  pin_hash TEXT NOT NULL, -- 4-digit secret PIN set during class join
  homework_streak INT DEFAULT 0,
  last_homework_completed_date DATE,
  joined_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (class_section_id, roll_no)
);
CREATE INDEX IF NOT EXISTS idx_students_parent_phone ON students(parent_phone);
CREATE INDEX IF NOT EXISTS idx_students_class ON students(class_section_id);

-- 9. Daily Attendance
CREATE TABLE IF NOT EXISTS attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_section_id UUID NOT NULL REFERENCES class_sections(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  status attendance_status NOT NULL DEFAULT 'present',
  marked_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (student_id, date)
);
CREATE INDEX IF NOT EXISTS idx_attendance_class_date ON attendance(class_section_id, date);

-- 10. Timetables
CREATE TABLE IF NOT EXISTS timetables (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_section_id UUID NOT NULL REFERENCES class_sections(id) ON DELETE CASCADE,
  day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 6), -- 1=Monday ... 6=Saturday
  period_no INT NOT NULL, -- 1 to 8
  start_time TEXT NOT NULL, -- e.g. '08:00 AM'
  end_time TEXT NOT NULL,   -- e.g. '08:45 AM'
  is_break BOOLEAN DEFAULT false,
  break_label TEXT,
  subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
  teacher_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  UNIQUE (class_section_id, day_of_week, period_no)
);

-- 11. Syllabi
CREATE TABLE IF NOT EXISTS syllabi (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_section_id UUID NOT NULL REFERENCES class_sections(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  exam_term exam_type NOT NULL DEFAULT 'full_year',
  title TEXT NOT NULL,
  chapters_overview TEXT, -- Markdown bullet points with chapter topics & weightage
  attachments JSONB DEFAULT '[]'::jsonb, -- [{url, type, name, size_kb}]
  updated_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (class_section_id, subject_id, exam_term)
);

-- 12. Homeworks
CREATE TABLE IF NOT EXISTS homeworks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_section_id UUID NOT NULL REFERENCES class_sections(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE NOT NULL,
  attachments JSONB DEFAULT '[]'::jsonb, -- [{url, type, name, size_kb}]
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 13. Student Homework Completions
CREATE TABLE IF NOT EXISTS homework_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  homework_id UUID NOT NULL REFERENCES homeworks(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  is_completed BOOLEAN DEFAULT true,
  completed_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (homework_id, student_id)
);

-- 14. Announcements
CREATE TABLE IF NOT EXISTS announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  category announcement_category NOT NULL DEFAULT 'general',
  is_pinned BOOLEAN DEFAULT false,
  event_or_holiday_date DATE,
  target_grade INT, -- NULL = school wide
  target_class_section_id UUID REFERENCES class_sections(id) ON DELETE CASCADE, -- NULL = all sections
  attachments JSONB DEFAULT '[]'::jsonb,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 15. Exams
CREATE TABLE IF NOT EXISTS exams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  name TEXT NOT NULL, -- 'Unit Test 1', 'Half Yearly Exam', 'Final Exam'
  exam_category exam_type NOT NULL,
  default_max_marks NUMERIC(5,2) NOT NULL DEFAULT 100.00,
  is_published BOOLEAN DEFAULT false,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 16. Exam Results
CREATE TABLE IF NOT EXISTS exam_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  class_section_id UUID NOT NULL REFERENCES class_sections(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  marks_obtained NUMERIC(5,2),
  max_marks NUMERIC(5,2) NOT NULL DEFAULT 100.00,
  status result_status DEFAULT 'present',
  grade TEXT, -- 'A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'D', 'E'
  subject_remarks TEXT,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (exam_id, student_id, subject_id),
  CHECK (marks_obtained IS NULL OR (marks_obtained >= 0 AND marks_obtained <= max_marks))
);

-- 17. Exam Student Summaries
CREATE TABLE IF NOT EXISTS exam_student_summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  class_teacher_remarks TEXT,
  rank_in_class INT,
  UNIQUE (exam_id, student_id)
);

-- Helper Function: CBSE Grading
CREATE OR REPLACE FUNCTION calculate_cbse_grade(p_marks NUMERIC, p_max_marks NUMERIC)
RETURNS TEXT AS $$
DECLARE
  v_percentage NUMERIC;
BEGIN
  IF p_marks IS NULL OR p_max_marks IS NULL OR p_max_marks = 0 THEN
    RETURN 'E';
  END IF;
  v_percentage := (p_marks / p_max_marks) * 100.0;
  IF v_percentage >= 91.0 THEN
    RETURN 'A1';
  ELSIF v_percentage >= 81.0 THEN
    RETURN 'A2';
  ELSIF v_percentage >= 71.0 THEN
    RETURN 'B1';
  ELSIF v_percentage >= 61.0 THEN
    RETURN 'B2';
  ELSIF v_percentage >= 51.0 THEN
    RETURN 'C1';
  ELSIF v_percentage >= 41.0 THEN
    RETURN 'C2';
  ELSIF v_percentage >= 33.0 THEN
    RETURN 'D';
  ELSE
    RETURN 'E';
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Trigger to automatically compute grade on exam_results insert/update
CREATE OR REPLACE FUNCTION trg_compute_exam_grade()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'present' AND NEW.marks_obtained IS NOT NULL THEN
    NEW.grade := calculate_cbse_grade(NEW.marks_obtained, NEW.max_marks);
  ELSE
    NEW.grade := '-';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_exam_grade ON exam_results;
CREATE TRIGGER trg_set_exam_grade
  BEFORE INSERT OR UPDATE ON exam_results
  FOR EACH ROW
  EXECUTE FUNCTION trg_compute_exam_grade();

-- -------------------------------------------------------------
-- SEED DATA (Indian School Demo Data: Class 8-B, Code 8B-K9X2)
-- -------------------------------------------------------------

-- Academic Year
INSERT INTO academic_years (id, name, is_active)
VALUES ('00000000-0000-0000-0000-000000000001', '2026-2027', true)
ON CONFLICT (name) DO NOTHING;

-- App Version & OTA Updates
INSERT INTO app_versions (id, platform, min_version, current_version, patch_version, patch_download_url, is_forced_update, release_notes)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  'android',
  '1.0.0',
  '1.0.1',
  1,
  'https://github.com/school-org/school-manager/releases/download/v1.0.1/school-manager-release.apk',
  false,
  '✨ Indian School Release v1.0.1: Added instant class code join, monthly attendance calendar, unified media viewer, and Excel exam import.'
)
ON CONFLICT (id) DO UPDATE SET
  current_version = EXCLUDED.current_version,
  patch_download_url = EXCLUDED.patch_download_url,
  release_notes = EXCLUDED.release_notes;

-- Profiles: Admin & Teachers
INSERT INTO profiles (id, role, full_name, login_code, phone, pin_hash) VALUES
('11111111-1111-1111-1111-111111111111', 'admin', 'Office Administration', 'admin', '+919876543200', '1234'),
('22222222-2222-2222-2222-222222222222', 'teacher', 'Mr. Ramesh Sharma', 'ramesh', '+919876543210', '1234'),
('33333333-3333-3333-3333-333333333333', 'teacher', 'Mrs. Sunita Rao', 'sunita', '+919876543220', '1234'),
('44444444-4444-4444-4444-444444444444', 'teacher', 'Mr. Vikram Singh', 'vikram', '+919876543230', '1234'),
('55555555-5555-5555-5555-555555555555', 'teacher', 'Mrs. Priya Joshi', 'priya', '+919876543240', '1234'),
('66666666-6666-6666-6666-666666666666', 'teacher', 'Mr. Amit Patel', 'amit', '+919876543250', '1234')
ON CONFLICT (id) DO NOTHING;

-- Class Section: 8-B
INSERT INTO class_sections (id, academic_year_id, grade, section, class_teacher_id, class_code, is_code_locked, timetable_file_url)
VALUES (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '00000000-0000-0000-0000-000000000001',
  8,
  'B',
  '22222222-2222-2222-2222-222222222222', -- Mr. Ramesh Sharma
  '8B-K9X2',
  false,
  'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=1200'
)
ON CONFLICT (class_code) DO NOTHING;

-- Subjects
INSERT INTO subjects (id, name, code, theme_color_hex, is_practical) VALUES
('b1111111-1111-1111-1111-111111111111', 'Mathematics', 'MATH', '#4F46E5', false),
('b2222222-2222-2222-2222-222222222222', 'Science', 'SCI', '#059669', true),
('b3333333-3333-3333-3333-333333333333', 'English', 'ENG', '#E11D48', false),
('b4444444-4444-4444-4444-444444444444', 'Hindi', 'HIN', '#D97706', false),
('b5555555-5555-5555-5555-555555555555', 'Social Science', 'SST', '#0284C7', false)
ON CONFLICT (code) DO NOTHING;

-- Subject Allocations for 8-B
INSERT INTO subject_allocations (class_section_id, subject_id, teacher_id) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'b1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222'), -- Ramesh -> MATH
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'b2222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333'), -- Sunita -> SCI
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'b3333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444'), -- Vikram -> ENG
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'b4444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555'), -- Priya -> HIN
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'b5555555-5555-5555-5555-555555555555', '66666666-6666-6666-6666-666666666666')  -- Amit -> SST
ON CONFLICT (class_section_id, subject_id) DO NOTHING;

-- Students in 8-B
INSERT INTO students (id, roll_no, full_name, admission_no, class_section_id, parent_name, parent_phone, house, pin_hash, homework_streak) VALUES
('c1111111-1111-1111-1111-111111111111', 1, 'Aarav Sharma', 'ADM2026101', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Rajesh Sharma', '+919876540001', 'red', '1234', 5),
('c2222222-2222-2222-2222-222222222222', 2, 'Kabir Verma', 'ADM2026102', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Sanjay Verma', '+919876540002', 'blue', '2345', 3),
('c3333333-3333-3333-3333-333333333333', 3, 'Ananya Gupta', 'ADM2026103', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Meera Gupta', '+919876540003', 'green', '3456', 7),
('c4444444-4444-4444-4444-444444444444', 4, 'Rohan Mehta', 'ADM2026104', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Nitin Mehta', '+919876540004', 'yellow', '4567', 4)
ON CONFLICT (id) DO NOTHING;

-- Timetable for 8-B (Monday)
INSERT INTO timetables (class_section_id, day_of_week, period_no, start_time, end_time, is_break, break_label, subject_id, teacher_id) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 1, '08:00 AM', '08:45 AM', false, null, 'b1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 2, '08:45 AM', '09:30 AM', false, null, 'b2222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 3, '09:30 AM', '10:15 AM', false, null, 'b3333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 4, '10:15 AM', '11:00 AM', false, null, 'b4444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 5, '11:00 AM', '11:30 AM', true, 'Lunch & Recess Break', null, null),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 6, '11:30 AM', '12:15 PM', false, null, 'b5555555-5555-5555-5555-555555555555', '66666666-6666-6666-6666-666666666666'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 7, '12:15 PM', '01:00 PM', false, null, 'b1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 8, '01:00 PM', '01:45 PM', false, null, 'b2222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333')
ON CONFLICT (class_section_id, day_of_week, period_no) DO NOTHING;

-- Announcements
INSERT INTO announcements (title, body, category, is_pinned, event_or_holiday_date, target_grade) VALUES
('🏖️ Holiday Announcement: Guru Nanak Jayanti', 'The school will remain closed tomorrow on account of Guru Nanak Jayanti. Classes will resume as per regular timetable on Wednesday.', 'holiday', true, CURRENT_DATE + INTERVAL '1 day', null),
('📝 Half-Yearly Examination Schedule Released', 'The date sheet and syllabus for Half-Yearly examinations 2026-27 have been uploaded. Please review the syllabus vault.', 'exam', false, CURRENT_DATE + INTERVAL '10 day', 8),
('🚨 Annual Sports Day Selection Trials', 'Selection trials for Inter-House Football and Athletics will be held this Friday during zero period. Sports uniform mandatory.', 'event', false, CURRENT_DATE + INTERVAL '3 day', null)
ON CONFLICT DO NOTHING;
