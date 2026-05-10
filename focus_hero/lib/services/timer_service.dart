import 'dart:async';
import 'dart:isolate';
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
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    final prefs = await SharedPreferences.getInstance();
    _secondsRemaining = prefs.getInt('secondsRemaining') ?? 0;
    _mode = prefs.getString('timerMode') ?? 'focus';

    _startTimer(sendPort);
  }

  void _startTimer(SendPort? sendPort) {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        _updateNotification(sendPort);
        _saveState();
      } else {
        _onFinished(sendPort);
        timer.cancel();
      }
    });
  }

  void _updateNotification(SendPort? sendPort) {
    String title = _mode == 'focus' ? '正在专注中...' : '休息时间';
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    String timeStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: "剩余时间: $timeStr",
    );

    // Send data to main isolate
    sendPort?.send(_secondsRemaining);
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('secondsRemaining', _secondsRemaining);
  }

  void _onFinished(SendPort? sendPort) {
    FlutterForegroundTask.updateService(
      notificationTitle: '时间到！',
      notificationText: _mode == 'focus' ? '太棒了，完成了一个番茄！' : '休息结束，准备开始下一个番茄吗？',
    );
    sendPort?.send(-1); // -1 signifies finished
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {}

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) {
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
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: false,
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
