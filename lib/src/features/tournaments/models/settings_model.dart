class TournamentSettings {
  TournamentSettings({
    required this.tournamentId,
    this.format = 'round_robin',
    this.tieBreakers = const ['head_to_head', 'point_diff'],
    this.courts = const [],
  });

  final String tournamentId;
  final String format; // round_robin | single_elim | double_elim | swiss | pool_play
  final List<String> tieBreakers; // ordered list
  final List<String> courts;

  factory TournamentSettings.fromMap(Map<String, dynamic> m) => TournamentSettings(
        tournamentId: m['tournament_id'] as String,
        format: (m['format'] as String?) ?? 'round_robin',
        tieBreakers: ((m['tiebreakers'] as List?) ?? const []).cast<String>(),
        courts: ((m['courts'] as List?) ?? const []).cast<String>(),
      );

  Map<String, dynamic> toMap() => {
        'tournament_id': tournamentId,
        'format': format,
        'tiebreakers': tieBreakers,
        'courts': courts,
      };
}

