import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pool_model.dart';
import '../models/team_model.dart';
import '../models/game_model.dart';
import '../models/player_model.dart';
import '../models/announcement_model.dart';

class TournamentRepo {
  TournamentRepo(this._client);
  final SupabaseClient _client;

  Future<List<Pool>> fetchPools(String tournamentId) async {
    final res = await _client
        .from('pools')
        .select()
        .eq('tournament_id', tournamentId)
        .order('position', ascending: true);
    return (res as List).cast<Map<String, dynamic>>().map(Pool.fromMap).toList();
  }

  Future<Pool> addPool(String tournamentId, String name, {int position = 0}) async {
    final res = await _client
        .from('pools')
        .insert({
          'tournament_id': tournamentId,
          'name': name,
          'position': position,
        })
        .select()
        .single();
    return Pool.fromMap((res as Map<String, dynamic>));
  }

  Future<void> removePool(String poolId) async {
    await _client.from('pools').delete().eq('id', poolId);
  }

  Future<void> reorderPools(List<Pool> pools) async {
    // Bulk update positions
    for (var i = 0; i < pools.length; i++) {
      await _client.from('pools').update({'position': i}).eq('id', pools[i].id);
    }
  }

  Future<List<Team>> fetchTeams(String tournamentId, {String? poolId}) async {
    var query = _client.from('teams').select().eq('tournament_id', tournamentId);
    if (poolId != null) {
      query = query.eq('pool_id', poolId);
    }
    final res = await query.order('seed', ascending: true);
    return (res as List).cast<Map<String, dynamic>>().map(Team.fromMap).toList();
  }

  Future<Team> addTeam(String tournamentId, {required String name, String? poolId, int seed = 0}) async {
    final res = await _client
        .from('teams')
        .insert({
          'tournament_id': tournamentId,
          'name': name,
          'pool_id': poolId,
          'seed': seed,
        })
        .select()
        .single();
    return Team.fromMap((res as Map<String, dynamic>));
  }

  Future<void> assignTeamToPool(String teamId, String? poolId) async {
    await _client.from('teams').update({'pool_id': poolId}).eq('id', teamId);
  }

  Future<void> setSeeds(List<Team> teams) async {
    // Update seed to list order index (0-based)
    for (var i = 0; i < teams.length; i++) {
      await _client.from('teams').update({'seed': i}).eq('id', teams[i].id);
    }
  }

  Future<List<GameModel>> fetchGames(String tournamentId, {String? poolId}) async {
    var q = _client.from('games').select().eq('tournament_id', tournamentId);
    if (poolId != null) {
      q = q.eq('pool_id', poolId);
    }
    final res = await q.order('start_time', ascending: true);
    return (res as List).cast<Map<String, dynamic>>().map(GameModel.fromMap).toList();
  }

  Future<void> clearGamesForPool(String poolId) async {
    await _client.from('games').delete().eq('pool_id', poolId);
  }

  Future<void> insertGames(List<GameModel> games) async {
    final rows = games.map((g) {
      final m = g.toMap();
      m.remove('id');
      return m;
    }).toList();
    await _client.from('games').insert(rows);
  }

  Future<void> updateScore(String gameId, {required int a, required int b, String status = 'final'}) async {
    await _client.from('games').update({'score_a': a, 'score_b': b, 'status': status}).eq('id', gameId);
  }

  Future<void> updateGame(String gameId, {String? court, DateTime? startTime}) async {
    final payload = <String, dynamic>{};
    if (court != null) payload['court'] = court;
    if (startTime != null) payload['start_time'] = startTime.toIso8601String();
    if (payload.isEmpty) return;
    await _client.from('games').update(payload).eq('id', gameId);
  }

  Stream<List<GameModel>> streamGames(String tournamentId, {String? poolId}) {
    var q = _client
        .from('games')
        .stream(primaryKey: ['id'])
        .eq('tournament_id', tournamentId);
    if (poolId != null) {
      q = q.eq('pool_id', poolId);
    }
    return q.order('start_time').map(
          (rows) => rows.map((e) => GameModel.fromMap(e)).toList(),
        );
  }

  // Announcements
  Future<List<Announcement>> fetchAnnouncements(String tournamentId) async {
    final res = await _client
        .from('announcements')
        .select()
        .eq('tournament_id', tournamentId)
        .order('inserted_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>().map(Announcement.fromMap).toList();
  }

  Future<Announcement> addAnnouncement(String tournamentId, String content, {String target = 'all'}) async {
    final res = await _client
        .from('announcements')
        .insert({'tournament_id': tournamentId, 'content': content, 'target': target, 'created_by': _client.auth.currentUser?.id})
        .select()
        .single();
    return Announcement.fromMap((res as Map<String, dynamic>));
  }

  Stream<List<Announcement>> streamAnnouncements(String tournamentId) {
    return _client
        .from('announcements')
        .stream(primaryKey: ['id'])
        .eq('tournament_id', tournamentId)
        .order('inserted_at')
        .map((rows) => rows.map((e) => Announcement.fromMap(e)).toList().reversed.toList());
  }

  // Settings
  Future<Map<String, dynamic>> fetchSettings(String tournamentId) async {
    final res = await _client.from('tournaments').select('settings').eq('id', tournamentId).single();
    return (res['settings'] as Map<String, dynamic>? ?? {});
  }

  Future<void> saveSettings(String tournamentId, Map<String, dynamic> settings) async {
    await _client.from('tournaments').update({'settings': settings}).eq('id', tournamentId);
  }

  // Players
  Future<List<Player>> fetchPlayers(String teamId) async {
    final res = await _client.from('players').select().eq('team_id', teamId).order('inserted_at');
    return (res as List).cast<Map<String, dynamic>>().map(Player.fromMap).toList();
  }

  Future<Player> addPlayer(String teamId, {required String name, int? number, String? email}) async {
    final res = await _client
        .from('players')
        .insert({'team_id': teamId, 'name': name, 'number': number, 'email': email})
        .select()
        .single();
    return Player.fromMap((res as Map<String, dynamic>));
  }

  Future<void> removePlayer(String playerId) async {
    await _client.from('players').delete().eq('id', playerId);
  }
}
