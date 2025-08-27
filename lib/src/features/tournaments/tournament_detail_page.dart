import 'package:flutter/material.dart';

import 'tournament_model.dart';
import 'data/tournament_repo.dart';
import 'models/pool_model.dart';
import 'models/team_model.dart';
import 'models/game_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tournament_settings_page.dart';
import 'team_roster_page.dart';
import 'team_registration_page.dart';
import 'approvals_page.dart';
import 'join_team_page.dart';

class TournamentDetailPage extends StatefulWidget {
  const TournamentDetailPage({super.key, required this.tournament});
  final Tournament tournament;

  @override
  State<TournamentDetailPage> createState() => _TournamentDetailPageState();
}

class _TournamentDetailPageState extends State<TournamentDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.name),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Pools'),
            Tab(text: 'Schedule'),
            Tab(text: 'Standings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _OverviewTab(t: t),
          _PoolsTab(tournament: t),
          _ScheduleTab(tournament: t),
          _StandingsTab(tournament: t),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.t});
  final Tournament t;
  @override
  Widget build(BuildContext context) {
    final subtitle = '${t.location} • '
        '${t.startDate.year}/${t.startDate.month}/${t.startDate.day}'
        ' - '
        '${t.endDate.year}/${t.endDate.month}/${t.endDate.day}';
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: Text(t.name),
            subtitle: Text(subtitle),
            trailing: Chip(
              label: Text(t.sport == Sport.volleyball ? 'Volleyball' : 'Pickleball'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TournamentSettingsPage(tournament: t),
                  ));
                },
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TeamRegistrationPage(tournament: t),
                  ));
                },
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Register team'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final repo = TournamentRepo(Supabase.instance.client);
                  final teams = await repo.fetchTeams(t.id);
                  if (!context.mounted) return;
                  if (teams.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No teams yet. Add teams in Pools tab.')),
                    );
                    return;
                  }
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    builder: (ctx) => ListView(
                      children: [
                        const ListTile(title: Text('Select a team')), 
                        for (final team in teams)
                          ListTile(
                            title: Text(team.name),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => TeamRosterPage(team: team)),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.groups_2_outlined),
                label: const Text('Rosters'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JoinTeamPage()),
                  );
                },
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('Join with code'),
              ),
            ),
            const SizedBox(width: 12),
            if (t.createdBy == Supabase.instance.client.auth.currentUser?.id)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ApprovalsPage(tournament: t)),
                    );
                  },
                  icon: const Icon(Icons.inbox_outlined),
                  label: const Text('Review registrations'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _AnnouncementsPanel(tournament: t),
      ],
    );
  }
}

class _AnnouncementsPanel extends StatefulWidget {
  const _AnnouncementsPanel({required this.tournament});
  final Tournament tournament;
  @override
  State<_AnnouncementsPanel> createState() => _AnnouncementsPanelState();
}

