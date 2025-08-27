class TeamRegistration {
  TeamRegistration({
    required this.id,
    required this.tournamentId,
    required this.teamName,
    this.captainName,
    this.captainEmail,
    this.captainPhone,
    this.notes,
    this.status = 'pending',
    this.createdBy,
    this.teamId,
  });

  final String id;
  final String tournamentId;
  final String teamName;
  final String? captainName;
  final String? captainEmail;
  final String? captainPhone;
  final String? notes;
  final String status;
  final String? createdBy;
  final String? teamId;

  factory TeamRegistration.fromMap(Map<String, dynamic> m) => TeamRegistration(
        id: m['id'] as String,
        tournamentId: m['tournament_id'] as String,
        teamName: m['team_name'] as String,
        captainName: m['captain_name'] as String?,
        captainEmail: m['captain_email'] as String?,
        captainPhone: m['captain_phone'] as String?,
        notes: m['notes'] as String?,
        status: m['status'] as String,
        createdBy: m['created_by'] as String?,
        teamId: m['team_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'tournament_id': tournamentId,
        'team_name': teamName,
        'captain_name': captainName,
        'captain_email': captainEmail,
        'captain_phone': captainPhone,
        'notes': notes,
        'status': status,
        'created_by': createdBy,
        'team_id': teamId,
      };
}

