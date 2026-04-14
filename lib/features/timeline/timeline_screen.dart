import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../data/models/timeline_event.dart';
import 'timeline_event_detail_screen.dart';

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
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: sorted.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.35,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Nenhuma memória ainda.\nToque em + para registrar o primeiro momento.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final e = sorted[index];
                    final scheme = Theme.of(context).colorScheme;
                    final lineColor = scheme.primary.withValues(alpha: 0.4);
                    final alignRight = index.isEven;
                    final segment = _railSegmentFor(index, sorted.length);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index > 0)
                          _TimelineGap(
                            height: _timelineGapHeightPx(
                              sorted[index - 1].occurredAt,
                              e.occurredAt,
                            ),
                            lineColor: lineColor,
                          ),
                        _TimelineRow(
                          alignRight: alignRight,
                          segment: segment,
                          child: _TimelineEventNode(
                            event: e,
                            onEdit: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      TimelineEventDetailScreen(initialEvent: e),
                                ),
                              );
                              if (context.mounted) {
                                ref.invalidate(timelineEventsProvider);
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Não foi possível carregar a linha do tempo.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(timelineEventsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/// Continuação da haste no espaço proporcional ao tempo entre dois eventos.
class _TimelineGap extends StatelessWidget {
  const _TimelineGap({
    required this.height,
    required this.lineColor,
  });

  final double height;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TimelineGapPainter(lineColor: lineColor),
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

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.alignRight,
    required this.segment,
    required this.child,
  });

  final bool alignRight;
  final _RailSegment segment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lineColor = scheme.primary.withValues(alpha: 0.4);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Align(
                alignment: alignRight ? Alignment.topRight : Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: alignRight ? 8 : 16,
                    right: alignRight ? 16 : 8,
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
                    left: alignRight ? 16 : 8,
                    right: alignRight ? 8 : 16,
                  ),
                  child: alignRight ? const SizedBox.shrink() : child,
                ),
              ),
            ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _TimelineRailPainter(
                segment: segment,
                lineColor: lineColor,
                dotBorderColor: scheme.surface,
                dotFillColor: scheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Desenha linha + ponto no eixo vertical central (sem [LayoutBuilder], compatível com [ListView]).
class _TimelineRailPainter extends CustomPainter {
  _TimelineRailPainter({
    required this.segment,
    required this.lineColor,
    required this.dotBorderColor,
    required this.dotFillColor,
  });

  final _RailSegment segment;
  final Color lineColor;
  final Color dotBorderColor;
  final Color dotFillColor;

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

    final fillPaint = Paint()..color = dotFillColor;
    canvas.drawCircle(Offset(cx, cy), _dotR, fillPaint);

    final borderPaint = Paint()
      ..color = dotBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), _dotR, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _TimelineRailPainter oldDelegate) {
    return segment != oldDelegate.segment ||
        lineColor != oldDelegate.lineColor ||
        dotBorderColor != oldDelegate.dotBorderColor ||
        dotFillColor != oldDelegate.dotFillColor;
  }
}

class _TimelineEventNode extends StatelessWidget {
  const _TimelineEventNode({
    required this.event,
    required this.onEdit,
  });

  final TimelineEvent event;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final dateStr = DateFormat('dd/MM/yyyy').format(event.occurredAt.toLocal());
    final desc = event.description.trim();
    final cover = event.coverImageUrl;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Material(
        color: surface,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (cover != null && cover.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      cover,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        desc,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (event.origin == TimelineEventOrigin.fromHangout) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Rolê',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
