class Pool {
  Pool({required this.id, required this.tournamentId, required this.name, required this.position});
  final String id;
  final String tournamentId;
  final String name;
  final int position;

  factory Pool.fromMap(Map<String, dynamic> m) => Pool(
        id: m['id'] as String,
        tournamentId: m['tournament_id'] as String,
        name: m['name'] as String,
        position: (m['position'] as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'tournament_id': tournamentId,
        'name': name,
        'position': position,
      };
}

