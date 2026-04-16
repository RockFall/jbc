import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/timeline_event.dart';
import 'timeline_event_detail_screen.dart';
import 'timeline_scroll_background_painter.dart';
import 'timeline_theme.dart';

/// Trecho da haste entre dois eventos: mais recente acima, mais antigo abaixo.
///
/// Escala **linear em dias** (com fração de dia a partir da diferença em ms),
/// para a distância visual acompanhar o tempo real. Referência com 6 px/dia:
/// ~1 semana ≈ 56 px, ~1 mês ≈ 180 px, ~1 ano ≈ 2 200 px.
/// Só existe um teto alto para evitar valores absurdos (erro de data).
double _timelineGapHeightPx(DateTime newer, DateTime older) {
  final days =
      (newer.difference(older).inMilliseconds / Duration.millisecondsPerDay)
          .abs();

  const minPx = 14.0;
  const pixelsPerDay = 6.0;
  const safetyMaxPx = 56000.0;

  if (days < 1e-9) return minPx;

  return (minPx + days * pixelsPerDay).clamp(minPx, safetyMaxPx);
}

enum _RailSegment { only, first, middle, last }

_RailSegment _railSegmentFor(int index, int length) {
  if (length <= 1) return _RailSegment.only;
  if (index == 0) return _RailSegment.first;
  if (index == length - 1) return _RailSegment.last;
  return _RailSegment.middle;
}

double _estimateCardBlockHeight(TimelineEvent e) {
  const captionMat = 88.0;
  const topPad = 10.0;
  final hasImg =
      e.coverImageUrl != null && e.coverImageUrl!.trim().isNotEmpty;
  if (hasImg) {
    return topPad +
        40 +
        (396 * 3 / 4 * timelinePolaroidImageBoost) +
        14 +
        captionMat +
        36 +
        timelinePolaroidLayoutBottomBleed;
  }
  return topPad + captionMat + 36 + timelinePolaroidLayoutBottomBleed;
}

double _estimateListContentHeight(List<TimelineEvent> sorted) {
  if (sorted.isEmpty) return 800;
  var h = 16.0 + 28.0;
  for (var i = 0; i < sorted.length; i++) {
    if (i > 0) {
      h += _timelineGapHeightPx(sorted[i - 1].occurredAt, sorted[i].occurredAt);
    }
    h += _estimateCardBlockHeight(sorted[i]);
  }
  return h * 1.12 + 720;
}

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(timelineEventsProvider);

    Future<void> onRefresh() async {
      ref.invalidate(timelineEventsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    return async.when(
      skipLoadingOnReload: true,
      data: (events) {
        final sorted = [...events]
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
        final scheme = Theme.of(context).colorScheme;
        if (sorted.isEmpty) {
          return DecoratedBox(
            decoration: timelineListBackgroundDecoration(scheme),
            child: RefreshIndicator(
              onRefresh: onRefresh,
              color: scheme.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.4,
                    child: _TimelineEmptyState(theme: Theme.of(context)),
                  ),
                ],
              ),
            ),
          );
        }
        return _TimelineEventsScrollView(
          sorted: sorted,
          scheme: scheme,
          onRefresh: onRefresh,
          onEventOpen: (e) async {
            unawaited(HapticFeedback.selectionClick());
            await Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => TimelineEventDetailScreen(initialEvent: e),
              ),
            );
            if (context.mounted) {
              ref.invalidate(timelineEventsProvider);
            }
          },
        );
      },
      loading: () {
        final scheme = Theme.of(context).colorScheme;
        return DecoratedBox(
          decoration: timelineListBackgroundDecoration(scheme),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, _) {
        final scheme = Theme.of(context).colorScheme;
        return DecoratedBox(
          decoration: timelineListBackgroundDecoration(scheme),
          child: _TimelineErrorState(
            error: error,
            onRetry: () => ref.invalidate(timelineEventsProvider),
          ),
        );
      },
    );
  }

}

