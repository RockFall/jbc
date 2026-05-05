import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/profile/jbc_profile.dart';
import '../../data/models/availability.dart';
import '../../data/models/hangout.dart';
import 'hangouts_format.dart';
import 'week_view_layout.dart';

Color weekGridColorForPerson(String storageKey) {
  switch (storageKey) {
    case 'caio':
      return const Color(0xFF1565C0);
    case 'jojo':
      return const Color(0xFF2E7D32);
    case 'bibi':
      return const Color(0xFF6A1B9A);
    default:
      return const Color(0xFF607D8B);
  }
}

/// Grade semanal (7 colunas × faixa horária). Rolês sobrepostos: colunas por componente de sobreposição (`week_view_layout.dart`).
class WeekGridView extends StatelessWidget {
  const WeekGridView({
    super.key,
    required this.weekMonday,
    required this.hangoutsInWeek,
    required this.availabilities,
    required this.visiblePeople,
    this.onHangoutTap,
    this.window = const WeekGridTimeWindow(firstHour: 6, lastHour: 24),
    this.pixelsPerHour = 44,
  });

  final DateTime weekMonday;
  final List<Hangout> hangoutsInWeek;
  final List<Availability> availabilities;
  final Set<String> visiblePeople;
  final ValueChanged<Hangout>? onHangoutTap;
  final WeekGridTimeWindow window;
  final double pixelsPerHour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = hangoutDateOnly(DateTime.now());
    final now = DateTime.now();

    final hangoutBlocks = layoutHangoutsForWeek(
      weekMonday: weekMonday,
      hangouts: hangoutsInWeek,
      window: window,
    );
    final availBlocks = layoutAvailabilitiesForWeek(
      weekMonday: weekMonday,
      availabilities: availabilities,
      visiblePeople: visiblePeople,
      window: window,
    );

