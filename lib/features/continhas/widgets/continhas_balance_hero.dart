import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../continhas_currency.dart';
import '../../../core/theme/continhas_tokens.dart';

/// Faixa teal + valor dominante (linguagem tipo app de rateio).
class ContinhasBalanceHero extends StatelessWidget {
  const ContinhasBalanceHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.balanceAsync,
    this.ctaLabel,
    this.onCta,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final AsyncValue<double> balanceAsync;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = ContinhasTokens.of(context);
    final radius = BorderRadius.circular(18);
    return Material(
      color: t.brandTeal,
      elevation: 2,
      shadowColor: t.brandTeal.withValues(alpha: 0.45),
      borderRadius: radius,
      child: InkWell(
        onTap: onCta,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, compact ? 18 : 22, 20, compact ? 18 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: compact ? 24 : 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                                height: 1.3,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (ctaLabel != null && onCta != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 28,
                    ),
                ],
              ),
              SizedBox(height: compact ? 16 : 20),
              balanceAsync.when(
                skipLoadingOnReload: true,
                data: (b) => Text(
                  ContinhasCurrency.format(b),
                  style: ContinhasCurrency.headlineBalance(context, color: Colors.white).copyWith(
                        fontSize: compact ? 30 : 36,
                        letterSpacing: -0.8,
                      ),
                ),
                loading: () => SizedBox(
                  height: compact ? 40 : 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
                error: (e, _) => Text(
                  '$e',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ),
              if (ctaLabel != null && onCta != null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onCta,
                    style: TextButton.styleFrom(
                      foregroundColor: t.brandTealDark,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      ctaLabel!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
