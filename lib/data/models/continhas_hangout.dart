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

  String get dbValue => name;
}

class ContinhasHangout {
  const ContinhasHangout({
    required this.hangoutId,
    required this.status,
    this.closedAt,
    this.closedBy,
    this.settlementSnapshot,
    required this.createdAt,
  });

  final String hangoutId;
  final ContinhasHangoutStatus status;
  final DateTime? closedAt;
  final String? closedBy;
  final Map<String, dynamic>? settlementSnapshot;
  final DateTime createdAt;

  factory ContinhasHangout.fromRow(Map<String, dynamic> row) {
    final snap = row['settlement_snapshot'];
    return ContinhasHangout(
      hangoutId: row['hangout_id'] as String,
      status: ContinhasHangoutStatus.fromDb(row['status'] as String? ?? 'open'),
      closedAt: row['closed_at'] != null ? DateTime.parse(row['closed_at'] as String) : null,
      closedBy: row['closed_by'] as String?,
      settlementSnapshot: snap is Map ? Map<String, dynamic>.from(snap) : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
