import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/achievement.dart';
import '../models/tomato_session.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("成就与数据")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SummaryCards(),
          const SizedBox(height: 30),
          Text("已解锁成就", style: Theme.of(context).textTheme.titleLarge),
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
    return FutureBuilder(
      future: Future.wait([
        DatabaseService().getAllSessions(),
        DatabaseService().getProfile(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final List<TomatoSession> sessions = snapshot.data![0];
        final profile = snapshot.data![1];

        final totalCount = profile.totalTomatoes;
        final weekCount = sessions.where((s) {
          final date = DateTime.parse(s.completedAt);
          return !s.interrupted && date.isAfter(DateTime.now().subtract(const Duration(days: 7)));
        }).length;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _StatCard(label: "累计番茄", value: "$totalCount", icon: Icons.workspace_premium),
            _StatCard(label: "本周专注", value: "$weekCount", icon: Icons.calendar_today),
            _StatCard(label: "最高等级", value: "Lv ${profile.level}", icon: Icons.trending_up),
            _StatCard(label: "当前状态", value: "专注中", icon: Icons.flash_on),
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

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  const _AchievementGrid();

  static const Map<String, Map<String, String>> achievementMeta = {
    'first_tomato': {'name': '首秀', 'desc': '完成第 1 个番茄'},
    'on_fire': {'name': '火力全开', 'desc': '今日连续 3 个不中断'},
    'daily_hero': {'name': '今日英雄', 'desc': '今日完成 8 个'},
    'dragon_slayer': {'name': '屠龙者', 'desc': '累计完成 50 个'},
    'night_owl': {'name': '熬夜猫', 'desc': '深夜 23:00 后完成'},
    'perfectionist': {'name': '完美主义', 'desc': '连续 7 天每天 ≥ 4 个'},
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
            childAspectRatio: 2.5,
          ),
          itemCount: achievementMeta.length,
          itemBuilder: (context, index) {
            final key = achievementMeta.keys.elementAt(index);
            final meta = achievementMeta[key]!;
            final isUnlocked = unlocked.contains(key);

            return Card(
              color: isUnlocked ? Colors.blueGrey.withValues(alpha: 0.3) : Colors.black26,
              child: ListTile(
                leading: Icon(
                  isUnlocked ? Icons.check_circle : Icons.lock,
                  color: isUnlocked ? Colors.greenAccent : Colors.white24,
                ),
                title: Text(meta['name']!, style: TextStyle(fontSize: 14, fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text(meta['desc']!, style: const TextStyle(fontSize: 10)),
              ),
            );
          },
        );
      },
    );
  }
}
