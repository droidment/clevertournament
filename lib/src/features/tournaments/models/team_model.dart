class Team {
  Team({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.poolId,
    this.seed = 0,
  });

  final String id;
  final String tournamentId;
  final String name;
  final String? poolId;
  final int seed;

  factory Team.fromMap(Map<String, dynamic> m) => Team(
        id: m['id'] as String,
        tournamentId: m['tournament_id'] as String,
        name: m['name'] as String,
        poolId: m['pool_id'] as String?,
        seed: (m['seed'] ?? 0) is int
            ? (m['seed'] as int)
            : ((m['seed'] as num?)?.toInt() ?? 0),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'tournament_id': tournamentId,
        'name': name,
        'pool_id': poolId,
        'seed': seed,
      };
}