    final hoursShown = window.lastHour - window.firstHour;
    final gridInnerHeight = hoursShown * pixelsPerHour;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          height: gridInnerHeight + 36,
          child: Column(
            children: [
              const SizedBox(height: 36),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < hoursShown; i++)
                      SizedBox(
                        height: pixelsPerHour,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              '${window.firstHour + i}h',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              SizedBox(
                height: 36,
                child: Row(
                  children: List.generate(7, (dayIndex) {
                    final d = weekMonday.add(Duration(days: dayIndex));
                    final isToday = hangoutDateOnly(d) == today;
                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isToday ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
                          border: Border(
                            bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${weekdayShortPt(d.weekday)}\n${d.day}/${d.month}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                              color: isToday ? scheme.primary : null,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(
                height: gridInnerHeight,
                child: Row(
                  children: List.generate(7, (dayIndex) {
                    final d = weekMonday.add(Duration(days: dayIndex));
                    final isToday = hangoutDateOnly(d) == today;
                    final nowMin = now.hour * 60 + now.minute;
                    return Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          Widget? nowLine;
                          if (isToday) {
                            final y = normalizedYFromMinutes(nowMin, window) * gridInnerHeight;
                            if (y >= 0 && y <= gridInnerHeight) {
                              nowLine = Positioned(
                                top: y,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2,
                                  color: scheme.error.withValues(alpha: 0.85),
                                ),
                              );
                            }
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
                                  right: dayIndex == 6
                                      ? BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35))
                                      : BorderSide.none,
                                ),
                              ),
                              child: Stack(
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  CustomPaint(
                                    size: Size(w, gridInnerHeight),
                                    painter: _WeekHourGridPainter(
                                      hours: hoursShown,
                                      pixelsPerHour: pixelsPerHour,
                                      color: scheme.outlineVariant.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  for (final b in availBlocks.where((x) => x.dayIndex == dayIndex))
                                    Positioned(
                                      left: 2,
                                      right: 2,
                                      top: b.top * gridInnerHeight,
                                      height: (b.height * gridInnerHeight).clamp(4.0, gridInnerHeight),
                                      child: Material(
                                        color: weekGridColorForPerson(b.availability.person)
                                            .withValues(alpha: 0.38),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Tooltip(
                                          message:
                                              '${JbcProfile.displayNameForStorageKey(b.availability.person)} · '
                                              '${b.availability.startTime}–${b.availability.endTime}',
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 2),
                                              child: Text(
                                                (b.availability.title != null &&
                                                        b.availability.title!.trim().isNotEmpty)
                                                    ? b.availability.title!.trim()
                                                    : JbcProfile.displayNameForStorageKey(b.availability.person),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  for (final b in hangoutBlocks.where((x) => x.dayIndex == dayIndex))
                                    Positioned(
                                      left: 2 + b.left * (w - 4),
                                      width: (b.width * (w - 4)).clamp(8.0, w),
                                      top: b.top * gridInnerHeight,
                                      height: (b.height * gridInnerHeight).clamp(6.0, gridInnerHeight),
                                      child: Material(
                                        elevation: 1,
                                        borderRadius: BorderRadius.circular(6),
                                        color: scheme.secondaryContainer,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(6),
                                          onTap: onHangoutTap == null ? null : () => onHangoutTap!(b.hangout),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  b.hangout.title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: scheme.onSecondaryContainer,
                                                  ),
                                                ),
                                                Text(
                                                  '${b.hangout.startTime}'
                                                  '${b.hangout.endTime != null && b.hangout.endTime!.isNotEmpty ? '–${b.hangout.endTime}' : ''}',
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    fontSize: 9,
                                                    color: scheme.onSecondaryContainer.withValues(alpha: 0.9),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (nowLine case final Widget line) line,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekHourGridPainter extends CustomPainter {
  _WeekHourGridPainter({
    required this.hours,
    required this.pixelsPerHour,
    required this.color,
  });

  final int hours;
  final double pixelsPerHour;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 0; i <= hours; i++) {
      final y = i * pixelsPerHour;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _WeekHourGridPainter oldDelegate) {
    return oldDelegate.hours != hours ||
        oldDelegate.pixelsPerHour != pixelsPerHour ||
        oldDelegate.color != color;
  }
}

/// Navegação por semana (deslize horizontal ou setas).
class WeekSchedulePager extends StatefulWidget {
  const WeekSchedulePager({
    super.key,
    required this.viewportHeight,
    required this.hangouts,
    required this.availabilities,
    required this.visiblePeople,
    required this.onHangoutTap,
  });

  /// Altura útil para a área da grade (descontando cabeçalhos externos, se houver).
  final double viewportHeight;
  final List<Hangout> hangouts;
  final List<Availability> availabilities;
  final Set<String> visiblePeople;
  final ValueChanged<Hangout> onHangoutTap;

  @override
  State<WeekSchedulePager> createState() => _WeekSchedulePagerState();
}

class _WeekSchedulePagerState extends State<WeekSchedulePager> {
  static const _pageCount = 2001;
  static const _mid = 1000;
  late final PageController _controller = PageController(initialPage: _mid, viewportFraction: 1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _mondayForPage(int page) {
    final anchor = mondayOfWeekContaining(DateTime.now());
    return anchor.add(Duration(days: 7 * (page - _mid)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = DateFormat.yMMMEd('pt_BR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Semana anterior',
              onPressed: () {
                _controller.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final page = _controller.hasClients
                      ? (_controller.page ?? _controller.initialPage.toDouble()).round().clamp(0, _pageCount - 1)
                      : _mid;
                  final mon = _mondayForPage(page);
                  final sun = mon.add(const Duration(days: 6));
                  return Text(
                    '${label.format(mon)} — ${label.format(sun)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  );
                },
              ),
            ),
            IconButton(
              tooltip: 'Semana seguinte',
              onPressed: () {
                _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Rolês ao mesmo tempo: colunas lado a lado no mesmo dia (cada grupo ligado por sobreposição de horário).',
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: (widget.viewportHeight - 120).clamp(200.0, 2000.0),
          child: PageView.builder(
            controller: _controller,
            itemCount: _pageCount,
            itemBuilder: (context, page) {
              final mon = _mondayForPage(page);
              final weekHangouts = hangoutsIntersectingWeek(mon, widget.hangouts);
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: WeekGridView(
                  weekMonday: mon,
                  hangoutsInWeek: weekHangouts,
                  availabilities: widget.availabilities,
                  visiblePeople: widget.visiblePeople,
                  onHangoutTap: widget.onHangoutTap,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