class _AnnouncementsPanelState extends State<_AnnouncementsPanel> {
  late final TournamentRepo repo;
  final _controller = TextEditingController();
  String target = 'all';
  @override
  void initState() {
    super.initState();
    repo = TournamentRepo(Supabase.instance.client);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get isOwner => widget.tournament.createdBy == Supabase.instance.client.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Announcements', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (isOwner) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(labelText: 'Compose announcement'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: target,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                    ],
                    onChanged: (v) => setState(() => target = v ?? 'all'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      await repo.addAnnouncement(widget.tournament.id, text, target: target);
                      _controller.clear();
                    },
                    child: const Text('Send'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 200,
              child: StreamBuilder(
                stream: repo.streamAnnouncements(widget.tournament.id),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const [];
                  if (items.isEmpty) {
                    return const Center(child: Text('No announcements yet'));
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final a = items[i];
                      return ListTile(
                        leading: const Icon(Icons.campaign_outlined),
                        title: Text(a.content),
                        subtitle: Text('${a.target} • ${a.insertedAt}'),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _PoolsTab extends StatefulWidget {
  const _PoolsTab({required this.tournament});
  final Tournament tournament;
  @override
  State<_PoolsTab> createState() => _PoolsTabState();
}

class _PoolsTabState extends State<_PoolsTab> {
  late final TournamentRepo repo;
  List<Pool> pools = [];
  Map<String, List<Team>> teamsByPool = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    repo = TournamentRepo(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final ps = await repo.fetchPools(widget.tournament.id);
    final map = <String, List<Team>>{};
    for (final p in ps) {
      map[p.id] = await repo.fetchTeams(widget.tournament.id, poolId: p.id);
    }
    setState(() {
      pools = ps;
      teamsByPool = map;
      loading = false;
    });
  }

  Future<void> _addPool() async {
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New pool/division'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Name (e.g., Pool A)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      final p = await repo.addPool(widget.tournament.id, nameCtrl.text.trim(), position: pools.length);
      setState(() {
        pools.add(p);
        teamsByPool[p.id] = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text('Pools/Divisions',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          if (loading)
            const _PlaceholderCard(text: 'Loading...')
          else if (pools.isEmpty)
            const _PlaceholderCard(text: 'No pools yet')
          else
            ...pools.map((p) => _PoolCard(
                  pool: p,
                  teams: teamsByPool[p.id] ?? const [],
                  tournament: widget.tournament,
                  onDelete: () async {
                    await repo.removePool(p.id);
                    setState(() {
                      pools.removeWhere((x) => x.id == p.id);
                      teamsByPool.remove(p.id);
                    });
                  },
                  onAddTeam: (name) async {
                    final t = await repo.addTeam(widget.tournament.id, name: name, poolId: p.id, seed: (teamsByPool[p.id]?.length ?? 0));
                    setState(() {
                      teamsByPool[p.id] = [...(teamsByPool[p.id] ?? const []), t];
                    });
                  },
                  onReorderTeams: (newOrder) async {
                    await repo.setSeeds(newOrder);
                    setState(() {
                      teamsByPool[p.id] = newOrder;
                    });
                  },
                  onGenerateSchedule: () async {
                    final teams = teamsByPool[p.id] ?? const [];
                    final games = _roundRobin(widget.tournament.id, p.id, teams);
                    await repo.clearGamesForPool(p.id);
                    await repo.insertGames(games);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule generated')));
                    }
                  },
                )),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPool,
        icon: const Icon(Icons.add),
        label: const Text('Add pool'),
      ),
    );
  }
}

class _PoolCard extends StatefulWidget {
  const _PoolCard({
    required this.pool,
    required this.teams,
    required this.tournament,
    required this.onDelete,
    required this.onAddTeam,
    required this.onReorderTeams,
    required this.onGenerateSchedule,
  });
  final Pool pool;
  final List<Team> teams;
  final Tournament tournament;
  final VoidCallback onDelete;
  final Future<void> Function(String name) onAddTeam;
  final Future<void> Function(List<Team> newOrder) onReorderTeams;
  final Future<void> Function() onGenerateSchedule;

  @override
  State<_PoolCard> createState() => _PoolCardState();
}

class _PoolCardState extends State<_PoolCard> {
  bool seedingMode = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.pool.name, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => seedingMode = !seedingMode),
                  icon: Icon(seedingMode ? Icons.check : Icons.format_list_numbered),
                  tooltip: seedingMode ? 'Done seeding' : 'Seed teams',
                ),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove pool',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!seedingMode)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.teams.isEmpty)
                    const Text('No teams assigned')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in widget.teams)
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => TeamRosterPage(team: t)),
                              );
                            },
                            onLongPress: () => _showTeamActions(context, t),
                            child: Chip(
                              label: Text(t.name),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final nameCtrl = TextEditingController();
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Add team'),
                              content: TextField(
                                controller: nameCtrl,
                                decoration: const InputDecoration(labelText: 'Team name'),
                                autofocus: true,
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
                              ],
                            ),
                          );
                          if (ok == true && nameCtrl.text.trim().isNotEmpty) {
                            await widget.onAddTeam(nameCtrl.text.trim());
                          }
                        },
                        icon: const Icon(Icons.group_add_outlined),
                        label: const Text('Add team'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: widget.teams.length < 2 ? null : widget.onGenerateSchedule,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Generate schedule'),
                      ),
                    ],
                  ),
                ],
              )
            else
              _SeedingList(
                initial: widget.teams,
                onSaved: widget.onReorderTeams,
              ),
          ],
        ),
      ),
    );
  }
}

