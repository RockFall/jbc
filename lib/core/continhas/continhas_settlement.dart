import '../../data/models/continhas_expense.dart';

/// Valor em cêntimos (BRL) para evitar erros de ponto flutuante.
int brlToCents(double brl) => (brl * 100).round();

double centsToBrl(int cents) => cents / 100.0;

/// Parte igual com resto distribuído pelas primeiras chaves (ordem lexicográfica).
List<int> splitEqualCents(int totalCents, List<String> orderedKeys) {
  final k = orderedKeys.length;
  if (k == 0) return const [];
  final base = totalCents ~/ k;
  final rem = totalCents % k;
  return List.generate(k, (i) => base + (i < rem ? 1 : 0));
}

/// Uma sugestão de pagamento: [from] deve pagar [to] (quem recebe o saldo).
class ContinhasNettingTransfer {
  const ContinhasNettingTransfer({
    required this.fromParticipantKey,
    required this.toParticipantKey,
    required this.amountCents,
  });

  final String fromParticipantKey;
  final String toParticipantKey;
  final int amountCents;
}

class ContinhasSettlementResult {
  const ContinhasSettlementResult({
    required this.netCentsByParticipant,
    required this.transfers,
  });

  /// Saldo líquido: positivo = deve receber no agregado; negativo = deve pagar.
  final Map<String, int> netCentsByParticipant;
  final List<ContinhasNettingTransfer> transfers;

  Map<String, dynamic> toSnapshotJson() {
    return {
      'net_cents': netCentsByParticipant,
      'transfers': transfers
          .map(
            (t) => {
              'from': t.fromParticipantKey,
              'to': t.toParticipantKey,
              'amount_cents': t.amountCents,
            },
          )
          .toList(),
    };
  }

  static ContinhasSettlementResult? fromSnapshotJson(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final netRaw = raw['net_cents'];
    final trRaw = raw['transfers'];
    if (netRaw is! Map) return null;
    final net = netRaw.map((k, v) => MapEntry(k as String, (v as num).round()));
    final transfers = <ContinhasNettingTransfer>[];
    if (trRaw is List) {
      for (final e in trRaw) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        transfers.add(
          ContinhasNettingTransfer(
            fromParticipantKey: m['from'] as String,
            toParticipantKey: m['to'] as String,
            amountCents: (m['amount_cents'] as num).round(),
          ),
        );
      }
    }
    return ContinhasSettlementResult(netCentsByParticipant: net, transfers: transfers);
  }
}

/// Despesa mínima para cálculo (modo próprio gera dívidas; Caixa não entra no grafo).
class ContinhasSettlementExpenseInput {
  const ContinhasSettlementExpenseInput({
    required this.amountCents,
    required this.payerProfileKey,
    required this.paymentSource,
    required this.shareParticipantKeys,
  });

  final int amountCents;
  final String payerProfileKey;
  final ContinhasPaymentSource paymentSource;
  final Set<String> shareParticipantKeys;
}

ContinhasSettlementResult computeContinhasSettlement(
  List<ContinhasSettlementExpenseInput> expenses,
) {
  final net = <String, int>{};

  void addNet(String key, int delta) {
    net[key] = (net[key] ?? 0) + delta;
  }

  for (final e in expenses) {
    if (e.paymentSource == ContinhasPaymentSource.jbcCash) continue;
    if (e.amountCents <= 0) continue;
    final keys = e.shareParticipantKeys.toList()..sort();
    if (keys.isEmpty) continue;
    final payerKey = 'profile:${e.payerProfileKey}';
    if (!keys.contains(payerKey)) {
      continue;
    }
    final parts = splitEqualCents(e.amountCents, keys);
    for (var i = 0; i < keys.length; i++) {
      addNet(keys[i], -parts[i]);
    }
    addNet(payerKey, e.amountCents);
  }

  net.removeWhere((_, v) => v == 0);

  final transfers = _netGreedy(net);
  return ContinhasSettlementResult(netCentsByParticipant: Map<String, int>.from(net), transfers: transfers);
}

List<ContinhasNettingTransfer> _netGreedy(Map<String, int> net) {
  final bal = Map<String, int>.from(net);
  final out = <ContinhasNettingTransfer>[];
  while (true) {
    String? debtorKey;
    var debtorBal = 0;
    for (final e in bal.entries) {
      if (e.value < 0 && (debtorKey == null || e.value < debtorBal)) {
        debtorKey = e.key;
        debtorBal = e.value;
      }
    }
    String? creditorKey;
    var creditorBal = 0;
    for (final e in bal.entries) {
      if (e.value > 0 && (creditorKey == null || e.value > creditorBal)) {
        creditorKey = e.key;
        creditorBal = e.value;
      }
    }
    if (debtorKey == null || creditorKey == null) break;
    if (debtorBal >= 0 || creditorBal <= 0) break;
    final pay = (-debtorBal) < creditorBal ? -debtorBal : creditorBal;
    if (pay <= 0) break;
    out.add(
      ContinhasNettingTransfer(
        fromParticipantKey: debtorKey,
        toParticipantKey: creditorKey,
        amountCents: pay,
      ),
    );
    bal[debtorKey] = bal[debtorKey]! + pay;
    bal[creditorKey] = bal[creditorKey]! - pay;
    if (bal[debtorKey] == 0) bal.remove(debtorKey);
    if (bal[creditorKey] == 0) bal.remove(creditorKey);
  }
  return out;
}
