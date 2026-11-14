import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../repositories/mock_school_repository.dart';
import '../repositories/school_repository.dart';
import '../repositories/supabase_school_repository.dart';
import '../services/connectivity_service.dart';
import '../services/ota_update_service.dart';

export '../services/connectivity_service.dart'
    show connectivityStatusProvider, appRefreshTriggerProvider;

/// Global repository provider for School operations
final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  if (AppConfig.hasSupabaseCredentials) {
    return SupabaseSchoolRepository();
  }
  return MockSchoolRepository();
});

/// OTA Update StateNotifier provider (GitHub Releases)
final otaUpdateProvider =
    StateNotifierProvider<OtaUpdateService, OtaUpdateState>((ref) {
  return OtaUpdateService();
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
