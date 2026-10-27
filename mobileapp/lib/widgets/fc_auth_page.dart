import 'package:flutter/material.dart';

import '../theme/fc_tokens.dart';

/// Layout shared by the account screens: wordmark, title, subtitle, a form
/// column, and a footer pinned to the bottom.
class FcAuthPage extends StatelessWidget {
  const FcAuthPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
  });

  final String title;
  final Widget subtitle;
  final List<Widget> children;
  final Widget? footer;

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
                        title,
                        style: FcText.display.copyWith(color: c.textPrimary),
                      ),
                    ),
                    const SizedBox(height: FcSpace.s2),
                    subtitle,
                    const SizedBox(height: FcSpace.s8),
                    AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                    const Spacer(),
                    if (footer != null)
                      Padding(
                        padding: const EdgeInsets.only(top: FcSpace.s6),
                        child: Center(child: footer),
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
