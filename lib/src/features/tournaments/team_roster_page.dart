import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/tournament_repo.dart';
import 'models/team_model.dart';
import 'models/player_model.dart';

class TeamRosterPage extends StatefulWidget {
  const TeamRosterPage({super.key, required this.team});
  final Team team;
  @override
  State<TeamRosterPage> createState() => _TeamRosterPageState();
}

class _TeamRosterPageState extends State<TeamRosterPage> {
  late final TournamentRepo repo;
  List<Player> players = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    repo = TournamentRepo(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final ps = await repo.fetchPlayers(widget.team.id);
    setState(() { players = ps; loading = false; });
  }

  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: numberCtrl, decoration: const InputDecoration(labelText: 'Number'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      final numVal = int.tryParse(numberCtrl.text);
      final p = await repo.addPlayer(widget.team.id, name: nameCtrl.text.trim(), number: numVal, email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim());
      setState(() { players = [...players, p]; });
    }
  }

  Future<void> _remove(Player p) async {
    await repo.removePlayer(p.id);
    setState(() { players.removeWhere((x) => x.id == p.id); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.team.name} roster')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (players.isEmpty) const Text('No players yet'),
                for (final p in players)
                  Card(
                    child: ListTile(
                      title: Text(p.name),
                      subtitle: Text([if (p.number != null) '#${p.number}', if (p.email != null) p.email].where((e) => e != null && e.toString().isNotEmpty).join(' • ')),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _remove(p)),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.person_add_alt_1), label: const Text('Add player')),
    );
  }
}

