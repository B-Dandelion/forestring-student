import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/forestring_theme.dart';
import '../features/auth/domain/current_profile.dart';
import '../features/lessons/presentation/lesson_controller.dart';
import '../features/lessons/presentation/reschedule_page.dart';
import '../features/lessons/presentation/student_home_page.dart';
import '../features/lessons/presentation/student_my_page.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({
    super.key,
    required this.profile,
  });

  final CurrentProfile profile;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell>
    with WidgetsBindingObserver {
  static const int _reservationIndex = 0;
  static const int _scheduleIndex = 1;
  static const int _myPageIndex = 2;

  int _currentIndex = _scheduleIndex;
  final List<bool> _visited = <bool>[false, true, false];
  int _reservationRefreshSignal = 0;
  bool _wasBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _wasBackgrounded = true;
      return;
    }

    if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      unawaited(_refreshAfterResume());
    }
  }

  Future<void> _refreshAfterResume() async {
    await context.read<LessonController>().refreshAll();

    if (!mounted) {
      return;
    }

    if (_visited[_reservationIndex]) {
      setState(() {
        _reservationRefreshSignal += 1;
      });
    }
  }

  void _selectTab(int index) {
    if (index == _currentIndex) {
      return;
    }

    final wasVisited = _visited[index];

    setState(() {
      _visited[index] = true;
      _currentIndex = index;

      if (index == _reservationIndex && wasVisited) {
        _reservationRefreshSignal += 1;
      }
    });

    final controller = context.read<LessonController>();
    if (index == _scheduleIndex) {
      unawaited(controller.refreshLessonsIfStale());
    } else if (index == _myPageIndex) {
      unawaited(controller.refreshHistoryIfStale());
    }
  }

  Widget _buildTab(int index) {
    if (!_visited[index]) {
      return const SizedBox.shrink();
    }

    return switch (index) {
      _reservationIndex => ReschedulePage(
          key: const PageStorageKey<String>('student-reservation-tab'),
          profile: widget.profile,
          refreshSignal: _reservationRefreshSignal,
        ),
      _scheduleIndex => StudentHomePage(
          key: const PageStorageKey<String>('student-schedule-tab'),
          profile: widget.profile,
        ),
      _myPageIndex => StudentMyPage(
          key: const PageStorageKey<String>('student-my-page-tab'),
          profile: widget.profile,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == _scheduleIndex,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _currentIndex == _scheduleIndex) {
          return;
        }

        setState(() {
          _currentIndex = _scheduleIndex;
        });
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List<Widget>.generate(3, _buildTab),
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: primaryColor.withValues(alpha: 0.10),
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
              (states) => forestringTextStyle.copyWith(
                color: states.contains(WidgetState.selected)
                    ? primaryColor
                    : Colors.black54,
                fontSize: 11,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w500
                    : FontWeight.w300,
              ),
            ),
          ),
          child: NavigationBar(
            height: 68,
            selectedIndex: _currentIndex,
            onDestinationSelected: _selectTab,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.event_available_outlined),
                selectedIcon: Icon(Icons.event_available_rounded),
                label: '수업 예약',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: '일정',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: '마이페이지',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
