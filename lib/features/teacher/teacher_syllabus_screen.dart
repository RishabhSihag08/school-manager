import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/syllabus.dart';
import '../../core/models/models.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/tactile_feedback.dart';

/// Single Chapter Model used by TeacherSyllabusScreen
class SyllabusChapterItem {
  String id;
  String title;
  int marks;
  String topics;

  SyllabusChapterItem({
    required this.id,
    required this.title,
    this.marks = 0,
    this.topics = '',
  });

  SyllabusChapterItem copyWith({
    String? id,
    String? title,
    int? marks,
    String? topics,
  }) {
    return SyllabusChapterItem(
      id: id ?? this.id,
      title: title ?? this.title,
      marks: marks ?? this.marks,
      topics: topics ?? this.topics,
    );
  }
}

/// Teacher Syllabus Editor & Manager Screen
/// Enables subject teachers to create, view, and update chapter breakdowns,
/// topics, and weightage marks for their allocated class and subject.
class TeacherSyllabusScreen extends ConsumerStatefulWidget {
  final String classSectionId;
  final String className;
  final String subjectName;
  final String subjectCode;

  const TeacherSyllabusScreen({
    super.key,
    required this.classSectionId,
    required this.className,
    required this.subjectName,
    required this.subjectCode,
  });

  @override
  ConsumerState<TeacherSyllabusScreen> createState() => _TeacherSyllabusScreenState();
}

