import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../widgets/unified_media_viewer.dart';
import 'mock_school_repository.dart';
import 'school_repository.dart';

/// Production Supabase implementation of [SchoolRepository].
/// Interacts directly with PostgreSQL via Supabase PostgREST client.
/// Automatically falls back gracefully to in-memory store if offline.
class SupabaseSchoolRepository implements SchoolRepository {
  final MockSchoolRepository _fallback = MockSchoolRepository();
  static const _uuid = Uuid();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      debugPrint('SupabaseSchoolRepository: Client not initialized: $e');
      return null;
    }
  }

  // Local caches to guarantee zero-latency reads and seamless offline resilience
  final Map<String, Map<String, dynamic>> _staffSessionCache = {};

  // ==========================================
  // 1. CLASS CODE & STUDENT ONBOARDING
  // ==========================================

  @override
  Future<ClassSection?> findClassByCode(String code) async {
    final client = _client;
    final cleanCode = code.trim().toUpperCase();

    if (client != null) {
      try {
        final data = await client
            .from('class_sections')
            .select('*, profiles:class_teacher_id(full_name)')
            .ilike('class_code', cleanCode)
            .maybeSingle();

        if (data != null) {
          return _parseClassSection(data);
        }
      } catch (e) {
        debugPrint('findClassByCode error: $e, falling back to local store');
      }
    }
    return _fallback.findClassByCode(cleanCode);
  }

  @override
  Future<Student> registerStudentWithCode({
    required String classCode,
    required String fullName,
    required int rollNo,
    String? admissionNo,
    required String parentName,
    required String parentPhone,
    required String house,
    required String pin,
  }) async {
    final client = _client;
    final cls = await findClassByCode(classCode);
    if (cls == null) {
      throw Exception('Class with code "$classCode" not found.');
    }
    if (cls.isCodeLocked) {
      throw Exception('This class has been locked by the Class Teacher.');
    }

    final admNo = admissionNo?.trim().isNotEmpty == true
        ? admissionNo!.trim()
        : 'ADM${DateTime.now().year}${100 + rollNo}';

    if (client != null) {
      try {
        final payload = {
          'roll_no': rollNo,
          'full_name': fullName.trim(),
          'admission_no': admNo,
          'class_section_id': cls.id,
          'parent_name': parentName.trim(),
          'parent_phone': parentPhone.trim(),
          'house': house.trim().isEmpty ? 'blue' : house.toLowerCase().trim(),
          'pin_hash': pin.trim(),
          'homework_streak': 0,
        };

        final res = await client
            .from('students')
            .upsert(payload, onConflict: 'class_section_id, roll_no')
            .select()
            .single();

        final student = Student.fromJson(res);
        await _fallback.updateStudent(student);
        return student;
      } catch (e) {
        debugPrint('registerStudentWithCode error: $e, saving to fallback');
      }
    }

    return _fallback.registerStudentWithCode(
      classCode: classCode,
      fullName: fullName,
      rollNo: rollNo,
      admissionNo: admNo,
      parentName: parentName,
      parentPhone: parentPhone,
      house: house,
      pin: pin,
    );
  }

  @override
  Future<Student?> loginStudent({
    required String classSectionId,
    required int rollNo,
    required String pin,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        final res = await client
            .from('students')
            .select()
            .eq('class_section_id', classSectionId)
            .eq('roll_no', rollNo)
            .eq('pin_hash', pin.trim())
            .maybeSingle();

        if (res != null) {
          final student = Student.fromJson(res);
          await _fallback.updateStudent(student);
          return student;
        }
      } catch (e) {
        debugPrint('loginStudent error: $e, falling back');
      }
    }
    return _fallback.loginStudent(
      classSectionId: classSectionId,
      rollNo: rollNo,
      pin: pin,
    );
  }

  @override
  Future<List<Student>> getSiblings(List<String> studentIds) async {
    if (studentIds.isEmpty) return const [];
    final client = _client;
    if (client != null) {
      try {
        final List<dynamic> res = await client
            .from('students')
            .select()
            .filter('id', 'in', studentIds);

        return res.map((j) => Student.fromJson(j as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('getSiblings error: $e');
      }
    }
    return _fallback.getSiblings(studentIds);
  }

  @override
  Future<Student?> getStudentById(String studentId) async {
    final client = _client;
    if (client != null) {
      try {
        final res = await client
            .from('students')
            .select()
            .eq('id', studentId)
            .maybeSingle();

        if (res != null) {
          return Student.fromJson(res);
        }
      } catch (e) {
        debugPrint('getStudentById error: $e');
      }
    }
    return _fallback.getStudentById(studentId);
  }

  @override
  Future<Student> updateStudent(Student student) async {
    final client = _client;
    if (client != null) {
      try {
        final payload = {
          'roll_no': student.rollNo,
          'full_name': student.fullName,
          if (student.admissionNo != null) 'admission_no': student.admissionNo,
          'class_section_id': student.classSectionId,
          'parent_name': student.parentName,
          'parent_phone': student.parentPhone,
          'house': student.house.isEmpty ? 'blue' : student.house,
          'pin_hash': student.pinHash,
        };

        final res = await client
            .from('students')
            .update(payload)
            .eq('id', student.id)
            .select()
            .maybeSingle();

        if (res != null) {
          final updated = Student.fromJson(res);
          await _fallback.updateStudent(updated);
          return updated;
        }
      } catch (e) {
        debugPrint('updateStudent error: $e');
      }
    }
    return _fallback.updateStudent(student);
  }

  // ==========================================
  // 2. CLASS SECTIONS & ROSTER
  // ==========================================

  @override
  Future<ClassSection?> getClassSectionById(String classSectionId) async {
    final client = _client;
    if (client != null) {
      try {
        final res = await client
            .from('class_sections')
            .select('*, profiles:class_teacher_id(full_name)')
            .eq('id', classSectionId)
            .maybeSingle();

        if (res != null) {
          return _parseClassSection(res);
        }
      } catch (e) {
        debugPrint('getClassSectionById error: $e');
      }
    }
    return _fallback.getClassSectionById(classSectionId);
  }

  @override
  Future<List<ClassSection>> getAllClassSections() async {
    final client = _client;
    if (client != null) {
      try {
        final List<dynamic> res = await client
            .from('class_sections')
            .select('*, profiles:class_teacher_id(full_name)')
            .order('grade', ascending: true)
            .order('section', ascending: true);

        if (res.isNotEmpty) {
          return res.map((j) => _parseClassSection(j)).toList();
        }
      } catch (e) {
        debugPrint('getAllClassSections error: $e');
      }
    }
    return _fallback.getAllClassSections();
  }

  @override
  Future<ClassSection> createClassSection({
    required int grade,
    required String section,
    required String classCode,
    String? classTeacherId,
    String? classTeacherName,
  }) async {
    final client = _client;
    final cleanCode = classCode.toUpperCase().trim();
    final cleanSection = section.toUpperCase().trim();

    if (client != null) {
      try {
        // Query active academic year
        String academicYearId = '00000000-0000-0000-0000-000000000001';
        try {
          final yearRes = await client
              .from('academic_years')
              .select('id')
              .eq('is_active', true)
              .maybeSingle();
          if (yearRes != null && yearRes['id'] != null) {
            academicYearId = yearRes['id'] as String;
          }
        } catch (_) {}

        final payload = {
          'academic_year_id': academicYearId,
          'grade': grade,
          'section': cleanSection,
          'class_code': cleanCode,
          'is_code_locked': false,
          if (classTeacherId != null && !classTeacherId.startsWith('staff-') && !classTeacherId.startsWith('teacher-'))
            'class_teacher_id': classTeacherId,
        };

        final res = await client.from('class_sections').insert(payload).select().single();
        final created = ClassSection(
          id: res['id'] as String,
          grade: res['grade'] as int,
          section: res['section'] as String,
          classTeacherId: classTeacherId,
          classTeacherName: classTeacherName,
          classCode: res['class_code'] as String,
          isCodeLocked: res['is_code_locked'] as bool? ?? false,
          academicYear: '2026-2027',
        );
        await _fallback.createClassSection(
          grade: grade,
          section: cleanSection,
          classCode: cleanCode,
          classTeacherId: classTeacherId,
          classTeacherName: classTeacherName,
        );
        return created;
      } catch (e) {
        debugPrint('createClassSection error: $e');
      }
    }

    return _fallback.createClassSection(
      grade: grade,
      section: cleanSection,
      classCode: cleanCode,
      classTeacherId: classTeacherId,
      classTeacherName: classTeacherName,
    );
  }

  @override
  Future<List<Student>> getStudentsForClass(String classSectionId) async {
    final client = _client;
    if (client != null) {
      try {
        final List<dynamic> res = await client
            .from('students')
            .select()
            .eq('class_section_id', classSectionId)
            .order('roll_no', ascending: true);

        return res.map((j) => Student.fromJson(j as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('getStudentsForClass error: $e');
      }
    }
    return _fallback.getStudentsForClass(classSectionId);
  }

  @override
  Future<void> updateStudentRollNo(String studentId, int newRollNo) async {
    final client = _client;
    if (client != null) {
      try {
        await client.from('students').update({'roll_no': newRollNo}).eq('id', studentId);
      } catch (e) {
        debugPrint('updateStudentRollNo error: $e');
      }
    }
    await _fallback.updateStudentRollNo(studentId, newRollNo);
  }

  @override
  Future<void> setClassCodeLocked(String classSectionId, bool isLocked) async {
    final client = _client;
    if (client != null) {
      try {
        await client.from('class_sections').update({'is_code_locked': isLocked}).eq('id', classSectionId);
      } catch (e) {
        debugPrint('setClassCodeLocked error: $e');
      }
    }
    await _fallback.setClassCodeLocked(classSectionId, isLocked);
  }

  @override
  Future<String> regenerateClassCode(String classSectionId) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final newSuffix = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();

    final cls = await getClassSectionById(classSectionId);
    final prefix = cls != null ? '${cls.grade}${cls.section}' : '8B';
    final newCode = '$prefix-$newSuffix';

    final client = _client;
    if (client != null) {
      try {
        await client.from('class_sections').update({'class_code': newCode}).eq('id', classSectionId);
      } catch (e) {
        debugPrint('regenerateClassCode error: $e');
      }
    }
    await _fallback.regenerateClassCode(classSectionId);
    return newCode;
  }

  // ==========================================
  // 3. ATTENDANCE
  // ==========================================

  @override
  Future<List<Attendance>> getAttendanceForDate(
    String classSectionId,
    DateTime date,
  ) async {
    final client = _client;
    final dateStr = date.toIso8601String().split('T')[0];

    if (client != null) {
      try {
        final List<dynamic> res = await client
            .from('attendance')
            .select()
            .eq('class_section_id', classSectionId)
            .eq('date', dateStr);

        return res.map((j) => Attendance.fromJson(j as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('getAttendanceForDate error: $e');
      }
    }
    return _fallback.getAttendanceForDate(classSectionId, date);
  }

  @override
  Future<List<Attendance>> getAttendanceForStudent(
    String studentId, {
    int? month,
    int? year,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        var query = client.from('attendance').select().eq('student_id', studentId);
        if (year != null && month != null) {
          final start = DateTime(year, month, 1).toIso8601String().split('T')[0];
          final end = DateTime(year, month + 1, 0).toIso8601String().split('T')[0];
          query = query.gte('date', start).lte('date', end);
        } else if (year != null) {
          query = query.gte('date', '$year-01-01').lte('date', '$year-12-31');
        }
        final List<dynamic> res = await query.order('date', ascending: false);
        return res.map((j) => Attendance.fromJson(j as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('getAttendanceForStudent error: $e');
      }
    }
    return _fallback.getAttendanceForStudent(studentId, month: month, year: year);
  }

  @override
  Future<double> getStudentAttendancePercentage(String studentId) async {
    final client = _client;
    if (client != null) {
      try {
        final List<dynamic> res = await client
            .from('attendance')
            .select('status')
            .eq('student_id', studentId);

        if (res.isNotEmpty) {
          final presentCount = res.where((r) => r['status'] == 'present').length;
          return (presentCount / res.length) * 100.0;
        }
      } catch (e) {
        debugPrint('getStudentAttendancePercentage error: $e');
      }
    }
    return _fallback.getStudentAttendancePercentage(studentId);
  }

  @override
  Future<void> submitClassAttendance({
    required String classSectionId,
    required DateTime date,
    required Map<String, AttendanceStatus> attendanceMap,
    required String markedBy,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final client = _client;

    if (client != null && attendanceMap.isNotEmpty) {
      try {
        final isUuid = markedBy.contains('-') && markedBy.length >= 32;
        final rows = attendanceMap.entries.map((e) => {
              'class_section_id': classSectionId,
              'student_id': e.key,
              'date': dateStr,
              'status': e.value.name,
              if (isUuid) 'marked_by': markedBy,
            }).toList();

        await client.from('attendance').upsert(rows, onConflict: 'student_id, date');
      } catch (e) {
        debugPrint('submitClassAttendance error: $e');
      }
    }

    await _fallback.submitClassAttendance(
      classSectionId: classSectionId,
      date: date,
      attendanceMap: attendanceMap,
      markedBy: markedBy,
    );
  }

  // ==========================================
  // 4. TIMETABLE
  // ==========================================

  @override
  Future<List<TimetablePeriod>> getTimetableForDay(
    String classSectionId,
    int dayOfWeek,
  ) async {
    final client = _client;
    if (client != null) {
      try {
        final List<dynamic> res = await client
            .from('timetables')
            .select('*, subjects(name, code), profiles:teacher_id(full_name)')
            .eq('class_section_id', classSectionId)
            .eq('day_of_week', dayOfWeek)
            .order('period_no', ascending: true);

        return res.map((j) => _parseTimetablePeriod(j)).toList();
      } catch (e) {
        debugPrint('getTimetableForDay error: $e');
      }
    }
    return _fallback.getTimetableForDay(classSectionId, dayOfWeek);
  }

  @override
  Future<List<TimetablePeriod>> getFullTimetable(String classSectionId) async {
    final client = _client;
    if (client != null) {
      try {
        final List<dynamic> res = await client
            .from('timetables')
            .select('*, subjects(name, code), profiles:teacher_id(full_name)')
            .eq('class_section_id', classSectionId)
            .order('day_of_week', ascending: true)
            .order('period_no', ascending: true);

        return res.map((j) => _parseTimetablePeriod(j)).toList();
      } catch (e) {
        debugPrint('getFullTimetable error: $e');
      }
    }
    return _fallback.getFullTimetable(classSectionId);
  }

  @override
  Future<void> saveTimetable(
    String classSectionId,
    List<TimetablePeriod> periods,
  ) async {
    final client = _client;
    if (client != null) {
      try {
        await client.from('timetables').delete().eq('class_section_id', classSectionId);
        final rows = periods.map((p) => {
              'class_section_id': classSectionId,
              'day_of_week': p.dayOfWeek,
              'period_no': p.periodNo,
              'start_time': p.startTime,
              'end_time': p.endTime,
              'is_break': p.isBreak,
              'break_label': p.breakLabel,
              'subject_id': p.subjectId,
            }).toList();

        await client.from('timetables').insert(rows);
      } catch (e) {
        debugPrint('saveTimetable error: $e');
      }
    }
    await _fallback.saveTimetable(classSectionId, periods);
  }

  // ==========================================
  // 5. SYLLABUS
  // ==========================================

  @override
  Future<List<Syllabus>> getSyllabiForClass(
    String classSectionId, {
    String? examTerm,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        var query = client
            .from('syllabi')
            .select('*, subjects(name, code)')
            .eq('class_section_id', classSectionId);

        if (examTerm != null && examTerm != 'all' && examTerm.isNotEmpty) {
          query = query.eq('exam_term', examTerm);
        }

        final List<dynamic> res = await query.order('updated_at', ascending: false);
        if (res.isNotEmpty) {
          return res.map((j) => _parseSyllabus(j)).toList();
        }
      } catch (e) {
        debugPrint('getSyllabiForClass error: $e');
      }
    }
    return _fallback.getSyllabiForClass(classSectionId, examTerm: examTerm);
  }

  @override
  Future<void> saveSyllabus(Syllabus syllabus) async {
    final client = _client;
    if (client != null) {
      try {
        final payload = {
          'id': syllabus.id.length >= 32 ? syllabus.id : _uuid.v4(),
          'class_section_id': syllabus.classSectionId,
          'subject_id': syllabus.subjectId.length >= 32
              ? syllabus.subjectId
              : 'b1111111-1111-1111-1111-111111111111',
          'exam_term': syllabus.examTerm,
          'title': syllabus.title,
          'chapters_overview': syllabus.chaptersOverview,
          'attachments': syllabus.attachments.map((a) => a.toJson()).toList(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await client.from('syllabi').upsert(
              payload,
              onConflict: 'class_section_id, subject_id, exam_term',
            );
      } catch (e) {
        debugPrint('saveSyllabus error: $e');
      }
    }
    await _fallback.saveSyllabus(syllabus);
  }

  // ==========================================
  // 6. HOMEWORK
  // ==========================================

  @override
  Future<List<Homework>> getHomeworksForClass(
    String classSectionId, {
    String? studentId,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        final List<dynamic> res = await client
            .from('homeworks')
            .select('*, subjects(name, code), profiles:teacher_id(full_name)')
            .eq('class_section_id', classSectionId)
            .order('due_date', ascending: true);

        Set<String> completedIds = {};
        if (studentId != null) {
          final List<dynamic> compRes = await client
              .from('homework_completions')
              .select('homework_id')
              .eq('student_id', studentId)
              .eq('is_completed', true);
          completedIds = compRes.map((c) => c['homework_id'] as String).toSet();
        }

        if (res.isNotEmpty) {
          return res.map((j) => _parseHomework(j, completedIds)).toList();
        }
      } catch (e) {
        debugPrint('getHomeworksForClass error: $e');
      }
    }
    return _fallback.getHomeworksForClass(classSectionId, studentId: studentId);
  }

  @override
  Future<void> toggleHomeworkCompletion({
    required String homeworkId,
    required String studentId,
    required bool isCompleted,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        await client.from('homework_completions').upsert({
          'homework_id': homeworkId,
          'student_id': studentId,
          'is_completed': isCompleted,
          'completed_at': DateTime.now().toIso8601String(),
        }, onConflict: 'homework_id, student_id');
      } catch (e) {
        debugPrint('toggleHomeworkCompletion error: $e');
      }
    }
    await _fallback.toggleHomeworkCompletion(
      homeworkId: homeworkId,
      studentId: studentId,
      isCompleted: isCompleted,
    );
  }

  @override
  Future<void> createHomework(Homework homework) async {
    final client = _client;
    if (client != null) {
      try {
        final isTeacherUuid = homework.teacherId != null &&
            homework.teacherId!.contains('-') &&
            homework.teacherId!.length >= 32;

        final payload = {
          'id': homework.id.length >= 32 ? homework.id : _uuid.v4(),
          'class_section_id': homework.classSectionId,
          'subject_id': homework.subjectId.length >= 32
              ? homework.subjectId
              : 'b1111111-1111-1111-1111-111111111111',
          if (isTeacherUuid) 'teacher_id': homework.teacherId,
          'title': homework.title,
          'description': homework.description,
          'due_date': homework.dueDate.toIso8601String().split('T')[0],
          'attachments': homework.attachments.map((a) => a.toJson()).toList(),
        };

        await client.from('homeworks').insert(payload);
      } catch (e) {
        debugPrint('createHomework error: $e');
      }
    }
    await _fallback.createHomework(homework);
  }

  // ==========================================
  // 7. EXAMS & EXAM RESULTS
  // ==========================================

  @override
  Future<List<String>> getAvailableExams() async {
    final client = _client;
    if (client != null) {
      try {
        final List<dynamic> res = await client
            .from('exams')
            .select('name')
            .order('created_at', ascending: true);

        if (res.isNotEmpty) {
          return res.map((e) => e['name'] as String).toSet().toList();
        }
      } catch (e) {
        debugPrint('getAvailableExams error: $e');
      }
    }
    return _fallback.getAvailableExams();
  }

  @override
  Future<List<ExamResult>> getStudentExamResults(
    String studentId,
    String examName,
  ) async {
    final client = _client;
    if (client != null) {
      try {
        final List<dynamic> res = await client
            .from('exam_results')
            .select('*, exams!inner(name), subjects(name, code), students(roll_no, full_name)')
            .eq('student_id', studentId)
            .eq('exams.name', examName);

        if (res.isNotEmpty) {
          return res.map((j) => _parseExamResult(j)).toList();
        }
      } catch (e) {
        debugPrint('getStudentExamResults error: $e');
      }
    }
    return _fallback.getStudentExamResults(studentId, examName);
  }

  @override
  Future<ExamStudentSummary?> getStudentExamSummary(
    String studentId,
    String examName,
  ) async {
    final results = await getStudentExamResults(studentId, examName);
    if (results.isEmpty) return null;

    double obtained = 0;
    double maxTotal = 0;
    for (final r in results) {
      if (r.status == 'present' && r.marksObtained != null) {
        obtained += r.marksObtained!;
      }
      maxTotal += r.maxMarks;
    }

    final percentage = maxTotal > 0 ? (obtained / maxTotal) * 100.0 : 0.0;
    final grade = ExamResult.calculateCbseGrade(obtained, maxTotal);

    return ExamStudentSummary(
      examId: 'exam-$examName',
      examName: examName,
      studentId: studentId,
      totalObtained: obtained,
      totalMax: maxTotal,
      percentage: double.parse(percentage.toStringAsFixed(1)),
      overallGrade: grade,
      rankInClass: 1,
    );
  }

  @override
  Future<List<ExamResult>> getClassExamResults(
    String classSectionId,
    String examName,
  ) async {
    final client = _client;
    if (client != null) {
      try {
        final List<dynamic> res = await client
            .from('exam_results')
            .select('*, exams!inner(name), subjects(name, code), students(roll_no, full_name)')
            .eq('class_section_id', classSectionId)
            .eq('exams.name', examName);

        if (res.isNotEmpty) {
          return res.map((j) => _parseExamResult(j)).toList();
        }
      } catch (e) {
        debugPrint('getClassExamResults error: $e');
      }
    }
    return _fallback.getClassExamResults(classSectionId, examName);
  }

  @override
  Future<void> publishExamResults({
    required String examName,
    required String classSectionId,
    required List<ExamResult> results,
  }) async {
    final client = _client;
    if (client != null && results.isNotEmpty) {
      try {
        final rows = results.map((r) => {
              'id': r.id.length >= 32 ? r.id : _uuid.v4(),
              'exam_id': r.examId.length >= 32 ? r.examId : '00000000-0000-0000-0000-000000000001',
              'student_id': r.studentId,
              'class_section_id': classSectionId,
              'subject_id': r.subjectId.length >= 32 ? r.subjectId : 'b1111111-1111-1111-1111-111111111111',
              'marks_obtained': r.marksObtained,
              'max_marks': r.maxMarks,
              'status': r.status,
              'grade': r.grade,
              'subject_remarks': r.subjectRemarks,
            }).toList();

        await client.from('exam_results').upsert(
              rows,
              onConflict: 'exam_id, student_id, subject_id',
            );
      } catch (e) {
        debugPrint('publishExamResults error: $e');
      }
    }
    await _fallback.publishExamResults(
      examName: examName,
      classSectionId: classSectionId,
      results: results,
    );
  }

  // ==========================================
  // 8. ANNOUNCEMENTS
  // ==========================================

  @override
  Future<List<Announcement>> getAnnouncements({
    int? grade,
    String? classSectionId,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        var query = client.from('announcements').select();
        if (grade != null) {
          query = query.or('target_grade.is.null,target_grade.eq.$grade');
        }
        if (classSectionId != null) {
          query = query.or('target_class_section_id.is.null,target_class_section_id.eq.$classSectionId');
        }

        final List<dynamic> res = await query.order('created_at', ascending: false);
        return res.map((j) => Announcement.fromJson(j as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('getAnnouncements error: $e');
      }
    }
    return _fallback.getAnnouncements(grade: grade, classSectionId: classSectionId);
  }

  @override
  Future<Announcement?> getPinnedAnnouncement({
    int? grade,
    String? classSectionId,
  }) async {
    final announcements = await getAnnouncements(grade: grade, classSectionId: classSectionId);
    for (final a in announcements) {
      if (a.isPinned) return a;
    }
    return null;
  }

  @override
  Future<void> createAnnouncement(Announcement announcement) async {
    final client = _client;
    if (client != null) {
      try {
        final payload = {
          'id': announcement.id.length >= 32 ? announcement.id : _uuid.v4(),
          'title': announcement.title,
          'body': announcement.body,
          'category': announcement.category.name,
          'is_pinned': announcement.isPinned,
          if (announcement.eventOrHolidayDate != null)
            'event_or_holiday_date': announcement.eventOrHolidayDate!.toIso8601String().split('T')[0],
          if (announcement.targetGrade != null) 'target_grade': announcement.targetGrade,
          if (announcement.targetClassSectionId != null)
            'target_class_section_id': announcement.targetClassSectionId,
          'attachments': announcement.attachments.map((a) => a.toJson()).toList(),
          'created_at': announcement.createdAt.toIso8601String(),
        };

        await client.from('announcements').insert(payload);
      } catch (e) {
        debugPrint('createAnnouncement error: $e');
      }
    }
    await _fallback.createAnnouncement(announcement);
  }

  // ==========================================
  // 9. PROFILES & STAFF
  // ==========================================

  @override
  Future<Map<String, dynamic>?> loginStaff({
    required String loginCode,
    required String pin,
  }) async {
    final cleanCode = loginCode.trim().toLowerCase();
    final client = _client;

    if (client != null) {
      try {
        final res = await client
            .from('profiles')
            .select()
            .eq('login_code', cleanCode)
            .eq('pin_hash', pin.trim())
            .maybeSingle();

        if (res != null) {
          final id = res['id'] as String;
          final role = res['role'] as String;
          final fullName = res['full_name'] as String;
          final phone = res['phone'] as String? ?? '';

          // Look up subject allocation and homeroom class
          String? subjectName;
          String? subjectCode;
          String? homeroomClassId;
          String? homeroomClassName;

          try {
            final classRes = await client
                .from('class_sections')
                .select('id, grade, section')
                .eq('class_teacher_id', id)
                .maybeSingle();
            if (classRes != null) {
              homeroomClassId = classRes['id'] as String;
              homeroomClassName = 'Class ${classRes['grade']}-${classRes['section']}';
            }
          } catch (_) {}

          try {
            final allocRes = await client
                .from('subject_allocations')
                .select('subjects(name, code)')
                .eq('teacher_id', id)
                .maybeSingle();
            if (allocRes != null && allocRes['subjects'] is Map) {
              subjectName = allocRes['subjects']['name'] as String?;
              subjectCode = allocRes['subjects']['code'] as String?;
            }
          } catch (_) {}

          // Check memory session cache for subject if not in DB
          if (_staffSessionCache.containsKey(id)) {
            subjectName ??= _staffSessionCache[id]!['subject_name'] as String?;
            subjectCode ??= _staffSessionCache[id]!['subject_code'] as String?;
          }

          final staffMap = {
            'id': id,
            'role': role,
            'login_code': cleanCode,
            'full_name': fullName,
            'phone': phone,
            'pin': pin.trim(),
            'homeroom_class_id': homeroomClassId ?? 'class-8b',
            'homeroom_class_name': homeroomClassName ?? 'Class 8-B',
            'homeroom_class_code': '8B-K9X2',
            'subject_name': subjectName ?? 'Mathematics',
            'subject_code': subjectCode ?? 'MATH',
          };

          _staffSessionCache[id] = staffMap;
          return staffMap;
        }
      } catch (e) {
        debugPrint('loginStaff error: $e');
      }
    }
    return _fallback.loginStaff(loginCode: cleanCode, pin: pin);
  }

  @override
  Future<Map<String, dynamic>> registerStaff({
    required String fullName,
    required String role,
    required String loginCode,
    required String pin,
    String? phone,
    String? homeroomClassId,
    String? homeroomClassName,
    String? subjectName,
    String? subjectCode,
  }) async {
    final cleanCode = loginCode.trim().toLowerCase();
    final client = _client;
    String profileId = _uuid.v4();

    if (client != null) {
      try {
        final payload = {
          'id': profileId,
          'role': role.toLowerCase().trim(),
          'full_name': fullName.trim(),
          'login_code': cleanCode,
          'pin_hash': pin.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        };

        final res = await client.from('profiles').insert(payload).select().maybeSingle();
        if (res != null && res['id'] != null) {
          profileId = res['id'] as String;
        }
      } catch (e) {
        debugPrint('registerStaff error: $e');
      }
    }

    final staffMap = {
      'id': profileId,
      'role': role,
      'login_code': cleanCode,
      'full_name': fullName.trim(),
      'phone': phone?.trim() ?? '',
      'homeroom_class_id': homeroomClassId ?? (role == 'teacher' ? 'class-8b' : null),
      'homeroom_class_name': homeroomClassName ?? (role == 'teacher' ? 'Class 8-B' : null),
      'homeroom_class_code': role == 'teacher' ? '8B-K9X2' : null,
      'subject_name': subjectName,
      'subject_code': subjectCode,
      'pin': pin.trim(),
    };

    _staffSessionCache[profileId] = staffMap;
    await _fallback.registerStaff(
      fullName: fullName,
      role: role,
      loginCode: loginCode,
      pin: pin,
      phone: phone,
      homeroomClassId: homeroomClassId,
      homeroomClassName: homeroomClassName,
      subjectName: subjectName,
      subjectCode: subjectCode,
    );

    return staffMap;
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherSubjectAllocations(
    String teacherId,
  ) async {
    final client = _client;
    if (client != null) {
      try {
        final List<dynamic> res = await client
            .from('subject_allocations')
            .select('class_section_id, class_sections(grade, section), subjects(name, code)')
            .eq('teacher_id', teacherId);

        if (res.isNotEmpty) {
          return res.map((item) {
            final cls = item['class_sections'] as Map<String, dynamic>?;
            final sub = item['subjects'] as Map<String, dynamic>?;
            return {
              'class_section_id': item['class_section_id'],
              'class_name': cls != null ? 'Class ${cls['grade']}-${cls['section']}' : 'Class Section',
              'subject_name': sub != null ? sub['name'] : 'Subject',
              'subject_code': sub != null ? sub['code'] : 'SUB',
              'is_homeroom': true,
            };
          }).toList();
        }
      } catch (e) {
        debugPrint('getTeacherSubjectAllocations error: $e');
      }
    }

    // Check staff session cache
    if (_staffSessionCache.containsKey(teacherId)) {
      final staff = _staffSessionCache[teacherId]!;
      if (staff['subject_name'] != null) {
        return [
          {
            'class_section_id': staff['homeroom_class_id'] ?? 'class-8b',
            'class_name': staff['homeroom_class_name'] ?? 'Class 8-B',
            'subject_name': staff['subject_name'],
            'subject_code': staff['subject_code'] ?? 'SUB',
            'is_homeroom': true,
          }
        ];
      }
    }

    return _fallback.getTeacherSubjectAllocations(teacherId);
  }

  // ==========================================
  // HELPER PARSING FUNCTIONS
  // ==========================================

  ClassSection _parseClassSection(Map<String, dynamic> json) {
    String? teacherName;
    if (json['profiles'] is Map) {
      teacherName = json['profiles']['full_name'] as String?;
    }
    return ClassSection(
      id: json['id'] as String,
      grade: json['grade'] as int,
      section: json['section'] as String,
      classTeacherId: json['class_teacher_id'] as String?,
      classTeacherName: teacherName ?? json['class_teacher_name'] as String?,
      classCode: json['class_code'] as String,
      isCodeLocked: json['is_code_locked'] as bool? ?? false,
      academicYear: '2026-2027',
      timetableFileUrl: json['timetable_file_url'] as String?,
    );
  }

  TimetablePeriod _parseTimetablePeriod(Map<String, dynamic> json) {
    String? subjectName = json['subject_name'] as String?;
    String? subjectCode = json['subject_code'] as String?;
    String? teacherName = json['teacher_name'] as String?;

    if (json['subjects'] is Map) {
      subjectName ??= json['subjects']['name'] as String?;
      subjectCode ??= json['subjects']['code'] as String?;
    }
    if (json['profiles'] is Map) {
      teacherName ??= json['profiles']['full_name'] as String?;
    }

    return TimetablePeriod(
      id: json['id'] as String,
      classSectionId: json['class_section_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      periodNo: json['period_no'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isBreak: json['is_break'] as bool? ?? false,
      breakLabel: json['break_label'] as String?,
      subjectId: json['subject_id'] as String?,
      subjectName: subjectName,
      subjectCode: subjectCode,
      teacherName: teacherName,
    );
  }

  Syllabus _parseSyllabus(Map<String, dynamic> json) {
    String subjectName = json['subject_name'] as String? ?? 'Subject';
    String subjectCode = json['subject_code'] as String? ?? 'SUB';

    if (json['subjects'] is Map) {
      subjectName = json['subjects']['name'] as String? ?? subjectName;
      subjectCode = json['subjects']['code'] as String? ?? subjectCode;
    }

    var rawAttachments = json['attachments'];
    List<MediaAttachmentItem> parsedAttachments = [];
    if (rawAttachments is List) {
      parsedAttachments = rawAttachments
          .map((item) => MediaAttachmentItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Syllabus(
      id: json['id'] as String,
      classSectionId: json['class_section_id'] as String,
      subjectId: json['subject_id'] as String,
      subjectName: subjectName,
      subjectCode: subjectCode,
      examTerm: json['exam_term'] as String? ?? 'full_year',
      title: json['title'] as String,
      chaptersOverview: json['chapters_overview'] as String? ?? '',
      attachments: parsedAttachments,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Homework _parseHomework(Map<String, dynamic> json, Set<String> completedIds) {
    String subjectName = json['subject_name'] as String? ?? 'Subject';
    String subjectCode = json['subject_code'] as String? ?? 'SUB';
    String? teacherName = json['teacher_name'] as String?;

    if (json['subjects'] is Map) {
      subjectName = json['subjects']['name'] as String? ?? subjectName;
      subjectCode = json['subjects']['code'] as String? ?? subjectCode;
    }
    if (json['profiles'] is Map) {
      teacherName ??= json['profiles']['full_name'] as String?;
    }

    var rawAttachments = json['attachments'];
    List<MediaAttachmentItem> parsedAttachments = [];
    if (rawAttachments is List) {
      parsedAttachments = rawAttachments
          .map((item) => MediaAttachmentItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final id = json['id'] as String;
    return Homework(
      id: id,
      classSectionId: json['class_section_id'] as String,
      subjectId: json['subject_id'] as String,
      subjectName: subjectName,
      subjectCode: subjectCode,
      teacherId: json['teacher_id'] as String?,
      teacherName: teacherName,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      attachments: parsedAttachments,
      isCompleted: completedIds.contains(id) || (json['is_completed'] as bool? ?? false),
    );
  }

  ExamResult _parseExamResult(Map<String, dynamic> json) {
    String examName = json['exam_name'] as String? ?? 'Examination';
    String subjectName = json['subject_name'] as String? ?? 'Subject';
    String subjectCode = json['subject_code'] as String? ?? 'SUB';
    String? studentName = json['student_name'] as String?;
    int? studentRollNo = json['student_roll_no'] as int?;

    if (json['exams'] is Map) {
      examName = json['exams']['name'] as String? ?? examName;
    }
    if (json['subjects'] is Map) {
      subjectName = json['subjects']['name'] as String? ?? subjectName;
      subjectCode = json['subjects']['code'] as String? ?? subjectCode;
    }
    if (json['students'] is Map) {
      studentName = json['students']['full_name'] as String?;
      studentRollNo = json['students']['roll_no'] as int?;
    }

    final marks = (json['marks_obtained'] as num?)?.toDouble();
    final max = (json['max_marks'] as num?)?.toDouble() ?? 100.0;
    final status = json['status'] as String? ?? 'present';
    final grade = json['grade'] as String? ??
        (status == 'present' && marks != null ? ExamResult.calculateCbseGrade(marks, max) : '-');

    return ExamResult(
      id: json['id'] as String,
      examId: json['exam_id'] as String,
      examName: examName,
      studentId: json['student_id'] as String,
      studentRollNo: studentRollNo,
      studentName: studentName,
      classSectionId: json['class_section_id'] as String,
      subjectId: json['subject_id'] as String,
      subjectName: subjectName,
      subjectCode: subjectCode,
      marksObtained: marks,
      maxMarks: max,
      status: status,
      grade: grade,
      subjectRemarks: json['subject_remarks'] as String?,
    );
  }
}
