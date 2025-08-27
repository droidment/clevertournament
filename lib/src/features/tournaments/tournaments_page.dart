import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'create_tournament_page.dart';
import 'tournament_detail_page.dart';
import 'tournament_model.dart';

class TournamentsPage extends StatefulWidget {
  const TournamentsPage({super.key});

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  final List<Tournament> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final res = await Supabase.instance.client
        .from('tournaments')
        .select()
        .order('inserted_at', ascending: false);
    setState(() {
      _items
        ..clear()
        ..addAll((res as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(Tournament.fromMap));
    });
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<Tournament>(
      MaterialPageRoute(builder: (_) => const CreateTournamentPage()),
    );
    if (created != null) {
      // Persist to Supabase
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please sign in to create a tournament.')),
            );
          }
          return;
        }

        final map = created.toMap();
        map.remove('id');
        map['created_by'] = userId; // also set by DB trigger if omitted
        // Ensure date-only strings for date columns
        map['start_date'] = created.startDate.toIso8601String().substring(0, 10);
        map['end_date'] = created.endDate.toIso8601String().substring(0, 10);

        final inserted = await Supabase.instance.client
            .from('tournaments')
            .insert(map)
            .select()
            .single();
        final t = Tournament.fromMap(
            (inserted as Map<String, dynamic>));
        setState(() => _items.insert(0, t));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created "${t.name}"')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save tournament')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (Supabase.instance.client.auth.currentUser == null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('You are not signed in'),
                subtitle: const Text('Sign in to create and manage tournaments.'),
                trailing: FilledButton(
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  child: const Text('Sign in'),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text('Browse tournaments',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          if (_items.isEmpty)
            const _PlaceholderCard(text: 'No tournaments yet')
          else
            ..._items.map((t) => _TournamentCard(t)),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: Supabase.instance.client.auth.currentUser == null
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please sign in first')),
                )
            : _create,
        icon: const Icon(Icons.add),
        label: const Text('New tournament'),
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard(this.t);
  final Tournament t;
  @override
  Widget build(BuildContext context) {
    final subtitle = '${t.location} • '
        '${t.startDate.year}/${t.startDate.month}/${t.startDate.day}'
        ' - '
        '${t.endDate.year}/${t.endDate.month}/${t.endDate.day}';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.emoji_events_outlined),
        title: Text(t.name),
        subtitle: Text(subtitle),
        trailing: Chip(
          label: Text(t.sport == Sport.volleyball ? 'Volleyball' : 'Pickleball'),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TournamentDetailPage(tournament: t)),
          );
        },
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
