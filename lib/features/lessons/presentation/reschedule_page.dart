import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/forestring_theme.dart';
import '../domain/lesson.dart';
import '../domain/lesson_history.dart';
import 'lesson_controller.dart';

class ReschedulePage extends StatefulWidget {
  const ReschedulePage({
    super.key,
    this.refreshSignal = 0,
  });

  final int refreshSignal;

  @override
  State<ReschedulePage> createState() => _ReschedulePageState();
}

class _ReschedulePageState extends State<ReschedulePage>
    with SingleTickerProviderStateMixin {
  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  List<LessonRightHistory> _bookingRights = const [];
  String? _selectedRightId;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  LessonBookingWindow? _window;
  List<LessonBookingOption> _options = const [];
  LessonBookingOption? _selectedOption;
  bool _hasSelectedDate = false;
  bool _loadingRights = false;
  bool _loadingWindow = false;
  bool _loadingOptions = false;
  bool _booking = false;
  bool _showBookingSuccess = false;
  LessonBookingOption? _lastBookedOption;
  int _bookingSuccessToken = 0;
  String? _errorMessage;
  bool _initialized = false;
  int _loadToken = 0;
  final GlobalKey _timeSectionKey = GlobalKey();
  final GlobalKey _confirmSectionKey = GlobalKey();
  late final AnimationController _stepPulseController;

  @override
  void initState() {
    super.initState();
    _stepPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _stepPulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReschedulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_initialized || oldWidget.refreshSignal == widget.refreshSignal) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBookingRights();
      }
    });
  }

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

  Future<void> _bringIntoView(
    GlobalKey key, {
    Duration delay = const Duration(milliseconds: 120),
    Duration duration = const Duration(milliseconds: 360),
    double alignment = 0.18,
  }) async {
    await Future<void>.delayed(delay);
    if (!mounted) {
      return;
    }

    final targetContext = key.currentContext;
    if (targetContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: duration,
      curve: Curves.easeInOutCubic,
      alignment: alignment,
    );
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
          _selectedOption = null;
          _hasSelectedDate = false;
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
    await context.read<LessonController>().refreshAll();
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
      _selectedOption = null;
      _hasSelectedDate = false;
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
      _selectedOption = null;
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

  Future<void> _confirmBooking(
    LessonRightHistory right,
    LessonBookingOption option,
  ) async {
    if (_booking || _showBookingSuccess) {
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

    final successToken = ++_bookingSuccessToken;
    setState(() {
      _showBookingSuccess = true;
      _lastBookedOption = option;
    });
    await HapticFeedback.mediumImpact();

    await Future<void>.delayed(const Duration(milliseconds: 2000));
    if (!mounted || successToken != _bookingSuccessToken) {
      return;
    }

    await _loadBookingRights();

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || successToken != _bookingSuccessToken) {
      return;
    }

    setState(() {
      _showBookingSuccess = false;
      _lastBookedOption = null;
    });
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
  ) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: forestringTextStyle.copyWith(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 48,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final selected = _selectedOption?.startsAt == option.startsAt;

              return OutlinedButton(
                onPressed: _booking
                    ? null
                    : () {
                        setState(() {
                          _selectedOption = option;
                        });
                        _bringIntoView(_confirmSectionKey);
                      },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: selected ? Colors.white : Colors.black87,
                  backgroundColor: selected ? primaryColor : Colors.white,
                  disabledForegroundColor: Colors.black26,
                  side: BorderSide(
                    color: selected
                        ? primaryColor
                        : Colors.black.withValues(alpha: 0.10),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _formatBookingTime(option.startsAt),
                  style: forestringTextStyle.copyWith(
                    color: selected ? Colors.white : Colors.black87,
                    fontSize: 15,
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

  Widget _progressIndicator(int currentStep) {
    const labels = ['날짜 선택', '시간 선택', '예약 확인'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List<Widget>.generate(labels.length * 2 - 1, (index) {
          if (index.isOdd) {
            final completed = (index ~/ 2) + 1 < currentStep;
            return Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.only(bottom: 20),
                color: completed
                    ? primaryColor.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.10),
              ),
            );
          }

          final step = index ~/ 2 + 1;
          final active = step == currentStep;
          final completed = step < currentStep;

          return SizedBox(
            width: 84,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _stepPulseController,
                  builder: (context, child) {
                    final pulse = active
                        ? Curves.easeInOut.transform(
                            _stepPulseController.value,
                          )
                        : 0.0;

                    return Transform.scale(
                      scale: active ? 1 + (0.07 * pulse) : 1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: active || completed
                              ? primaryColor
                              : Colors.black.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(
                                      alpha: 0.16 + (0.22 * pulse),
                                    ),
                                    blurRadius: 9 + (13 * pulse),
                                    spreadRadius: 1 + (4 * pulse),
                                  ),
                                ]
                              : const [],
                        ),
                        alignment: Alignment.center,
                        child: child,
                      ),
                    );
                  },
                  child: completed
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 17,
                        )
                      : Text(
                          '${step}',
                          style: forestringTextStyle.copyWith(
                            color: active ? Colors.white : Colors.black45,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[step - 1],
                  textAlign: TextAlign.center,
                  style: forestringTextStyle.copyWith(
                    color: active ? primaryColor : Colors.black45,
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w500 : FontWeight.w300,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }

  Widget _bookingConfirmationCard(
    LessonRightHistory right,
    LessonBookingOption option,
  ) {
    final weekday = _weekdayLabels[option.startsAt.weekday - 1];
    final dateLabel =
        '${DateFormat('M월 d일').format(option.startsAt)} ($weekday)';
    final timeLabel =
        '${DateFormat('HH:mm').format(option.startsAt)} ~ '
        '${DateFormat('HH:mm').format(option.endsAt)}';

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xffE7EFE4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: primaryColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '예약 확인',
                      style: forestringTextStyle.copyWith(
                        color: Colors.black87,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '선택한 날짜와 시간을 확인해 주세요.',
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
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xffF3F6EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: forestringTextStyle.copyWith(
                          color: primaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        timeLabel,
                        style: forestringTextStyle.copyWith(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${right.durationMinutes}분',
                  style: forestringTextStyle.copyWith(
                    color: Colors.black45,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _booking ? null : () => _confirmBooking(right, option),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    primaryColor.withValues(alpha: 0.45),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _booking
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      '이 시간으로 예약하기',
                      style: forestringTextStyle.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slideInFromLeft({
    required Widget child,
    required Key key,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(-0.30, 0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slide,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: key,
        child: child,
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
    final currentStep = _showBookingSuccess
        ? 4
        : _selectedOption != null
            ? 3
            : _hasSelectedDate
                ? 2
                : 1;

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
      backgroundColor: const Color(0xffF8F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xffF8F6F0),
        surfaceTintColor: Colors.transparent,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '수업 예약',
          style: forestringTextStyle.copyWith(
            color: primaryColor,
            fontSize: 21,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: _loadingRights && rights.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : rights.isEmpty
                ? RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: const Color(0xffF8F6F0),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _progressIndicator(currentStep),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final offset = Tween<Offset>(
                            begin: const Offset(0, -0.18),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          );
                        },
                        child: !_showBookingSuccess ||
                                _lastBookedOption == null
                            ? const SizedBox.shrink(
                                key: ValueKey('booking-success-hidden'),
                              )
                            : Container(
                                key: const ValueKey(
                                  'booking-success-visible',
                                ),
                                width: double.infinity,
                                margin: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffE7EFE4),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${DateFormat('M월 d일 HH:mm').format(_lastBookedOption!.startsAt)} 수업 예약이 완료되었습니다.',
                                        style: forestringTextStyle.copyWith(
                                          color: primaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      Divider(
                        height: 1,
                        color: primaryColor.withValues(alpha: 0.07),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                            children: [
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '수업권',
                                style: forestringTextStyle.copyWith(
                                  color: primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '예약에 사용할 수업권을 선택해 주세요.',
                                style: forestringTextStyle.copyWith(
                                  color: Colors.black45,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: selectedRight?.id,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xffF7F8F3),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: primaryColor.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: primaryColor.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.confirmation_number_outlined,
                                    color: primaryColor,
                                  ),
                                ),
                                items: rights
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => DropdownMenuItem<String>(
                                        value: entry.value.id,
                                        child: Text(
                                          '수업권 ${entry.key + 1}',
                                          style: forestringTextStyle.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_loadingWindow)
                          _sectionCard(
                            child: const SizedBox(
                              height: 310,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          )
                        else if (_window != null && selectedRight != null)
                          _sectionCard(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: const BoxDecoration(
                                          color: Color(0xffE7EFE4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.calendar_month_rounded,
                                          color: primaryColor,
                                          size: 19,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '날짜 선택',
                                              style: forestringTextStyle.copyWith(
                                                color: Colors.black87,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '수업을 예약할 날짜를 선택해 주세요.',
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
                                const SizedBox(height: 6),
                                TableCalendar<void>(
                                  firstDay: _dateOnly(_window!.startsOn),
                                  lastDay: _dateOnly(_window!.endsOn),
                                  focusedDay: _focusedDate,
                                  availableGestures:
                                      AvailableGestures.horizontalSwipe,
                                  startingDayOfWeek:
                                      StartingDayOfWeek.sunday,
                                  selectedDayPredicate: (day) =>
                                      _hasSelectedDate &&
                                      isSameDay(_selectedDate, day),
                                  onDaySelected:
                                      _booking ? null : (selectedDay, focusedDay) {
                                    setState(() {
                                      _selectedDate = selectedDay;
                                      _focusedDate = focusedDay;
                                      _hasSelectedDate = true;
                                      _selectedOption = null;
                                    });
                                    _bringIntoView(
                                      _timeSectionKey,
                                      delay: const Duration(milliseconds: 220),
                                      duration:
                                          const Duration(milliseconds: 500),
                                      alignment: 0.38,
                                    );
                                    _loadOptions(selectedRight, selectedDay);
                                  },
                                  onPageChanged: (focusedDay) {
                                    _focusedDate = focusedDay;
                                  },
                                  headerStyle: HeaderStyle(
                                    titleCentered: true,
                                    formatButtonVisible: false,
                                    titleTextFormatter: (date, locale) =>
                                        '${date.year}년 ${date.month}월',
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
                                      fontSize: 18,
                                      color: primaryColor,
                                    ),
                                  ),
                                  calendarStyle: const CalendarStyle(
                                    todayDecoration: BoxDecoration(
                                      color: Color(0xffE7EFE4),
                                      shape: BoxShape.circle,
                                    ),
                                    todayTextStyle: TextStyle(
                                      color: primaryColor,
                                      fontFamily: 'ELAND',
                                      fontWeight: FontWeight.w500,
                                    ),
                                    selectedDecoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    selectedTextStyle: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'ELAND',
                                      fontWeight: FontWeight.w500,
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
                                            color: day.weekday ==
                                                    DateTime.sunday
                                                ? Colors.red
                                                : day.weekday ==
                                                        DateTime.saturday
                                                    ? Colors.blue
                                                    : Colors.black87,
                                          ),
                                        ),
                                      );
                                    },
                                    defaultBuilder:
                                        (context, day, focusedDay) {
                                      final color =
                                          day.weekday == DateTime.sunday
                                              ? Colors.redAccent
                                              : day.weekday ==
                                                      DateTime.saturday
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
                                    todayBuilder:
                                        (context, day, focusedDay) {
                                      final color =
                                          day.weekday == DateTime.sunday
                                              ? Colors.redAccent
                                              : day.weekday ==
                                                      DateTime.saturday
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
                                            style:
                                                forestringTextStyle.copyWith(
                                              color: color,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    outsideBuilder:
                                        (context, day, focusedDay) {
                                      final color =
                                          day.weekday == DateTime.sunday
                                              ? Colors.redAccent.withValues(
                                                  alpha: 0.38,
                                                )
                                              : day.weekday ==
                                                      DateTime.saturday
                                                  ? Colors.blueAccent
                                                      .withValues(alpha: 0.38)
                                                  : Colors.black26;
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
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          _sectionCard(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 52,
                              ),
                              child: Text(
                                _errorMessage ?? '예약 정보를 불러오지 못했습니다.',
                                textAlign: TextAlign.center,
                                style: forestringTextStyle.copyWith(
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                              _slideInFromLeft(
                                key: ValueKey(
                                  _hasSelectedDate && selectedRight != null
                                      ? 'time-visible'
                                      : 'time-hidden',
                                ),
                                child: !_hasSelectedDate ||
                                        selectedRight == null
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        padding:
                                            const EdgeInsets.only(top: 14),
                                        child: _sectionCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          key: _timeSectionKey,
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: const BoxDecoration(
                                                color: Color(0xffE7EFE4),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.schedule_rounded,
                                                color: primaryColor,
                                                size: 19,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '예약 가능한 시간',
                                                    style: forestringTextStyle
                                                        .copyWith(
                                                      color: Colors.black87,
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${DateFormat('M월 d일').format(_selectedDate)}에 가능한 시간을 선택해 주세요.',
                                                    style: forestringTextStyle
                                                        .copyWith(
                                                      color: Colors.black45,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          switchInCurve: Curves.easeOutCubic,
                                          child: _loadingOptions
                                              ? const SizedBox(
                                                  key: ValueKey('loading'),
                                                  height: 150,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                )
                                              : _errorMessage != null
                                                  ? Padding(
                                                      key: const ValueKey(
                                                          'error'),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              18),
                                                      child: Text(
                                                        _errorMessage!,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            forestringTextStyle
                                                                .copyWith(
                                                          color:
                                                              Colors.redAccent,
                                                        ),
                                                      ),
                                                    )
                                                  : _options.isEmpty
                                                      ? Padding(
                                                          key: const ValueKey(
                                                              'empty'),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            vertical: 32,
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              '예약 가능한 시간이 없습니다.',
                                                              style:
                                                                  forestringTextStyle
                                                                      .copyWith(
                                                                color: Colors
                                                                    .black45,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : Column(
                                                          key: const ValueKey(
                                                              'options'),
                                                          children: [
                                                            _timeGroup(
                                                              '오전',
                                                              _options
                                                                  .where(
                                                                    (option) =>
                                                                        option
                                                                            .startsAt
                                                                            .hour <
                                                                        12,
                                                                  )
                                                                  .toList(),
                                                            ),
                                                            _timeGroup(
                                                              '오후',
                                                              _options
                                                                  .where(
                                                                    (option) =>
                                                                        option
                                                                            .startsAt
                                                                            .hour >=
                                                                        12,
                                                                  )
                                                                  .toList(),
                                                            ),
                                                          ],
                                                        ),
                                        ),
                                      ],
                                    ),
                                        ),
                                      ),
                              ),
                              _slideInFromLeft(
                                key: ValueKey(
                                  _selectedOption == null
                                      ? 'confirm-hidden'
                                      : 'confirm-visible',
                                ),
                                child: selectedRight == null ||
                                        _selectedOption == null
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        key: _confirmSectionKey,
                                        padding:
                                            const EdgeInsets.only(top: 14),
                                        child: _bookingConfirmationCard(
                                          selectedRight,
                                          _selectedOption!,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

}