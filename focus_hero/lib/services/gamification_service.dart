import 'dart:math';
import '../models/profile.dart';
import '../models/tomato_session.dart';
import '../models/achievement.dart';
import 'database_service.dart';
import 'package:uuid/uuid.dart';

class GamificationService {
  final DatabaseService _dbService = DatabaseService();
  final _uuid = const Uuid();

  int getNextLevelExp(int currentLevel) {
    return (300 * pow(1.5, currentLevel - 1)).round();
  }

  String getTitle(int level) {
    if (level >= 20) return '传说番茄王';
    if (level >= 10) return '时间法师';
    if (level >= 5) return '专注骑士';
    return '新手学徒';
  }

  Future<Map<String, dynamic>> completeSession(int duration, bool interrupted) async {
    Profile profile = await _dbService.getProfile();
    List<TomatoSession> allSessions = await _dbService.getAllSessions();
    DateTime now = DateTime.now();
    String todayStr = "${now.year}-${now.month}-${now.day}";

    bool hasInterruptionToday = false;
    for (var s in allSessions) {
      if (s.completedAt.startsWith(todayStr) && s.interrupted) {
        hasInterruptionToday = true;
        break;
      }
    }

    int expGained = 0;
    if (!interrupted) {
      expGained += 100; // Base reward
      if (!hasInterruptionToday) {
        expGained += 50; // Continuous bonus
      }
    }

    await _dbService.insertSession(TomatoSession(
      id: _uuid.v4(),
      completedAt: now.toIso8601String(),
      duration: duration,
      interrupted: interrupted,
    ));

    if (interrupted) {
      return {'expGained': 0, 'leveledUp': false, 'newAchievements': []};
    }

    int newExp = profile.exp + expGained;
    int newLevel = profile.level;
    bool leveledUp = false;

    while (newExp >= getNextLevelExp(newLevel)) {
      newExp -= getNextLevelExp(newLevel);
      newLevel++;
      leveledUp = true;
    }

    int newTotalTomatoes = profile.totalTomatoes + 1;

    Profile updatedProfile = Profile(
      id: 1,
      username: profile.username,
      level: newLevel,
      exp: newExp,
      totalTomatoes: newTotalTomatoes,
      maxStreak: profile.maxStreak,
      updatedAt: now.toIso8601String(),
    );

    await _dbService.updateProfile(updatedProfile);

    List<Achievement> currentAchievements = await _dbService.getAchievements();
    Set<String> unlockedKeys = currentAchievements.map((e) => e.achievementKey).toSet();
    List<String> newAchievementKeys = [];

    if (newTotalTomatoes >= 1 && !unlockedKeys.contains('first_tomato')) {
      newAchievementKeys.add('first_tomato');
    }

    allSessions = await _dbService.getAllSessions();
    int consecutiveToday = 0;
    for (var s in allSessions) {
      if (s.completedAt.startsWith(todayStr)) {
        if (!s.interrupted) {
          consecutiveToday++;
          if (consecutiveToday >= 3) break;
        } else {
          consecutiveToday = 0;
          break;
        }
      } else {
        break;
      }
    }

    if (consecutiveToday >= 3 && !unlockedKeys.contains('on_fire')) {
      newAchievementKeys.add('on_fire');
    }

    int todayTotal = 0;
    for (var s in allSessions) {
       if (s.completedAt.startsWith(todayStr) && !s.interrupted) todayTotal++;
    }
    if (todayTotal >= 8 && !unlockedKeys.contains('daily_hero')) {
      newAchievementKeys.add('daily_hero');
    }

    if (newTotalTomatoes >= 50 && !unlockedKeys.contains('dragon_slayer')) {
      newAchievementKeys.add('dragon_slayer');
    }

    if (now.hour >= 23 && !unlockedKeys.contains('night_owl')) {
      newAchievementKeys.add('night_owl');
    }

    if (!unlockedKeys.contains('perfectionist')) {
       if (await _checkPerfectionist(allSessions)) {
          newAchievementKeys.add('perfectionist');
       }
    }

    for (var key in newAchievementKeys) {
      await _dbService.insertAchievement(Achievement(
        id: _uuid.v4(),
        achievementKey: key,
        unlockedAt: now.toIso8601String(),
      ));
    }

    return {
      'expGained': expGained,
      'leveledUp': leveledUp,
      'newAchievements': newAchievementKeys,
    };
  }

  Future<bool> _checkPerfectionist(List<TomatoSession> sessions) async {
    Map<String, int> dailyCounts = {};
    for (var s in sessions) {
      if (!s.interrupted) {
        String day = s.completedAt.substring(0, 10);
        dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
      }
    }

    int consecutiveDays = 0;
    List<String> sortedDays = dailyCounts.keys.toList()..sort((a, b) => b.compareTo(a));

    if (sortedDays.isEmpty) return false;

    for (int i = 0; i < sortedDays.length; i++) {
       if (dailyCounts[sortedDays[i]]! >= 4) {
          consecutiveDays++;
          if (consecutiveDays >= 7) return true;

          if (i + 1 < sortedDays.length) {
             DateTime current = DateTime.parse(sortedDays[i]);
             DateTime next = DateTime.parse(sortedDays[i+1]);
             if (current.difference(next).inDays != 1) {
                consecutiveDays = 0;
             }
          }
       } else {
          consecutiveDays = 0;
       }
    }
    return false;
  }
}
