import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/mock_school_repository.dart';
import '../repositories/school_repository.dart';
import '../services/ota_update_service.dart';

/// Global repository provider for School operations
final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return MockSchoolRepository();
});

/// OTA Update StateNotifier provider (Dual-Layer: Shorebird + GitHub Releases)
final otaUpdateProvider =
    StateNotifierProvider<OtaUpdateService, OtaUpdateState>((ref) {
  return OtaUpdateService();
});

/// Convenient selector for Shorebird Quick Patch state
final shorebirdStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final otaState = ref.watch(otaUpdateProvider);
  return {
    'isAvailable': otaState.isShorebirdAvailable,
    'currentPatch': otaState.currentPatchNumber,
    'nextPatch': otaState.nextPatchNumber,
    'isChecking': otaState.isCheckingShorebird,
    'isPatchAvailable': otaState.isShorebirdPatchAvailable,
    'isDownloading': otaState.isShorebirdPatchDownloading,
    'isReadyToInstall': otaState.isShorebirdPatchReadyToInstall,
    'message': otaState.shorebirdMessage,
  };
});

/// Currently active student session (Defaults to demo student Aarav Sharma)
final currentStudentProvider = StateProvider<Student?>((ref) {
  return const Student(
    id: 'student-aarav',
    rollNo: 1,
    fullName: 'Aarav Sharma',
    admissionNo: 'ADM2026101',
    classSectionId: 'class-8b',
    parentName: 'Rajesh Sharma',
    parentPhone: '+919876540001',
    house: 'red',
    pinHash: '1234',
    homeworkStreak: 5,
  );
});

/// Linked siblings for parent switcher
final linkedSiblingsProvider = StateProvider<List<Student>>((ref) {
  return [
    const Student(
      id: 'student-aarav',
      rollNo: 1,
      fullName: 'Aarav Sharma',
      admissionNo: 'ADM2026101',
      classSectionId: 'class-8b',
      parentName: 'Rajesh Sharma',
      parentPhone: '+919876540001',
      house: 'red',
      pinHash: '1234',
      homeworkStreak: 5,
    ),
    const Student(
      id: 'student-kabir',
      rollNo: 2,
      fullName: 'Kabir Verma',
      admissionNo: 'ADM2026102',
      classSectionId: 'class-8b',
      parentName: 'Sanjay Verma',
      parentPhone: '+919876540002',
      house: 'blue',
      pinHash: '1234',
      homeworkStreak: 3,
    ),
  ];
});

/// Currently active staff session (Teacher or Admin)
final currentStaffProvider = StateProvider<Map<String, dynamic>?>((ref) {
  return {
    'id': 'teacher-ramesh',
    'role': 'teacher',
    'full_name': 'Mr. Ramesh Sharma',
    'homeroom_class_id': 'class-8b',
    'homeroom_class_name': 'Class 8-B',
    'homeroom_class_code': '8B-K9X2',
  };
});

/// Active app role switcher: 'student', 'teacher', 'admin'
final activeRoleProvider = StateProvider<String>((ref) => 'student');

/// Accessibility toggle for reduced motion
final reduceMotionProvider = StateProvider<bool>((ref) => false);
