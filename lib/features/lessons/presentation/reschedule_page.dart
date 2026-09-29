import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/forestring_theme.dart';
import '../../../core/widgets/student_navigation.dart';
import '../../auth/domain/current_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/lesson.dart';
import '../domain/lesson_history.dart';
import 'lesson_controller.dart';
import 'student_my_page.dart';

class ReschedulePage extends StatefulWidget {
  const ReschedulePage({
    super.key,
    required this.profile,
  });

  final CurrentProfile profile;

  @override
  State<ReschedulePage> createState() => _ReschedulePageState();
}

class _ReschedulePageState extends State<ReschedulePage> {
  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  List<LessonRightHistory> _bookingRights = const [];
  String? _selectedRightId;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  LessonBookingWindow? _window;
  List<LessonBookingOption> _options = const [];
  bool _loadingRights = false;
  bool _loadingWindow = false;
  bool _loadingOptions = false;
  bool _booking = false;
  String? _errorMessage;
  bool _initialized = false;
  int _loadToken = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadBookingRights();
    });
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _clampToWindow(DateTime date, LessonBookingWindow window) {
    final value = _dateOnly(date);
    final start = _dateOnly(window.startsOn);
    final end = _dateOnly(window.endsOn);
    if (value.isBefore(start)) {
      return start;
    }
    if (value.isAfter(end)) {
      return end;
    }
    return value;
  }

  Future<void> _loadBookingRights() async {
    final token = ++_loadToken;
    setState(() {
      _loadingRights = true;
      _errorMessage = null;
    });

    try {
      final rights = await context
          .read<LessonController>()
          .fetchAvailableBookingRights();
      if (!mounted || token != _loadToken) {
        return;
      }

      setState(() {
        _bookingRights = rights;
        _loadingRights = false;
        if (rights.isEmpty) {
          _selectedRightId = null;
          _window = null;
          _options = const [];
        }
      });

      if (rights.isNotEmpty) {
        final selected = rights.where(
          (right) => right.id == _selectedRightId,
        );
        await _selectRight(selected.isEmpty ? rights.first : selected.first);
      }
    } catch (error) {
      if (!mounted || token != _loadToken) {
        return;
      }
      setState(() {
        _bookingRights = const [];
        _loadingRights = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _refresh() async {
    await context.read<LessonController>().reload();
    if (mounted) {
      await _loadBookingRights();
    }
  }

  Future<void> _selectRight(LessonRightHistory right) async {
    final token = ++_loadToken;
    setState(() {
      _selectedRightId = right.id;
      _window = null;
      _options = const [];
      _loadingWindow = true;
      _loadingOptions = false;
      _errorMessage = null;
    });

    try {
      final controller = context.read<LessonController>();
      final window = await controller.getBookingWindow(right.id);
      if (!mounted || token != _loadToken) {
        return;
      }

      final preferredDate = right.lesson?.startsAt ?? DateTime.now();
      final selectedDate = _clampToWindow(preferredDate, window);
      setState(() {
        _window = window;
        _selectedDate = selectedDate;
        _focusedDate = selectedDate;
        _loadingWindow = false;
      });
      await _loadOptions(right, selectedDate);
    } catch (error) {
      if (!mounted || token != _loadToken) {
        return;
      }
      setState(() {
        _loadingWindow = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _loadOptions(
    LessonRightHistory right,
    DateTime date,
  ) async {
    final token = ++_loadToken;
    setState(() {
      _loadingOptions = true;
      _errorMessage = null;
      _options = const [];
    });

    try {
      final loaded = await context.read<LessonController>().getBookingOptions(
            rightId: right.id,
            selectedDate: date,
          );
      if (!mounted || token != _loadToken) {
        return;
      }
      setState(() {
        _options = loaded;
        _loadingOptions = false;
      });
    } catch (error) {
      if (!mounted || token != _loadToken) {
        return;
      }
      setState(() {
        _loadingOptions = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _book(
    LessonRightHistory right,
    LessonBookingOption option,
  ) async {
    if (_booking) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('수업 예약'),
            content: Text(
              '${DateFormat('M월 d일 HH:mm').format(option.startsAt)} ~ '
              '${DateFormat('HH:mm').format(option.endsAt)}\n이 시간으로 예약하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('예약'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _booking = true;
    });

    final controller = context.read<LessonController>();
    final ok = await controller.bookLessonRight(
      rightId: right.id,
      option: option,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _booking = false;
    });

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? '수업을 예약하지 못했습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('수업이 예약되었습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await _loadBookingRights();
  }

  String _formatBookingTime(DateTime value) {
    var hour = value.hour % 12;
    if (hour == 0) {
      hour = 12;
    }
    return '$hour:${value.minute.toString().padLeft(2, '0')}';
  }

  Widget _timeGroup(
    String label,
    List<LessonBookingOption> options,
    LessonRightHistory right,
  ) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: forestringTextStyle.copyWith(
              color: Colors.black87,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 50,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              return OutlinedButton(
                onPressed: _booking
                    ? null
                    : () => _book(
                          right,
                          option,
                        ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: Colors.black87,
                  backgroundColor: Colors.white,
                  disabledForegroundColor: Colors.black26,
                  side: BorderSide(
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _formatBookingTime(option.startsAt),
                  style: forestringTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final rights = _bookingRights;
    final selectedRight = rights.isEmpty
        ? null
        : rights.firstWhere(
            (right) => right.id == _selectedRightId,
            orElse: () => rights.first,
          );

    if (selectedRight != null &&
        _selectedRightId != selectedRight.id &&
        !_loadingWindow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _selectRight(selectedRight);
        }
      });
    }

    return Scaffold(
      appBar: const StudentAppBar(title: '수업 예약·변경'),
      drawer: StudentDrawer(
        displayName: widget.profile.displayName,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).maybePop();
        },
        onReschedule: () => Navigator.of(context).pop(),
        onMyPage: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<LessonController>(),
                child: StudentMyPage(profile: widget.profile),
              ),
            ),
          );
        },
        onLogout: () async {
          Navigator.of(context).pop();
          await context.read<AuthController>().signOut();
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
      body: SafeArea(
        child: _loadingRights && rights.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : rights.isEmpty
                ? RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 120),
                        const Icon(
                          Icons.event_available_outlined,
                          size: 52,
                          color: primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage ?? '예약 가능한 수업권이 없습니다.',
                          textAlign: TextAlign.center,
                          style: forestringTextStyle.copyWith(
                            fontSize: 17,
                            color: _errorMessage == null
                                ? Colors.black
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedRight?.id,
                            decoration: const InputDecoration(
                              labelText: '수업권 선택',
                              border: OutlineInputBorder(),
                            ),
                            items: rights
                                .asMap()
                                .entries
                                .map(
                                  (entry) => DropdownMenuItem<String>(
                                    value: entry.value.id,
                                    child: Text(
                                      '수업권 ${entry.key + 1}',
                                      style: forestringTextStyle,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _loadingWindow || _booking
                                ? null
                                : (id) {
                                    if (id == null) {
                                      return;
                                    }
                                    final right = rights.firstWhere(
                                      (item) => item.id == id,
                                    );
                                    _selectRight(right);
                                  },
                          ),
                        ),
                        if (_loadingWindow)
                          const SizedBox(
                            height: 320,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_window != null && selectedRight != null) ...[
                          TableCalendar<void>(
                            firstDay: _dateOnly(_window!.startsOn),
                            lastDay: _dateOnly(_window!.endsOn),
                            focusedDay: _focusedDate,
                            startingDayOfWeek: StartingDayOfWeek.sunday,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDate, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDate = selectedDay;
                                _focusedDate = focusedDay;
                              });
                              _loadOptions(selectedRight, selectedDay);
                            },
                            onPageChanged: (focusedDay) {
                              _focusedDate = focusedDay;
                            },
                            headerStyle: HeaderStyle(
                              titleCentered: true,
                              formatButtonVisible: false,
                              titleTextFormatter: (date, locale) =>
                                  '${date.month}월',
                              leftChevronIcon: const Icon(
                                Icons.chevron_left,
                                color: primaryColor,
                              ),
                              rightChevronIcon: const Icon(
                                Icons.chevron_right,
                                color: primaryColor,
                              ),
                              titleTextStyle: const TextStyle(
                                fontFamily: 'ELAND',
                                fontWeight: FontWeight.w500,
                                fontSize: 22,
                                color: primaryColor,
                              ),
                            ),
                            calendarStyle: const CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: secondaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            calendarBuilders: CalendarBuilders(
                              dowBuilder: (context, day) {
                                final label =
                                    _weekdayLabels[day.weekday - 1];
                                return Center(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontFamily: 'ELAND',
                                      fontWeight: FontWeight.w500,
                                      color:
                                          day.weekday == DateTime.sunday
                                              ? Colors.red
                                              : day.weekday ==
                                                      DateTime.saturday
                                                  ? Colors.blue
                                                  : Colors.black,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: ivoryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${DateFormat('M월 d일').format(_selectedDate)} '
                              '예약 가능 시간',
                              style: forestringTextStyle.copyWith(
                                color: primaryColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_loadingOptions)
                            const SizedBox(
                              height: 180,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: forestringTextStyle.copyWith(
                                  color: Colors.redAccent,
                                ),
                              ),
                            )
                          else if (_options.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 44,
                              ),
                              child: Text(
                                '예약 가능한 시간이 없습니다.',
                                textAlign: TextAlign.center,
                                style: forestringTextStyle.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                8,
                                14,
                                0,
                              ),
                              child: Column(
                                children: [
                                  _timeGroup(
                                    '오전',
                                    _options
                                        .where(
                                          (option) =>
                                              option.startsAt.hour < 12,
                                        )
                                        .toList(),
                                    selectedRight,
                                  ),
                                  _timeGroup(
                                    '오후',
                                    _options
                                        .where(
                                          (option) =>
                                              option.startsAt.hour >= 12,
                                        )
                                        .toList(),
                                    selectedRight,
                                  ),
                                ],
                              ),
                            ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 80,
                            ),
                            child: Text(
                              _errorMessage ?? '예약 정보를 불러오지 못했습니다.',
                              textAlign: TextAlign.center,
                              style: forestringTextStyle.copyWith(
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}