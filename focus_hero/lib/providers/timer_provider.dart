import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../services/timer_service.dart';
import '../services/gamification_service.dart';
import '../services/database_service.dart';

class TimerProvider with ChangeNotifier {
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  String _mode = 'focus'; // focus, shortBreak, longBreak
  int _completedToday = 0;

  final GamificationService _gamificationService = GamificationService();
  final DatabaseService _dbService = DatabaseService();

  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  String get mode => _mode;
  int get completedToday => _completedToday;

  TimerProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    bool wasActive = prefs.getBool('isTimerActive') ?? false;
    String? lastMode = prefs.getString('timerMode');

    if (wasActive && lastMode == 'focus') {
      await _gamificationService.completeSession(0, true);
      await prefs.setBool('isTimerActive', false);
    }

    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    await _loadStats();
  }

  void _onReceiveTaskData(dynamic data) {
    if (data is int) {
      if (data == -1) {
        _onFinished();
      } else {
        _secondsRemaining = data;
        _isRunning = true;
        notifyListeners();
      }
    }
  }

  Future<void> _loadStats() async {
    final sessions = await _dbService.getAllSessions();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    _completedToday = sessions.where((s) => !s.interrupted && s.completedAt.startsWith(today)).length;
    notifyListeners();
  }

  Future<void> startTimer() async {
    _isRunning = true;
    int duration = _mode == 'focus' ? 25 * 60 : (_mode == 'shortBreak' ? 5 * 60 : 15 * 60);
    _secondsRemaining = duration;
    await TimerService.start(_secondsRemaining, _mode);
    notifyListeners();
  }

  Future<void> stopTimer({bool abandoned = false}) async {
    _isRunning = false;
    await TimerService.stop();

    if (abandoned && _mode == 'focus') {
      await _gamificationService.completeSession(0, true);
    }

    int duration = _mode == 'focus' ? 25 * 60 : (_mode == 'shortBreak' ? 5 * 60 : 15 * 60);
    _secondsRemaining = duration;
    notifyListeners();
  }

  void handleAppLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStats();
    }
  }

  void _onFinished() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isTimerActive", false);
    await TimerService.stop();
    _isRunning = false;
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 1000);
    }

    if (_mode == 'focus') {
      final result = await _gamificationService.completeSession(25, false);
      _completedToday++;

      if (_completedToday % 4 == 0) {
        _mode = 'longBreak';
        _secondsRemaining = 15 * 60;
      } else {
        _mode = 'shortBreak';
        _secondsRemaining = 5 * 60;
      }

      _lastSessionResult = result;
    } else {
      _mode = 'focus';
      _secondsRemaining = 25 * 60;
    }

    notifyListeners();
  }

  Map<String, dynamic>? _lastSessionResult;
  Map<String, dynamic>? get lastSessionResult => _lastSessionResult;
  void clearLastResult() => _lastSessionResult = null;
}
