import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api_client.dart';
import '../app.dart';
import '../theme/fc_tokens.dart';
import '../widgets/fc_auth_page.dart';
import '../widgets/fc_button.dart';
import '../widgets/fc_form.dart';
import 'verify_code_screen.dart';

/// Shown to accounts made before email existed. They can't use the app until
/// they add and verify one.
class AddEmailScreen extends StatefulWidget {
  const AddEmailScreen({super.key});

  @override
  State<AddEmailScreen> createState() => _AddEmailScreenState();
}

class _AddEmailScreenState extends State<AddEmailScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    final email = _email.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await SessionScope.of(context).api.addEmail(email);
      if (mounted) {
        context.go('/verify-code', extra: VerifyCodeArgs.addEmail(email));
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
      title: 'Add your email',
      subtitle: Text(
        'Accounts now need a verified email so you can reset your password. '
        "We'll send you a code.",
        style: FcText.body.copyWith(color: c.textSecondary),
      ),
      footer: FcButton(
        label: 'Log out',
        variant: FcButtonVariant.ghost,
        onPressed: () => SessionScope.of(context).logout(),
      ),
      children: [
        FcTextField(
          label: 'Email',
          placeholder: 'name@example.com',
          controller: _email,
          hasError: _error != null,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
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
