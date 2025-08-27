class Team {
  Team({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.poolId,
    this.seed = 0,
    this.captainName,
    this.captainEmail,
    this.captainPhone,
    this.jerseyColor,
  });

  final String id;
  final String tournamentId;
  final String name;
  final String? poolId;
  final int seed;
  final String? captainName;
  final String? captainEmail;
  final String? captainPhone;
  final String? jerseyColor;

  factory Team.fromMap(Map<String, dynamic> m) => Team(
        id: m['id'] as String,
        tournamentId: m['tournament_id'] as String,
        name: m['name'] as String,
        poolId: m['pool_id'] as String?,
        seed: (m['seed'] ?? 0) is int
            ? (m['seed'] as int)
            : ((m['seed'] as num?)?.toInt() ?? 0),
        captainName: m['captain_name'] as String?,
        captainEmail: m['captain_email'] as String?,
        captainPhone: m['captain_phone'] as String?,
        jerseyColor: m['jersey_color'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'tournament_id': tournamentId,
        'name': name,
        'pool_id': poolId,
        'seed': seed,
        'captain_name': captainName,
        'captain_email': captainEmail,
        'captain_phone': captainPhone,
        'jersey_color': jerseyColor,
      };
}
