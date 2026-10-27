import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../api_client.dart';
import '../app.dart';
import '../theme/fc_tokens.dart';
import '../widgets/fc_auth_page.dart';
import '../widgets/fc_button.dart';
import '../widgets/fc_form.dart';
import '../widgets/fc_icons.dart';

enum VerifyPurpose {
  signup('signup'),
  addEmail('add_email'),
  reset('reset');

  const VerifyPurpose(this.wireName);

  /// The `purpose` value the server uses.
  final String wireName;
}

/// What the code screen is verifying. Passed as the route's `extra`.
class VerifyCodeArgs {
  const VerifyCodeArgs._(this.purpose, {this.email = '', this.identifier = ''});

  /// Finishing signup: the code creates the account.
  const VerifyCodeArgs.signup(String email)
      : this._(VerifyPurpose.signup, email: email);

  /// An older account confirming the email it just added.
  const VerifyCodeArgs.addEmail(String email)
      : this._(VerifyPurpose.addEmail, email: email);

  /// Password reset; [identifier] is what the user typed (username or email).
  const VerifyCodeArgs.reset(String identifier)
      : this._(VerifyPurpose.reset, identifier: identifier);

  final VerifyPurpose purpose;
  final String email;
  final String identifier;
}

class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key, required this.args});

  final VerifyCodeArgs args;

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  static const _resendWait = 60;

  final _code = TextEditingController();
  final _password = TextEditingController();
  Timer? _timer;
  int _secondsLeft = _resendWait;
  bool _busy = false;
  String? _error;
  String? _info;

  VerifyPurpose get _purpose => widget.args.purpose;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendWait);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
      }
      if (mounted) {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    final session = SessionScope.of(context);
    final code = _code.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      switch (_purpose) {
        case VerifyPurpose.signup:
          await session.verifySignup(widget.args.email, code);
        case VerifyPurpose.addEmail:
          await session.verifyEmail(widget.args.email, code);
        case VerifyPurpose.reset:
          await session.resetPassword(
            widget.args.identifier,
            code,
            _password.text,
          );
      }
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = error is ApiException ? error.message : '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _resend() async {
    setState(() {
      _error = null;
      _info = null;
    });
    try {
      await SessionScope.of(context).api.resendCode(
            _purpose.wireName,
            email: widget.args.email,
            identifier: widget.args.identifier,
          );
      if (mounted) {
        _startCountdown();
        setState(() => _info = 'A new code is on its way.');
      }
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = error is ApiException ? error.message : '$error');
      }
    }
  }

  void _back() {
    switch (_purpose) {
      case VerifyPurpose.signup:
        context.go('/signup');
      case VerifyPurpose.addEmail:
        context.go('/add-email');
      case VerifyPurpose.reset:
        context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isReset = _purpose == VerifyPurpose.reset;
    // A reset never shows an address, so a username can't reveal one.
    final sentTo = widget.args.email.isEmpty
        ? 'We sent a 6-digit code to the email on your account.'
        : 'We sent a 6-digit code to ${widget.args.email}.';
    return FcAuthPage(
      title: isReset ? 'Reset your password' : 'Confirm your email',
      subtitle: Text(
        '$sentTo It expires in 15 minutes.',
        style: FcText.body.copyWith(color: c.textSecondary),
      ),
      footer: FcButton(
        label: 'Back',
        variant: FcButtonVariant.ghost,
        icon: FcIcons.caretLeft,
        onPressed: _back,
      ),
      children: [
        FcTextField(
          label: 'Code',
          placeholder: '6-digit code',
          code: true,
          controller: _code,
          hasError: _error != null,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          autofillHints: const [AutofillHints.oneTimeCode],
          textInputAction:
              isReset ? TextInputAction.next : TextInputAction.done,
          onSubmitted: isReset ? null : (_) => _submit(),
          describedBy: _error,
        ),
        if (_error != null) ...[
          const SizedBox(height: FcSpace.s2),
          FcFieldError(_error!),
        ] else if (_info != null) ...[
          const SizedBox(height: FcSpace.s2),
          // Neutral hint with a check; the info color is reserved for
          // "Verified by restaurant".
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                FcIcon(FcIcons.check, size: 16, color: c.textSecondary),
                const SizedBox(width: FcSpace.s2),
                Expanded(
                  child: Text(
                    _info!,
                    style: FcText.caption.copyWith(
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (isReset) ...[
          const SizedBox(height: FcSpace.s4),
          FcTextField(
            label: 'New password',
            placeholder: 'Create a new password',
            controller: _password,
            obscure: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            describedBy: 'At least 4 characters',
          ),
          const SizedBox(height: FcSpace.s2),
          Text(
            'At least 4 characters.',
            style: FcText.caption.copyWith(
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: FcSpace.s6),
        FcButton(
          label: isReset ? 'Reset password' : 'Confirm',
          large: true,
          block: true,
          loading: _busy,
          onPressed: _busy ? null : _submit,
        ),
        const SizedBox(height: FcSpace.s2),
        FcButton(
          label: _secondsLeft > 0
              ? 'Send a new code in ${_secondsLeft}s'
              : 'Send a new code',
          variant: FcButtonVariant.ghost,
          block: true,
          readableWhenDisabled: true,
          onPressed: _secondsLeft > 0 ? null : _resend,
        ),
      ],
    );
  }
}
