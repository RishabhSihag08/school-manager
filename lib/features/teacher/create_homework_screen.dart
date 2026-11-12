import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  String _selectedClassId = 'class-8b';
  String _selectedClassName = 'Class 8-B';
  String _selectedSubjectCode = 'MATH';
  String _selectedSubjectName = 'Mathematics';

  final List<MediaAttachmentItem> _attachments = [];
  bool _isPublishing = false;

  final List<Map<String, dynamic>> _assignedClasses = [
    {
      'class_id': 'class-8b',
      'class_name': 'Class 8-B',
      'subject_code': 'MATH',
      'subject_name': 'Mathematics',
    },
    {
      'class_id': 'class-6a',
      'class_name': 'Class 6-A',
      'subject_code': 'MATH',
      'subject_name': 'Mathematics',
    },
    {
      'class_id': 'class-7c',
      'class_name': 'Class 7-C',
      'subject_code': 'MATH',
      'subject_name': 'Mathematics',
    },
  ];

  @override
  void initState() {
    super.initState();
    _dueDate = DateTime.now().add(const Duration(days: 1));
    if (widget.initialClassId != null) {
      _selectedClassId = widget.initialClassId!;
      final match = _assignedClasses.firstWhere(
        (c) => c['class_id'] == widget.initialClassId,
        orElse: () => _assignedClasses.first,
      );
      _selectedClassName = match['class_name'] as String;
      _selectedSubjectCode = match['subject_code'] as String;
      _selectedSubjectName = match['subject_name'] as String;
    }
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

  void _addMediaAttachment(String type) {
    HapticFeedback.lightImpact();
    // Demo presets for rich multimedia homework
    if (type == 'image') {
      setState(() {
        _attachments.add(
          const MediaAttachmentItem(
            title: 'Blackboard Notes (Ex 2.3).jpg',
            url:
                'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=1000',
            type: 'image',
            sizeKb: 185,
          ),
        );
      });
    } else if (type == 'pdf') {
      setState(() {
        _attachments.add(
          const MediaAttachmentItem(
            title: 'Exercise Worksheet Unit 2.pdf',
            url:
                'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            type: 'pdf',
            sizeKb: 240,
          ),
        );
      });
    } else if (type == 'video') {
      setState(() {
        _attachments.add(
          const MediaAttachmentItem(
            title: 'NCERT Concept Video: Linear Equations',
            url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            type: 'video',
            sizeKb: 0,
          ),
        );
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attached $type successfully!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
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

    setState(() => _isPublishing = true);
    HapticFeedback.heavyImpact();

    final repo = ref.read(schoolRepositoryProvider);
    final staff = ref.read(currentStaffProvider);
    final teacherId = staff?['id'] as String? ?? 'teacher-ramesh';
    final teacherName = staff?['full_name'] as String? ?? 'Mr. Ramesh Sharma';

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
                  Text('Target Class & Subject',
                      style: AppTypography.titleSmall),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClassId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.canvasBackground,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                    items: _assignedClasses.map((item) {
                      return DropdownMenuItem<String>(
                        value: item['class_id'] as String,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: subjectColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item['class_name']} • ${item['subject_name']}',
                              style: AppTypography.bodyMedium,
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Title & Due Date Row
            BentoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Homework Details', style: AppTypography.titleSmall),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    validator: (val) =>
                        (val == null || val.trim().isEmpty)
                            ? 'Please enter homework title'
                            : null,
                    decoration: InputDecoration(
                      labelText: 'Title / Chapter Name *',
                      hintText: 'e.g. Linear Equations Exercise 2.3',
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
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    validator: (val) =>
                        (val == null || val.trim().isEmpty)
                            ? 'Please provide instructions for students'
                            : null,
                    decoration: InputDecoration(
                      labelText: 'Instructions for Students *',
                      hintText:
                          'Specify question numbers, notebook format, submission instructions...',
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
                      const Icon(LucideIcons.calendar,
                          size: 18, color: AppColors.brandPrimary),
                      const SizedBox(width: 8),
                      Text('Submission Due Date:',
                          style: AppTypography.bodyMedium),
                      const Spacer(),
                      TactileFeedback(
                        onTap: _pickDueDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.canvasBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Text(formattedDue,
                                  style: AppTypography.monospace(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: AppColors.inkPrimary,
                                  )),
                              const SizedBox(width: 6),
                              const Icon(LucideIcons.chevronDown,
                                  size: 14, color: AppColors.inkMuted),
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

            // Multimedia Attachments Card
            BentoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Media Attachments',
                          style: AppTypography.titleSmall),
                      Text(
                        '${_attachments.length} Attached',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Attach blackboard photos, worksheets, or concept videos for in-app viewing.',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 14),

                  // 3 Attachment Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _mediaAddButton(
                          label: '+ Photo',
                          icon: LucideIcons.image,
                          onTap: () => _addMediaAttachment('image'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _mediaAddButton(
                          label: '+ PDF Doc',
                          icon: LucideIcons.fileText,
                          onTap: () => _addMediaAttachment('pdf'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _mediaAddButton(
                          label: '+ Video',
                          icon: LucideIcons.video,
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.canvasBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.type == 'pdf'
                                  ? LucideIcons.fileText
                                  : (item.type == 'video'
                                      ? LucideIcons.video
                                      : LucideIcons.image),
                              size: 18,
                              color: AppColors.brandPrimary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: AppTypography.titleSmall
                                        .copyWith(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if ((item.sizeKb ?? 0) > 0)
                                    Text(
                                      '${item.sizeKb ?? 0} KB • Ready for in-app viewer',
                                      style: AppTypography.caption
                                          .copyWith(fontSize: 10),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2,
                                  size: 16, color: AppColors.danger),
                              onPressed: () => _removeAttachment(idx),
                              tooltip: 'Remove',
                            ),
                          ],
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
    required VoidCallback onTap,
  }) {
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
            Icon(icon, size: 16, color: AppColors.brandPrimary),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.pillLabel),
          ],
        ),
      ),
    );
  }
}
