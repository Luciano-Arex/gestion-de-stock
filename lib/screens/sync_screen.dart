import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../data/sync_controller.dart';
import '../l10n/app_localizations.dart';

/// Connexion au compte partagé et état de la synchronisation.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key, required this.sync});

  final SyncController sync;

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.sync)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.sync,
          builder: (context, _) {
            final status = widget.sync.status;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(t.syncIntro, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                if (status == SyncStatus.notConfigured)
                  Text(t.syncNotConfigured)
                else if (status == SyncStatus.signedOut)
                  ..._signInForm(t)
                else
                  ..._status(t, status),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _status(AppLocalizations t, SyncStatus status) {
    final last = widget.sync.lastSuccess;
    final (label, icon) = switch (status) {
      SyncStatus.syncing => (t.syncSyncing, Icons.sync),
      SyncStatus.offline => (t.syncOffline, Icons.cloud_off),
      _ => (t.syncIdle, Icons.cloud_done),
    };
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, size: 32),
        title: Text(label),
        subtitle: last == null
            ? null
            : Text(t.syncLast(DateFormat.yMd('fr').add_Hm().format(last))),
      ),
      if (widget.sync.account case final email?) Text(t.syncAccount(email)),
      const SizedBox(height: 24),
      FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        icon: const Icon(Icons.sync),
        label: Text(t.syncNow),
        onPressed: status == SyncStatus.syncing ? null : widget.sync.syncNow,
      ),
      const SizedBox(height: 16),
      TextButton(
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: widget.sync.signOut,
        child: Text(t.signOut),
      ),
    ];
  }

  List<Widget> _signInForm(AppLocalizations t) => [
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: t.email, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: t.password,
            errorText: _error,
            errorMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _signIn(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: _busy ? null : _signIn,
          child: Text(t.signIn),
        ),
      ];

  Future<void> _signIn() async {
    final t = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.sync.signIn(_email.text, _password.text);
      _password.clear();
    } on AuthException {
      setState(() => _error = t.signInError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
