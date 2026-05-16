import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TimerHandler());
}

class TimerHandler extends TaskHandler {
  int _secondsRemaining = 0;
  String _mode = 'focus';
  Timer? _timer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final prefs = await SharedPreferences.getInstance();
    _secondsRemaining = prefs.getInt('secondsRemaining') ?? 0;
    _mode = prefs.getString('timerMode') ?? 'focus';

    _startTimer();
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map<String, dynamic>) {
       if (data.containsKey('secondsRemaining')) {
         _secondsRemaining = data['secondsRemaining'];
       }
       if (data.containsKey('mode')) {
         _mode = data['mode'];
       }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        _updateNotification();
        if (_secondsRemaining % 10 == 0) {
           _saveState();
        }
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

    FlutterForegroundTask.sendDataToMain(_secondsRemaining);
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('secondsRemaining', _secondsRemaining);
  }

  void _onFinished() {
    String finishTitle = _mode == 'focus' ? '专注完成！' : '休息结束！';
    String finishText = _mode == 'focus' ? '太棒了，完成了一个番茄！' : '准备开始下一个番茄吗？';

    FlutterForegroundTask.updateService(
      notificationTitle: finishTitle,
      notificationText: finishText,
    );
    FlutterForegroundTask.sendDataToMain(-1);
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _timer?.cancel();
    await _saveState();
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
      FlutterForegroundTask.sendDataToTask({
        'secondsRemaining': seconds,
        'mode': mode,
      });
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: '专注英雄',
        notificationText: '计时器准备中...',
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
