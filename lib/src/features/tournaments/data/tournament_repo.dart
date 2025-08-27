import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pool_model.dart';
import '../models/team_model.dart';
import '../models/game_model.dart';

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
    var query = _client.from('teams').select().eq('tournament_id', tournamentId).order('seed', ascending: true);
    if (poolId != null) query = query.eq('pool_id', poolId);
    final res = await query;
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
    var q = _client.from('games').select().eq('tournament_id', tournamentId).order('start_time', ascending: true);
    if (poolId != null) q = q.eq('pool_id', poolId);
    final res = await q;
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
}

