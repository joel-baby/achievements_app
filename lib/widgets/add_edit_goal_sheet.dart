import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class AddEditGoalSheet extends StatefulWidget {
  final Goal? existingGoal;
  const AddEditGoalSheet({super.key, this.existingGoal});

  @override
  State<AddEditGoalSheet> createState() => _AddEditGoalSheetState();
}

class _AddEditGoalSheetState extends State<AddEditGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  final TextEditingController _segCtrl = TextEditingController();

  late GoalType _type;
  late GoalLevel _level;
  late List<GoalSegment> _segments;

  bool get _isEditing => widget.existingGoal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.existingGoal;
    _titleCtrl = TextEditingController(text: g?.title ?? '');
    _descCtrl = TextEditingController(text: g?.description ?? '');
    _type = g?.type ?? GoalType.simple;
    _level = g?.level ?? GoalLevel.spark;
    // Deep-copy segments so edits don't mutate provider state directly
    _segments = g?.segments
            .map((s) => GoalSegment(id: s.id, title: s.title, completed: s.completed))
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _segCtrl.dispose();
    super.dispose();
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  void _addSegment() {
    final t = _segCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _segments.add(GoalSegment(title: t));
      _segCtrl.clear();
    });
  }

  void _removeSegment(int i) => setState(() => _segments.removeAt(i));

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Validate segments for staged type
    if (_type == GoalType.segmented && _segments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            'Add at least one milestone for a Staged journey.',
            style: GoogleFonts.inter(color: AppColors.textPrimary),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();

    if (_isEditing) {
      provider.updateGoal(Goal(
        id: widget.existingGoal!.id,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        type: _type,
        level: _level,
        createdAt: widget.existingGoal!.createdAt,
        segments: _type == GoalType.segmented ? _segments : [],
      ));
    } else {
      provider.addGoal(Goal(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        type: _type,
        level: _level,
        segments: _type == GoalType.segmented ? _segments : [],
      ));
    }

    Navigator.pop(context);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      // Rounded top corners + dark background
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        minChildSize: 0.55,
        expand: false,
        builder: (context, scroller) => Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHandle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scroller,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSheetHeader(),
                      const SizedBox(height: 24),
                      _section('Title'),
                      const SizedBox(height: 8),
                      _titleField(),
                      const SizedBox(height: 18),
                      _section('Description (optional)'),
                      const SizedBox(height: 8),
                      _descField(),
                      const SizedBox(height: 24),
                      _section('Type'),
                      const SizedBox(height: 12),
                      _typeSelector(),
                      const SizedBox(height: 24),
                      _section('Level'),
                      const SizedBox(height: 12),
                      _levelSelector(),
                      if (_type == GoalType.segmented) ...[
                        const SizedBox(height: 24),
                        _buildSegmentHeader(),
                        const SizedBox(height: 12),
                        ..._buildSegmentList(),
                        const SizedBox(height: 10),
                        _segmentInput(),
                      ],
                      const SizedBox(height: 32),
                      _saveButton(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing ? 'Edit Journey' : 'New Journey',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isEditing
              ? 'Adjust the path. Progress is preserved.'
              : 'Define what you want to achieve.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
        ),
      ],
    );
  }

  // ── Fields ─────────────────────────────────────────────────────────────────

  Widget _section(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _titleField() {
    return TextFormField(
      controller: _titleCtrl,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        hintText: 'What do you want to achieve?',
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Title cannot be empty' : null,
    );
  }

  Widget _descField() {
    return TextFormField(
      controller: _descCtrl,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        hintText: 'Why does this matter to you?',
      ),
    );
  }

  // ── Type selector ──────────────────────────────────────────────────────────

  Widget _typeSelector() {
    return Row(
      children: [
        Expanded(
          child: _typeOption(
            GoalType.simple,
            Icons.check_circle_outline_rounded,
            'Simple',
            'Single action to complete',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _typeOption(
            GoalType.segmented,
            Icons.view_week_outlined,
            'Staged',
            'Complete milestone by milestone',
          ),
        ),
      ],
    );
  }

  Widget _typeOption(
      GoalType type, IconData icon, String label, String subtitle) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentViolet.withOpacity(0.12)
              : AppColors.bgDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accentViolet : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? AppColors.accentVioletLight
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.accentVioletLight
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ── Level selector ─────────────────────────────────────────────────────────

  Widget _levelSelector() {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: GoalLevel.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final level = GoalLevel.values[i];
          final selected = _level == level;
          final lc = _lColor(level);
          return GestureDetector(
            onTap: () => setState(() => _level = level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 82,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? lc.withOpacity(0.14) : AppColors.bgDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? lc : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    level.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? lc : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Segment editor ─────────────────────────────────────────────────────────

  Widget _buildSegmentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _section('Milestones'),
        if (_segments.isNotEmpty)
          Text(
            '${_segments.length} added',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
      ],
    );
  }

  List<Widget> _buildSegmentList() {
    return _segments.asMap().entries.map((entry) {
      final idx = entry.key;
      final seg = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              seg.completed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 15,
              color: seg.completed
                  ? AppColors.accentViolet
                  : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                seg.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: seg.completed
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  decoration: seg.completed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: AppColors.textMuted,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _removeSegment(idx),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _segmentInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _segCtrl,
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontSize: 14),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Add a milestone…',
              filled: true,
              fillColor: AppColors.bgDark,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.accentViolet, width: 1.5),
              ),
            ),
            onSubmitted: (_) => _addSegment(),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _addSegment,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.accentViolet,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_rounded,
                color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  // ── Save button ────────────────────────────────────────────────────────────

  Widget _saveButton() {
    return GestureDetector(
      onTap: _save,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accentViolet, Color(0xFF9F67FF)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentViolet.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          _isEditing ? 'Save Changes' : 'Start Journey',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Level color helper ─────────────────────────────────────────────────────

  Color _lColor(GoalLevel l) {
    switch (l) {
      case GoalLevel.spark:  return AppColors.spark;
      case GoalLevel.grind:  return AppColors.grind;
      case GoalLevel.hustle: return AppColors.hustle;
      case GoalLevel.elite:  return AppColors.elite;
      case GoalLevel.legend: return AppColors.legend;
    }
  }
}
