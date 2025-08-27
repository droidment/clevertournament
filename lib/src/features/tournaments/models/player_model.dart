class Player {
  Player({required this.id, required this.teamId, required this.name, this.number, this.email});
  final String id;
  final String teamId;
  final String name;
  final int? number;
  final String? email;

  factory Player.fromMap(Map<String, dynamic> m) => Player(
        id: m['id'] as String,
        teamId: m['team_id'] as String,
        name: m['name'] as String,
        number: (m['number'] as num?)?.toInt(),
        email: m['email'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'team_id': teamId,
        'name': name,
        'number': number,
        'email': email,
      };
}

