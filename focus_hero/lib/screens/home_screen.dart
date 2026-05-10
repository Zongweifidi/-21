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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
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
}

class _UserInfoHeader extends StatelessWidget {
  const _UserInfoHeader();

  @override
  Widget build(BuildContext context) {
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
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  profile.level.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
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
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: profile.exp / nextExp,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    Text(
                      "EXP ${profile.exp} / $nextExp",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

    return Column(
      children: [
        SizedBox(
          height: 300,
          width: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: timerProvider.secondsRemaining / (timerProvider.mode == 'focus' ? 25 * 60 : 5 * 60),
                strokeWidth: 10,
                backgroundColor: Colors.white10,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timerProvider.mode == 'focus' ? "专注中" : "休息中",
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  ),
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
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
            icon: const Icon(Icons.play_arrow),
            label: const Text("开始专注"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          )
        else
          Column(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                   showDialog(
                     context: context,
                     builder: (context) => AlertDialog(
                       title: const Text("放弃当前专注？"),
                       content: const Text("放弃后将不会获得经验奖励，也会中断今日连击。"),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
                         TextButton(
                           onPressed: () {
                             timerProvider.stopTimer(abandoned: true);
                             Navigator.pop(context);
                           },
                           child: const Text("确认放弃", style: TextStyle(color: Colors.red)),
                         ),
                       ],
                     ),
                   );
                },
                icon: const Icon(Icons.close),
                label: const Text("放弃"),
              ),
            ],
          ),
      ],
    );
  }
}
