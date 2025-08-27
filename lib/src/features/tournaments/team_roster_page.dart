import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

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
  String? joinCode;

  @override
  void initState() {
    super.initState();
    repo = TournamentRepo(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final ps = await repo.fetchPlayers(widget.team.id);
    setState(() { players = ps; joinCode = widget.team.joinCode; loading = false; });
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

  Future<void> _edit(Player player) async {
    final nameCtrl = TextEditingController(text: player.name);
    final numberCtrl = TextEditingController(text: player.number?.toString() ?? '');
    final emailCtrl = TextEditingController(text: player.email ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit player'),
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
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      // No separate update endpoint for player fields, so delete + add replacement or add update if needed later.
      await repo.removePlayer(player.id);
      final numVal = int.tryParse(numberCtrl.text);
      final p = await repo.addPlayer(widget.team.id, name: nameCtrl.text.trim(), number: numVal, email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim());
      setState(() {
        final idx = players.indexWhere((x) => x.id == player.id);
        if (idx >= 0) {
          players[idx] = p;
        }
      });
    }
  }

  Future<void> _import() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bulk add players'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: ctrl,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Paste names, one per line (optionally "#number Name" or "Name, number")',
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true) {
      final lines = ctrl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty);
      for (final line in lines) {
        int? number;
        String name = line;
        final m1 = RegExp(r'^#?(\d+)\s+(.*)$').firstMatch(line);
        final m2 = RegExp(r'^(.*?)[,\s]+(\d+)$').firstMatch(line);
        if (m1 != null) {
          number = int.tryParse(m1.group(1)!);
          name = m1.group(2)!.trim();
        } else if (m2 != null) {
          name = m2.group(1)!.trim();
          number = int.tryParse(m2.group(2)!);
        }
        final p = await repo.addPlayer(widget.team.id, name: name, number: number);
        setState(() { players = [...players, p]; });
      }
    }
  }

  Future<void> _remove(Player p) async {
    await repo.removePlayer(p.id);
    setState(() { players.removeWhere((x) => x.id == p.id); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.team.name} roster'),
        actions: [
          if (joinCode != null) IconButton(
            tooltip: 'Copy join code',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: joinCode));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Join code copied')));
            },
          ),
          if (joinCode != null) IconButton(
            tooltip: 'Copy share link',
            icon: const Icon(Icons.link_outlined),
            onPressed: () {
              final base = Uri.base;
              String origin = '';
              if (base.hasScheme && (base.scheme == 'http' || base.scheme == 'https') && base.hasAuthority) {
                origin = '${base.scheme}://${base.authority}';
              }
              final link = origin.isNotEmpty ? '$origin/#/join?code=$joinCode' : '/#/join?code=$joinCode';
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Join link copied')));
            },
          ),
          IconButton(
            tooltip: 'Regenerate join code',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final code = await repo.regenerateJoinCode(widget.team.id);
              setState(() => joinCode = code);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Join code updated')));
            },
          )
        ],
      ),
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(p)),
                          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _remove(p)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.person_add_alt_1), label: const Text('Add player')),
          const SizedBox(height: 8),
          FloatingActionButton.extended(onPressed: _import, icon: const Icon(Icons.upload_file), label: const Text('Import list')),
        ],
      ),
    );
  }
}
