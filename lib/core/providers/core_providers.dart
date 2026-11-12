import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../repositories/mock_school_repository.dart';
import '../repositories/school_repository.dart';
import '../repositories/supabase_school_repository.dart';
import '../services/ota_update_service.dart';

/// Global repository provider for School operations
final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  if (AppConfig.hasSupabaseCredentials) {
    return SupabaseSchoolRepository();
  }
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

/// Currently active student session (Production: null until authenticated)
final currentStudentProvider = StateProvider<Student?>((ref) => null);

/// Linked siblings for parent switcher
final linkedSiblingsProvider = StateProvider<List<Student>>((ref) => const <Student>[]);

/// Currently active staff session (Production: null until authenticated)
final currentStaffProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

/// Active app role switcher: 'student', 'teacher', 'admin'
final activeRoleProvider = StateProvider<String>((ref) => 'student');

/// Initial navigation route (determined on app startup from persisted session)
final initialRouteProvider = StateProvider<String>((ref) => '/');

/// Accessibility toggle for reduced motion
final reduceMotionProvider = StateProvider<bool>((ref) => false);
