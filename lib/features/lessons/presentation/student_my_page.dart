import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/forestring_theme.dart';
import '../../auth/domain/current_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/lesson_history.dart';
import 'lesson_controller.dart';
import 'widgets/lesson_card.dart';

class StudentMyPage extends StatefulWidget {
  const StudentMyPage({
    super.key,
    required this.profile,
  });

  final CurrentProfile profile;

  @override
  State<StudentMyPage> createState() => _StudentMyPageState();
}

class _StudentMyPageState extends State<StudentMyPage> {
  bool _requestedHistory = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedHistory) {
      return;
    }

    _requestedHistory = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LessonController>().ensureHistoryLoaded();
      }
    });
  }

  Future<void> _reload() {
    return context.read<LessonController>().refreshAll(forceHistory: true);
  }

  void _showNotificationNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('알림 기능은 준비 중입니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              '로그아웃',
              style: forestringTextStyle.copyWith(
                color: primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            content: Text(
              '로그아웃하시겠습니까?',
              style: forestringTextStyle.copyWith(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  '아니요',
                  style: forestringTextStyle.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  '로그아웃',
                  style: forestringTextStyle.copyWith(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    await context.read<AuthController>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LessonController>();
    final history = controller.history;

    return Scaffold(
      backgroundColor: const Color(0xffF8F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xffF8F6F0),
        surfaceTintColor: Colors.transparent,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '마이페이지',
          style: forestringTextStyle.copyWith(
            color: primaryColor,
            fontSize: 21,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '알림',
            onPressed: _showNotificationNotice,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: history == null
            ? controller.historyErrorMessage == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 120),
                        Text(
                          controller.historyErrorMessage!,
                          textAlign: TextAlign.center,
                          style: forestringTextStyle.copyWith(
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  )
            : RefreshIndicator(
                onRefresh: _reload,
                child: Builder(
                  builder: (context) {
                    final current = history.currentSemester;
                    final past = history.pastSemesters;

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                      children: [
                        _profileHeader(history),
                        const SizedBox(height: 18),
                        if (current == null)
                          _emptyCurrentSemesterCard()
                        else
                          _semesterHero(history, current),
                        const SizedBox(height: 16),
                        _nextLessonCard(history),
                        const SizedBox(height: 26),
                        if (current != null) ...[
                          _sectionTitle('이번 학기 수업 내역'),
                          const SizedBox(height: 10),
                          ..._timeline(history, current),
                          const SizedBox(height: 26),
                        ],
                        _sectionTitle('지난 학기'),
                        const SizedBox(height: 10),
                        if (past.isEmpty)
                          _emptyCard('지난 학기 수강 내역이 없습니다.')
                        else
                          ...past.map(
                            (semester) => _pastTile(history, semester),
                          ),
                        const SizedBox(height: 22),
                        Divider(
                          height: 1,
                          color: Colors.black.withValues(alpha: 0.10),
                        ),
                        const SizedBox(height: 10),
                        _logoutButton(),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xffFFF7F6),
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 13),
          side: BorderSide(
            color: Colors.redAccent.withValues(alpha: 0.16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(
          Icons.logout_rounded,
          size: 19,
        ),
        label: Text(
          '로그아웃',
          style: forestringTextStyle.copyWith(
            color: Colors.redAccent,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _profileHeader(LessonHistoryData history) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xffE7EFE4),
            shape: BoxShape.circle,
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.08),
            ),
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: primaryColor,
            size: 34,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '${widget.profile.displayName}님',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: forestringTextStyle.copyWith(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _pill(
                    history.studentTypeLabel,
                    primaryColor.withValues(alpha: 0.10),
                    primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyCurrentSemesterCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primaryColor,
            Color(0xff315E45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        '현재 진행 중인 학기가 없습니다.',
        style: forestringTextStyle.copyWith(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  _SemesterMetrics _semesterMetrics(
    LessonHistoryData history,
    SemesterLessonHistory semester,
  ) {
    final baseRights = semester.rights
        .where(
          (right) => history.isRegular
              ? right.origin == 'regular_base'
              : right.origin == 'flex_base',
        )
        .toList();

    final carryoverCount = semester.rights
        .where((right) => right.origin == 'carryover')
        .length;
    final availableCount = semester.rights
        .where((right) => right.status == 'available')
        .length;

    return _SemesterMetrics(
      baseCount: baseRights.length,
      availableCount: availableCount,
      reservedCount: semester.reservedRights,
      remainingCancellations:
          semester.cancellationQuota?.remainingCancellations,
      carryoverCount: carryoverCount,
    );
  }

  Widget _semesterHero(
    LessonHistoryData history,
    SemesterLessonHistory semester,
  ) {
    final metrics = _semesterMetrics(history, semester);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primaryColor,
            Color(0xff315E45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -22,
              top: -20,
              child: Icon(
                Icons.music_note_rounded,
                color: Colors.white.withValues(alpha: 0.07),
                size: 148,
              ),
            ),
            Positioned(
              right: 22,
              bottom: 18,
              child: Icon(
                Icons.eco_rounded,
                color: Colors.white.withValues(alpha: 0.14),
                size: 28,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이번 학기',
                    style: forestringTextStyle.copyWith(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _semesterShortTitle(semester.code),
                    style: forestringTextStyle.copyWith(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${DateFormat('yyyy.MM.dd').format(semester.startsOn)} '
                    '~ ${DateFormat('yyyy.MM.dd').format(semester.endsOn)}',
                    style: forestringTextStyle.copyWith(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  if (history.isFlex) ...[
                    const SizedBox(height: 8),
                    Text(
                      '기본 수업권 ${metrics.baseCount}개',
                      style: forestringTextStyle.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffFAF9F4),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _metricCell(
                                icon: Icons.calendar_month_rounded,
                                label: '예약된 수업',
                                value: '${metrics.reservedCount}회',
                                backgroundColor: const Color(0xffEDF5ED),
                                iconBackgroundColor: const Color(0xffDCEBDD),
                                iconColor: const Color(0xff477253),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _metricCell(
                                icon: Icons.confirmation_number_outlined,
                                label: '남은 수업권',
                                value: '${metrics.availableCount}개',
                                backgroundColor: const Color(0xffFBF3E3),
                                iconBackgroundColor: const Color(0xffF6E2B7),
                                iconColor: const Color(0xff98651B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _metricCell(
                                icon: Icons.cancel_outlined,
                                label: '취소 가능 횟수',
                                value: metrics.remainingCancellations == null
                                    ? '확인 불가'
                                    : '${metrics.remainingCancellations}회',
                                backgroundColor: const Color(0xffFBEDED),
                                iconBackgroundColor: const Color(0xffF5DADB),
                                iconColor: const Color(0xffB75D61),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _metricCell(
                                icon: Icons.school_outlined,
                                label: '보강 수업권',
                                value: metrics.carryoverCount == 0
                                    ? '없음'
                                    : '${metrics.carryoverCount}개',
                                backgroundColor: const Color(0xffF0F1EF),
                                iconBackgroundColor: const Color(0xffDFE1DE),
                                iconColor: const Color(0xff59615B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCell({
    required IconData icon,
    required String label,
    required String value,
    required Color backgroundColor,
    required Color iconBackgroundColor,
    required Color iconColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: forestringTextStyle.copyWith(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: forestringTextStyle.copyWith(
                    color: Colors.black87,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LessonRightHistory? _nextLessonRight(LessonHistoryData history) {
    final now = DateTime.now();
    final candidates = <LessonRightHistory>[];

    for (final semester in history.semesters) {
      for (final right in semester.rights) {
        final lesson = right.lesson;
        if (lesson == null ||
            lesson.isCanceled ||
            !lesson.endsAt.isAfter(now)) {
          continue;
        }
        candidates.add(right);
      }
    }

    candidates.sort(
      (a, b) => a.lesson!.startsAt.compareTo(b.lesson!.startsAt),
    );
    return candidates.isEmpty ? null : candidates.first;
  }

  Widget _nextLessonCard(LessonHistoryData history) {
    final right = _nextLessonRight(history);
    final lesson = right?.lesson;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xffF1F6EE),
            Color(0xffFBF8EE),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.08),
        ),
      ),
      child: lesson == null
          ? Row(
              children: [
                _nextLessonIcon(),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '예정된 다음 수업이 없습니다.',
                    style: forestringTextStyle.copyWith(
                      color: Colors.black54,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '다음 수업',
                        style: forestringTextStyle.copyWith(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${DateFormat('M월 d일').format(lesson.startsAt)} '
                        '${_weekdayLabel(lesson.startsAt)}',
                        style: forestringTextStyle.copyWith(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('HH:mm').format(lesson.startsAt),
                        style: forestringTextStyle.copyWith(
                          color: primaryColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${lesson.teacherName ?? '담당 선생님'} 선생님'
                        ' · ${lesson.displayTypeLabel}',
                        style: forestringTextStyle.copyWith(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _nextLessonIcon(),
              ],
            ),
    );
  }

  Widget _nextLessonIcon() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.08),
        ),
      ),
      child: const Icon(
        Icons.event_available_rounded,
        color: primaryColor,
        size: 30,
      ),
    );
  }

  Widget _sectionTitle(String text, {bool small = false}) {
    return Text(
      text,
      style: forestringTextStyle.copyWith(
        color: small ? primaryColor : Colors.black87,
        fontSize: small ? 16 : 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _semesterSummary(
    LessonHistoryData history,
    SemesterLessonHistory semester,
  ) {
    final carryoverCount = semester.rights
        .where((right) => right.origin == 'carryover')
        .length;
    final availableCount = semester.rights
        .where((right) => right.status == 'available')
        .length;
    final cancellationLabel = semester.cancellationQuota == null
        ? '확인 불가'
        : '${semester.cancellationQuota!.remainingCancellations}회';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${DateFormat('M월 d일').format(semester.startsOn)} ~ '
          '${DateFormat('M월 d일').format(semester.endsOn)}',
          style: forestringTextStyle.copyWith(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metricCell(
                icon: Icons.calendar_month_rounded,
                label: '예약된 수업',
                value: '${semester.reservedRights}회',
                backgroundColor: const Color(0xffEDF5ED),
                iconBackgroundColor: const Color(0xffDCEBDD),
                iconColor: const Color(0xff477253),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCell(
                icon: Icons.confirmation_number_outlined,
                label: '남은 수업권',
                value: '${availableCount}개',
                backgroundColor: const Color(0xffFBF3E3),
                iconBackgroundColor: const Color(0xffF6E2B7),
                iconColor: const Color(0xff98651B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _metricCell(
                icon: Icons.cancel_outlined,
                label: '취소 가능 횟수',
                value: cancellationLabel,
                backgroundColor: const Color(0xffEEF2F4),
                iconBackgroundColor: const Color(0xffDDE5E9),
                iconColor: const Color(0xff657783),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCell(
                icon: Icons.school_outlined,
                label: '보강 수업권',
                value: carryoverCount == 0 ? '없음' : '${carryoverCount}개',
                backgroundColor: const Color(0xffF0F1EF),
                iconBackgroundColor: const Color(0xffDFE1DE),
                iconColor: const Color(0xff59615B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _timeline(
    LessonHistoryData history,
    SemesterLessonHistory semester,
  ) {
    final rights = semester.rights.where((right) {
      if (history.isRegular) {
        return right.origin == 'regular_base';
      }
      return right.origin == 'flex_base' || right.origin == 'carryover';
    }).toList();

    rights.sort((a, b) {
      final aDate = _originalCardDate(a);
      final bDate = _originalCardDate(b);
      if (aDate == null && bDate == null) {
        return a.sequenceNo.compareTo(b.sequenceNo);
      }
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      final dateComparison = aDate.compareTo(bDate);
      return dateComparison != 0
          ? dateComparison
          : a.sequenceNo.compareTo(b.sequenceNo);
    });

    final cards = rights
        .where((right) => right.lesson != null)
        .map(
          (right) => _lessonHistoryCard(
            history,
            right,
            history.isRegular ? '정규 수업' : '예약 수업',
          ),
        )
        .toList();

    if (cards.isEmpty) {
      return [_emptyCard('아직 등록된 수업 내역이 없습니다.')];
    }
    return cards;
  }

  DateTime? _originalCardDate(LessonRightHistory right) {
    final lesson = right.lesson;
    if (lesson == null) {
      return null;
    }
    return right.originalStartsAt ?? lesson.startsAt;
  }

  Widget _lessonHistoryCard(
    LessonHistoryData history,
    LessonRightHistory right,
    String title,
  ) {
    final lesson = right.lesson!;
    final canceled = lesson.isCanceled;
    final rebooked = right.isRebooked;
    final staffChanged = !canceled && !rebooked && lesson.isAcademyChanged;

    final statusLabel = canceled
        ? '취소됨'
        : rebooked
            ? '재예약'
            : staffChanged
                ? '변경'
                : null;
    final statusColor = rebooked || staffChanged
        ? secondaryColor
        : primaryColor;

    final visibleActivities = [...right.activities]
      ..sort((a, b) => a.eventAt.compareTo(b.eventAt));
    final showTimeline = visibleActivities.any(
      (activity) =>
          activity.isCancellation ||
          activity.isRebooking ||
          activity.isManualUpdate ||
          activity.isMakeupCreated,
    );

    return StudentLessonHistoryCard(
      title: title,
      startsAt: lesson.startsAt,
      endsAt: lesson.endsAt,
      teacherName: lesson.teacherName,
      statusLabel: statusLabel,
      statusColor: statusColor,
      isCanceled: canceled,
      footer: showTimeline
          ? _activityTimeline(history, visibleActivities)
          : null,
    );
  }

  Widget _activityTimeline(
    LessonHistoryData history,
    List<LessonActivityHistory> activities,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xffF8F8F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (var i = 0; i < activities.length; i++)
            _activityTimelineItem(
              history,
              activities[i],
              isLast: i == activities.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _activityTimelineItem(
    LessonHistoryData history,
    LessonActivityHistory activity, {
    required bool isLast,
  }) {
    final color = activity.isCancellation
        ? Colors.redAccent
        : activity.isRebooking
            ? secondaryColor
            : primaryColor;
    final label = _activityLabel(activity);
    final scheduleText = _activityScheduleText(activity);
    final actorText = activity.actorRoleLabel(history.studentId);
    final actionTime = DateFormat('M월 d일 HH:mm').format(activity.eventAt);
    final metadata = actorText == null
        ? actionTime
        : '$actorText · $actionTime';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          child: Column(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 38,
                  margin: const EdgeInsets.only(top: 3),
                  color: Colors.black.withValues(alpha: 0.10),
                ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: forestringTextStyle.copyWith(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (scheduleText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    scheduleText,
                    style: forestringTextStyle.copyWith(
                      color: Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  metadata,
                  style: forestringTextStyle.copyWith(
                    color: Colors.black38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _activityLabel(LessonActivityHistory activity) {
    if (activity.isOriginalSchedule) {
      return '원래 일정';
    }
    if (activity.isCancellation) {
      return activity.details['cancellationOrigin']?.toString() == 'student'
          ? '학생 취소'
          : '학원 취소';
    }
    if (activity.isBooking) {
      return activity.isRebooking ? '재예약' : '예약';
    }
    if (activity.isManualUpdate) {
      return '일정 변경';
    }
    if (activity.isMakeupCreated) {
      return '보강 등록';
    }
    return '처리';
  }

  String? _activityScheduleText(LessonActivityHistory activity) {
    if (activity.isManualUpdate) {
      final before = _mapValue(activity.details['before']);
      final after = _mapValue(activity.details['after']);
      final beforeStart = _parseActivityDate(before['startsAt']);
      final afterStart = _parseActivityDate(after['startsAt']);
      if (beforeStart == null && afterStart == null) {
        return null;
      }
      final beforeText = beforeStart == null
          ? '기존 일정'
          : DateFormat('M월 d일 HH:mm').format(beforeStart);
      final afterText = afterStart == null
          ? '변경 일정'
          : DateFormat('M월 d일 HH:mm').format(afterStart);
      return '$beforeText → $afterText';
    }

    final startsAt = activity.startsAt;
    final endsAt = activity.endsAt;
    if (startsAt == null) {
      return null;
    }
    if (endsAt == null) {
      return DateFormat('M월 d일 HH:mm').format(startsAt);
    }
    return '${DateFormat('M월 d일 HH:mm').format(startsAt)} ~ '
        '${DateFormat('HH:mm').format(endsAt)}';
  }

  Map<String, dynamic> _mapValue(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }

  DateTime? _parseActivityDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  Widget _pastTile(
    LessonHistoryData history,
    SemesterLessonHistory semester,
  ) {
    final regularCount = semester.rights
        .where((right) => right.origin == 'regular_base')
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.14)),
      ),
      child: ExpansionTile(
        key: PageStorageKey<String>('past-semester-${semester.id}'),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          _semesterTitle(semester.code),
          style: forestringTextStyle.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          history.isRegular
              ? '기본 수업 $regularCount개'
              : '수강권 ${semester.totalRights}개 · 남은 ${semester.availableRights}개',
          style: forestringTextStyle.copyWith(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          _semesterSummary(history, semester),
          const SizedBox(height: 10),
          ..._timeline(history, semester),
        ],
      ),
    );
  }

  Widget _pill(
    String text,
    Color background,
    Color foreground, {
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: borderColor == null ? null : Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: forestringTextStyle.copyWith(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ivoryColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: forestringTextStyle.copyWith(color: Colors.black54),
      ),
    );
  }

  String _weekdayLabel(DateTime date) {
    const labels = [
      '월요일',
      '화요일',
      '수요일',
      '목요일',
      '금요일',
      '토요일',
      '일요일',
    ];
    return labels[date.weekday - 1];
  }

  String _semesterShortTitle(String code) {
    final parts = code.split('-');
    if (parts.length == 2) {
      final month = int.tryParse(parts[1]);
      if (month != null) {
        return '$month월 학기';
      }
    }
    return '$code 학기';
  }

  String _semesterTitle(String code) {
    final parts = code.split('-');
    if (parts.length == 2) {
      final month = int.tryParse(parts[1]);
      if (month != null) {
        return '${parts[0]}년 $month월 학기';
      }
    }
    return '$code 학기';
  }
}


class _SemesterMetrics {
  const _SemesterMetrics({
    required this.baseCount,
    required this.availableCount,
    required this.reservedCount,
    required this.remainingCancellations,
    required this.carryoverCount,
  });

  final int baseCount;
  final int availableCount;
  final int reservedCount;
  final int? remainingCancellations;
  final int carryoverCount;
}
