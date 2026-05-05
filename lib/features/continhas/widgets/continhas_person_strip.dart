import 'package:flutter/material.dart';

import '../../../data/models/continhas_guest.dart';

/// Avatares dos convidados extra no rolê (scroll horizontal).
class ContinhasPersonStrip extends StatelessWidget {
  const ContinhasPersonStrip({
    super.key,
    required this.guests,
  });

  final List<ContinhasGuest> guests;

  static Color _bg(int index) {
    final hues = [160.0, 200.0, 280.0, 35.0, 320.0];
    return HSVColor.fromAHSV(1, hues[index % hues.length], 0.22, 0.92).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (guests.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: guests.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final g = guests[i];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _bg(i),
                child: Text(
                  g.emoji.isNotEmpty ? g.emoji : '?',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                child: Text(
                  g.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
