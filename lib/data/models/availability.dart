/// Dia da semana: 1 = segunda … 7 = domingo (ISO, `DateTime.weekday`).
class Availability {
  const Availability({
    required this.id,
    required this.person,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.title,
  });

  final String id;
  final String person;
  final int weekday;
  final String startTime;
  final String endTime;
  final String? title;

  factory Availability.fromRow(Map<String, dynamic> row) {
    return Availability(
      id: row['id'] as String,
      person: row['person'] as String,
      weekday: (row['weekday'] as num).toInt(),
      startTime: row['start_time'] as String,
      endTime: row['end_time'] as String,
      title: row['title'] as String?,
    );
  }
}
