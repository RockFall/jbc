import '../../core/continhas/continhas_participant_key.dart';

enum ContinhasPaymentSource {
  self,
  jbcCash;

  static ContinhasPaymentSource fromDb(String v) {
    switch (v) {
      case 'jbc_cash':
        return ContinhasPaymentSource.jbcCash;
      default:
        return ContinhasPaymentSource.self;
    }
  }

  String get dbValue => switch (this) {
        ContinhasPaymentSource.self => 'self',
        ContinhasPaymentSource.jbcCash => 'jbc_cash',
      };
}

enum ContinhasShareParticipantType {
  profile,
  guest;

  static ContinhasShareParticipantType fromDb(String v) {
    switch (v) {
      case 'guest':
        return ContinhasShareParticipantType.guest;
      default:
        return ContinhasShareParticipantType.profile;
    }
  }

  String get dbValue => switch (this) {
        ContinhasShareParticipantType.profile => 'profile',
        ContinhasShareParticipantType.guest => 'guest',
      };
}

class ContinhasExpenseShare {
  const ContinhasExpenseShare({
    required this.id,
    required this.expenseId,
    required this.participantType,
    required this.participantId,
  });

  final String id;
  final String expenseId;
  final ContinhasShareParticipantType participantType;
  final String participantId;

  String get participantKey => switch (participantType) {
        ContinhasShareParticipantType.profile =>
          ContinhasParticipantKey.profile(participantId),
        ContinhasShareParticipantType.guest => ContinhasParticipantKey.guest(participantId),
      };

  factory ContinhasExpenseShare.fromRow(Map<String, dynamic> row) {
    return ContinhasExpenseShare(
      id: row['id'] as String,
      expenseId: row['expense_id'] as String,
      participantType: ContinhasShareParticipantType.fromDb(row['participant_type'] as String? ?? 'profile'),
      participantId: row['participant_id'] as String,
    );
  }
}

class ContinhasExpense {
  const ContinhasExpense({
    required this.id,
    required this.hangoutId,
    required this.amountBrl,
    required this.payerProfile,
    required this.paymentSource,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.shares,
  });

  final String id;
  final String hangoutId;
  final double amountBrl;
  final String payerProfile;
  final ContinhasPaymentSource paymentSource;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final List<ContinhasExpenseShare> shares;

  factory ContinhasExpense.fromRow(Map<String, dynamic> row, List<ContinhasExpenseShare> shares) {
    final rawAmount = row['amount_brl'];
    final amount = rawAmount is num ? rawAmount.toDouble() : double.parse('$rawAmount');
    return ContinhasExpense(
      id: row['id'] as String,
      hangoutId: row['hangout_id'] as String,
      amountBrl: amount,
      payerProfile: row['payer_profile'] as String,
      paymentSource: ContinhasPaymentSource.fromDb(row['payment_source'] as String? ?? 'self'),
      description: row['description'] as String? ?? '',
      createdBy: row['created_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      shares: shares,
    );
  }
}
