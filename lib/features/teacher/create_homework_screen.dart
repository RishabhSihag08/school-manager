import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/models.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/tactile_feedback.dart';
import '../../core/widgets/unified_media_viewer.dart';

/// Screen for teachers to publish multimedia homework assignments
/// filtered to their assigned classes & subjects.
class CreateHomeworkScreen extends ConsumerStatefulWidget {
  final String? initialClassId;
  final String? initialSubjectCode;

  const CreateHomeworkScreen({
    super.key,
    this.initialClassId,
    this.initialSubjectCode,
  });

  @override
  ConsumerState<CreateHomeworkScreen> createState() =>
      _CreateHomeworkScreenState();
}

class _CreateHomeworkScreenState extends ConsumerState<CreateHomeworkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _dueDate;
  String _selectedClassId = '';
  String _selectedClassName = '';
  String _selectedSubjectCode = 'GEN';
  String _selectedSubjectName = 'General';

  final List<MediaAttachmentItem> _attachments = [];
  bool _isPublishing = false;
  List<Map<String, dynamic>> _assignedClasses = [];

  @override
  void initState() {
    super.initState();
    _dueDate = DateTime.now().add(const Duration(days: 1));
    _loadAssignedClasses();
  }

  Future<void> _loadAssignedClasses() async {
    final staff = ref.read(currentStaffProvider);
    final repo = ref.read(schoolRepositoryProvider);
    final teacherId = staff?['id'] as String? ?? '';
    final defaultSubject = staff?['subject_name'] as String? ?? 'General';
    final defaultSubjectCode = staff?['subject_code'] as String? ?? 'GEN';

    List<Map<String, dynamic>> classesList = [];
    if (teacherId.isNotEmpty) {
      try {
        final allocs = await repo.getTeacherSubjectAllocations(teacherId);
        classesList = allocs.map((a) => {
          'class_id': a['class_section_id'] ?? a['class_id'] ?? '',
          'class_name': a['class_name'] ?? 'Class',
          'subject_code': a['subject_code'] ?? defaultSubjectCode,
          'subject_name': a['subject_name'] ?? defaultSubject,
        }).toList();
      } catch (_) {}
    }

    if (classesList.isEmpty) {
      try {
        final allSections = await repo.getAllClassSections();
        classesList = allSections.map((c) => {
          'class_id': c.id,
          'class_name': c.displayName,
          'subject_code': defaultSubjectCode,
          'subject_name': defaultSubject,
        }).toList();
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _assignedClasses = classesList;
      if (_assignedClasses.isNotEmpty) {
        final match = widget.initialClassId != null
            ? _assignedClasses.firstWhere(
                (c) => c['class_id'] == widget.initialClassId,
                orElse: () => _assignedClasses.first,
              )
            : _assignedClasses.first;
        _selectedClassId = match['class_id'] as String? ?? '';
        _selectedClassName = match['class_name'] as String? ?? 'Class';
        _selectedSubjectCode = match['subject_code'] as String? ?? defaultSubjectCode;
        _selectedSubjectName = match['subject_name'] as String? ?? defaultSubject;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandPrimary,
              onPrimary: Colors.white,
              surface: AppColors.cardSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _addMediaAttachment(String type) async {
    HapticFeedback.lightImpact();

    if (type == 'image') {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          final filePath = file.path ?? '';
          final fileName = file.name;
          final sizeKb = (file.size / 1024).round();

          setState(() {
            _attachments.add(
              MediaAttachmentItem(
                title: fileName,
                url: filePath,
                type: 'image',
                sizeKb: sizeKb,
              ),
            );
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Attached photo: $fileName'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick photo: $e')),
          );
        }
      }
    } else if (type == 'pdf') {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: false,
        );
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          final filePath = file.path ?? '';
          final fileName = file.name;
          final sizeKb = (file.size / 1024).round();

          setState(() {
            _attachments.add(
              MediaAttachmentItem(
                title: fileName,
                url: filePath,
                type: 'pdf',
                sizeKb: sizeKb,
              ),
            );
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Attached PDF: $fileName'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick PDF: $e')),
          );
        }
      }
    } else if (type == 'video') {
      _showVideoAttachmentDialog();
    }
  }

  void _showVideoAttachmentDialog() {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.video, color: AppColors.brandPrimary, size: 22),
            SizedBox(width: 10),
            Text('Attach Concept Video'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Video Title',
                hintText: 'e.g. Chapter 4 Concept Video',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'YouTube / Web Video URL',
                hintText: 'https://www.youtube.com/watch?v=...',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.video,
                  allowMultiple: false,
                );
                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  urlCtrl.text = file.path ?? '';
                  if (titleCtrl.text.isEmpty) {
                    titleCtrl.text = file.name;
                  }
                }
              },
              icon: const Icon(LucideIcons.hardDrive, size: 16),
              label: const Text('Or Pick Video File from Device'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isEmpty) return;
              final title = titleCtrl.text.trim().isNotEmpty
                  ? titleCtrl.text.trim()
                  : 'Video Lesson';
              setState(() {
                _attachments.add(
                  MediaAttachmentItem(
                    title: title,
                    url: url,
                    type: 'video',
                    sizeKb: 0,
                  ),
                );
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Attached video: $title'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Attach'),
          ),
        ],
      ),
    );
  }

  void _removeAttachment(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _publishHomework() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target class first.')),
      );
      return;
    }

    setState(() => _isPublishing = true);
    HapticFeedback.heavyImpact();

    final repo = ref.read(schoolRepositoryProvider);
    final staff = ref.read(currentStaffProvider);
    final teacherId = staff?['id'] as String? ?? '';
    final teacherName = staff?['full_name'] as String? ?? 'Faculty';

    final newHomework = Homework(
      id: 'hw-${DateTime.now().millisecondsSinceEpoch}',
      classSectionId: _selectedClassId,
      subjectId: 'sub-${_selectedSubjectCode.toLowerCase()}',
      subjectName: _selectedSubjectName,
      subjectCode: _selectedSubjectCode,
      teacherId: teacherId,
      teacherName: teacherName,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueDate,
      attachments: List.from(_attachments),
    );

    await repo.createHomework(newHomework);

    if (!mounted) return;
    setState(() => _isPublishing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCheck, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Homework published to $_selectedClassName successfully!',
                style: AppTypography.bodySmall.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDue = DateFormat('EEE, dd MMM yyyy').format(_dueDate);
    final subjectColor = AppColors.getSubjectColor(_selectedSubjectCode);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: AppColors.canvasBackground,
        elevation: 0,
        title: Text('Publish Homework', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.helpCircle,
                color: AppColors.inkSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Attachments are compressed to <250KB for fast cellular viewing by students.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Target Class & Subject Selector
            BentoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Target Class & Subject',
                          style: AppTypography.titleSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: subjectColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: subjectColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _selectedSubjectCode,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: subjectColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Styled Subject Pill Dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.canvasBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _assignedClasses.any((item) => item['class_id'] == _selectedClassId)
                            ? _selectedClassId
                            : (_assignedClasses.isNotEmpty ? _assignedClasses.first['class_id'] as String : null),
                        icon: const Icon(LucideIcons.chevronDown,
                            size: 18, color: AppColors.inkSecondary),
                        items: _assignedClasses.map((item) {
                          final subCode = item['subject_code'] as String? ?? 'GEN';
                          final (subBg, subFg) = AppColors.getSubjectColors(subCode);
                          return DropdownMenuItem<String>(
                            value: item['class_id'] as String,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: subBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    subCode,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: subFg,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${item['class_name']} • ${item['subject_name']}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.inkPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final found = _assignedClasses.firstWhere(
                              (c) => c['class_id'] == val,
                            );
                            setState(() {
                              _selectedClassId = val;
                              _selectedClassName = found['class_name'] as String;
                              _selectedSubjectCode =
                                  found['subject_code'] as String;
                              _selectedSubjectName =
                                  found['subject_name'] as String;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Homework Title & Submission Date
            BentoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Homework Assignment Details',
                      style: AppTypography.titleSmall),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    validator: (val) =>
                        (val == null || val.trim().isEmpty)
                            ? 'Please enter homework title'
                            : null,
                    decoration: InputDecoration(
                      labelText: 'Title / Chapter Name *',
                      hintText: 'e.g. Chapter 4: Linear Equations Exercise 4.2',
                      prefixIcon: const Icon(LucideIcons.bookOpen, size: 18),
                      filled: true,
                      fillColor: AppColors.canvasBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Due Date Picker Field
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.calendar,
                            size: 16, color: AppColors.brandPrimary),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Submission Due Date',
                              style: AppTypography.caption),
                          Text(formattedDue,
                              style: GoogleFonts.jetBrainsMono(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.inkPrimary,
                              )),
                        ],
                      ),
                      const Spacer(),
                      TactileFeedback(
                        onTap: _pickDueDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimaryLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.brandPrimary
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Change Date',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.chevronDown,
                                  size: 14, color: AppColors.brandPrimary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Homework Description Section
            BentoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.fileText,
                            size: 16, color: AppColors.brandPrimary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Homework Description *',
                        style: AppTypography.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter instructions, problems, or notes for students to complete.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    style: AppTypography.bodyMedium,
                    validator: (val) =>
                        (val == null || val.trim().isEmpty)
                            ? 'Please provide homework instructions for students'
                            : null,
                    decoration: InputDecoration(
                      hintText:
                          'Enter assignment details here...\n• Exercises or problems to solve\n• Specific notebook or submission instructions',
                      hintStyle: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkSecondary.withValues(alpha: 0.6),
                      ),
                      filled: true,
                      fillColor: AppColors.canvasBackground,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.cardBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.cardBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.brandPrimary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Multimedia Attachments Card
            BentoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.paperclip,
                              size: 16, color: AppColors.brandPrimary),
                          const SizedBox(width: 8),
                          Text('Multi-Attachment Media',
                              style: AppTypography.titleSmall),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_attachments.length} Attached',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Attach blackboard photos, PDF worksheets, or concept video lessons for students to stream.',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 14),

                  // 3 Multi-Attachment Upload Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _mediaAddButton(
                          label: '+ Photo',
                          icon: LucideIcons.image,
                          color: const Color(0xFF059669), // Emerald
                          onTap: () => _addMediaAttachment('image'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _mediaAddButton(
                          label: '+ PDF Doc',
                          icon: LucideIcons.fileText,
                          color: const Color(0xFFE11D48), // Crimson
                          onTap: () => _addMediaAttachment('pdf'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _mediaAddButton(
                          label: '+ Video',
                          icon: LucideIcons.video,
                          color: const Color(0xFF7C3AED), // Violet
                          onTap: () => _addMediaAttachment('video'),
                        ),
                      ),
                    ],
                  ),

                  // Attachment Chips List
                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppColors.cardBorder),
                    const SizedBox(height: 10),
                    ...List.generate(_attachments.length, (idx) {
                      final item = _attachments[idx];
                      final isPdf = item.type == 'pdf';
                      final isVideo = item.type == 'video';
                      final icon = isPdf
                          ? LucideIcons.fileText
                          : (isVideo ? LucideIcons.video : LucideIcons.image);
                      final badgeColor = isPdf
                          ? const Color(0xFFE11D48)
                          : (isVideo
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF059669));

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.canvasBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => UnifiedMediaViewer.show(
                            context,
                            items: _attachments,
                            initialIndex: idx,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(icon,
                                      size: 18, color: badgeColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: AppTypography.titleSmall
                                            .copyWith(fontSize: 12.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: badgeColor
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.type.toUpperCase(),
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: badgeColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            (item.sizeKb ?? 0) > 0
                                                ? '${item.sizeKb} KB • Tap to preview'
                                                : 'Tap to preview',
                                            style: AppTypography.caption
                                                .copyWith(fontSize: 10.5),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2,
                                      size: 16, color: AppColors.danger),
                                  onPressed: () => _removeAttachment(idx),
                                  tooltip: 'Remove Attachment',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: SafeArea(
          child: TactileFeedback(
            onTap: _isPublishing ? null : _publishHomework,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isPublishing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.send,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Broadcast to $_selectedClassName',
                            style: AppTypography.button
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mediaAddButton({
    required String label,
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    final effectiveColor = color ?? AppColors.brandPrimary;
    return TactileFeedback(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.canvasBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: effectiveColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.pillLabel.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