class _SeedingList extends StatefulWidget {
  const _SeedingList({required this.initial, required this.onSaved});
  final List<Team> initial;
  final Future<void> Function(List<Team>) onSaved;

  @override
  State<_SeedingList> createState() => _SeedingListState();
}

class _SeedingListState extends State<_SeedingList> {
  late List<Team> items;
  @override
  void initState() {
    super.initState();
    items = [...widget.initial];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
            });
          },
          children: [
            for (final t in items)
              ListTile(
                key: ValueKey(t.id),
                leading: const Icon(Icons.drag_indicator),
                title: Text(t.name),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () async {
              await widget.onSaved(items);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Seeding updated')));
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Save seeding'),
          ),
        ),
      ],
    );
  }
}

extension on _PoolCardState {
  Future<void> _showTeamActions(BuildContext context, Team team) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Open roster'),
              onTap: () => Navigator.pop(ctx, 'roster'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit team'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Move to another pool'),
              onTap: () => Navigator.pop(ctx, 'move'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete team'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'roster':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => TeamRosterPage(team: team)));
        break;
      case 'edit':
        await _editTeamDialog(team);
        break;
      case 'move':
        await _moveTeamDialog(team);
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete team?'),
            content: Text('This will remove ${team.name} and its roster.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ),
        );
        if (ok == true) {
          final repo = TournamentRepo(Supabase.instance.client);
          await repo.deleteTeam(team.id);
          if (!mounted) return;
          setState(() {
            final list = widget.teams..removeWhere((x) => x.id == team.id);
            // reflect in parent list
            (context as Element).markNeedsBuild();
          });
        }
        break;
    }
  }

  Future<void> _editTeamDialog(Team team) async {
    final nameCtrl = TextEditingController(text: team.name);
    final captainCtrl = TextEditingController(text: team.captainName ?? '');
    final emailCtrl = TextEditingController(text: team.captainEmail ?? '');
    final phoneCtrl = TextEditingController(text: team.captainPhone ?? '');
    final colorCtrl = TextEditingController(text: team.jerseyColor ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit team'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Team name')),
              const SizedBox(height: 8),
              TextField(controller: captainCtrl, decoration: const InputDecoration(labelText: 'Captain name')),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Captain email')),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Captain phone')),
              const SizedBox(height: 8),
              TextField(controller: colorCtrl, decoration: const InputDecoration(labelText: 'Jersey color')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      final repo = TournamentRepo(Supabase.instance.client);
      await repo.updateTeam(
        team.id,
        name: nameCtrl.text.trim(),
        captainName: captainCtrl.text.trim().isEmpty ? null : captainCtrl.text.trim(),
        captainEmail: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
        captainPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        jerseyColor: colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim(),
      );
      if (!mounted) return;
      (context as Element).markNeedsBuild();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team updated')));
    }
  }

  Future<void> _moveTeamDialog(Team team) async {
    final repo = TournamentRepo(Supabase.instance.client);
    // Fetch pools in this tournament
    final pools = await repo.fetchPools(widget.tournament.id);
    String? selected = team.poolId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move team to pool'),
        content: DropdownButtonFormField<String>(
          value: selected,
          items: [
            const DropdownMenuItem(value: null, child: Text('Unassigned')),
            for (final p in pools) DropdownMenuItem(value: p.id, child: Text(p.name)),
          ],
          onChanged: (v) => selected = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Move')),
        ],
      ),
    );
    if (ok == true) {
      await repo.assignTeamToPool(team.id, selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team moved')));
    }
  }
}

