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

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xffFFFDF8),
                Color(0xffF3F6EF),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -26,
                  child: Icon(
                    Icons.eco_rounded,
                    size: 116,
                    color: primaryColor.withValues(alpha: 0.055),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: primaryColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 62,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(lesson.startsAt),
                              style: forestringTextStyle.copyWith(
                                color: primaryColor,
                                fontSize: 21,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('HH:mm').format(lesson.endsAt),
                              style: forestringTextStyle.copyWith(
                                color: Colors.black38,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 52,
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        color: primaryColor.withValues(alpha: 0.12),
                      ),
                      Expanded(
                        child: Column(
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
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (badge != null) ...[
                                  const SizedBox(width: 8),
                                  _badge(
                                    badge,
                                    lesson.isStudentRebooked
                                        ? secondaryColor
                                        : primaryColor,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color:
                                        primaryColor.withValues(alpha: 0.07),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.music_note_rounded,
                                    color: primaryColor,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  lesson.displayTypeLabel,
                                  style: forestringTextStyle.copyWith(
                                    color: Colors.black45,
                                    fontSize: 12,
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
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
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
