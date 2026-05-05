enum JbcCashLedgerType {
  deposit,
  hangoutExpenseDebit;

  static JbcCashLedgerType fromDb(String v) {
    switch (v) {
      case 'deposit':
        return JbcCashLedgerType.deposit;
      case 'hangout_expense_debit':
        return JbcCashLedgerType.hangoutExpenseDebit;
      default:
        return JbcCashLedgerType.deposit;
    }
  }

  String get dbValue {
    switch (this) {
      case JbcCashLedgerType.deposit:
        return 'deposit';
      case JbcCashLedgerType.hangoutExpenseDebit:
        return 'hangout_expense_debit';
    }
  }
}

class JbcCashLedgerEntry {
  const JbcCashLedgerEntry({
    required this.id,
    required this.type,
    required this.amountBrl,
    required this.recordedBy,
    this.hangoutExpenseId,
    this.note,
    required this.createdAt,
  });

  final String id;
  final JbcCashLedgerType type;
  final double amountBrl;
  final String recordedBy;
  final String? hangoutExpenseId;
  final String? note;
  final DateTime createdAt;

  factory JbcCashLedgerEntry.fromRow(Map<String, dynamic> row) {
    final rawAmount = row['amount_brl'];
    final amount = rawAmount is num ? rawAmount.toDouble() : double.parse('$rawAmount');
    return JbcCashLedgerEntry(
      id: row['id'] as String,
      type: JbcCashLedgerType.fromDb(row['type'] as String? ?? 'deposit'),
      amountBrl: amount,
      recordedBy: row['recorded_by'] as String,
      hangoutExpenseId: row['hangout_expense_id'] as String?,
      note: row['note'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
