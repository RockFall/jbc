import 'continhas_money.dart';

/// Sugestão de transferência mínima (em centavos).
class ContinhasNettingEdge {
  const ContinhasNettingEdge({
    required this.fromKey,
    required this.toKey,
    required this.amountCents,
  });

  final String fromKey;
  final String toKey;
  final int amountCents;
}

/// Greedy: maiores devedores com maiores credores. [balances] em centavos (soma ≈ 0).
List<ContinhasNettingEdge> computeMinimalTransfersCents(Map<String, int> balances) {
  final debtorKeys = <String>[];
  final debtorAmts = <int>[];
  final creditorKeys = <String>[];
  final creditorAmts = <int>[];

  for (final e in balances.entries) {
    if (e.value < 0) {
      debtorKeys.add(e.key);
      debtorAmts.add(-e.value);
    } else if (e.value > 0) {
      creditorKeys.add(e.key);
      creditorAmts.add(e.value);
    }
  }

  final orderD = List<int>.generate(debtorKeys.length, (i) => i)
    ..sort((a, b) => debtorAmts[b].compareTo(debtorAmts[a]));
  final orderC = List<int>.generate(creditorKeys.length, (i) => i)
    ..sort((a, b) => creditorAmts[b].compareTo(creditorAmts[a]));

  final edges = <ContinhasNettingEdge>[];
  var di = 0;
  var ci = 0;
  while (di < orderD.length && ci < orderC.length) {
    final dix = orderD[di];
    final cix = orderC[ci];
    if (debtorAmts[dix] == 0) {
      di++;
      continue;
    }
    if (creditorAmts[cix] == 0) {
      ci++;
      continue;
    }
    final pay = debtorAmts[dix] < creditorAmts[cix] ? debtorAmts[dix] : creditorAmts[cix];
    if (pay > 0) {
      edges.add(ContinhasNettingEdge(
        fromKey: debtorKeys[dix],
        toKey: creditorKeys[cix],
        amountCents: pay,
      ));
    }
    debtorAmts[dix] -= pay;
    creditorAmts[cix] -= pay;
    if (debtorAmts[dix] == 0) di++;
    if (creditorAmts[cix] == 0) ci++;
  }

  return edges;
}

Map<String, double> edgesCentsToBrlMap(List<ContinhasNettingEdge> edges) {
  return {
    for (final e in edges)
      '${e.fromKey}>${e.toKey}': double.parse(centsToBrl(e.amountCents).toStringAsFixed(2)),
  };
}
