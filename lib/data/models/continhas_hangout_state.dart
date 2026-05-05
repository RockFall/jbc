enum ContinhasHangoutStatus {
  open,
  closed;

  static ContinhasHangoutStatus fromDb(String v) {
    switch (v) {
      case 'closed':
        return ContinhasHangoutStatus.closed;
      default:
        return ContinhasHangoutStatus.open;
    }
  }

  String get dbValue => switch (this) {
        ContinhasHangoutStatus.open => 'open',
        ContinhasHangoutStatus.closed => 'closed',
      };
}

class ContinhasHangoutState {
  const ContinhasHangoutState({
    required this.hangoutId,
    required this.status,
    this.closedAt,
    this.closedBy,
    this.settlementJson,
  });

  final String hangoutId;
  final ContinhasHangoutStatus status;
  final DateTime? closedAt;
  final String? closedBy;
  final Map<String, dynamic>? settlementJson;

  bool get isClosed => status == ContinhasHangoutStatus.closed;

  factory ContinhasHangoutState.fromRow(Map<String, dynamic> row) {
    final rawSet = row['settlement_json'];
    Map<String, dynamic>? settlement;
    if (rawSet is Map) {
      settlement = Map<String, dynamic>.from(rawSet);
    }
    return ContinhasHangoutState(
      hangoutId: row['hangout_id'] as String,
      status: ContinhasHangoutStatus.fromDb(row['status'] as String? ?? 'open'),
      closedAt: row['closed_at'] != null ? DateTime.parse(row['closed_at'] as String) : null,
      closedBy: row['closed_by'] as String?,
      settlementJson: settlement,
    );
  }
}
