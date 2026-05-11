import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TimerHandler());
}

class TimerHandler extends TaskHandler {
  int _secondsRemaining = 0;
  String _mode = 'focus'; // focus, shortBreak, longBreak
  Timer? _timer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final prefs = await SharedPreferences.getInstance();
    _secondsRemaining = prefs.getInt('secondsRemaining') ?? 0;
    _mode = prefs.getString('timerMode') ?? 'focus';

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        _updateNotification();
        _saveState();
      } else {
        _onFinished();
        timer.cancel();
      }
    });
  }

  void _updateNotification() {
    String title = _mode == 'focus' ? '正在专注中...' : '休息时间';
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    String timeStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: "剩余时间: $timeStr",
    );

    // Send data to main isolate
    FlutterForegroundTask.sendDataToMain(_secondsRemaining);
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('secondsRemaining', _secondsRemaining);
  }

  void _onFinished() {
    FlutterForegroundTask.updateService(
      notificationTitle: '时间到！',
      notificationText: _mode == 'focus' ? '太棒了，完成了一个番茄！' : '休息结束，准备开始下一个番茄吗？',
    );
    FlutterForegroundTask.sendDataToMain(-1); // -1 signifies finished
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _timer?.cancel();
  }
}

class TimerService {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'focus_hero_timer',
        channelName: 'Focus Hero Timer',
        channelDescription: 'Countdown timer for focus sessions',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start(int seconds, String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('secondsRemaining', seconds);
    await prefs.setString('timerMode', mode);
    await prefs.setBool('isTimerActive', true);

    if (await FlutterForegroundTask.isRunningService) {
      // Just update if already running
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: '准备开始',
        notificationText: '倒计时即将开始',
        callback: startCallback,
      );
    }
  }

  static Future<void> stop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTimerActive', false);
    await FlutterForegroundTask.stopService();
  }
}
