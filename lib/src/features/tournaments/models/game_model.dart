class GameModel {
  GameModel({
    required this.id,
    required this.tournamentId,
    this.poolId,
    this.court,
    this.startTime,
    this.teamA,
    this.teamB,
    this.scoreA = 0,
    this.scoreB = 0,
    this.status = 'scheduled',
  });

  final String id;
  final String tournamentId;
  final String? poolId;
  final String? court;
  final DateTime? startTime;
  final String? teamA;
  final String? teamB;
  final int scoreA;
  final int scoreB;
  final String status;

  factory GameModel.fromMap(Map<String, dynamic> m) => GameModel(
        id: m['id'] as String,
        tournamentId: m['tournament_id'] as String,
        poolId: m['pool_id'] as String?,
        court: m['court'] as String?,
        startTime: m['start_time'] == null ? null : DateTime.parse(m['start_time'] as String),
        teamA: m['team_a'] as String?,
        teamB: m['team_b'] as String?,
        scoreA: (m['score_a'] ?? 0) is int ? m['score_a'] as int : ((m['score_a'] as num?)?.toInt() ?? 0),
        scoreB: (m['score_b'] ?? 0) is int ? m['score_b'] as int : ((m['score_b'] as num?)?.toInt() ?? 0),
        status: (m['status'] as String?) ?? 'scheduled',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'tournament_id': tournamentId,
        'pool_id': poolId,
        'court': court,
        'start_time': startTime?.toIso8601String(),
        'team_a': teamA,
        'team_b': teamB,
        'score_a': scoreA,
        'score_b': scoreB,
        'status': status,
      };
}

