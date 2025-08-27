class Announcement {
  Announcement({
    required this.id,
    required this.tournamentId,
    required this.content,
    required this.target,
    required this.insertedAt,
    this.createdBy,
  });

  final String id;
  final String tournamentId;
  final String content;
  final String target;
  final DateTime insertedAt;
  final String? createdBy;

  factory Announcement.fromMap(Map<String, dynamic> m) => Announcement(
        id: m['id'] as String,
        tournamentId: m['tournament_id'] as String,
        content: m['content'] as String,
        target: m['target'] as String,
        insertedAt: DateTime.parse(m['inserted_at'] as String),
        createdBy: m['created_by'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'tournament_id': tournamentId,
        'content': content,
        'target': target,
        'inserted_at': insertedAt.toIso8601String(),
        'created_by': createdBy,
      };
}

