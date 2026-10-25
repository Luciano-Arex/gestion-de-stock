import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/pin_lock.dart';
import '../data/sync_controller.dart';
import '../l10n/app_localizations.dart';

/// Pavé numérique : gros boutons au doigt, chiffres et Entrée au clavier sous Windows.
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.title, required this.onSubmit, this.error});

  final String title;
  final String? error;
  // Reçoit le code saisi (4 à 6 chiffres).
  final ValueChanged<String> onSubmit;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  final _focus = FocusNode();

  @override
  void didUpdateWidget(PinPad old) {
    super.didUpdateWidget(old);
    // Une nouvelle erreur efface la saisie précédente.
    if (widget.error != null && widget.error != old.error) _pin = '';
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _add(String digit) {
    if (_pin.length < 6) setState(() => _pin += digit);
  }

  void _remove() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _submit() {
    if (PinLock.isValidPin(_pin)) {
      final pin = _pin;
      setState(() => _pin = '');
      widget.onSubmit(pin);
    }
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final char = event.character;
    if (char != null && RegExp(r'^\d$').hasMatch(char)) {
      _add(char);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _remove();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _submit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget key(String label, {VoidCallback? onPressed, String? tooltip, IconData? icon}) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          width: 80,
          height: 64,
          child: Tooltip(
            message: tooltip ?? label,
            child: FilledButton.tonal(
              onPressed: onPressed,
              child: icon != null ? Icon(icon) : Text(label, style: text.headlineSmall),
            ),
          ),
        ),
      );
    }

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title, style: text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Semantics(
            label: t.pinDigits(_pin.length),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 6; i++)
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      i < _pin.length ? Icons.circle : Icons.circle_outlined,
                      size: 18,
                      color: i < 4 || i < _pin.length ? scheme.primary : scheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: widget.error == null
                ? null
                : Center(
                    child: Text(widget.error!,
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(color: scheme.error)),
                  ),
          ),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (final d in row) key(d, onPressed: () => _add(d))],
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              key('', tooltip: t.pinErase, icon: Icons.backspace_outlined, onPressed: _remove),
              key('0', onPressed: () => _add('0')),
              key('', tooltip: t.validate, icon: Icons.check,
                  onPressed: PinLock.isValidPin(_pin) ? _submit : null),
            ],
          ),
        ],
      ),
    );
  }
}

/// Affiche l'écran de verrouillage par-dessus l'appli quand c'est nécessaire,
/// et reverrouille après une minute passée en arrière-plan.
class PinGate extends StatefulWidget {
  const PinGate({super.key, required this.pin, required this.child, this.sync});

