enum Sport { volleyball, pickleball }

class Tournament {
  Tournament({
    required this.id,
    required this.name,
    required this.sport,
    required this.location,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String name;
  final Sport sport;
  final String location;
  final DateTime startDate;
  final DateTime endDate;

  factory Tournament.fromMap(Map<String, dynamic> m) {
    final sportStr = (m['sport'] as String).toLowerCase();
    return Tournament(
      id: m['id'] as String,
      name: m['name'] as String,
      sport: sportStr == 'pickleball' ? Sport.pickleball : Sport.volleyball,
      location: (m['location'] ?? '') as String,
      startDate: DateTime.parse(m['start_date'] as String),
      endDate: DateTime.parse(m['end_date'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'sport': sport == Sport.pickleball ? 'pickleball' : 'volleyball',
        'location': location,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };
}
