import 'continhas_money.dart';
import 'continhas_participant_key.dart';

/// Origem do pagamento na despesa (espelho do DB).
enum ContinhasPaymentSourceCalc {
  self,
  jbcCash,
}

/// Linha mínima para saldo líquido (modo próprio só entra no grafo).
class ContinhasExpenseForBalance {
  const ContinhasExpenseForBalance({
    required this.paymentSource,
    required this.payerProfileStorageKey,
    required this.amountCents,
    required this.participantKeys,
  });

  final ContinhasPaymentSourceCalc paymentSource;
  final String payerProfileStorageKey;
  final int amountCents;
  final List<String> participantKeys;
}

/// Partes iguais em centavos (soma = [totalCents]).
List<int> splitCentsEvenly(int totalCents, int k) {
  if (k <= 0) {
    throw ArgumentError.value(k, 'k', 'split precisa de pelo menos 1 participante');
  }
  final base = totalCents ~/ k;
  final rem = totalCents % k;
  return List.generate(k, (i) => base + (i < rem ? 1 : 0));
}

/// Saldos em centavos: positivo = a receber, negativo = a pagar (perspectiva Splitwise).
Map<String, int> computeContinhasBalancesCents(List<ContinhasExpenseForBalance> expenses) {
  final balances = <String, int>{};
  void add(String k, int delta) {
    balances[k] = (balances[k] ?? 0) + delta;
  }

  for (final e in expenses) {
    if (e.paymentSource == ContinhasPaymentSourceCalc.jbcCash) continue;
    if (e.participantKeys.isEmpty) continue;

    final keys = [...e.participantKeys]..sort();
    final payerKey = ContinhasParticipantKey.profile(e.payerProfileStorageKey);
    final shares = splitCentsEvenly(e.amountCents, keys.length);
    add(payerKey, e.amountCents);
    for (var i = 0; i < keys.length; i++) {
      add(keys[i], -shares[i]);
    }
  }

  return balances;
}

/// Converte mapa de centavos para BRL (2 casas) para persistência em JSON.
Map<String, double> balancesCentsToBrlMap(Map<String, int> cents) {
  final out = <String, double>{};
  for (final e in cents.entries) {
    if (e.value == 0) continue;
    out[e.key] = double.parse(centsToBrl(e.value).toStringAsFixed(2));
  }
  return out;
}

int parseAmountBrlToCents(Object? raw) {
  if (raw == null) return 0;
  if (raw is int) return raw * 100;
  if (raw is num) return brlToCents(raw.toDouble());
  if (raw is String) {
    final v = double.tryParse(raw);
    if (v == null) return 0;
    return brlToCents(v);
  }
  return 0;
}
