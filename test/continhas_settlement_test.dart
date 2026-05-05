import 'package:flutter_test/flutter_test.dart';
import 'package:jbc/core/continhas/continhas_settlement.dart';
import 'package:jbc/data/models/continhas_expense.dart';

void main() {
  test('split igual 90 entre três perfis — saldos e netting', () {
    final r = computeContinhasSettlement([
      const ContinhasSettlementExpenseInput(
        amountCents: 9000,
        payerProfileKey: 'caio',
        paymentSource: ContinhasPaymentSource.self,
        shareParticipantKeys: {'profile:caio', 'profile:jojo', 'profile:bibi'},
      ),
    ]);
    expect(r.netCentsByParticipant['profile:caio'], 6000);
    expect(r.netCentsByParticipant['profile:jojo'], -3000);
    expect(r.netCentsByParticipant['profile:bibi'], -3000);
    expect(r.transfers.length, 2);
    final sumToCaio = r.transfers
        .where((t) => t.toParticipantKey == 'profile:caio')
        .fold<int>(0, (a, t) => a + t.amountCents);
    expect(sumToCaio, 6000);
  });

  test('despesa paga pela Caixa não gera dívidas', () {
    final r = computeContinhasSettlement([
      const ContinhasSettlementExpenseInput(
        amountCents: 10000,
        payerProfileKey: 'bibi',
        paymentSource: ContinhasPaymentSource.jbcCash,
        shareParticipantKeys: {'profile:caio', 'profile:bibi'},
      ),
    ]);
    expect(r.netCentsByParticipant, isEmpty);
    expect(r.transfers, isEmpty);
  });

  test('convidado no split', () {
    final r = computeContinhasSettlement([
      const ContinhasSettlementExpenseInput(
        amountCents: 10000,
        payerProfileKey: 'caio',
        paymentSource: ContinhasPaymentSource.self,
        shareParticipantKeys: {'profile:caio', 'guest:lu-uuid'},
      ),
    ]);
    expect(r.netCentsByParticipant['profile:caio'], 5000);
    expect(r.netCentsByParticipant['guest:lu-uuid'], -5000);
    expect(r.transfers.single.amountCents, 5000);
    expect(r.transfers.single.fromParticipantKey, 'guest:lu-uuid');
    expect(r.transfers.single.toParticipantKey, 'profile:caio');
  });

  test('várias despesas com subsets diferentes', () {
    final r = computeContinhasSettlement([
      const ContinhasSettlementExpenseInput(
        amountCents: 3000,
        payerProfileKey: 'caio',
        paymentSource: ContinhasPaymentSource.self,
        shareParticipantKeys: {'profile:caio', 'profile:jojo'},
      ),
      const ContinhasSettlementExpenseInput(
        amountCents: 6000,
        payerProfileKey: 'jojo',
        paymentSource: ContinhasPaymentSource.self,
        shareParticipantKeys: {'profile:caio', 'profile:jojo', 'profile:bibi'},
      ),
    ]);
    // 3000/2=1500: caio +1500, jojo -1500
    // 6000/3=2000: jojo +4000, caio -2000, bibi -2000
    expect(r.netCentsByParticipant['profile:caio'], -500);
    expect(r.netCentsByParticipant['profile:jojo'], 2500);
    expect(r.netCentsByParticipant['profile:bibi'], -2000);
    expect(r.transfers.isNotEmpty, true);
    var sum = 0;
    for (final t in r.transfers) {
      if (t.fromParticipantKey == 'profile:bibi') sum += t.amountCents;
    }
    expect(sum, 2000);
  });

  test('splitEqualCents reparte o resto pela ordem lexicográfica', () {
    final keys = ['profile:ze', 'profile:aa', 'profile:mm'];
    keys.sort();
    final parts = splitEqualCents(100, keys);
    expect(parts.fold<int>(0, (a, b) => a + b), 100);
    expect(parts.length, 3);
  });
}
