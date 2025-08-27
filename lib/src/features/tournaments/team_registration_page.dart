import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/tournament_repo.dart';
import 'tournament_model.dart';

class TeamRegistrationPage extends StatefulWidget {
  const TeamRegistrationPage({super.key, required this.tournament});
  final Tournament tournament;
  @override
  State<TeamRegistrationPage> createState() => _TeamRegistrationPageState();
}

class _TeamRegistrationPageState extends State<TeamRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _teamCtrl = TextEditingController();
  final _captainCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _teamCtrl.dispose();
    _captainCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in first')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final repo = TournamentRepo(Supabase.instance.client);
      await repo.submitRegistration(
        tournamentId: widget.tournament.id,
        teamName: _teamCtrl.text.trim(),
        captainName: _captainCtrl.text.trim().isEmpty ? null : _captainCtrl.text.trim(),
        captainEmail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        captainPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration submitted')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Team')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text('Tournament: ${widget.tournament.name}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _teamCtrl,
                      decoration: const InputDecoration(labelText: 'Team name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a team name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _captainCtrl,
                      decoration: const InputDecoration(labelText: 'Captain name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Captain email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Captain phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit registration'),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