  final PinLock pin;
  final SyncController? sync;
  final Widget child;

  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> with WidgetsBindingObserver {
  static const relockAfter = Duration(minutes: 1);
  DateTime? _leftAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _leftAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final left = _leftAt;
      _leftAt = null;
      if (left != null && DateTime.now().difference(left) >= relockAfter) widget.pin.lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.pin,
      // L'appli reste montée derrière, cachée : on retrouve l'écran où on
      // était. Le Navigator dédié permet les dialogues de « PIN oublié ».
      builder: (context, child) {
        final locked = widget.pin.locked;
        return Stack(
          children: [
            ExcludeFocus(
              excluding: locked,
              child: Offstage(offstage: locked, child: child),
            ),
            if (locked)
              HeroControllerScope.none(
                child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute(
                    builder: (_) => _LockScreen(pin: widget.pin, sync: widget.sync),
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _LockScreen extends StatefulWidget {
  const _LockScreen({required this.pin, this.sync});

  final PinLock pin;
  final SyncController? sync;

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  String? _error;
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _try(String pin) async {
    final t = AppLocalizations.of(context)!;
    final ok = await widget.pin.unlock(pin);
    if (ok || !mounted) return;
    _showWait(t);
  }

  void _showWait(AppLocalizations t) {
    final wait = widget.pin.waitRemaining;
    setState(() => _error = wait == null ? t.pinWrong : t.pinWait(wait.inSeconds + 1));
    _tick?.cancel();
    if (wait != null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
        final left = widget.pin.waitRemaining;
        if (!mounted) return;
        setState(() => _error = left == null ? null : t.pinWait(left.inSeconds + 1));
        if (left == null) timer.cancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                PinPad(title: t.pinEnter, error: _error, onSubmit: _try),
                const SizedBox(height: 16),
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => forgotPin(context, widget.pin, widget.sync),
                  child: Text(t.pinForgot),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// PIN oublié : si le compte de synchronisation est connecté, son mot de passe
/// permet d'enlever le PIN. Sinon, on explique comment s'en sortir.
Future<void> forgotPin(BuildContext context, PinLock pin, SyncController? sync) async {
  final t = AppLocalizations.of(context)!;
  final email = sync?.account;
  if (email == null) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.pinForgot),
        content: Text(t.pinForgotNoAccount),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(t.confirm)),
        ],
      ),
    );
    return;
  }
  final password = TextEditingController();
  String? error;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(t.pinForgot),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.pinForgotWithAccount(email)),
            const SizedBox(height: 16),
            TextField(
              controller: password,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(labelText: t.password, errorText: error),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          FilledButton(
            onPressed: () async {
              try {
                await sync!.signIn(email, password.text);
                await pin.removePin();
                if (context.mounted) Navigator.pop(context);
              } catch (_) {
                setState(() => error = t.signInError);
              }
            },
            child: Text(t.confirm),
          ),
        ],
      ),
    ),
  );
  password.dispose();
}

/// Création, changement ou suppression du PIN, depuis les Réglages.
class PinSettingsScreen extends StatefulWidget {
  const PinSettingsScreen({super.key, required this.pin});

  final PinLock pin;

  @override
  State<PinSettingsScreen> createState() => _PinSettingsScreenState();
}

enum _Step { menu, checkOld, newPin, confirmPin }

class _PinSettingsScreenState extends State<PinSettingsScreen> {
  _Step _step = _Step.menu;
  bool _removing = false;
  String? _first;
  String? _error;

  void _go(_Step step, {bool removing = false}) => setState(() {
        _step = step;
        _removing = removing;
        _error = null;
      });

  Future<void> _onPin(String value) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    switch (_step) {
      case _Step.checkOld:
        if (!await widget.pin.check(value)) {
          setState(() => _error = t.pinWrong);
        } else if (_removing) {
          await widget.pin.removePin();
          messenger.showSnackBar(SnackBar(content: Text(t.pinRemoved)));
          _go(_Step.menu);
        } else {
          _go(_Step.newPin);
        }
      case _Step.newPin:
        _first = value;
        _go(_Step.confirmPin);
      case _Step.confirmPin:
        if (value != _first) {
          _first = null;
          setState(() {
            _step = _Step.newPin;
            _error = t.pinMismatch;
          });
        } else {
          await widget.pin.setPin(value);
          messenger.showSnackBar(SnackBar(content: Text(t.pinSaved)));
          _go(_Step.menu);
        }
      case _Step.menu:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.pinTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: switch (_step) {
                _Step.menu => _menu(t),
                _Step.checkOld => PinPad(title: t.pinCurrent, error: _error, onSubmit: _onPin),
                _Step.newPin => PinPad(title: t.pinNew, error: _error, onSubmit: _onPin),
                _Step.confirmPin => PinPad(title: t.pinConfirm, error: _error, onSubmit: _onPin),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _menu(AppLocalizations t) {
    final enabled = widget.pin.enabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.pinIntro, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 32),
        if (!enabled)
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: () => _go(_Step.newPin),
            child: Text(t.pinCreate),
          )
        else ...[
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: () => _go(_Step.checkOld),
            child: Text(t.pinChange),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: () => _go(_Step.checkOld, removing: true),
            child: Text(t.pinRemove),
          ),
        ],
      ],
    );
  }
}
