import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/forestring_theme.dart';
import '../../../core/widgets/student_navigation.dart';
import '../domain/lesson.dart';
import 'lesson_controller.dart';
import 'widgets/lesson_action_dialog.dart';
import 'widgets/lesson_card.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({
    super.key,
  });

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _selectedDate = today;
    _focusedDate = today;
  }

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
  static const _fullWeekdayLabels = [
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일',
  ];

  Future<void> _pickCalendarDate(
    DateTime firstDay,
    DateTime lastDay,
  ) async {
    final initialMonth = DateTime(
      _focusedDate.year,
      _focusedDate.month,
    );
    final firstMonth = DateTime(firstDay.year, firstDay.month);
    final lastMonth = DateTime(lastDay.year, lastDay.month);

    final pickedMonth = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        var selectedYear = initialMonth.year
            .clamp(firstMonth.year, lastMonth.year);

        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableYears = List<int>.generate(
              lastMonth.year - firstMonth.year + 1,
              (index) => firstMonth.year + index,
            );

            bool monthEnabled(int month) {
              final candidate = DateTime(selectedYear, month);
              return !candidate.isBefore(firstMonth) &&
                  !candidate.isAfter(lastMonth);
            }

            return SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '날짜 이동',
                            style: forestringTextStyle.copyWith(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final now = DateTime.now();
                            final today = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                            if (!today.isBefore(firstDay) &&
                                !today.isAfter(lastDay)) {
                              Navigator.of(context).pop(
                                DateTime(today.year, today.month),
                              );
                            }
                          },
                          child: Text(
                            '오늘',
                            style: forestringTextStyle.copyWith(
                              color: primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableYears.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final year = availableYears[index];
                          final selected = year == selectedYear;
                          return ChoiceChip(
                            label: Text('$year년'),
                            selected: selected,
                            showCheckmark: false,
                            onSelected: (_) {
                              setModalState(() {
                                selectedYear = year;
                              });
                            },
                            selectedColor:
                                primaryColor.withValues(alpha: 0.12),
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.04),
                            side: BorderSide(
                              color: selected
                                  ? primaryColor.withValues(alpha: 0.18)
                                  : Colors.transparent,
                            ),
                            labelStyle: forestringTextStyle.copyWith(
                              color: selected
                                  ? primaryColor
                                  : Colors.black54,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisExtent: 44,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final enabled = monthEnabled(month);
                        final selected = selectedYear == initialMonth.year &&
                            month == initialMonth.month;

                        return OutlinedButton(
                          onPressed: enabled
                              ? () => Navigator.of(context).pop(
                                    DateTime(selectedYear, month),
                                  )
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: selected
                                ? primaryColor
                                : Colors.white,
                            foregroundColor: selected
                                ? Colors.white
                                : Colors.black87,
                            disabledForegroundColor: Colors.black26,
                            side: BorderSide(
                              color: selected
                                  ? primaryColor
                                  : primaryColor.withValues(alpha: 0.10),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '$month월',
                            style: forestringTextStyle.copyWith(
                              color: enabled
                                  ? selected
                                      ? Colors.white
                                      : Colors.black87
                                  : Colors.black26,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (pickedMonth == null || !mounted) {
      return;
    }

    final now = DateTime.now();
    final isCurrentMonth =
        pickedMonth.year == now.year && pickedMonth.month == now.month;
    final preferredDay = isCurrentMonth ? now.day : 1;
    final daysInMonth = DateTime(
      pickedMonth.year,
      pickedMonth.month + 1,
      0,
    ).day;
    var picked = DateTime(
      pickedMonth.year,
      pickedMonth.month,
      preferredDay.clamp(1, daysInMonth),
    );

    if (picked.isBefore(firstDay)) {
      picked = firstDay;
    } else if (picked.isAfter(lastDay)) {
      picked = lastDay;
    }

    setState(() {
      _selectedDate = picked;
      _focusedDate = picked;
    });
  }

  Widget _calendar(
    LessonController controller,
    DateTime firstDay,
    DateTime lastDay,
  ) {
    final safeFocusedDay = _focusedDate.isBefore(firstDay)
        ? firstDay
        : _focusedDate.isAfter(lastDay)
            ? lastDay
            : _focusedDate;

    return TableCalendar<Lesson>(
      key: ValueKey<String>(
        'schedule-calendar-${firstDay.toIso8601String()}-${lastDay.toIso8601String()}',
      ),
      firstDay: firstDay,
      lastDay: lastDay,
      focusedDay: safeFocusedDay,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
      eventLoader: controller.lessonsOn,
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDate = selectedDay;
          _focusedDate = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDate = focusedDay;
      },
      rowHeight: 48,
      daysOfWeekHeight: 34,
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        leftChevronMargin: const EdgeInsets.only(left: 4),
        rightChevronMargin: const EdgeInsets.only(right: 4),
        leftChevronIcon: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            color: primaryColor,
            size: 22,
          ),
        ),
        rightChevronIcon: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chevron_right_rounded,
            color: primaryColor,
            size: 22,
          ),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'ELAND',
          fontWeight: FontWeight.w500,
          fontSize: 19,
          color: primaryColor,
        ),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        cellMargin: const EdgeInsets.all(5),
        todayDecoration: const BoxDecoration(
          color: Color(0xffE7EFE4),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          color: primaryColor,
          fontFamily: 'ELAND',
          fontWeight: FontWeight.w500,
        ),
        selectedDecoration: const BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'ELAND',
          fontWeight: FontWeight.w500,
        ),
        defaultTextStyle: forestringTextStyle.copyWith(
          color: Colors.black87,
          fontSize: 14,
        ),
        weekendTextStyle: forestringTextStyle.copyWith(
          color: Colors.black87,
          fontSize: 14,
        ),
        markerDecoration: const BoxDecoration(
          color: secondaryColor,
          shape: BoxShape.circle,
        ),
        markerSize: 5,
        markersMaxCount: 1,
        markersAlignment: Alignment.bottomCenter,
        markerMargin: const EdgeInsets.only(top: 1),
      ),
      calendarBuilders: CalendarBuilders(
        headerTitleBuilder: (context, day) {
          return Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickCalendarDate(firstDay, lastDay),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${day.year}년 ${day.month}월',
                      style: forestringTextStyle.copyWith(
                        color: primaryColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: primaryColor,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        dowBuilder: (context, day) {
          final label = _weekdayLabels[day.weekday - 1];
          final color = day.weekday == DateTime.sunday
              ? Colors.redAccent
              : day.weekday == DateTime.saturday
                  ? Colors.blueAccent
                  : Colors.black45;

          return Center(
            child: Text(
              label,
              style: forestringTextStyle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          );
        },
        defaultBuilder: (context, day, focusedDay) {
          final color = day.weekday == DateTime.sunday
              ? Colors.redAccent
              : day.weekday == DateTime.saturday
                  ? Colors.blueAccent
                  : Colors.black87;
          return Center(
            child: Text(
              '${day.day}',
              style: forestringTextStyle.copyWith(
                color: color,
                fontSize: 14,
              ),
            ),
          );
        },
        todayBuilder: (context, day, focusedDay) {
          final color = day.weekday == DateTime.sunday
              ? Colors.redAccent
              : day.weekday == DateTime.saturday
                  ? Colors.blueAccent
                  : primaryColor;
          return Center(
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xffE7EFE4),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${day.day}',
                style: forestringTextStyle.copyWith(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _lessonSectionHeader(int lessonCount) {
    final weekday = _fullWeekdayLabels[_selectedDate.weekday - 1];

    return Row(
      children: [
        Expanded(
          child: Text(
            '${DateFormat('M월 d일').format(_selectedDate)} $weekday',
            style: forestringTextStyle.copyWith(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xffE7EFE4),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$lessonCount개 수업',
            style: forestringTextStyle.copyWith(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyLessonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xffF1F5ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_outlined,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '예약된 수업이 없습니다.',
            style: forestringTextStyle.copyWith(
              color: Colors.black45,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessonContent(
    BuildContext context,
    LessonController controller,
    List<Lesson> selectedLessons,
  ) {
    final lessons = [...selectedLessons]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    if (controller.isLoading && controller.lessons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 54),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (lessons.isEmpty) {
      return _emptyLessonCard();
    }

    return Column(
      children: [
        for (var i = 0; i < lessons.length; i++) ...[
          StudentLessonCard(
            lesson: lessons[i],
            onTap: () => showStudentLessonDialog(
              context: context,
              lesson: lessons[i],
              controller: context.read<LessonController>(),
            ),
          ),
          if (i != lessons.length - 1)
            const SizedBox(height: 10),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LessonController>();
    final selectedLessons = controller.lessonsOn(_selectedDate);
    final firstDay = controller.calendarFirstDay;
    final lastDay = controller.calendarLastDay;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const StudentAppBar(title: '일정'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
            children: [
              _calendar(controller, firstDay, lastDay),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                decoration: BoxDecoration(
                  color: const Color(0xffE8F0E4),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  children: [
                    _lessonSectionHeader(selectedLessons.length),
                    const SizedBox(height: 12),
                    if (controller.errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          controller.errorMessage!,
                          textAlign: TextAlign.center,
                          style: forestringTextStyle.copyWith(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    _lessonContent(
                      context,
                      controller,
                      selectedLessons,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