class _TeacherSyllabusScreenState extends ConsumerState<TeacherSyllabusScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedTerm = 'half_yearly';

  final List<({String key, String label})> _terms = const [
    (key: 'unit_test_1', label: 'UT-1'),
    (key: 'half_yearly', label: 'Half Yearly'),
    (key: 'unit_test_2', label: 'UT-2'),
    (key: 'annual_finals', label: 'Annual Finals'),
    (key: 'full_year', label: 'Full Year'),
  ];

  final _titleController = TextEditingController();
  List<SyllabusChapterItem> _chapters = [];
  Syllabus? _currentSyllabus;
  List<Syllabus> _allClassSyllabi = [];

  @override
  void initState() {
    super.initState();
    _loadSyllabi();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadSyllabi() async {
    setState(() => _isLoading = true);
    final repo = ref.read(schoolRepositoryProvider);

    try {
      final list = await repo.getSyllabiForClass(widget.classSectionId);
      if (!mounted) return;

      _allClassSyllabi = list;
      _populateForTerm(_selectedTerm);
    } catch (e) {
      debugPrint('Error loading syllabi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateForTerm(String term) {
    // Find matching syllabus for this subject & term
    final match = _allClassSyllabi.firstWhere(
      (s) =>
          (s.subjectCode.toUpperCase() == widget.subjectCode.toUpperCase() ||
              s.subjectName.toLowerCase() == widget.subjectName.toLowerCase()) &&
          s.examTerm == term,
      orElse: () => Syllabus(
        id: 'syl-${widget.subjectCode.toLowerCase()}-$term-${DateTime.now().millisecondsSinceEpoch}',
        classSectionId: widget.classSectionId,
        subjectId: 'sub-${widget.subjectCode.toLowerCase()}',
        subjectName: widget.subjectName,
        subjectCode: widget.subjectCode,
        examTerm: term,
        title: '${_getTermLabel(term)} Syllabus (${widget.subjectName})',
        chaptersOverview: '',
        attachments: const [],
      ),
    );

    _currentSyllabus = match;
    _titleController.text = match.title;
    _chapters = _parseChapters(match.chaptersOverview);
  }

  String _getTermLabel(String termKey) {
    final found = _terms.firstWhere((t) => t.key == termKey, orElse: () => (key: termKey, label: 'Term'));
    return found.label;
  }

  List<SyllabusChapterItem> _parseChapters(String overview) {
    if (overview.trim().isEmpty) {
      return [];
    }

    final List<SyllabusChapterItem> result = [];
    final lines = overview.split('\n');

    SyllabusChapterItem? current;

    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('•') || line.startsWith('-') || RegExp(r'^\d+[\.\)]').hasMatch(line)) {
        // Save previous chapter if existing
        if (current != null) {
          result.add(current);
        }

        // Clean bullet / numbering
        var clean = line.replaceFirst(RegExp(r'^[•\-\d+\.\)]\s*'), '').trim();

        // Check if marks are embedded in format "(X Marks)" or "(X marks)"
        int marks = 0;
        final markMatch = RegExp(r'\((?:(\d+)\s*Marks?|Marks?:\s*(\d+))\)', caseSensitive: false).firstMatch(clean);
        if (markMatch != null) {
          final marksStr = markMatch.group(1) ?? markMatch.group(2) ?? '0';
          marks = int.tryParse(marksStr) ?? 0;
          clean = clean.replaceRange(markMatch.start, markMatch.end, '').trim();
        }

        current = SyllabusChapterItem(
          id: 'chap-${DateTime.now().microsecondsSinceEpoch}-${result.length}',
          title: clean,
          marks: marks,
          topics: '',
        );
      } else if (line.toLowerCase().startsWith('topics:') || line.toLowerCase().startsWith('subtopics:')) {
        final topicText = line.replaceFirst(RegExp(r'^(?:topics|subtopics):\s*', caseSensitive: false), '').trim();
        if (current != null) {
          current.topics = current.topics.isEmpty ? topicText : '${current.topics}\n$topicText';
        }
      } else {
        if (current != null) {
          current.topics = current.topics.isEmpty ? line : '${current.topics}\n$line';
        }
      }
    }

    if (current != null) {
      result.add(current);
    }

    return result;
  }

  String _buildOverviewString() {
    final buffer = StringBuffer();
    for (var i = 0; i < _chapters.length; i++) {
      final c = _chapters[i];
      final title = c.title.trim();
      if (title.isEmpty) continue;

      if (c.marks > 0) {
        buffer.write('• $title (${c.marks} Marks)');
      } else {
        buffer.write('• $title');
      }

      if (c.topics.trim().isNotEmpty) {
        buffer.write('\n  Topics: ${c.topics.trim()}');
      }

      if (i < _chapters.length - 1) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }

  int get _totalMarks => _chapters.fold<int>(0, (sum, c) => sum + c.marks);

  void _onTermChanged(String term) {
    if (_selectedTerm == term) return;
    setState(() {
      _selectedTerm = term;
      _populateForTerm(term);
    });
  }

  Future<void> _saveSyllabus() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showToast('Please enter a syllabus title', isError: true);
      return;
    }

    if (_chapters.isEmpty) {
      _showToast('Please add at least one chapter before saving', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final repo = ref.read(schoolRepositoryProvider);

    try {
      final overview = _buildOverviewString();
      final updatedSyllabus = Syllabus(
        id: _currentSyllabus?.id ??
            'syl-${widget.subjectCode.toLowerCase()}-$_selectedTerm-${DateTime.now().millisecondsSinceEpoch}',
        classSectionId: widget.classSectionId,
        subjectId: _currentSyllabus?.subjectId ?? 'sub-${widget.subjectCode.toLowerCase()}',
        subjectName: widget.subjectName,
        subjectCode: widget.subjectCode,
        examTerm: _selectedTerm,
        title: title,
        chaptersOverview: overview,
        attachments: _currentSyllabus?.attachments ?? const [],
        updatedAt: DateTime.now(),
      );

      await repo.saveSyllabus(updatedSyllabus);

      // Update local memory list
      _allClassSyllabi.removeWhere(
        (s) =>
            s.id == updatedSyllabus.id ||
            ((s.subjectCode.toUpperCase() == widget.subjectCode.toUpperCase() ||
                    s.subjectName.toLowerCase() == widget.subjectName.toLowerCase()) &&
                s.examTerm == _selectedTerm),
      );
      _allClassSyllabi.add(updatedSyllabus);
      _currentSyllabus = updatedSyllabus;

      if (mounted) {
        _showToast('🎉 Syllabus saved & live in Student Vault!');
      }
    } catch (e) {
      _showToast('Failed to save syllabus: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openChapterDialog({SyllabusChapterItem? existing, int? index}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final marksCtrl = TextEditingController(text: existing != null && existing.marks > 0 ? existing.marks.toString() : '');
    final topicsCtrl = TextEditingController(text: existing?.topics ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                existing == null ? LucideIcons.plusCircle : LucideIcons.fileEdit,
                color: AppColors.brandPrimary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                existing == null ? 'Add Chapter' : 'Edit Chapter',
                style: AppTypography.titleLarge,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Specify chapter name and weightage for the exam.',
                  style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Chapter Name *',
                    hintText: 'e.g. Chapter 3: Practical Geometry',
                    filled: true,
                    fillColor: AppColors.canvasBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: marksCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Exam Weightage (Marks)',
                    hintText: 'e.g. 10',
                    suffixText: 'Marks',
                    filled: true,
                    fillColor: AppColors.canvasBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topicsCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Key Topics & Subtopics',
                    hintText: 'e.g. Angle sum property, types of quadrilaterals, theorem 3.1',
                    filled: true,
                    fillColor: AppColors.canvasBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final marks = int.tryParse(marksCtrl.text.trim()) ?? 0;
                final topics = topicsCtrl.text.trim();

                setState(() {
                  if (existing != null && index != null) {
                    _chapters[index] = existing.copyWith(
                      title: title,
                      marks: marks,
                      topics: topics,
                    );
                  } else {
                    _chapters.add(
                      SyllabusChapterItem(
                        id: 'chap-${DateTime.now().microsecondsSinceEpoch}',
                        title: title,
                        marks: marks,
                        topics: topics,
                      ),
                    );
                  }
                });

                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(existing == null ? 'Add Chapter' : 'Save Chapter'),
            ),
          ],
        );
      },
    );
  }

  void _deleteChapter(int index) {
    final deleted = _chapters[index];
    setState(() {
      _chapters.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${deleted.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _chapters.insert(index, deleted);
            });
          },
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _moveChapter(int from, int to) {
    if (to < 0 || to >= _chapters.length) return;
    setState(() {
      final item = _chapters.removeAt(from);
      _chapters.insert(to, item);
    });
  }

  IconData _getSubjectIcon(String? code) {
    final c = code?.toUpperCase() ?? '';
    if (c.contains('MATH')) return LucideIcons.calculator;
    if (c.contains('SCI') || c.contains('PHY') || c.contains('CHEM') || c.contains('BIO')) {
      return LucideIcons.flaskConical;
    }
    if (c.contains('ENG')) return LucideIcons.bookOpen;
    if (c.contains('HIN') || c.contains('SAN')) return LucideIcons.languages;
    if (c.contains('SST') || c.contains('ECO')) return LucideIcons.globe;
    if (c.contains('COMP') || c.contains('CS')) return LucideIcons.laptop;
    return LucideIcons.bookOpen;
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppColors.getSubjectColors(widget.subjectCode);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getSubjectIcon(widget.subjectCode), color: fg, size: 18),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${widget.subjectName} Syllabus', style: AppTypography.titleMedium),
                  Text(
                    '${widget.className} • Subject Teacher Portal',
                    style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isSaving
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary),
                    ),
                  )
                : TactileFeedback(
                    onTap: _saveSyllabus,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.save, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Save Live',
                            style: AppTypography.pillLabel.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Term Selector Horizontal Pills
                _buildTermSelectorBar(),

                // Main Scrollable Syllabus Form
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      // Header Stats Card
                      _buildHeaderInfoCard(bg, fg),

                      const SizedBox(height: 16),

                      // Editable Syllabus Title Card
                      _buildTitleEditorCard(),

                      const SizedBox(height: 16),

                      // Chapters Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.listOrdered, size: 18, color: AppColors.brandPrimary),
                              const SizedBox(width: 8),
                              Text('Chapters & Exam Weightages', style: AppTypography.titleMedium),
                            ],
                          ),
                          TactileFeedback(
                            onTap: () => _openChapterDialog(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.plus, size: 14, color: AppColors.brandPrimary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+ Add Chapter',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.brandPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Chapter List
                      if (_chapters.isEmpty)
                        _buildEmptyChaptersCard()
                      else
                        ...List.generate(_chapters.length, (idx) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildChapterCard(idx),
                          );
                        }),

                      const SizedBox(height: 20),

                      // Save Floating Action Banner
                      _buildSaveBanner(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTermSelectorBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _terms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final term = _terms[idx];
          final isSelected = _selectedTerm == term.key;

          return TactileFeedback(
            onTap: () => _onTermChanged(term.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandPrimary : AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.brandPrimary : AppColors.cardBorder,
                ),
              ),
              child: Center(
                child: Text(
                  term.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.inkPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderInfoCard(Color bg, Color fg) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_getSubjectIcon(widget.subjectCode), color: fg, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${widget.subjectName} (${widget.subjectCode})',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.className,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_chapters.length} Chapters • Total: $_totalMarks Marks in ${_getTermLabel(_selectedTerm)}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.inkSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Text(
                  '$_totalMarks',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandPrimary,
                  ),
                ),
                Text(
                  'MARKS',
                  style: AppTypography.monospace(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleEditorCard() {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Syllabus Title & Term Assignment', style: AppTypography.labelLarge),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Exam: ${_getTermLabel(_selectedTerm)}',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'e.g. Half Yearly Examination Syllabus (${widget.subjectName})',
              prefixIcon: const Icon(LucideIcons.fileText, size: 18, color: AppColors.inkMuted),
              filled: true,
              fillColor: AppColors.secondarySurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChaptersCard() {
    return BentoCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            const Icon(LucideIcons.bookOpenCheck, size: 40, color: AppColors.inkMuted),
            const SizedBox(height: 12),
            Text(
              'No chapters defined for ${_getTermLabel(_selectedTerm)}',
              style: AppTypography.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "+ Add Chapter" to add topics and weightage marks for this term.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openChapterDialog(),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add First Chapter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterCard(int index) {
    final chapter = _chapters[index];

    return BentoCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag/Index order indicator
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.inkPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Chapter details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        chapter.title,
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (chapter.marks > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.brandPrimary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '${chapter.marks} Marks',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (chapter.topics.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      chapter.topics,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.inkSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Actions Column
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.pencil, size: 16, color: AppColors.inkSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Edit Chapter',
                    onPressed: () => _openChapterDialog(existing: chapter, index: index),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Delete Chapter',
                    onPressed: () => _deleteChapter(index),
                  ),
                ],
              ),
              if (_chapters.length > 1)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index > 0)
                      IconButton(
                        icon: const Icon(LucideIcons.arrowUp, size: 14, color: AppColors.inkMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: () => _moveChapter(index, index - 1),
                      ),
                    if (index < _chapters.length - 1)
                      IconButton(
                        icon: const Icon(LucideIcons.arrowDown, size: 14, color: AppColors.inkMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: () => _moveChapter(index, index + 1),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.cloudCheck, color: AppColors.brandPrimary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Publish to Student Vault', style: AppTypography.titleSmall),
                Text(
                  'Students enrolled in ${widget.className} see updates immediately.',
                  style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveSyllabus,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save & Publish', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
