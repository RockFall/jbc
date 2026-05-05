import 'package:flutter_test/flutter_test.dart';
import 'package:jbc/core/continhas/continhas_balance.dart';
import 'package:jbc/core/continhas/continhas_netting.dart';
import 'package:jbc/core/continhas/continhas_participant_key.dart';

void main() {
  test('split igual em centavos soma o total', () {
    expect(splitCentsEvenly(100, 3), [34, 33, 33]);
    expect(splitCentsEvenly(101, 3), [34, 34, 33]);
    expect(splitCentsEvenly(1, 2), [1, 0]);
  });

  test('uma despesa própria: pagador a receber, outros a pagar', () {
    final b = computeContinhasBalancesCents([
      ContinhasExpenseForBalance(
        paymentSource: ContinhasPaymentSourceCalc.self,
        payerProfileStorageKey: 'caio',
        amountCents: 100,
        participantKeys: [
          ContinhasParticipantKey.profile('caio'),
          ContinhasParticipantKey.profile('bibi'),
        ],
      ),
    ]);
    expect(b[ContinhasParticipantKey.profile('caio')], 50);
    expect(b[ContinhasParticipantKey.profile('bibi')], -50);
  });

  test('despesa pela Caixa não altera saldos entre pessoas', () {
    final b = computeContinhasBalancesCents([
      ContinhasExpenseForBalance(
        paymentSource: ContinhasPaymentSourceCalc.jbcCash,
        payerProfileStorageKey: 'jojo',
        amountCents: 999,
        participantKeys: [
          ContinhasParticipantKey.profile('caio'),
          ContinhasParticipantKey.profile('jojo'),
        ],
      ),
    ]);
    expect(b, isEmpty);
  });

  test('guest no split', () {
    final guestKey = ContinhasParticipantKey.guest('11111111-1111-1111-1111-111111111111');
    final b = computeContinhasBalancesCents([
      ContinhasExpenseForBalance(
        paymentSource: ContinhasPaymentSourceCalc.self,
        payerProfileStorageKey: 'bibi',
        amountCents: 90,
        participantKeys: [
          ContinhasParticipantKey.profile('bibi'),
          guestKey,
        ],
      ),
    ]);
    expect(b[guestKey], -45);
    expect(b[ContinhasParticipantKey.profile('bibi')], 45);
  });

  test('netting reduz a duas arestas num cenário em cadeia', () {
    final balances = {
      ContinhasParticipantKey.profile('caio'): 60,
      ContinhasParticipantKey.profile('jojo'): -30,
      ContinhasParticipantKey.profile('bibi'): -30,
    };
    final edges = computeMinimalTransfersCents(balances);
    var sum = 0;
    for (final e in edges) {
      expect(e.amountCents, greaterThan(0));
      sum += e.amountCents;
    }
    expect(sum, 60);
    expect(edges.length, lessThanOrEqualTo(2));
  });
}
