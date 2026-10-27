import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api_client.dart';
import '../app.dart';
import '../theme/fc_tokens.dart';
import '../widgets/fc_auth_page.dart';
import '../widgets/fc_button.dart';
import '../widgets/fc_form.dart';
import '../widgets/fc_icons.dart';
import 'verify_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifier = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _identifier.text.trim();
    if (_busy) {
      return;
    }
    if (identifier.isEmpty) {
      setState(() => _error = 'Enter your username or email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await SessionScope.of(context).api.forgotPassword(identifier);
      if (mounted) {
        context.go('/verify-code', extra: VerifyCodeArgs.reset(identifier));
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException ? error.message : '$error',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return FcAuthPage(
      title: 'Forgot password',
      subtitle: Text(
        "Enter your username or email and we'll send a code to the email "
        'on the account.',
        style: FcText.body.copyWith(color: c.textSecondary),
      ),
      footer: FcButton(
        label: 'Back to log in',
        variant: FcButtonVariant.ghost,
        icon: FcIcons.caretLeft,
        onPressed: () => context.go('/login'),
      ),
      children: [
        FcTextField(
          label: 'Username or email',
          placeholder: 'Your username or email',
          controller: _identifier,
          hasError: _error != null,
          autofillHints: const [AutofillHints.username],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          describedBy: _error,
          onChanged: (_) {
            if (_error != null) {
              setState(() => _error = null);
            }
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: FcSpace.s2),
          FcFieldError(_error!),
        ],
        const SizedBox(height: FcSpace.s6),
        FcButton(
          label: 'Send code',
          large: true,
          block: true,
          loading: _busy,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}
