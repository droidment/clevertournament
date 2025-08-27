import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/tournament_repo.dart';
import 'models/team_registration_model.dart';
import 'tournament_model.dart';

class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({super.key, required this.tournament});
  final Tournament tournament;
  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage> {
  late final TournamentRepo repo;
  List<TeamRegistration> regs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    repo = TournamentRepo(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final list = await repo.fetchRegistrations(widget.tournament.id);
    setState(() { regs = list; loading = false; });
  }

  Future<void> _approve(TeamRegistration r) async {
    try {
      final team = await repo.approveRegistration(r);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved: ${team.name}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Approve failed')),
      );
    }
  }

  Future<void> _reject(TeamRegistration r) async {
    await repo.updateRegistrationStatus(r.id, 'rejected');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team registrations')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (regs.isEmpty) const Text('No registrations yet'),
                for (final r in regs)
                  Card(
                    child: ListTile(
                      title: Text(r.teamName),
                      subtitle: Text([
                        if (r.captainName != null) r.captainName,
                        if (r.captainEmail != null) r.captainEmail,
                        if (r.captainPhone != null) r.captainPhone,
                        if (r.notes != null) 'Notes: ${r.notes}',
                        'Status: ${r.status}',
                      ].whereType<String>().join(' • ')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Reject',
                            icon: const Icon(Icons.close),
                            onPressed: r.status == 'pending' ? () => _reject(r) : null,
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: r.status == 'pending' ? () => _approve(r) : null,
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

