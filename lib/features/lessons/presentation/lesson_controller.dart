import 'package:flutter/foundation.dart';

import '../data/lesson_repository.dart';
import '../domain/lesson.dart';
import '../domain/lesson_history.dart';

class LessonController extends ChangeNotifier {
  LessonController(this._repository);

  final LessonRepository _repository;

  bool _isLoading = false;
  bool _isHistoryLoading = false;
  String? _errorMessage;
  String? _historyErrorMessage;
  List<Lesson> _lessons = const [];
  LessonHistoryData? _history;
  DateTime? _calendarFirstDay;
  DateTime? _calendarLastDay;
  DateTime? _lessonsRefreshedAt;
  DateTime? _historyRefreshedAt;

  bool get isLoading => _isLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  String? get errorMessage => _errorMessage;
  String? get historyErrorMessage => _historyErrorMessage;
  List<Lesson> get lessons => _lessons;
  LessonHistoryData? get history => _history;
  bool get hasHistory => _history != null;
  DateTime? get lessonsRefreshedAt => _lessonsRefreshedAt;
  DateTime? get historyRefreshedAt => _historyRefreshedAt;

  DateTime get calendarFirstDay {
    final now = DateTime.now();
    return _calendarFirstDay ?? DateTime(now.year, now.month, 1);
  }

  DateTime get calendarLastDay {
    final now = DateTime.now();
    return _calendarLastDay ?? DateTime(now.year, now.month + 2, 0);
  }

  List<Lesson> get canceledLessons => _lessons
      .where(
        (lesson) => lesson.isCanceled && lesson.lessonRightId != null,
      )
      .toList();

  Future<void> initialize() async {
    await reload();
  }

  Future<void> reload() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final calendarStart = await _repository.fetchCalendarStartDate();
      final firstDay = calendarStart == null
          ? DateTime(now.year, now.month, 1)
          : DateTime(
              calendarStart.year,
              calendarStart.month,
              calendarStart.day,
            );
      final safeFirstDay = firstDay.isAfter(today) ? today : firstDay;
      final lastDay = DateTime(now.year, now.month + 2, 0);

      _calendarFirstDay = safeFirstDay;
      _calendarLastDay = lastDay;

      _lessons = await _repository.fetchMyLessons(
        from: safeFirstDay,
        to: lastDay.add(const Duration(days: 1)),
      );
      _lessonsRefreshedAt = DateTime.now();
    } on LessonFailure catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '수업 정보를 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureHistoryLoaded() async {
    if (_history != null || _isHistoryLoading) {
      return;
    }
    await reloadHistory();
  }

  Future<void> reloadHistory() async {
    if (_isHistoryLoading) {
      return;
    }

    _isHistoryLoading = true;
    _historyErrorMessage = null;
    notifyListeners();

    try {
      _history = await _repository.fetchMyLessonHistory();
      _historyRefreshedAt = DateTime.now();
    } on LessonFailure catch (error) {
      _historyErrorMessage = error.message;
    } catch (_) {
      _historyErrorMessage = '수강 내역을 불러오지 못했습니다.';
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll({bool forceHistory = false}) async {
    final shouldRefreshHistory = forceHistory || _history != null;
    await reload();
    if (shouldRefreshHistory) {
      await reloadHistory();
    }
  }

  Future<void> refreshLessonsIfStale({
    Duration maxAge = const Duration(seconds: 30),
  }) async {
    final refreshedAt = _lessonsRefreshedAt;
    if (refreshedAt == null ||
        DateTime.now().difference(refreshedAt) >= maxAge) {
      await reload();
    }
  }

  Future<void> refreshHistoryIfStale({
    Duration maxAge = const Duration(seconds: 30),
  }) async {
    final refreshedAt = _historyRefreshedAt;
    if (_history == null ||
        refreshedAt == null ||
        DateTime.now().difference(refreshedAt) >= maxAge) {
      await reloadHistory();
    }
  }

  Future<LessonHistoryData> fetchLessonHistory() async {
    await reloadHistory();
    final value = _history;
    if (value == null) {
      throw LessonFailure(
        _historyErrorMessage ?? '수강 내역을 불러오지 못했습니다.',
      );
    }
    return value;
  }

  Future<List<LessonRightHistory>> fetchAvailableBookingRights() async {
    try {
      final history = await _repository.fetchMyLessonHistory();
      _history = history;
      _historyErrorMessage = null;
      _historyRefreshedAt = DateTime.now();
      notifyListeners();

      final semester = history.currentSemester;
      if (semester == null) {
        return const [];
      }

      return semester.rights
          .where((right) => right.status == 'available')
          .toList();
    } on LessonFailure catch (error) {
      _historyErrorMessage = error.message;
      notifyListeners();
      rethrow;
    }
  }

  List<Lesson> lessonsOn(DateTime date) {
    return _lessons.where((lesson) {
      if (lesson.isCanceled) {
        return false;
      }

      final local = lesson.startsAt;
      return local.year == date.year &&
          local.month == date.month &&
          local.day == date.day;
    }).toList();
  }

  Future<bool> cancelLesson(Lesson lesson) async {
    try {
      await _repository.cancelLesson(
        lessonId: lesson.id,
        reason: '학생 앱에서 수업 취소',
      );
      await refreshAll();
      return true;
    } on LessonFailure catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }

  Future<LessonBookingWindow> getBookingWindow(String rightId) async {
    return _repository.getBookingWindow(rightId: rightId);
  }

  Future<List<LessonBookingOption>> getBookingOptions({
    required String rightId,
    required DateTime selectedDate,
  }) async {
    return _repository.getBookingOptions(
      rightId: rightId,
      selectedDate: selectedDate,
    );
  }

  Future<bool> bookLessonRight({
    required String rightId,
    required LessonBookingOption option,
  }) async {
    try {
      await _repository.bookLessonRight(
        rightId: rightId,
        startsAt: option.startsAt,
      );
      await refreshAll();
      return true;
    } on LessonFailure catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }
}
