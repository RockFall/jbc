import 'conchinha_address.dart';

enum ConchinhaRequestStatus {
  open,
  completed,
  cancelled;

  static ConchinhaRequestStatus parse(String raw) {
    switch (raw) {
      case 'open':
        return ConchinhaRequestStatus.open;
      case 'completed':
        return ConchinhaRequestStatus.completed;
      case 'cancelled':
        return ConchinhaRequestStatus.cancelled;
      default:
        return ConchinhaRequestStatus.open;
    }
  }

  String get dbValue => name;
}

class ConchinhaRequest {
  const ConchinhaRequest({
    required this.id,
    required this.requesterKey,
    required this.address,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String requesterKey;
  final ConchinhaAddress address;
  final ConchinhaRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  static ConchinhaRequest fromRow(Map<String, dynamic> row) {
    final addrRaw = row['address'];
    Map<String, dynamic> addrMap = {};
    if (addrRaw is Map) {
      addrMap = Map<String, dynamic>.from(addrRaw);
    }
    return ConchinhaRequest(
      id: row['id'] as String,
      requesterKey: row['requester'] as String,
      address: ConchinhaAddress.fromJson(addrMap),
      status: ConchinhaRequestStatus.parse(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
