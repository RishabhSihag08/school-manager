import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../providers/core_providers.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';

/// Persistent Session Service for School Manager
/// Ensures users stay logged in across app closes until explicit logout
class SessionService {
  SessionService._();

  static const String _keyAuthRole = 'sm_auth_role';
  static const String _keyStudentJson = 'sm_auth_student_json';
  static const String _keyStaffJson = 'sm_auth_staff_json';
  static const String _keyStudentId = 'sm_auth_student_id';
  static const String _keyClassSectionId = 'sm_auth_class_id';
  static const String _keyRollNo = 'sm_auth_roll_no';
  static const String _keyStaffCode = 'sm_auth_staff_code';

  /// Save authenticated Student session
  static Future<void> saveStudentSession(Student student) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAuthRole, 'student');
      await prefs.setString(_keyStudentId, student.id);
      await prefs.setString(_keyClassSectionId, student.classSectionId);
      await prefs.setInt(_keyRollNo, student.rollNo);
      await prefs.setString(_keyStudentJson, jsonEncode(student.toJson()));
      debugPrint('SessionService: Saved student session for ${student.fullName} (Roll: ${student.rollNo})');
    } catch (e) {
      debugPrint('SessionService: Error saving student session: $e');
    }
  }

  /// Save authenticated Staff session (Teacher or Admin)
  static Future<void> saveStaffSession(Map<String, dynamic> staff) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = staff['role'] as String? ?? 'teacher';
      await prefs.setString(_keyAuthRole, role);
      await prefs.setString(_keyStaffCode, staff['login_code'] as String? ?? '');
      await prefs.setString(_keyStaffJson, jsonEncode(staff));
      debugPrint('SessionService: Saved staff session for ${staff['name']} (Role: $role)');
    } catch (e) {
      debugPrint('SessionService: Error saving staff session: $e');
    }
  }

  /// Clear all active sessions (called on explicit Log Out or Switch Role)
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAuthRole);
      await prefs.remove(_keyStudentJson);
      await prefs.remove(_keyStaffJson);
      await prefs.remove(_keyStudentId);
      await prefs.remove(_keyClassSectionId);
      await prefs.remove(_keyRollNo);
      await prefs.remove(_keyStaffCode);
      debugPrint('SessionService: Cleared active user session.');
    } catch (e) {
      debugPrint('SessionService: Error clearing session: $e');
    }
  }

  /// Restore active session into Riverpod state
  /// Returns the restored role ('student', 'teacher', 'admin', or null if none)
  static Future<String?> restoreSession(WidgetRef ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(_keyAuthRole);
      if (role == null || role.isEmpty) {
        return null;
      }

      if (role == 'student') {
        final studentJsonStr = prefs.getString(_keyStudentJson);
        if (studentJsonStr != null && studentJsonStr.isNotEmpty) {
          final map = jsonDecode(studentJsonStr) as Map<String, dynamic>;
          final student = Student.fromJson(map);
          ref.read(currentStudentProvider.notifier).state = student;
          ref.read(activeRoleProvider.notifier).state = 'student';
          debugPrint('SessionService: Restored active student session: ${student.fullName}');
          return 'student';
        }
      } else if (role == 'teacher' || role == 'admin') {
        final staffJsonStr = prefs.getString(_keyStaffJson);
        if (staffJsonStr != null && staffJsonStr.isNotEmpty) {
          final staff = jsonDecode(staffJsonStr) as Map<String, dynamic>;
          ref.read(currentStaffProvider.notifier).state = staff;
          ref.read(activeRoleProvider.notifier).state = role;
          debugPrint('SessionService: Restored active staff session: ${staff['name']} ($role)');
          return role;
        }
      }
    } catch (e) {
      debugPrint('SessionService: Error restoring session: $e');
    }
    return null;
  }

  /// Determine initial navigation location based on saved session
  static Future<String> getSavedInitialRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(_keyAuthRole);
      if (role == 'student') {
        return AppRoutes.studentHome;
      } else if (role == 'teacher') {
        return AppRoutes.teacherDashboard;
      } else if (role == 'admin') {
        return AppRoutes.adminDashboard;
      }
    } catch (e) {
      debugPrint('SessionService: Error determining initial route: $e');
    }
    return AppRoutes.onboarding;
  }

  /// Show a confirmation dialog and log out the user from School Manager
  static Future<bool> confirmAndLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.logOut, color: AppColors.danger, size: 22),
            SizedBox(width: 10),
            Text('Log Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of School Manager?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await clearSession();
      ref.read(currentStudentProvider.notifier).state = null;
      ref.read(currentStaffProvider.notifier).state = null;
      ref.read(activeRoleProvider.notifier).state = 'student';
      if (context.mounted) {
        context.go(AppRoutes.onboarding);
      }
      return true;
    }
    return false;
  }
}
