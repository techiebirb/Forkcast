import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api_client.dart';
import '../app.dart';
import '../theme/fc_tokens.dart';
import '../widgets/fc_button.dart';
import '../widgets/fc_chips.dart';
import '../widgets/fc_form.dart';
import '../widgets/fc_icons.dart';
import '../widgets/fc_surfaces.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  /// Banner for errors that are not about the username (validation, network).
  String? _error;

  /// Set when the server says the name is taken (HTTP 409).
  String? _usernameError;
  List<String> _suggestions = const [];

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _usernameError = null;
      _suggestions = const [];
    });
    try {
      await SessionScope.of(context).signup(
        _username.text.trim(),
        _password.text,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          if (error is ApiException && error.statusCode == 409) {
            _usernameError =
                'That username is taken. Try one of these or add a number.';
            _suggestions = error.suggestions;
          } else {
            _error = error is ApiException ? error.message : '$error';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _useSuggestion(String name) {
    setState(() {
      _username.text = name;
      _username.selection = TextSelection.collapsed(offset: name.length);
      _usernameError = null;
      _suggestions = const [];
    });
  }

  void _clearUsernameError(String _) {
    if (_usernameError != null) {
      setState(() {
        _usernameError = null;
        _suggestions = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  FcSpace.s4,
                  FcSpace.s12,
                  FcSpace.s4,
                  FcSpace.s8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forkcast',
                      style: FcText.wordmark.copyWith(color: c.textPrimary),
                    ),
                    const SizedBox(height: 72),
                    Semantics(
                      header: true,
                      child: Text(
                        'Create an account',
                        style: FcText.display.copyWith(color: c.textPrimary),
                      ),
                    ),
                    const SizedBox(height: FcSpace.s2),
                    Text(
                      'Save your targets once and use them at every '
                      'restaurant.',
                      style: FcText.body.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: FcSpace.s8),
                    AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            FcAlert(message: _error!),
                            const SizedBox(height: FcSpace.s4),
                          ],
                          FcTextField(
                            label: 'Username',
                            controller: _username,
                            hasError: _usernameError != null,
                            autofillHints: const [AutofillHints.newUsername],
                            textInputAction: TextInputAction.next,
                            onChanged: _clearUsernameError,
                            describedBy:
                                _usernameError ?? 'At least 3 characters',
                          ),
                          const SizedBox(height: FcSpace.s2),
                          if (_usernameError != null) ...[
                            Semantics(
                              liveRegion: true,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: FcIcon(
                                      FcIcons.warning,
                                      size: 16,
                                      color: c.danger,
                                    ),
                                  ),
                                  const SizedBox(width: FcSpace.s2),
                                  Expanded(
                                    child: Text(
                                      _usernameError!,
                                      style: FcText.label.copyWith(
                                        color: c.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_suggestions.isNotEmpty) ...[
                              const SizedBox(height: FcSpace.s2),
                              Wrap(
                                spacing: FcSpace.s2,
                                runSpacing: FcSpace.s2,
                                children: [
                                  for (final name in _suggestions)
                                    FcFilterChip(
                                      label: name,
                                      onSelected: (_) => _useSuggestion(name),
                                    ),
                                ],
                              ),
                            ],
                          ] else
                            const _Hint('At least 3 characters'),
                          const SizedBox(height: FcSpace.s4),
                          FcTextField(
                            label: 'Password',
                            controller: _password,
                            obscure: true,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            describedBy: 'At least 4 characters',
                          ),
                          const SizedBox(height: FcSpace.s2),
                          const _Hint('At least 4 characters'),
                          const SizedBox(height: FcSpace.s6),
                          FcButton(
                            label: 'Create account',
                            large: true,
                            block: true,
                            loading: _busy,
                            onPressed: _busy ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: FcSpace.s6),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: FcText.bodySm.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          FcButton(
                            label: 'Log in',
                            variant: FcButtonVariant.ghost,
                            onPressed: () => context.go('/login'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper text under a field: info icon and a short rule.
class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return ExcludeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: FcIcon(FcIcons.info, size: 16, color: c.textSecondary),
          ),
          const SizedBox(width: FcSpace.s2),
          Expanded(
            child: Text(
              text,
              style: FcText.caption.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
