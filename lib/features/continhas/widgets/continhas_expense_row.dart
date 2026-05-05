import 'package:flutter/material.dart';

import '../../../core/profile/jbc_profile.dart';
import '../../../data/models/continhas_expense.dart';
import '../../../data/models/continhas_guest.dart';
import '../continhas_currency.dart';
import '../../../core/theme/continhas_tokens.dart';

class ContinhasExpenseRow extends StatelessWidget {
  const ContinhasExpenseRow({
    super.key,
    required this.expense,
    required this.guests,
  });

  final ContinhasExpense expense;
  final List<ContinhasGuest> guests;

  static IconData _iconForDescription(String d) {
    final s = d.toLowerCase();
    if (s.contains('jantar') || s.contains('rest') || s.contains('comida')) {
      return Icons.restaurant_outlined;
    }
    if (s.contains('taxi') || s.contains('uber') || s.contains('combust')) {
      return Icons.local_taxi_outlined;
    }
    if (s.contains('beb') || s.contains('bar')) {
      return Icons.local_bar_outlined;
    }
    if (s.contains('hotel') || s.contains('airbnb')) {
      return Icons.hotel_outlined;
    }
    return Icons.receipt_long_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final t = ContinhasTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final payer = JbcProfile.displayNameForStorageKey(expense.payerProfile);
    final mode = expense.paymentSource == ContinhasPaymentSource.jbcCash ? 'Caixa' : 'Próprio';
    final names = expense.shares.map((s) {
      if (s.participantType == ContinhasShareParticipantType.profile) {
        return JbcProfile.displayNameForStorageKey(s.participantId);
      }
      for (final g in guests) {
        if (g.id == s.participantId) return g.label;
      }
      return s.participantId;
    }).join(', ');
    final title = expense.description.isEmpty ? '(sem descrição)' : expense.description;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: t.cardBackground,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(_iconForDescription(expense.description), color: t.brandTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$payer · $mode',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: t.subtitleOnCanvas,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Divide: $names',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: t.subtitleOnCanvas,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ContinhasCurrency.format(expense.amountBrl),
                style: ContinhasCurrency.amountStyle(
                  context,
                  fontSize: 16,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
