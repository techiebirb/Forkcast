import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api_client.dart';
import '../app.dart';
import '../theme/fc_tokens.dart';
import '../widgets/fc_button.dart';
import '../widgets/fc_form.dart';
import '../widgets/fc_surfaces.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  /// True when the server rejected the credentials, so both fields get the
  /// error edge. Network problems show the banner only.
  bool _badCredentials = false;

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
      _badCredentials = false;
    });
    try {
      await SessionScope.of(context).login(
        _username.text.trim(),
        _password.text,
      );
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : '$error';
        setState(() {
          _error = message;
          _badCredentials = error is ApiException && error.statusCode == 401;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _clearError(String _) {
    if (_error != null) {
      setState(() {
        _error = null;
        _badCredentials = false;
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
                        'Log in',
                        style: FcText.display.copyWith(color: c.textPrimary),
                      ),
                    ),
                    const SizedBox(height: FcSpace.s2),
                    Text(
                      'Your targets and allergies are saved to your account.',
                      style: FcText.body.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: FcSpace.s8),
                    AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            FcAlert(
                              message: _error!,
                              detail: _badCredentials
                                  ? 'Check both and try again.'
                                  : null,
                            ),
                            const SizedBox(height: FcSpace.s4),
                          ],
                          FcTextField(
                            label: 'Username',
                            controller: _username,
                            hasError: _badCredentials,
                            autofillHints: const [AutofillHints.username],
                            textInputAction: TextInputAction.next,
                            onChanged: _clearError,
                            describedBy: _error,
                          ),
                          const SizedBox(height: FcSpace.s4),
                          FcTextField(
                            label: 'Password',
                            controller: _password,
                            obscure: true,
                            hasError: _badCredentials,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            onChanged: _clearError,
                            describedBy: _error,
                          ),
                          const SizedBox(height: FcSpace.s6),
                          FcButton(
                            label: 'Log in',
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
                            'Need an account?',
                            style: FcText.bodySm.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          FcButton(
                            label: 'Sign up',
                            variant: FcButtonVariant.ghost,
                            onPressed: () => context.go('/signup'),
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
