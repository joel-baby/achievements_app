import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/achievement_card.dart';
import '../widgets/filter_pill_bar.dart';

class ShowcaseTab extends StatelessWidget {
  const ShowcaseTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentViolet),
          );
        }

        final achievements = provider.filteredAchievements;
        final total = provider.allAchievements.length;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(total, achievements.length)),

            // Stats chips
            if (total > 0)
              SliverToBoxAdapter(child: _buildStats(provider)),

            // Filter bar
            if (total > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: const FilterPillBar(),
                ),
              ),

            // Section divider
            if (total > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(height: 1, color: AppColors.border),
                ),
              ),

            // List or empty state
            if (achievements.isEmpty && total == 0)
              SliverFillRemaining(child: _buildEmptyState())
            else if (achievements.isEmpty)
              SliverFillRemaining(child: _buildFilterEmptyState(provider))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => AchievementCard(
                      key: ValueKey(achievements[index].id),
                      achievement: achievements[index],
                    ),
                    childCount: achievements.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(int total, int visible) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Showcase',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              if (total > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentGoldGlow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
                  ),
                  child: Text(
                    '$total',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentGold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'Your completed journeys will appear here.'
                : 'Every win tells your story.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(AppProvider provider) {
    final all = provider.allAchievements;
    final now = DateTime.now();
    final thisMonth = all
        .where((a) =>
            a.completedAt.year == now.year &&
            a.completedAt.month == now.month)
        .length;
    final avgDays = all.isEmpty
        ? 0
        : (all.fold(0, (sum, a) => sum + a.daysTaken) / all.length).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          _chip('🏆', '${all.length}', 'Total',
              AppColors.accentGold, AppColors.accentGoldGlow),
          const SizedBox(width: 10),
          _chip('📅', '$thisMonth', 'This Month',
              AppColors.accentCyan, AppColors.accentCyan.withOpacity(0.12)),
          const SizedBox(width: 10),
          _chip('⚡', '${avgDays}d', 'Avg Time',
              AppColors.accentVioletLight, AppColors.accentVioletGlow),
        ],
      ),
    );
  }

  Widget _chip(
      String emoji, String value, String label, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentGold.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No achievements yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first journey in the Progress tab and watch your showcase grow.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterEmptyState(AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 16),
            Text(
              'Nothing here',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No achievements for ${provider.filter.label.toLowerCase()}.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => provider.setFilter(ShowcaseFilter.all),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentVioletGlow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentViolet.withOpacity(0.4)),
                ),
                child: Text(
                  'Show All',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentVioletLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
