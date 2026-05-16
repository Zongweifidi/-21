import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/achievement.dart';
import '../models/tomato_session.dart';
import '../providers/timer_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("成就与统计"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SummaryCards(),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text("荣誉勋章", style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 15),
          const _AchievementGrid(),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards();

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<TimerProvider>();

    return FutureBuilder(
      future: Future.wait([
        DatabaseService().getAllSessions(),
        DatabaseService().getProfile(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final List<TomatoSession> sessions = snapshot.data![0];
        final profile = snapshot.data![1];

        final totalCount = profile.totalTomatoes;
        final now = DateTime.now();
        final weekCount = sessions.where((s) {
          final date = DateTime.parse(s.completedAt);
          return !s.interrupted && now.difference(date).inDays < 7;
        }).length;

        String statusText = timerProvider.isRunning ? "专注中" : "待机中";
        if (timerProvider.isRunning && timerProvider.mode != 'focus') {
          statusText = "休息中";
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _StatCard(label: "累计番茄", value: "$totalCount", icon: Icons.workspace_premium, color: Colors.orange),
            _StatCard(label: "本周专注", value: "$weekCount", icon: Icons.calendar_month, color: Colors.blue),
            _StatCard(label: "当前等级", value: "Lv ${profile.level}", icon: Icons.trending_up, color: Colors.purple),
            _StatCard(label: "目前状态", value: statusText, icon: Icons.bolt, color: Colors.green),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  const _AchievementGrid();

  static const Map<String, Map<String, String>> achievementMeta = {
    'first_tomato': {'name': '初露锋芒', 'desc': '完成第 1 个番茄'},
    'on_fire': {'name': '手感火热', 'desc': '连续 3 个不中断'},
    'daily_hero': {'name': '今日英雄', 'desc': '单日完成 8 个'},
    'dragon_slayer': {'name': '专注大师', 'desc': '累计完成 50 个'},
    'night_owl': {'name': '深夜极客', 'desc': '23:00 后完成'},
    'perfectionist': {'name': '完美主义', 'desc': '连续 7 天 ≥ 4 个'},
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Achievement>>(
      future: DatabaseService().getAchievements(),
      builder: (context, snapshot) {
        final unlocked = snapshot.data?.map((e) => e.achievementKey).toSet() ?? {};

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: achievementMeta.length,
          itemBuilder: (context, index) {
            final key = achievementMeta.keys.elementAt(index);
            final meta = achievementMeta[key]!;
            final isUnlocked = unlocked.contains(key);

            return Card(
              elevation: 0,
              color: isUnlocked ? Colors.orange.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isUnlocked ? Colors.orange.withValues(alpha: 0.3) : Colors.transparent,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      isUnlocked ? Icons.verified : Icons.lock_outline,
                      color: isUnlocked ? Colors.orange : Colors.white24,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta['name']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                              color: isUnlocked ? Colors.white : Colors.white38,
                            ),
                          ),
                          Text(
                            meta['desc']!,
                            style: TextStyle(fontSize: 10, color: isUnlocked ? Colors.white70 : Colors.white24),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
