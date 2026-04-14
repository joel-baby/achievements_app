import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/achievement.dart';
import '../models/goal.dart';
import '../theme/app_theme.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  const AchievementCard({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final lc = _levelColor(a.level);
    final lg = _levelGlow(a.level);
    final isLegend = a.level == GoalLevel.legend;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLegend ? AppColors.legend.withOpacity(0.5) : AppColors.border,
          width: isLegend ? 1.5 : 1,
        ),
        boxShadow: isLegend
            ? [
                BoxShadow(
                  color: AppColors.legend.withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional legend shimmer top stripe
          if (isLegend) _legendStripe(),

          _buildTop(a, lc, lg),
          _buildTitle(a),
          if (a.description.isNotEmpty) _buildDesc(a.description),
          const SizedBox(height: 12),
          _buildFooter(a, lc),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  Widget _legendStripe() {
    return Container(
      height: 3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF97316), Color(0xFFFBBF24)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  Widget _buildTop(Achievement a, Color lc, Color lg) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        children: [
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: lg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: lc.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.level.emoji, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text(
                  a.level.displayName,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: lc,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Completion date
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 13, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM d, yyyy').format(a.completedAt),
                style:
                    GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(Achievement a) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Text(
        a.title,
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
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildFooter(Achievement a, Color lc) {
    final days = a.daysTaken;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          _footerChip(
            Icons.calendar_today_rounded,
            'Started ${DateFormat('MMM d').format(a.startedAt)}',
            AppColors.textMuted,
            AppColors.bgDark,
          ),
          const SizedBox(width: 10),
          _footerChip(
            Icons.timer_outlined,
            days == 0 ? 'Same day' : '$days day${days == 1 ? '' : 's'}',
            lc,
            lc.withOpacity(0.12),
          ),
          if (a.type == GoalType.segmented) ...[
            const SizedBox(width: 10),
            _footerChip(
              Icons.check_box_rounded,
              '${a.segments.length} milestones',
              AppColors.accentCyan,
              AppColors.accentCyan.withOpacity(0.1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _footerChip(IconData icon, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
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
