import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/tournament_repo.dart';
import 'tournament_model.dart';

class TournamentSettingsPage extends StatefulWidget {
  const TournamentSettingsPage({super.key, required this.tournament});
  final Tournament tournament;

  @override
  State<TournamentSettingsPage> createState() => _TournamentSettingsPageState();
}

class _TournamentSettingsPageState extends State<TournamentSettingsPage> {
  late final TournamentRepo repo;
  bool loading = true;
  String format = 'Round Robin';
  List<String> tieBreakers = ['Head-to-head', 'Point differential'];
  final TextEditingController _courtCtrl = TextEditingController();
  List<String> courts = [];

  @override
  void initState() {
    super.initState();
    repo = TournamentRepo(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    final s = await repo.fetchSettings(widget.tournament.id);
    setState(() {
      format = (s['format'] as String?) ?? format;
      tieBreakers = (s['tie_breakers'] as List?)?.cast<String>() ?? tieBreakers;
      courts = (s['courts'] as List?)?.cast<String>() ?? courts;
      loading = false;
    });
  }

  Future<void> _save() async {
    final s = {
      'format': format,
      'tie_breakers': tieBreakers,
      'courts': courts,
    };
    await repo.saveSettings(widget.tournament.id, s);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Tournament settings'), actions: [
        IconButton(onPressed: _save, icon: const Icon(Icons.save)),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Format', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: format,
            items: const [
              DropdownMenuItem(value: 'Round Robin', child: Text('Round Robin')),
              DropdownMenuItem(value: 'Single Elimination', child: Text('Single Elimination')),
              DropdownMenuItem(value: 'Double Elimination', child: Text('Double Elimination')),
              DropdownMenuItem(value: 'Swiss', child: Text('Swiss')),
              DropdownMenuItem(value: 'Pool + Playoffs', child: Text('Pool + Playoffs')),
            ],
            onChanged: (v) => setState(() => format = v ?? format),
          ),
          const SizedBox(height: 24),
          Text('Tie-breakers (drag to reorder)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _TieBreakersEditor(
            initial: tieBreakers,
            onChanged: (v) => setState(() => tieBreakers = v),
          ),
          const SizedBox(height: 24),
          Text('Courts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final c in courts)
                Chip(
                  label: Text(c),
                  onDeleted: () => setState(() => courts.remove(c)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _courtCtrl,
                  decoration: const InputDecoration(labelText: 'Add court (e.g., Court 1)'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: () {
                final v = _courtCtrl.text.trim();
                if (v.isEmpty) return;
                setState(() {
                  courts.add(v);
                  _courtCtrl.clear();
                });
              }, child: const Text('Add')),
            ],
          )
        ],
      ),
    );
  }
}

class _TieBreakersEditor extends StatefulWidget {
  const _TieBreakersEditor({required this.initial, required this.onChanged});
  final List<String> initial;
  final ValueChanged<List<String>> onChanged;
  @override
  State<_TieBreakersEditor> createState() => _TieBreakersEditorState();
}

class _TieBreakersEditorState extends State<_TieBreakersEditor> {
  late List<String> items;
  @override
  void initState() {
    super.initState();
    items = [...widget.initial];
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
              widget.onChanged(items);
            });
          },
          children: [
            for (final t in items)
              ListTile(
                key: ValueKey(t),
                leading: const Icon(Icons.drag_indicator),
                title: Text(t),
              )
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () async {
              final ctrl = TextEditingController();
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Add tie-breaker'),
                  content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Name')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
                  ],
                ),
              );
              if (ok == true && ctrl.text.trim().isNotEmpty) {
                setState(() { items.add(ctrl.text.trim()); widget.onChanged(items); });
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add tie-breaker'),
          ),
        )
      ],
    );
  }
}