class _TimelineEventsScrollView extends StatefulWidget {
  const _TimelineEventsScrollView({
    required this.sorted,
    required this.scheme,
    required this.onRefresh,
    required this.onEventOpen,
  });

  final List<TimelineEvent> sorted;
  final ColorScheme scheme;
  final Future<void> Function() onRefresh;
  final Future<void> Function(TimelineEvent event) onEventOpen;

  @override
  State<_TimelineEventsScrollView> createState() => _TimelineEventsScrollViewState();
}

class _TimelineEventsScrollViewState extends State<_TimelineEventsScrollView> {
  final ScrollController _scrollController = ScrollController();
  late double _documentBgHeight;

  @override
  void initState() {
    super.initState();
    _documentBgHeight = _estimateListContentHeight(widget.sorted);
    _scrollController.addListener(_growDocumentBackgroundIfNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _growDocumentBackgroundIfNeeded();
      _precacheCovers();
    });
  }

  void _growDocumentBackgroundIfNeeded() {
    if (!mounted) return;
    final est = _estimateListContentHeight(widget.sorted);
    var target = est;
    if (_scrollController.hasClients) {
      final p = _scrollController.position;
      target = math.max(
        target,
        p.maxScrollExtent + p.viewportDimension + 800,
      );
    }
    if (target > _documentBgHeight) {
      setState(() => _documentBgHeight = target);
    }
  }

  void _precacheCovers() {
    if (!mounted) return;
    for (final e in widget.sorted) {
      final u = e.coverImageUrl?.trim();
      if (u != null && u.isNotEmpty) {
        unawaited(precacheImage(CachedNetworkImageProvider(u), context));
      }
    }
  }

  @override
  void didUpdateWidget(covariant _TimelineEventsScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.sorted, widget.sorted)) {
      setState(() {
        _documentBgHeight = _estimateListContentHeight(widget.sorted);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _growDocumentBackgroundIfNeeded();
        _precacheCovers();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_growDocumentBackgroundIfNeeded);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgPaintHeight = math.max(_documentBgHeight, 400.0);
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: ClipRect(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _scrollController,
                builder: (context, _) {
                  final offset = _scrollController.hasClients
                      ? _scrollController.offset
                      : 0.0;
                  return CustomPaint(
                    painter: TimelineDocumentBackgroundPainter(
                      scheme: widget.scheme,
                      contentHeight: bgPaintHeight,
                      scrollOffset: offset,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            _growDocumentBackgroundIfNeeded();
            return false;
          },
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            color: widget.scheme.primary,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
              itemCount: widget.sorted.length,
              itemBuilder: (context, index) {
                final e = widget.sorted[index];
                final lineAlpha = timelineRailAlphaForIndex(
                  index: index,
                  total: widget.sorted.length,
                );
                final alignRight = index.isEven;
                final segment = _railSegmentFor(index, widget.sorted.length);
                final gapH = index > 0
                    ? _timelineGapHeightPx(
                        widget.sorted[index - 1].occurredAt,
                        e.occurredAt,
                      )
                    : 0.0;
                final gapLineColor =
                    widget.scheme.primary.withValues(alpha: lineAlpha * 0.75);
                final rowLineColor =
                    widget.scheme.primary.withValues(alpha: lineAlpha);

                return RepaintBoundary(
                  child: Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.passthrough,
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _TimelineMergedRailPainter(
                              gapHeight: gapH,
                              segment: segment,
                              gapLineColor: gapLineColor,
                              rowLineColor: rowLineColor,
                              dotFillColor: widget.scheme.primary,
                              dotBorderColor: widget.scheme.surface,
                            ),
                          ),
                        ),
                      ),
                      RepaintBoundary(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (index > 0) SizedBox(height: gapH),
                            _TimelineRowContent(
                              alignRight: alignRight,
                              child: _TimelineEventNode(
                                event: e,
                                listIndex: index,
                                alignCardTowardCenter: alignRight,
                                onOpenDetail: () => widget.onEventOpen(e),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineEmptyState extends StatelessWidget {
  const _TimelineEmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 52,
            color: scheme.primary.withValues(alpha: 0.88),
          ),
          const SizedBox(height: 20),
          Text(
            'Ainda não há memórias',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Toque no + abaixo para registrar o primeiro momento. '
            'A linha do tempo fica aqui, à espera de vocês.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_outline, size: 22, color: scheme.outline.withValues(alpha: 0.55)),
              const SizedBox(width: 10),
              CustomPaint(
                size: const Size(72, 2),
                painter: _TimelineDashesPainter(color: scheme.outline.withValues(alpha: 0.4)),
              ),
              const SizedBox(width: 10),
              Icon(Icons.add_circle_outline, size: 26, color: scheme.primary.withValues(alpha: 0.75)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineDashesPainter extends CustomPainter {
  _TimelineDashesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 5.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width), y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineDashesPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _TimelineErrorState extends StatelessWidget {
  const _TimelineErrorState({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: scheme.error.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 18),
              Text(
                'Não deu para carregar a linha do tempo',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$error',
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineGapPainter extends CustomPainter {
  _TimelineGapPainter({required this.lineColor});

  final Color lineColor;

  static const _lineW = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    if (size.height <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - _lineW / 2, 0, _lineW, size.height),
        topLeft: Radius.zero,
        topRight: Radius.zero,
        bottomLeft: Radius.zero,
        bottomRight: Radius.zero,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimelineGapPainter oldDelegate) =>
      lineColor != oldDelegate.lineColor;
}

/// Haste no gap + haste/nó na zona do cartão — **uma** camada por baixo da [Column]
/// (evita a linha do gap seguinte por cima da polaroid sem [ClipRect]).
class _TimelineMergedRailPainter extends CustomPainter {
  _TimelineMergedRailPainter({
    required this.gapHeight,
    required this.segment,
    required this.gapLineColor,
    required this.rowLineColor,
    required this.dotFillColor,
    required this.dotBorderColor,
  });

  final double gapHeight;
  final _RailSegment segment;
  final Color gapLineColor;
  final Color rowLineColor;
  final Color dotFillColor;
  final Color dotBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final g = gapHeight.clamp(0.0, size.height);
    if (g > 0) {
      _TimelineGapPainter(lineColor: gapLineColor).paint(
        canvas,
        Size(size.width, g),
      );
    }
    final rowH = size.height - g;
    if (rowH <= 0) return;
    canvas.save();
    canvas.translate(0, g);
    _TimelineRailLinePainter(segment: segment, lineColor: rowLineColor).paint(
      canvas,
      Size(size.width, rowH),
    );
    _TimelineRailDotPainter(
      segment: segment,
      dotFillColor: dotFillColor,
      dotBorderColor: dotBorderColor,
    ).paint(canvas, Size(size.width, rowH));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TimelineMergedRailPainter oldDelegate) {
    return gapHeight != oldDelegate.gapHeight ||
        segment != oldDelegate.segment ||
        gapLineColor != oldDelegate.gapLineColor ||
        rowLineColor != oldDelegate.rowLineColor ||
        dotFillColor != oldDelegate.dotFillColor ||
        dotBorderColor != oldDelegate.dotBorderColor;
  }
}

/// Traço + nó da haste na zona do cartão (só usados dentro de [_TimelineMergedRailPainter]).
class _TimelineRailLinePainter extends CustomPainter {
  _TimelineRailLinePainter({
    required this.segment,
    required this.lineColor,
  });

  final _RailSegment segment;
  final Color lineColor;

  static const _lineW = 3.0;
  static const _dotR = 7.0;

  bool get _lineToTop =>
      segment == _RailSegment.middle || segment == _RailSegment.last;

  bool get _lineToBottom =>
      segment == _RailSegment.middle || segment == _RailSegment.first;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    if (_lineToTop) {
      final topH = (cy - _dotR).clamp(0.0, size.height);
      if (topH > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(cx - _lineW / 2, 0, _lineW, topH),
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2),
          ),
          linePaint,
        );
      }
    }

    if (_lineToBottom) {
      final y0 = cy + _dotR;
      final botH = size.height - y0;
      if (botH > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(cx - _lineW / 2, y0, _lineW, botH),
            bottomLeft: const Radius.circular(2),
            bottomRight: const Radius.circular(2),
          ),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineRailLinePainter oldDelegate) {
    return segment != oldDelegate.segment || lineColor != oldDelegate.lineColor;
  }
}

class _TimelineRailDotPainter extends CustomPainter {
  _TimelineRailDotPainter({
    required this.segment,
    required this.dotFillColor,
    required this.dotBorderColor,
  });

  final _RailSegment segment;
  final Color dotFillColor;
  final Color dotBorderColor;

  static const _dotR = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    _drawDot(canvas, size.width / 2, size.height / 2);
  }

  void _drawDot(Canvas canvas, double cx, double cy) {
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: _dotR));
    canvas.drawShadow(path, Colors.black26, 2.4, false);

    canvas.drawCircle(Offset(cx, cy), _dotR, Paint()..color = dotFillColor);

    canvas.drawCircle(
      Offset(cx, cy),
      _dotR,
      Paint()
        ..color = dotBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _TimelineRailDotPainter oldDelegate) {
    return segment != oldDelegate.segment ||
        dotFillColor != oldDelegate.dotFillColor ||
        dotBorderColor != oldDelegate.dotBorderColor;
  }
}

class _TimelineRowContent extends StatelessWidget {
  const _TimelineRowContent({
    required this.alignRight,
    required this.child,
  });

  final bool alignRight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Align(
            alignment: alignRight ? Alignment.topRight : Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: alignRight ? 4 : 20,
                right: alignRight ? 20 : 4,
              ),
              child: alignRight ? child : const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: alignRight ? Alignment.topLeft : Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(
                left: alignRight ? 20 : 4,
                right: alignRight ? 4 : 20,
              ),
              child: alignRight ? const SizedBox.shrink() : child,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineEventNode extends StatelessWidget {
  const _TimelineEventNode({
    required this.event,
    required this.onOpenDetail,
    required this.alignCardTowardCenter,
    required this.listIndex,
  });

  final TimelineEvent event;
  final Future<void> Function() onOpenDetail;
  final bool alignCardTowardCenter;
  final int listIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final dateStr = DateFormat('dd/MM/yyyy').format(event.occurredAt.toLocal());
    final desc = event.description.trim();
    final cover = event.coverImageUrl;
    final hasImageUrl = cover != null && cover.trim().isNotEmpty;
    final variant = timelineVisualVariantFor(
      eventId: event.id,
      listIndex: listIndex,
      reduceMotion: reduceMotion,
    );

    // Não usar Padding negativo (assert no framework); deslocar com Transform.
    final overlapDx =
        alignCardTowardCenter ? timelineRailOverlapPx : -timelineRailOverlapPx;

    final polaroidStack = Padding(
      padding: const EdgeInsets.fromLTRB(
        6,
        10,
        6,
        timelinePolaroidLayoutBottomBleed,
      ),
      child: RepaintBoundary(
        child: Transform.translate(
          offset: Offset(overlapDx, 0),
          child: Transform.rotate(
            angle: variant.rotationRadians,
            child: Transform.scale(
              scale: variant.widthFactor,
              child: _TimelinePolaroidFrame(
                scheme: scheme,
                authorSignature:
                    JbcProfile.displayNameForStorageKey(event.createdBy),
                image: hasImageUrl
                    ? AspectRatio(
                        aspectRatio: 4 / 3,
                        child: _TimelineCardImage(
                          coverUrl: cover,
                          scheme: scheme,
                        ),
                      )
                    : null,
                caption: _TimelinePolaroidCaption(
                  title: event.title,
                  dateStr: dateStr,
                  hasDescription: desc.isNotEmpty,
                  isHangout: event.origin == TimelineEventOrigin.fromHangout,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 432),
      child: Material(
        type: MaterialType.transparency,
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.none,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () => unawaited(onOpenDetail()),
          borderRadius: BorderRadius.circular(20),
          splashColor: scheme.primary.withValues(alpha: 0.08),
          highlightColor: scheme.primary.withValues(alpha: 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [polaroidStack],
          ),
        ),
      ),
    );
  }
}

/// Título + data na faixa branca da polaroid (manuscrito); ícones discretos.
class _TimelinePolaroidCaption extends StatelessWidget {
  const _TimelinePolaroidCaption({
    required this.title,
    required this.dateStr,
    required this.hasDescription,
    required this.isHangout,
  });

  final String title;
  final String dateStr;
  final bool hasDescription;
  final bool isHangout;

  static const _ink = Color(0xFF2A2224);
  static const _inkSoft = Color(0xFF4A3E41);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.caveat(
            fontSize: 22,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          dateStr,
          style: GoogleFonts.caveat(
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w500,
            color: _inkSoft,
          ),
        ),
        if (hasDescription || isHangout) ...[
          const SizedBox(height: 7),
          Row(
            children: [
              if (hasDescription)
                Icon(
                  Icons.notes_rounded,
                  size: 15,
                  color: _inkSoft.withValues(alpha: 0.4),
                ),
              if (hasDescription && isHangout) const SizedBox(width: 10),
              if (isHangout)
                Icon(
                  Icons.celebration_outlined,
                  size: 14,
                  color: _inkSoft.withValues(alpha: 0.36),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TimelinePolaroidFrame extends StatelessWidget {
  const _TimelinePolaroidFrame({
    required this.scheme,
    required this.authorSignature,
    this.image,
    this.caption,
  });

  final ColorScheme scheme;
  final String authorSignature;
  final Widget? image;
  final Widget? caption;

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null;
    final sig = authorSignature.trim();
    final showSig = sig.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: timelinePolaroidMatColor(scheme),
        borderRadius: BorderRadius.circular(timelinePolaroidOuterRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 11,
            offset: const Offset(0, 4),
            spreadRadius: -1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(timelinePolaroidOuterRadius),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasImage)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      timelinePolaroidPadH,
                      timelinePolaroidPadTop,
                      timelinePolaroidPadH,
                      0,
                    ),
                    child: Transform.scale(
                      scale: timelinePolaroidImageBoost,
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(timelinePolaroidInnerRadius),
                        child: image!,
                      ),
                    ),
                  ),
                if (caption != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      timelinePolaroidPadH,
                      hasImage ? 10 : timelinePolaroidPadTop,
                      timelinePolaroidPadH,
                      timelinePolaroidPadBottom,
                    ),
                    child: caption,
                  )
                else if (hasImage)
                  const SizedBox(height: timelinePolaroidPadBottom),
              ],
            ),
            if (showSig)
              Positioned(
                right: timelinePolaroidPadH - 0.5,
                bottom: 5,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    sig,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dancingScript(
                      fontSize: timelinePolaroidSignatureFontSize,
                      height: 1.0,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF2A2224).withValues(alpha: 0.52),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCardImage extends StatelessWidget {
  const _TimelineCardImage({
    required this.coverUrl,
    required this.scheme,
  });

  final String? coverUrl;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (coverUrl != null && coverUrl!.trim().isNotEmpty) {
      final url = coverUrl!.trim();
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (context, _) => _TimelineImageSkeleton(scheme: scheme),
            errorWidget: (context, url, error) =>
                _TimelineImagePlaceholder(scheme: scheme, broken: true),
          ),
        ],
      );
    }
    return _TimelineImagePlaceholder(scheme: scheme, broken: false);
  }
}

class _TimelineImageSkeleton extends StatelessWidget {
  const _TimelineImageSkeleton({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final base = scheme.surfaceContainerHighest;
    return ColoredBox(
      color: base,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: scheme.outline.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.outline.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineImagePlaceholder extends StatelessWidget {
  const _TimelineImagePlaceholder({
    required this.scheme,
    required this.broken,
  });

  final ColorScheme scheme;
  final bool broken;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          broken ? Icons.broken_image_outlined : Icons.photo_library_outlined,
          size: 56,
          color: scheme.outline.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}
