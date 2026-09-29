import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/forestring_theme.dart';
import '../../../core/widgets/student_navigation.dart';
import '../../auth/domain/current_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/lesson.dart';
import 'lesson_controller.dart';
import 'reschedule_page.dart';
import 'student_my_page.dart';
import 'widgets/lesson_action_dialog.dart';
import 'widgets/lesson_card.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({
    super.key,
    required this.profile,
  });

  final CurrentProfile profile;

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  Future<void> _pickCalendarDate(
    DateTime firstDay,
    DateTime lastDay,
  ) async {
    var initialDate = _focusedDate;
    if (initialDate.isBefore(firstDay)) {
      initialDate = firstDay;
    } else if (initialDate.isAfter(lastDay)) {
      initialDate = lastDay;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDay,
      lastDate: lastDay,
      helpText: '날짜 이동',
      cancelText: '취소',
      confirmText: '이동',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = picked;
      _focusedDate = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LessonController>();
    final selectedLessons = controller.lessonsOn(_selectedDate);
    final firstDay = controller.calendarFirstDay;
    final lastDay = controller.calendarLastDay;

    return Scaffold(
      appBar: const StudentAppBar(),
      drawer: StudentDrawer(
        displayName: widget.profile.displayName,
        onHome: () => Navigator.of(context).pop(),
        onReschedule: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<LessonController>(),
                child: ReschedulePage(
                  profile: widget.profile,
                ),
              ),
            ),
          );
        },
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
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            TableCalendar<Lesson>(
              firstDay: firstDay,
              lastDay: lastDay,
              focusedDay: _focusedDate,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              selectedDayPredicate: (day) =>
                  isSameDay(_selectedDate, day),
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
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextFormatter: (date, locale) => '${date.month}월',
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
                markerDecoration: BoxDecoration(
                  color: Color(0xff2E8B57),
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                headerTitleBuilder: (context, day) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _pickCalendarDate(firstDay, lastDay),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${day.month}월',
                            style: forestringTextStyle.copyWith(
                              color: primaryColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                dowBuilder: (context, day) {
                  final label = _weekdayLabels[day.weekday - 1];
                  return Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'ELAND',
                        fontWeight: FontWeight.w500,
                        color: day.weekday == DateTime.sunday
                            ? Colors.red
                            : day.weekday == DateTime.saturday
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
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: ivoryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${DateFormat('M월 d일').format(_selectedDate)} · '
                '${selectedLessons.length}개 수업',
                style: forestringTextStyle.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (controller.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  controller.errorMessage!,
                  style: forestringTextStyle.copyWith(
                    color: Colors.redAccent,
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.reload,
                child: controller.isLoading && controller.lessons.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: CircularProgressIndicator()),
                        ],
                      )
                    : selectedLessons.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 70),
                              Text(
                                '예약된 수업이 없습니다.',
                                textAlign: TextAlign.center,
                                style: forestringTextStyle.copyWith(
                                  color: Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                            itemCount: selectedLessons.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final lesson = selectedLessons[index];
                              return StudentLessonCard(
                                lesson: lesson,
                                onTap: () => showStudentLessonDialog(
                                  context: context,
                                  lesson: lesson,
                                  controller:
                                      context.read<LessonController>(),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
