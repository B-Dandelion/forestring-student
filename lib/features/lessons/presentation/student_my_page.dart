import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/forestring_theme.dart';
import '../../auth/domain/current_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/lesson_history.dart';
import 'lesson_controller.dart';

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
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(
          Icons.logout_rounded,
          color: Colors.redAccent,
          size: 20,
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

    final baseCount = baseRights.length;
    final carryoverCount = semester.rights
        .where((right) => right.origin == 'carryover')
        .length;
    final countedStudentCancellations = baseRights.fold<int>(
      0,
      (sum, right) =>
          sum +
          right.cancellations
              .where(
                (event) =>
                    event.origin == 'student' && event.countsTowardLimit,
              )
              .length,
    );
    final cancellationLimit = (baseCount ~/ 4) * 2;
    final remainingCancellations =
        cancellationLimit > countedStudentCancellations
            ? cancellationLimit - countedStudentCancellations
            : 0;
    final availableCount = semester.rights
        .where((right) => right.status == 'available')
        .length;

    return _SemesterMetrics(
      baseCount: baseCount,
      availableCount: availableCount,
      reservedCount: semester.reservedRights,
      remainingCancellations: remainingCancellations,
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
                              ),
                            ),
                            _metricDivider(),
                            Expanded(
                              child: _metricCell(
                                icon: Icons.confirmation_number_outlined,
                                label: '남은 수업권',
                                value: '${metrics.availableCount}개',
                              ),
                            ),
                          ],
                        ),
                        Divider(
                          height: 22,
                          color: primaryColor.withValues(alpha: 0.10),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _metricCell(
                                icon: Icons.cancel_outlined,
                                label: '취소 가능 횟수',
                                value:
                                    '${metrics.remainingCancellations}회',
                              ),
                            ),
                            _metricDivider(),
                            Expanded(
                              child: _metricCell(
                                icon: Icons.school_outlined,
                                label: '보강 수업권',
                                value: metrics.carryoverCount == 0
                                    ? '없음'
                                    : '${metrics.carryoverCount}개',
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

  Widget _metricDivider() {
    return Container(
      width: 1,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: primaryColor.withValues(alpha: 0.10),
    );
  }

  Widget _metricCell({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xffE7EFE4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 21,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
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
                style: forestringTextStyle.copyWith(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
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
    final baseRights = semester.rights
        .where(
          (right) => history.isRegular
              ? right.origin == 'regular_base'
              : right.origin == 'flex_base',
        )
        .toList();
    final baseCount = baseRights.length;
    final carryoverCount = semester.rights
        .where((right) => right.origin == 'carryover')
        .length;
    final countedStudentCancellations = baseRights.fold<int>(
      0,
      (sum, right) =>
          sum +
          right.cancellations
              .where(
                (event) =>
                    event.origin == 'student' && event.countsTowardLimit,
              )
              .length,
    );
    final cancellationLimit = history.isRegular
        ? (baseCount ~/ 4) * 2
        : (baseCount ~/ 4) * 2;
    final remainingCancellations =
        cancellationLimit > countedStudentCancellations
            ? cancellationLimit - countedStudentCancellations
            : 0;
    final availableCount = semester.rights
        .where((right) => right.status == 'available')
        .length;

    final chips = history.isRegular
        ? <String>[
            '예약 가능 수업권 $availableCount개',
            '예약된 수업 ${semester.reservedRights}개',
            '취소 가능 $remainingCancellations회',
            '보강 수업권 ${carryoverCount == 0 ? '없음' : '$carryoverCount개'}',
          ]
        : <String>[
            '기본 수업권 $baseCount개',
            '예약 가능 수업권 $availableCount개',
            '예약된 수업 ${semester.reservedRights}개',
            '취소 가능 $remainingCancellations회',
            '보강 수업권 ${carryoverCount == 0 ? '없음' : '$carryoverCount개'}',
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ivoryColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _semesterTitle(semester.code),
            style: forestringTextStyle.copyWith(
              color: primaryColor,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('M월 d일').format(semester.startsOn)} ~ '
            '${DateFormat('M월 d일').format(semester.endsOn)}',
            style: forestringTextStyle.copyWith(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (text) => _pill(
                    text,
                    Colors.white,
                    Colors.black87,
                    borderColor: primaryColor.withValues(alpha: 0.18),
                  ),
                )
                .toList(),
          ),
        ],
      ),
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

    final rebookedRights = rights.where((right) => right.isRebooked).toList()
      ..sort((a, b) {
        final aDate = a.currentStartsAt;
        final bDate = b.currentStartsAt;
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

    final originalCards = <Widget>[];

    for (final right in rights) {
      if (right.lesson != null) {
        originalCards.add(
          _originalCard(
            history,
            right,
            history.isRegular ? '정규 수업' : '예약 수업',
          ),
        );
      }
    }

    final rebookCards = rebookedRights
        .map((right) => _rebookCard(history, right))
        .toList();

    if (originalCards.isEmpty && rebookCards.isEmpty) {
      return [_emptyCard('아직 등록된 수업 내역이 없습니다.')];
    }

    return [
      ...originalCards,
      if (rebookCards.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(
          '재예약 내역',
          style: forestringTextStyle.copyWith(
            color: secondaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...rebookCards,
      ],
    ];
  }

  DateTime? _originalCardDate(LessonRightHistory right) {
    final lesson = right.lesson;
    if (lesson == null) {
      return null;
    }

    final staffChanged = !right.wasCanceled && lesson.isAcademyChanged;
    return staffChanged
        ? lesson.startsAt
        : right.originalStartsAt ?? lesson.startsAt;
  }

  Widget _originalCard(
    LessonHistoryData history,
    LessonRightHistory right,
    String title,
  ) {
    final lesson = right.lesson!;
    final originalStart = right.originalStartsAt ?? lesson.startsAt;
    final originalEnd = originalStart.add(
      Duration(minutes: right.durationMinutes),
    );
    final cancellations = [...right.cancellations]
      ..sort((a, b) => a.canceledAt.compareTo(b.canceledAt));
    final canceled = right.wasCanceled;
    final staffChanged = !canceled && lesson.isAcademyChanged;
    final displayStart = staffChanged ? lesson.startsAt : originalStart;
    final displayEnd = staffChanged ? lesson.endsAt : originalEnd;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: canceled ? Colors.black.withValues(alpha: 0.035) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canceled
              ? Colors.black12
              : primaryColor.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: forestringTextStyle.copyWith(
                    color: canceled ? Colors.black45 : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (canceled)
                _pill('취소됨', Colors.black12, Colors.black54)
              else if (staffChanged)
                _pill(
                  '변경',
                  secondaryColor.withValues(alpha: 0.12),
                  secondaryColor,
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${DateFormat('M월 d일 HH:mm').format(displayStart)} ~ '
            '${DateFormat('HH:mm').format(displayEnd)}',
            style: forestringTextStyle.copyWith(
              color: canceled ? Colors.black45 : Colors.black87,
              fontSize: 14,
              decoration: canceled ? TextDecoration.lineThrough : null,
            ),
          ),
          if (lesson.teacherName != null) ...[
            const SizedBox(height: 4),
            Text(
              '${lesson.teacherName} 선생님',
              style: forestringTextStyle.copyWith(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
          if (cancellations.isNotEmpty) ...[
            const SizedBox(height: 9),
            ...List.generate(
              cancellations.length,
              (index) => _cancellationHistoryItem(
                history,
                right,
                cancellations[index],
                index,
              ),
            ),
          ] else if (staffChanged && lesson.updatedAt != null) ...[
            const SizedBox(height: 9),
            Text(
              '학원 관리자 · '
              '${DateFormat('M월 d일 HH:mm').format(lesson.updatedAt!)} 변경',
              style: forestringTextStyle.copyWith(
                color: secondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cancellationHistoryItem(
    LessonHistoryData history,
    LessonRightHistory right,
    LessonCancellationHistory cancellation,
    int index,
  ) {
    final lessonStartsAt = cancellation.lessonStartsAt;
    final lessonEndsAt = lessonStartsAt?.add(
      Duration(
        minutes: cancellation.lessonDurationMinutes ?? right.durationMinutes,
      ),
    );
    final lessonTimeLabel = lessonStartsAt == null || lessonEndsAt == null
        ? null
        : '${DateFormat('M월 d일 HH:mm').format(lessonStartsAt)} ~ '
              '${DateFormat('HH:mm').format(lessonEndsAt)}';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        bottom: index == right.cancellations.length - 1 ? 0 : 6,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}차 취소'
            '${lessonTimeLabel == null ? '' : ' · $lessonTimeLabel'}',
            style: forestringTextStyle.copyWith(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${cancellation.actorLabel(history.studentId)} · '
            '${DateFormat('M월 d일 HH:mm').format(cancellation.canceledAt)} 취소',
            style: forestringTextStyle.copyWith(
              color: Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rebookCard(
    LessonHistoryData history,
    LessonRightHistory right,
  ) {
    final lesson = right.lesson!;
    final reservedAt = right.reservedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: secondaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: secondaryColor.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '재예약 수업',
                  style: forestringTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _pill(
                '재예약',
                secondaryColor.withValues(alpha: 0.14),
                secondaryColor,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${DateFormat('M월 d일 HH:mm').format(lesson.startsAt)} ~ '
            '${DateFormat('HH:mm').format(lesson.endsAt)}',
            style: forestringTextStyle.copyWith(fontSize: 14),
          ),
          if (lesson.teacherName != null) ...[
            const SizedBox(height: 4),
            Text(
              '${lesson.teacherName} 선생님',
              style: forestringTextStyle.copyWith(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
          if (reservedAt != null) ...[
            const SizedBox(height: 9),
            Text(
              '${right.bookingActorLabel(history.studentId)} · '
              '${DateFormat('M월 d일 HH:mm').format(reservedAt)} 재예약',
              style: forestringTextStyle.copyWith(
                color: secondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.14)),
      ),
      child: ExpansionTile(
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
  final int remainingCancellations;
  final int carryoverCount;
}
