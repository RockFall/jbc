import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/hangout.dart';
import '../../../core/theme/continhas_tokens.dart';

class ContinhasHangoutListTile extends StatelessWidget {
  const ContinhasHangoutListTile({
    super.key,
    required this.hangout,
    required this.onTap,
  });

  final Hangout hangout;
  final VoidCallback onTap;

  static String _relativeDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Amanhã';
    if (diff == -1) return 'Ontem';
    if (diff > 1 && diff < 7) return DateFormat.E('pt_BR').format(d);
    return DateFormat('d MMM', 'pt_BR').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final t = ContinhasTokens.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: t.cardBackground,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.07),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: t.cardBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.event_rounded, color: t.brandTeal, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hangout.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_relativeDate(hangout.date)} · '
                          '${hangout.date.day.toString().padLeft(2, '0')}/${hangout.date.month.toString().padLeft(2, '0')}/${hangout.date.year}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: t.subtitleOnCanvas,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 22, color: t.subtitleOnCanvas),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