List<GameModel> _roundRobin(String tournamentId, String poolId, List<Team> teams) {
  final list = [...teams];
  if (list.length < 2) return const [];
  // If odd, add a bye (null) by using a dummy id
  final byeId = '__BYE__';
  if (list.length.isOdd) {
    list.add(Team(id: byeId, tournamentId: tournamentId, name: 'BYE', poolId: poolId));
  }
  final n = list.length;
  final rounds = n - 1;
  final half = n ~/ 2;
  final schedule = <GameModel>[];
  var rotation = List<Team>.from(list);
  for (var r = 0; r < rounds; r++) {
    for (var i = 0; i < half; i++) {
      final a = rotation[i];
      final b = rotation[n - 1 - i];
      if (a.id == byeId || b.id == byeId) continue;
      schedule.add(GameModel(
        id: 'temp',
        tournamentId: tournamentId,
        poolId: poolId,
        teamA: a.id,
        teamB: b.id,
      ));
    }
    // Rotate (keep first fixed)
    final fixed = rotation.first;
    final tail = rotation.sublist(1);
    tail.insert(0, tail.removeLast());
    rotation = [fixed, ...tail];
  }
  return schedule;
}

class _ScheduleTab extends StatefulWidget {
  const _ScheduleTab({required this.tournament});
  final Tournament tournament;
  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  late final TournamentRepo repo;
  Map<String, Team> teamById = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    repo = TournamentRepo(Supabase.instance.client);
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => loading = true);
    final ts = await repo.fetchTeams(widget.tournament.id);
    setState(() {
      teamById = {for (final t in ts) t.id: t};
      loading = false;
    });
  }

  Future<void> _enterScore(GameModel g) async {
    final aCtrl = TextEditingController(text: g.scoreA.toString());
    final bCtrl = TextEditingController(text: g.scoreB.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter score'),
        content: Row(children: [
          Expanded(child: TextField(controller: aCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Team A'))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: bCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Team B'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      final a = int.tryParse(aCtrl.text) ?? 0;
      final b = int.tryParse(bCtrl.text) ?? 0;
      await repo.updateScore(g.id, a: a, b: b);
    }
  }

  Future<void> _editGame(GameModel g) async {
    final repo = this.repo;
    final settings = await repo.fetchSettings(widget.tournament.id);
    final courts = (settings['courts'] as List?)?.cast<String>() ?? <String>[];
    String? selectedCourt = g.court;
    DateTime? selectedTime = g.startTime ?? DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit game'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedCourt,
              items: [
                for (final c in courts)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => selectedCourt = v,
              decoration: const InputDecoration(labelText: 'Court'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Start time'),
              subtitle: Text(selectedTime.toString()),
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: selectedTime ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d == null) return;
                final t = await showTimePicker(
                  context: ctx,
                  initialTime: TimeOfDay.fromDateTime(selectedTime ?? DateTime.now()),
                );
                if (t == null) return;
                selectedTime = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                (ctx as Element).markNeedsBuild();
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await repo.updateGame(g.id, court: selectedCourt, startTime: selectedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const _PlaceholderCenter('Loading...');
    return StreamBuilder<List<GameModel>>(
      stream: repo.streamGames(widget.tournament.id),
      builder: (context, snapshot) {
        final games = snapshot.data ?? const <GameModel>[];
        if (games.isEmpty) return const _PlaceholderCenter('No games scheduled');
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: games.length,
          itemBuilder: (ctx, i) {
            final g = games[i];
            final a = teamById[g.teamA ?? ''];
            final b = teamById[g.teamB ?? ''];
            final title = '${a?.name ?? 'TBD'} vs ${b?.name ?? 'TBD'}';
            final details = <String>[
              if (g.court != null && g.court!.isNotEmpty) 'Court: ${g.court}',
              if (g.startTime != null) 'Start: ${g.startTime}',
              'Status: ${g.status}',
            ].join(' • ');
            return Card(
              child: ListTile(
                title: Text(title),
                subtitle: Text(details),
                trailing: Text('${g.scoreA} - ${g.scoreB}'),
                onTap: () => _enterScore(g),
                onLongPress: () => _editGame(g),
              ),
            );
          },
        );
      },
    );
  }
}

class _StandingsTab extends StatefulWidget {
  const _StandingsTab({required this.tournament});
  final Tournament tournament;
  @override
  State<_StandingsTab> createState() => _StandingsTabState();
}

class _StandingsTabState extends State<_StandingsTab> {
  late final TournamentRepo repo;
  bool loading = true;
  List<Pool> pools = [];
  List<Team> teams = [];

  @override
  void initState() {
    super.initState();
    repo = TournamentRepo(Supabase.instance.client);
    _loadPoolsAndTeams();
  }

  Future<void> _loadPoolsAndTeams() async {
    setState(() => loading = true);
    final ps = await repo.fetchPools(widget.tournament.id);
    final ts = await repo.fetchTeams(widget.tournament.id);
    setState(() {
      pools = ps;
      teams = ts;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const _PlaceholderCenter('Loading...');
    return StreamBuilder<List<GameModel>>(
      stream: repo.streamGames(widget.tournament.id),
      builder: (context, snapshot) {
        final games = snapshot.data ?? const <GameModel>[];
        if (teams.isEmpty) return const _PlaceholderCenter('No standings yet');

        final teamById = {for (final t in teams) t.id: t};
        final map = <String, _Agg>{};
        for (final g in games) {
          final a = g.teamA; final b = g.teamB;
          if (a == null || b == null) continue;
          final pa = teamById[a]?.poolId; final pb = teamById[b]?.poolId;
          if (pa == null || pb == null || pa != pb) continue;
          map.putIfAbsent(a, () => _Agg()).played++;
          map.putIfAbsent(b, () => _Agg()).played++;
          map[a]!.pointsFor += g.scoreA; map[a]!.pointsAgainst += g.scoreB;
          map[b]!.pointsFor += g.scoreB; map[b]!.pointsAgainst += g.scoreA;
          if (g.status == 'final') {
            if (g.scoreA > g.scoreB) { map[a]!.wins++; map[b]!.losses++; }
            else if (g.scoreB > g.scoreA) { map[b]!.wins++; map[a]!.losses++; }
          }
        }

        final byPool = <String, List<_StandingRow>>{};
        for (final t in teams) {
          final pid = t.poolId; if (pid == null) continue;
          final agg = map[t.id] ?? _Agg();
          byPool.putIfAbsent(pid, () => []);
          byPool[pid]!.add(_StandingRow(team: t, agg: agg));
        }
        byPool.updateAll((key, value) {
          value.sort((a, b) => b.agg.points.compareTo(a.agg.points));
          return value;
        });

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final p in pools) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(p.name, style: Theme.of(context).textTheme.titleMedium),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      for (var i = 0; i < (byPool[p.id]?.length ?? 0); i++)
                        Row(
                          children: [
                            SizedBox(width: 28, child: Text('${i + 1}')),
                            Expanded(child: Text(byPool[p.id]![i].team.name)),
                            SizedBox(width: 32, child: Text('${byPool[p.id]![i].agg.wins}')),
                            const SizedBox(width: 12),
                            SizedBox(width: 32, child: Text('${byPool[p.id]![i].agg.losses}')),
                            const SizedBox(width: 12),
                            SizedBox(width: 48, child: Text('${byPool[p.id]![i].agg.pointsFor}-${byPool[p.id]![i].agg.pointsAgainst}')),
                            const SizedBox(width: 12),
                            SizedBox(width: 32, child: Text('${byPool[p.id]![i].agg.points}')),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        );
      },
    );
  }
}

class _Agg {
  int played = 0;
  int wins = 0;
  int losses = 0;
  int pointsFor = 0;
  int pointsAgainst = 0;
  int get points => wins * 2; // 2 points per win
}

class _StandingRow {
  _StandingRow({required this.team, required this.agg});
  final Team team;
  final _Agg agg;
}

class _PlaceholderCenter extends StatelessWidget {
  const _PlaceholderCenter(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
