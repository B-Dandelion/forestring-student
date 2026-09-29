import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/forestring_theme.dart';
import '../../domain/lesson.dart';

class StudentLessonCard extends StatelessWidget {
  const StudentLessonCard({
    super.key,
    required this.lesson,
    this.onTap,
  });

  final Lesson lesson;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = lesson.changeBadgeLabel;
    final badgeColor =
        lesson.isStudentRebooked ? secondaryColor : primaryColor;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.10),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 58,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('HH:mm').format(lesson.startsAt),
                                style: forestringTextStyle.copyWith(
                                  color: primaryColor,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('HH:mm').format(lesson.endsAt),
                                style: forestringTextStyle.copyWith(
                                  color: Colors.black38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 42,
                          margin: const EdgeInsets.symmetric(horizontal: 14),
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${lesson.teacherName ?? '담당 선생님'} 선생님',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: forestringTextStyle.copyWith(
                                        color: Colors.black87,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (badge != null) ...[
                                    const SizedBox(width: 8),
                                    _statusBadge(badge, badgeColor),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                lesson.displayTypeLabel,
                                style: forestringTextStyle.copyWith(
                                  color: Colors.black45,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: forestringTextStyle.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class StudentLessonHistoryCard extends StatelessWidget {
  const StudentLessonHistoryCard({
    super.key,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    this.teacherName,
    this.statusLabel,
    this.statusColor = primaryColor,
    this.isCanceled = false,
    this.footer,
  });

  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? teacherName;
  final String? statusLabel;
  final Color statusColor;
  final bool isCanceled;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isCanceled ? const Color(0xff9B7474) : statusColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: isCanceled
            ? const Color(0xffFAF7F5)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCanceled
              ? const Color(0xff9B7474).withValues(alpha: 0.18)
              : primaryColor.withValues(alpha: 0.10),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 96,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('M월 d일').format(startsAt),
                                style: forestringTextStyle.copyWith(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${DateFormat('HH:mm').format(startsAt)} ~ ${DateFormat('HH:mm').format(endsAt)}',
                                style: forestringTextStyle.copyWith(
                                  color: isCanceled
                                      ? Colors.black54
                                      : primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  decoration: isCanceled
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      teacherName == null
                                          ? title
                                          : '$teacherName 선생님',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: forestringTextStyle.copyWith(
                                        color: Colors.black87,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (statusLabel != null) ...[
                                    const SizedBox(width: 7),
                                    _historyBadge(
                                      statusLabel!,
                                      isCanceled
                                          ? const Color(0xff8E5F5F)
                                          : statusColor,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                title,
                                style: forestringTextStyle.copyWith(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 10),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: forestringTextStyle.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
