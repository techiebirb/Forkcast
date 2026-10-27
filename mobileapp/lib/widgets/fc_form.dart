import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/fc_tokens.dart';
import 'fc_icons.dart';

/// Right-aligned numeric field with a unit, like "650 cal". Empty shows the
/// "Any" placeholder, meaning the target is skipped.
class FcNumberField extends StatefulWidget {
  const FcNumberField({
    super.key,
    required this.controller,
    required this.unit,
    required this.semanticLabel,
    this.placeholder = 'Any',
    this.width = 148,
    this.onChanged,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String unit;
  final String semanticLabel;
  final String placeholder;
  final double width;
  final ValueChanged<String>? onChanged;
  final bool hasError;

  @override
  State<FcNumberField> createState() => _FcNumberFieldState();
}

class _FcNumberFieldState extends State<FcNumberField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final focused = _focus.hasFocus;
    final edge = widget.hasError
        ? c.danger
        : focused
            ? c.accent
            : c.borderStrong;
    return SizedBox(
      width: widget.width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.only(left: FcSpace.s3),
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: BorderRadius.circular(FcRadius.input),
          border: Border.all(
            color: edge,
            width: focused || widget.hasError ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                label: '${widget.semanticLabel}, ${widget.unit}',
                textField: true,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  onChanged: widget.onChanged,
                  textAlign: TextAlign.end,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: FcText.tabular(FcText.body).copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                  cursorColor: c.accent,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintText: widget.placeholder,
                    hintStyle: FcText.body.copyWith(
                      color: c.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: FcSpace.s1,
                right: FcSpace.s3,
              ),
              child: Text(
                widget.unit,
                style: FcText.bodySm.copyWith(
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// On/off switch with a 44px-tall hit area. Pair it with a visible label and
/// pass the same text as [semanticLabel].
class FcSwitch extends StatelessWidget {
  const FcSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 120);
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: SizedBox(
          width: 52,
          height: kFcTargetMin,
          child: Center(
            child: AnimatedContainer(
              duration: duration,
              curve: const Cubic(0.2, 0, 0, 1),
              width: 52,
              height: 32,
              padding: const EdgeInsets.all(3),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: value ? c.accent : c.borderStrong,
                borderRadius: BorderRadius.circular(FcRadius.pill),
              ),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Labelled single-line text field: label above, 48px box with a strong edge
/// (accent when focused, danger when [hasError]). Use [obscure] for passwords;
/// it adds a Show/Hide button.
class FcTextField extends StatefulWidget {
  const FcTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hasError = false,
    this.obscure = false,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.describedBy,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.placeholder,
    this.code = false,
  });

  final String label;
  final TextEditingController controller;
  final bool hasError;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? placeholder;

  /// One-time code: large, wide-spaced tabular digits, left-aligned.
  final bool code;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  /// Hint or error text announced with the field.
  final String? describedBy;
  final bool enabled;

  @override
  State<FcTextField> createState() => _FcTextFieldState();
}

class _FcTextFieldState extends State<FcTextField> {
  final FocusNode _focus = FocusNode();
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final focused = _focus.hasFocus;
    final edge = widget.hasError
        ? c.danger
        : focused
            ? c.accent
            : c.borderStrong;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: FcText.label.copyWith(color: c.textPrimary),
          ),
        ),
        const SizedBox(height: FcSpace.s2),
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.only(left: FcSpace.s3),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: BorderRadius.circular(FcRadius.input),
            border: Border.all(
              color: edge,
              width: focused || widget.hasError ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  textField: true,
                  label: widget.label,
                  hint: widget.describedBy,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    enabled: widget.enabled,
                    obscureText: widget.obscure && _hidden,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    autocorrect: !widget.obscure,
                    enableSuggestions: !widget.obscure,
                    autofillHints: widget.autofillHints,
                    textInputAction: widget.textInputAction,
                    onSubmitted: widget.onSubmitted,
                    onChanged: widget.onChanged,
                    cursorColor: c.accent,
                    style: widget.code
                        ? FcText.tabular(FcText.title).copyWith(
                            fontSize: 24,
                            height: 32 / 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 9,
                            color: c.textPrimary,
                          )
                        : FcText.body.copyWith(color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: FcText.body.copyWith(
                        color: c.textSecondary,
                        letterSpacing: 0,
                      ),
                      isCollapsed: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: widget.code ? 10 : 12,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.obscure)
                Semantics(
                  button: true,
                  label: _hidden ? 'Show password' : 'Hide password',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(FcRadius.input),
                    onTap: () => setState(() => _hidden = !_hidden),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: kFcTargetMin,
                        minWidth: kFcTargetMin,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: FcSpace.s2,
                          ),
                          child: Text(
                            _hidden ? 'Show' : 'Hide',
                            style: FcText.label.copyWith(color: c.accent),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Error text under a field: warning icon and the message in danger color,
/// announced when it appears. Pair with `hasError` on the field.
class FcFieldError extends StatelessWidget {
  const FcFieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: FcIcon(FcIcons.warning, size: 16, color: c.danger),
          ),
          const SizedBox(width: FcSpace.s2),
          Expanded(
            child: Text(
              message,
              style: FcText.label.copyWith(color: c.danger),
            ),
          ),
        ],
      ),
    );
  }
}
