import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';
import '../models/achievement.dart';

// ─── Filter ───────────────────────────────────────────────────────────────────

enum ShowcaseFilter { all, week, month, year }

extension ShowcaseFilterX on ShowcaseFilter {
  String get label {
    switch (this) {
      case ShowcaseFilter.all:   return 'All Time';
      case ShowcaseFilter.week:  return 'This Week';
      case ShowcaseFilter.month: return 'This Month';
      case ShowcaseFilter.year:  return 'This Year';
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

class AppProvider extends ChangeNotifier {
  List<Goal> _goals = [];
  List<Achievement> _achievements = [];
  ShowcaseFilter _filter = ShowcaseFilter.all;
  bool _isLoading = true;

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  ShowcaseFilter get filter => _filter;
  List<Goal> get goals => List.unmodifiable(_goals);
  List<Achievement> get allAchievements => List.unmodifiable(_achievements);

  List<Achievement> get filteredAchievements {
    final now = DateTime.now();
    final filtered = _achievements.where((a) {
      switch (_filter) {
        case ShowcaseFilter.all:
          return true;
        case ShowcaseFilter.week:
          return now.difference(a.completedAt).inDays <= 7;
        case ShowcaseFilter.month:
          return a.completedAt.year == now.year &&
              a.completedAt.month == now.month;
        case ShowcaseFilter.year:
          return a.completedAt.year == now.year;
      }
    }).toList();
    filtered.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return filtered;
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final goalsJson = prefs.getString('goals');
    if (goalsJson != null) {
      final list = jsonDecode(goalsJson) as List<dynamic>;
      _goals = list
          .map((g) => Goal.fromJson(g as Map<String, dynamic>))
          .toList();
    }

    final achJson = prefs.getString('achievements');
    if (achJson != null) {
      final list = jsonDecode(achJson) as List<dynamic>;
      _achievements = list
          .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'goals',
      jsonEncode(_goals.map((g) => g.toJson()).toList()),
    );
  }

  Future<void> _saveAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'achievements',
      jsonEncode(_achievements.map((a) => a.toJson()).toList()),
    );
  }

  // ── Goal actions ───────────────────────────────────────────────────────────

  Future<void> addGoal(Goal goal) async {
    _goals.insert(0, goal);
    notifyListeners();
    await _saveGoals();
  }

  Future<void> updateGoal(Goal updated) async {
    final idx = _goals.indexWhere((g) => g.id == updated.id);
    if (idx == -1) return;
    _goals[idx] = updated;
    notifyListeners();
    await _saveGoals();
  }

  Future<void> toggleSegment(String goalId, String segmentId) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final seg = goal.segments.firstWhere((s) => s.id == segmentId);
    seg.completed = !seg.completed;
    notifyListeners();
    await _saveGoals();
  }

  Future<void> completeGoal(String goalId) async {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return;
    final goal = _goals.removeAt(idx);
    _achievements.insert(0, Achievement.fromGoal(goal));
    notifyListeners();
    await _saveGoals();
    await _saveAchievements();
  }

  Future<void> discardGoal(String goalId) async {
    _goals.removeWhere((g) => g.id == goalId);
    notifyListeners();
    await _saveGoals();
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  void setFilter(ShowcaseFilter f) {
    if (_filter == f) return;
    _filter = f;
    notifyListeners();
  }
}
