import 'package:flutter/material.dart';

import '../../../data/models/continhas_guest.dart';
import '../continhas_currency.dart';
import '../../../core/theme/continhas_tokens.dart';

/// Ecrã de fechamento com cartões tipo “settle up”.
class ContinhasSettlementBody extends StatelessWidget {
  const ContinhasSettlementBody({
    super.key,
    required this.hangoutTitle,
    required this.settlement,
    required this.guests,
    required this.labelFor,
  });

  final String hangoutTitle;
  final Map<String, dynamic>? settlement;
  final List<ContinhasGuest> guests;
  final String Function(String key, List<ContinhasGuest> guests) labelFor;

  @override
  Widget build(BuildContext context) {
    final t = ContinhasTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final s = settlement;
    if (s == null || s.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sem dados de fechamento.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final balances = s['balances_brl'];
    final suggestions = s['suggestions'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Material(
          color: t.brandTeal,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fechado',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  hangoutTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Saldos no modo próprio',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Material(
          color: t.cardBackground,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: balances is Map && balances.isNotEmpty
                ? Column(
                    children: [
                      for (final e in balances.entries)
                        ListTile(
                          title: Text(labelFor(e.key.toString(), guests)),
                          trailing: Text(
                            ContinhasCurrency.format((e.value as num).toDouble()),
                            style: ContinhasCurrency.amountStyle(
                              context,
                              color: (e.value as num) >= 0 ? t.positive : t.negative,
                            ),
                          ),
                        ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Sem saldos registados.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Quem paga a quem',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Sugestão para acertar em dinheiro',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (suggestions is List && suggestions.isNotEmpty)
          Material(
            color: t.cardBackground,
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.06),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final raw in suggestions)
                  if (raw is Map)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: t.brandTeal.withValues(alpha: 0.12),
                        child: Icon(Icons.arrow_forward_rounded, color: t.brandTealDark, size: 20),
                      ),
                      title: Text(
                        '${labelFor(raw['from']?.toString() ?? '', guests)} → '
                        '${labelFor(raw['to']?.toString() ?? '', guests)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Text(
                        ContinhasCurrency.format((raw['amount_brl'] as num?)?.toDouble() ?? 0),
                        style: ContinhasCurrency.amountStyle(context),
                      ),
                    ),
              ],
            ),
          )
        else
          Material(
            color: t.cardBackground,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: t.cardBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: t.brandTeal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nada a acertar em dinheiro entre pessoas.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
