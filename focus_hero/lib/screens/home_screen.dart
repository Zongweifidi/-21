import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../services/gamification_service.dart';
import '../services/database_service.dart';
import '../models/profile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen for session completion to show feedback
    final lastResult = context.watch<TimerProvider>().lastSessionResult;
    if (lastResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCompletionFeedback(context, lastResult);
        context.read<TimerProvider>().clearLastResult();
      });
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const _UserInfoHeader(),
              const Spacer(),
              const _TimerDisplay(),
              const Spacer(),
              const _TimerActions(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletionFeedback(BuildContext context, Map<String, dynamic> result) {
    final bool leveledUp = result['leveledUp'] ?? false;
    final List<String> achievements = List<String>.from(result['newAchievements'] ?? []);
    final int exp = result['expGained'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              leveledUp ? "升级了！" : "专注完成",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("获得 EXP +$exp", style: const TextStyle(fontSize: 18, color: Colors.orangeAccent)),
            if (achievements.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text("解锁成就：", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: achievements.map((a) => Chip(label: Text(a), backgroundColor: Colors.deepOrange.withValues(alpha: 0.2))).toList(),
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("太棒了"),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserInfoHeader extends StatelessWidget {
  const _UserInfoHeader();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: Stream.periodic(const Duration(seconds: 5)), // Refresh profile periodically or use a provider
      builder: (context, _) {
        return FutureBuilder<Profile>(
          future: DatabaseService().getProfile(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 100);
            final profile = snapshot.data!;
            final gamification = GamificationService();
            final nextExp = gamification.getNextLevelExp(profile.level);
            final title = gamification.getTitle(profile.level);

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        profile.level.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.username,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          title,
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: profile.exp / nextExp,
                            minHeight: 6,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "EXP ${profile.exp} / $nextExp",
                          style: const TextStyle(fontSize: 10, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay();

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<TimerProvider>();
    final int minutes = timerProvider.secondsRemaining ~/ 60;
    final int seconds = timerProvider.secondsRemaining % 60;
    final String timeStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    double totalSeconds;
    if (timerProvider.mode == 'focus') {
      totalSeconds = 25 * 60;
    } else if (timerProvider.mode == 'shortBreak') {
      totalSeconds = 5 * 60;
    } else {
      totalSeconds = 15 * 60;
    }

    double progress = timerProvider.secondsRemaining / totalSeconds;

    return Column(
      children: [
        SizedBox(
          height: 280,
          width: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: progress, end: progress),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 12,
                  backgroundColor: Colors.white10,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getModeText(timerProvider.mode),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getModeText(String mode) {
    switch (mode) {
      case 'focus': return "专注中";
      case 'shortBreak': return "短休息";
      case 'longBreak': return "长休息";
      default: return "专注中";
    }
  }
}

class _TimerActions extends StatelessWidget {
  const _TimerActions();

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<TimerProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!timerProvider.isRunning)
          ElevatedButton.icon(
            onPressed: () => timerProvider.startTimer(),
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: const Text("开始专注", style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
          )
        else
          IconButton.filledTonal(
            onPressed: () {
               showDialog(
                 context: context,
                 builder: (context) => AlertDialog(
                   title: const Text("中止专注？"),
                   content: const Text("中止后将无法获得本轮奖励。"),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(context), child: const Text("继续")),
                     TextButton(
                       onPressed: () {
                         timerProvider.stopTimer(abandoned: true);
                         Navigator.pop(context);
                       },
                       child: const Text("确定中止", style: TextStyle(color: Colors.redAccent)),
                     ),
                   ],
                 ),
               );
            },
            icon: const Icon(Icons.stop_rounded, size: 32),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(20),
            ),
          ),
      ],
    );
  }
}
