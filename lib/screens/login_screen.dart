import 'dart:io' show SocketException;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthRetryableFetchException;

import '../data/account.dart';
import '../data/locale_controller.dart';
import '../l10n/app_localizations.dart';
import 'settings_screen.dart';

enum _Mode { signIn, signUp }

/// Page d'accueil sans compte connecté : se connecter ou créer un compte.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth, this.locale});

  final AuthGateway auth;
  final LocaleController? locale;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _Mode _mode = _Mode.signIn;
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidden = true;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final signUp = _mode == _Mode.signUp;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (widget.locale case final locale?)
            IconButton(
              tooltip: t.language,
              icon: const Icon(Icons.language),
              onPressed: () => chooseLanguage(context, locale),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(Icons.inventory_2, size: 40, color: scheme.onPrimaryContainer),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(t.appTitle, style: text.headlineMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(t.loginSubtitle,
                          style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 32),
                      SegmentedButton<_Mode>(
                        segments: [
                          ButtonSegment(value: _Mode.signIn, label: Text(t.signIn)),
                          ButtonSegment(value: _Mode.signUp, label: Text(t.createAccount)),
                        ],
                        selected: {_mode},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) => setState(() {
                          _mode = s.single;
                          _error = null;
                          _info = null;
                        }),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: t.email,
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                        validator: (v) => _validEmail(v) ? null : t.authEmailInvalid,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: _hidden,
                        autofillHints: [signUp ? AutofillHints.newPassword : AutofillHints.password],
                        textInputAction: signUp ? TextInputAction.next : TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: t.password,
                          prefixIcon: const Icon(Icons.lock_outline),
                          helperText: signUp ? t.passwordRule : null,
                          suffixIcon: IconButton(
                            tooltip: _hidden ? t.showPassword : t.hidePassword,
                            icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _hidden = !_hidden),
                          ),
                        ),
                        validator: (v) =>
                            signUp && (v ?? '').length < minPasswordLength ? t.passwordRule : null,
                        onFieldSubmitted: signUp ? null : (_) => _submit(),
                      ),
                      if (signUp) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirm,
                          obscureText: _hidden,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: t.passwordConfirm,
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          validator: (v) => v == _password.text ? null : t.passwordMismatch,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
                      if (_error != null || _info != null) ...[
                        const SizedBox(height: 16),
                        _Notice(text: _error ?? _info!, error: _error != null),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 24, child: CircularProgressIndicator(strokeWidth: 3))
                            : Text(signUp ? t.createAccount : t.signIn),
                      ),
                      if (!signUp) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _busy ? null : _forgot,
                          child: Text(t.forgotPassword),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final t = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      if (_mode == _Mode.signIn) {
        await widget.auth.signIn(_email.text, _password.text);
      } else if (!await widget.auth.signUp(_email.text, _password.text)) {
        // Le serveur demande de confirmer l'adresse avant la première connexion.
        if (mounted) {
          setState(() {
            _mode = _Mode.signIn;
            _info = t.signUpCheckEmail(_email.text.trim());
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = authErrorText(t, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResetPasswordScreen(auth: widget.auth, email: _email.text.trim()),
    ));
  }
}

/// Mot de passe oublié : un code reçu par e-mail permet d'en choisir un nouveau.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.auth, this.email = ''});

  final AuthGateway auth;
  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.forgotPassword)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_codeSent ? t.resetCodeSent(_email.text.trim()) : t.resetIntro,
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      enabled: !_codeSent,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: t.email,
                        prefixIcon: const Icon(Icons.mail_outline),
                      ),
                      validator: (v) => _validEmail(v) ? null : t.authEmailInvalid,
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        decoration: InputDecoration(
                          labelText: t.resetCode,
                          prefixIcon: const Icon(Icons.pin_outlined),
                        ),
                        validator: (v) => (v ?? '').trim().length >= 6 ? null : t.authCodeInvalid,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: t.newPassword,
                          helperText: t.passwordRule,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        validator: (v) =>
                            (v ?? '').length < minPasswordLength ? t.passwordRule : null,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _Notice(text: _error!, error: true),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                      onPressed: _busy ? null : _submit,
                      child: Text(_codeSent ? t.resetConfirm : t.resetSend),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final t = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_codeSent) {
        await widget.auth.sendResetCode(_email.text);
        if (mounted) setState(() => _codeSent = true);
      } else {
        // Réussi : le compte s'ouvre et l'appli passe à l'accueil.
        await widget.auth.resetPassword(_email.text, _code.text, _password.text);
        if (navigator.mounted) navigator.popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (mounted) setState(() => _error = authErrorText(t, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Longueur minimale imposée par Supabase par défaut.
const minPasswordLength = 6;

bool _validEmail(String? v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim());

/// Message clair pour une erreur de connexion ou d'inscription.
String authErrorText(AppLocalizations t, Object e) {
  if (e is AuthRetryableFetchException || e is SocketException) return t.authOffline;
  if (e is! AuthException) return t.authOffline;
  return switch (e.code) {
    'invalid_credentials' => t.authInvalid,
    'email_not_confirmed' => t.authNotConfirmed,
    'user_already_exists' || 'email_exists' => t.authExists,
    'weak_password' => t.passwordRule,
    'signup_disabled' || 'email_provider_disabled' => t.authSignupDisabled,
    'over_email_send_rate_limit' || 'over_request_rate_limit' => t.authRateLimit,
    'otp_expired' => t.authCodeInvalid,
    'email_address_invalid' => t.authEmailInvalid,
    _ => t.authUnknown(e.message),
  };
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.error});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = error ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(error ? Icons.error_outline : Icons.mark_email_unread_outlined, color: fg),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: fg))),
        ],
      ),
    );
  }
}
