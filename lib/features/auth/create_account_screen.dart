import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/school_manager_logo.dart';
import '../../core/widgets/tactile_feedback.dart';

/// Comprehensive Create Account Screen for Students, Teachers, and Staff
class CreateAccountScreen extends ConsumerStatefulWidget {
  final String initialRole;

  const CreateAccountScreen({
    super.key,
    this.initialRole = 'student',
  });

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  late String _selectedRole;

  // Common
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _phoneController = TextEditingController();

  // Student specific
  final _classCodeController = TextEditingController();
  final _rollController = TextEditingController();
  final _admissionController = TextEditingController();
  final _parentNameController = TextEditingController();

  // Staff specific
  final _loginCodeController = TextEditingController();
  final _masterKeyController = TextEditingController();
  String _selectedHomeroom = 'class-8b';
  String _selectedSubject = 'Mathematics';
  bool _isLoading = false;

  static const List<String> _standardSubjects = [
    'Mathematics',
    'Science',
    'English',
    'Hindi',
    'Social Science',
    'Computer Science',
    'Physics',
    'Chemistry',
    'Biology',
    'Economics',
  ];

  static const Map<String, String> _subjectCodes = {
    'Mathematics': 'MATH',
    'Science': 'SCI',
    'English': 'ENG',
    'Hindi': 'HIN',
    'Social Science': 'SST',
    'Computer Science': 'CS',
    'Physics': 'PHY',
    'Chemistry': 'CHEM',
    'Biology': 'BIO',
    'Economics': 'ECO',
  };

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _phoneController.dispose();
    _classCodeController.dispose();
    _rollController.dispose();
    _admissionController.dispose();
    _parentNameController.dispose();
    _loginCodeController.dispose();
    _masterKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    if (pin.length < 4) {
      _showError('PIN must be at least 4 digits');
      return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(schoolRepositoryProvider);

    try {
      if (_selectedRole == 'student') {
        final code = _classCodeController.text.trim().toUpperCase();
        final rollStr = _rollController.text.trim();
        final parentName = _parentNameController.text.trim();
        final parentPhone = _phoneController.text.trim();

        if (code.isEmpty || rollStr.isEmpty || parentName.isEmpty || parentPhone.isEmpty) {
          _showError('Please complete all student & parent information');
          setState(() => _isLoading = false);
          return;
        }

        final roll = int.tryParse(rollStr) ?? 1;
        final student = await repo.registerStudentWithCode(
          classCode: code,
          fullName: name,
          rollNo: roll,
          admissionNo: _admissionController.text.trim().isEmpty ? null : _admissionController.text.trim(),
          parentName: parentName,
          parentPhone: parentPhone,
          house: '',
          pin: pin,
        );

        ref.read(currentStudentProvider.notifier).state = student;
        ref.read(activeRoleProvider.notifier).state = 'student';

        // Persist session across app restarts
        await SessionService.saveStudentSession(student);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('preferred_role', 'student');
        await prefs.setString('student_id', student.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text('🎉 Student account created successfully for $name!'),
            ),
          );
          context.go(AppRoutes.studentHome);
        }
      } else {
        // Teacher or Admin - Requires Master Security Key from .env
        final masterKeyInput = _masterKeyController.text.trim();
        if (masterKeyInput != AppConfig.masterKey) {
          _showError('Invalid Master Security Key. Administrative authorization required.');
          setState(() => _isLoading = false);
          return;
        }

        final loginCode = _loginCodeController.text.trim();
        if (loginCode.isEmpty) {
          _showError('Please enter a login code / user ID');
          setState(() => _isLoading = false);
          return;
        }

        String? homeroomName;
        if (_selectedRole == 'teacher') {
          if (_selectedHomeroom == 'class-8b') homeroomName = 'Class 8-B';
          if (_selectedHomeroom == 'class-6a') homeroomName = 'Class 6-A';
          if (_selectedHomeroom == 'class-7c') homeroomName = 'Class 7-C';
        }

        final staff = await repo.registerStaff(
          fullName: name,
          role: _selectedRole,
          loginCode: loginCode,
          pin: pin,
          phone: _phoneController.text.trim(),
          homeroomClassId: _selectedRole == 'teacher' ? _selectedHomeroom : null,
          homeroomClassName: homeroomName,
          subjectName: _selectedRole == 'teacher' ? _selectedSubject : null,
          subjectCode: _selectedRole == 'teacher'
              ? (_subjectCodes[_selectedSubject] ?? 'SUB')
              : null,
        );

        ref.read(currentStaffProvider.notifier).state = staff;
        ref.read(activeRoleProvider.notifier).state = _selectedRole;

        // Persist session across app restarts
        await SessionService.saveStaffSession(staff);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('preferred_role', _selectedRole);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text('🎉 ${_selectedRole == "admin" ? "Staff/Admin" : "Teacher"} account created! Code: $loginCode'),
            ),
          );
          if (_selectedRole == 'admin') {
            context.go(AppRoutes.adminDashboard);
          } else {
            context.go(AppRoutes.teacherDashboard);
          }
        }
      }
    } catch (e) {
      _showError('Registration note: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SchoolManagerLogo(size: 26),
            const SizedBox(width: 10),
            Text('Create Account', style: AppTypography.titleLarge),
          ],
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.onboarding),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Role Segmented Tabs
                  _buildRoleSelectorTabs(),

                  const SizedBox(height: 20),

                  // Form Container
                  BentoCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getRoleBgColor(),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getRoleIcon(),
                                color: _getRolePrimaryColor(),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getRoleHeading(),
                                    style: AppTypography.titleLarge,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getRoleSubheading(),
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: AppColors.cardBorder),
                        const SizedBox(height: 20),

                        // Form Inputs
                        if (_selectedRole == 'student')
                          ..._buildStudentFields()
                        else
                          ..._buildStaffFields(),

                        const SizedBox(height: 24),

                        // Submit Button
                        TactileFeedback(
                          onTap: _isLoading ? null : _handleCreateAccount,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _getRolePrimaryColor(),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.userPlus, size: 18, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Create ${_getRoleLabel()} Account',
                                          style: AppTypography.labelLarge.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Already have account prompt
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.go(AppRoutes.welcome),
                      icon: const Icon(LucideIcons.logIn, size: 16),
                      label: Text(
                        'Already registered? Sign In here',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.brandPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectorTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _roleTab('student', 'Student', LucideIcons.user),
          _roleTab('teacher', 'Teacher', LucideIcons.userCheck),
          _roleTab('admin', 'Staff / Admin', LucideIcons.shieldCheck),
        ],
      ),
    );
  }

  Widget _roleTab(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: TactileFeedback(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cardSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    const BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? _getRolePrimaryColor() : AppColors.inkMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.inkPrimary : AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStudentFields() {
    return [
      _fieldLabel('Class Join Code *'),
      const SizedBox(height: 6),
      _inputContainer(
        controller: _classCodeController,
        hint: 'Enter class join code',
        icon: LucideIcons.hash,
        textCapitalization: TextCapitalization.characters,
      ),
      const SizedBox(height: 14),

      _fieldLabel('Student Full Name *'),
      const SizedBox(height: 6),
      _inputContainer(
        controller: _nameController,
        hint: 'Enter student full name',
        icon: LucideIcons.user,
      ),
      const SizedBox(height: 14),

      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Roll Number *'),
                const SizedBox(height: 6),
                _inputContainer(
                  controller: _rollController,
                  hint: 'Roll #',
                  icon: LucideIcons.hash,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Admission No (Opt.)'),
                const SizedBox(height: 6),
                _inputContainer(
                  controller: _admissionController,
                  hint: 'ADM#',
                  icon: LucideIcons.fileText,
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),

      _fieldLabel('Parent / Guardian Name *'),
      const SizedBox(height: 6),
      _inputContainer(
        controller: _parentNameController,
        hint: "Parent's full name",
        icon: LucideIcons.users,
      ),
      const SizedBox(height: 14),

      _fieldLabel('Parent Mobile Phone *'),
      const SizedBox(height: 6),
      _inputContainer(
        controller: _phoneController,
        hint: '+91 98765 43210',
        icon: LucideIcons.phone,
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 14),



      _fieldLabel('Create 4-Digit Secret PIN *'),
      const SizedBox(height: 6),
      _inputContainer(
        controller: _pinController,
        hint: '4-digit login PIN',
        icon: LucideIcons.lock,
        isPassword: true,
        keyboardType: TextInputType.number,
      ),
    ];
  }

  List<Widget> _buildStaffFields() {
    final isTeacher = _selectedRole == 'teacher';
    return [
      _fieldLabel('Full Name *'),
      const SizedBox(height: 6),
      _inputContainer(
        controller: _nameController,
        hint: isTeacher ? 'Enter teacher name' : 'Enter admin name',
        icon: isTeacher ? LucideIcons.userCheck : LucideIcons.shieldCheck,
      ),
      const SizedBox(height: 14),

      _fieldLabel(isTeacher ? 'Teacher Login Code *' : 'Admin Login Code / ID *'),
      const SizedBox(height: 6),
      _inputContainer(
        controller: _loginCodeController,
        hint: isTeacher ? 'Enter teacher login code' : 'Enter admin login code',
        icon: LucideIcons.hash,
      ),
      const SizedBox(height: 14),

      _fieldLabel('Mobile Phone Number'),
      const SizedBox(height: 6),
      _inputContainer(
        controller: _phoneController,
        hint: '+91 98765 00000',
        icon: LucideIcons.phone,
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 14),

      if (isTeacher) ...[
        _fieldLabel('Teaching Subject *'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSubject,
              isExpanded: true,
              items: _standardSubjects.map((sub) {
                final code = _subjectCodes[sub] ?? 'SUB';
                return DropdownMenuItem<String>(
                  value: sub,
                  child: Text('$sub ($code)'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSubject = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        _fieldLabel('Homeroom Class Assignment'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedHomeroom,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'class-8b', child: Text('Class 8-B (Code: 8B-K9X2)')),
                DropdownMenuItem(value: 'class-6a', child: Text('Class 6-A (Code: 6A-M4P1)')),
                DropdownMenuItem(value: 'class-7c', child: Text('Class 7-C (Code: 7C-Q8W9)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedHomeroom = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],

      _fieldLabel('Master Administrative Security Key *'),
      const SizedBox(height: 6),
      _inputContainer(
        controller: _masterKeyController,
        hint: 'Case-sensitive master key from .env',
        icon: LucideIcons.keyRound,
        isPassword: true,
      ),
      const SizedBox(height: 14),

      _fieldLabel('Create 4-Digit Secret PIN *'),
      const SizedBox(height: 6),
      _inputContainer(
        controller: _pinController,
        hint: '4-digit login PIN',
        icon: LucideIcons.lock,
        isPassword: true,
        keyboardType: TextInputType.number,
      ),
    ];
  }



  Widget _inputContainer({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.inkMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.inkMuted),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.inkPrimary,
      ),
    );
  }

  Color _getRolePrimaryColor() {
    switch (_selectedRole) {
      case 'teacher':
        return const Color(0xFF059669);
      case 'admin':
        return const Color(0xFF7C3AED);
      default:
        return AppColors.brandPrimary;
    }
  }

  Color _getRoleBgColor() {
    switch (_selectedRole) {
      case 'teacher':
        return const Color(0xFFECFDF5);
      case 'admin':
        return const Color(0xFFF5F3FF);
      default:
        return AppColors.brandPrimaryLight;
    }
  }

  IconData _getRoleIcon() {
    switch (_selectedRole) {
      case 'teacher':
        return LucideIcons.userCheck;
      case 'admin':
        return LucideIcons.shieldCheck;
      default:
        return LucideIcons.user;
    }
  }

  String _getRoleHeading() {
    switch (_selectedRole) {
      case 'teacher':
        return 'Teacher Profile Registration';
      case 'admin':
        return 'Staff & Administrator Registration';
      default:
        return 'Student & Parent Registration';
    }
  }

  String _getRoleSubheading() {
    switch (_selectedRole) {
      case 'teacher':
        return 'Homeroom roll call, homework, and syllabus tools';
      case 'admin':
        return 'Campus administration, classes, and academic records';
      default:
        return 'Connect to your section with your class join code';
    }
  }

  String _getRoleLabel() {
    switch (_selectedRole) {
      case 'teacher':
        return 'Teacher';
      case 'admin':
        return 'Staff / Admin';
      default:
        return 'Student';
    }
  }
}
