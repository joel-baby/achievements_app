import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'add_edit_goal_sheet.dart';

class GoalCard extends StatefulWidget {
  final Goal goal;
  const GoalCard({super.key, required this.goal});

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Re-read from provider so the card updates when state changes.
    final provider = context.watch<AppProvider>();
    final goal = provider.goals.firstWhere(
      (g) => g.id == widget.goal.id,
      orElse: () => widget.goal,
    );

    final levelColor = _levelColor(goal.level);
    final levelGlow = _levelGlow(goal.level);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(goal, levelColor, levelGlow),
              _buildTitle(goal),
              if (goal.description.isNotEmpty) _buildDesc(goal.description),
              const SizedBox(height: 4),
              if (goal.type == GoalType.segmented)
                _buildSegmentedBody(goal, context)
              else
                _buildSimpleBody(goal, context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(Goal goal, Color levelColor, Color levelGlow) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 0),
      child: Row(
        children: [
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: levelGlow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: levelColor.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(goal.level.emoji,
                    style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text(
                  goal.level.displayName,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: levelColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Type tag
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              goal.type == GoalType.simple ? '· Simple' : '· Staged',
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.textMuted),
            ),
          ),
          const Spacer(),
          _buildMenu(goal),
        ],
      ),
    );
  }

  Widget _buildTitle(Goal goal) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Text(
        goal.title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDesc(String desc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Text(
        desc,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style:
            GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
      ),
    );
  }

  // ── Simple body ────────────────────────────────────────────────────────────

  Widget _buildSimpleBody(Goal goal, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: _completeButton(enabled: true, onTap: () => _confirmComplete(goal, context)),
    );
  }

  // ── Segmented body ─────────────────────────────────────────────────────────

  Widget _buildSegmentedBody(Goal goal, BuildContext context) {
    final done = goal.completedSegments;
    final total = goal.segments.length;
    final progress = goal.progress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),

        // Progress label + bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$done / $total milestones',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text(
                      '${(v * 100).round()}%',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: progress == 1.0
                            ? AppColors.success
                            : AppColors.accentVioletLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _progressBar(progress),
            ],
          ),
        ),

        // Segment tiles
        if (goal.segments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
            child: Column(
              children: goal.segments
                  .map((s) => _segmentTile(s, goal, context))
                  .toList(),
            ),
          ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: _completeButton(
            enabled: goal.canComplete,
            onTap: () => _confirmComplete(goal, context),
          ),
        ),
      ],
    );
  }

  Widget _progressBar(double progress) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            height: 6,
            width: constraints.maxWidth * progress,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: progress == 1.0
                    ? [AppColors.success, const Color(0xFF34D399)]
                    : [AppColors.accentViolet, AppColors.accentCyan],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      );
    });
  }

  Widget _segmentTile(GoalSegment seg, Goal goal, BuildContext context) {
    return InkWell(
      onTap: () => context.read<AppProvider>().toggleSegment(goal.id, seg.id),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: seg.completed
                    ? AppColors.accentViolet
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: seg.completed
                      ? AppColors.accentViolet
                      : AppColors.borderLight,
                  width: 1.5,
                ),
              ),
              child: seg.completed
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                seg.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: seg.completed
                      ? AppColors.textMuted
                      : AppColors.textSecondary,
                  decoration: seg.completed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Complete button ────────────────────────────────────────────────────────

  Widget _completeButton(
      {required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [AppColors.accentViolet, Color(0xFF9F67FF)],
                  )
                : null,
            color: enabled ? null : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Mark Complete',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Menu ───────────────────────────────────────────────────────────────────

  Widget _buildMenu(Goal goal) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          color: AppColors.textMuted, size: 20),
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      offset: const Offset(0, 36),
      itemBuilder: (_) => [
        _menuItem('edit', Icons.edit_outlined, 'Edit'),
        _menuItem('discard', Icons.delete_outline_rounded, 'Discard',
            isDestructive: true),
      ],
      onSelected: (val) {
        if (val == 'edit') _openEdit(goal);
        if (val == 'discard') _confirmDiscard(goal);
      },
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 15,
              color: isDestructive ? AppColors.error : AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDestructive ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _confirmComplete(Goal goal, BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Journey?'),
        content: Text(
          '"${goal.title}" will be moved to your Showcase. Great work!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Not Yet',
                style: GoogleFonts.outfit(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().completeGoal(goal.id);
              Navigator.pop(ctx);
            },
            child: Text(
              'Complete ✓',
              style: GoogleFonts.outfit(
                  color: AppColors.accentViolet,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDiscard(Goal goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Journey?'),
        content: Text(
          'All progress on "${goal.title}" will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Going',
                style: GoogleFonts.outfit(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().discardGoal(goal.id);
              Navigator.pop(ctx);
            },
            child: Text(
              'Discard',
              style: GoogleFonts.outfit(
                  color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _openEdit(Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditGoalSheet(existingGoal: goal),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _levelColor(GoalLevel l) {
    switch (l) {
      case GoalLevel.spark:  return AppColors.spark;
      case GoalLevel.grind:  return AppColors.grind;
      case GoalLevel.hustle: return AppColors.hustle;
      case GoalLevel.elite:  return AppColors.elite;
      case GoalLevel.legend: return AppColors.legend;
    }
  }

  Color _levelGlow(GoalLevel l) {
    switch (l) {
      case GoalLevel.spark:  return AppColors.sparkGlow;
      case GoalLevel.grind:  return AppColors.grindGlow;
      case GoalLevel.hustle: return AppColors.hustleGlow;
      case GoalLevel.elite:  return AppColors.eliteGlow;
      case GoalLevel.legend: return AppColors.legendGlow;
    }
  }
}
