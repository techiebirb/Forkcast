import 'package:flutter/material.dart';

import '../app.dart';
import '../theme/fc_tokens.dart';
import '../widgets/fc_button.dart';
import '../widgets/fc_icons.dart';
import '../widgets/fc_surfaces.dart';

const _themeModes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final session = SessionScope.of(context);
    final email = session.email ?? '';
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const FcAppBar(title: 'Settings', showBack: false),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  FcSpace.s4,
                  FcSpace.s2,
                  FcSpace.s4,
                  FcSpace.s8,
                ),
                children: [
                  _heading(c, 'Appearance'),
                  const SizedBox(height: FcSpace.s3),
                  FcCard(
                    padding: const EdgeInsets.all(FcSpace.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme',
                          style: FcText.label.copyWith(color: c.textPrimary),
                        ),
                        const SizedBox(height: FcSpace.s3),
                        FcSeg(
                          options: const ['System', 'Light', 'Dark'],
                          icons: const [
                            FcIcons.circleHalf,
                            FcIcons.sun,
                            FcIcons.moon,
                          ],
                          selectedIndex: _themeModes.indexOf(session.themeMode),
                          semanticLabel: 'Theme',
                          onChanged: (index) =>
                              session.setThemeMode(_themeModes[index]),
                        ),
                        const SizedBox(height: FcSpace.s3),
                        Text(
                          "System matches your phone's light or dark setting.",
                          style: FcText.bodySm.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: FcSpace.s6),
                  _heading(c, 'Account'),
                  const SizedBox(height: FcSpace.s3),
                  FcCard(
                    clip: true,
                    child: Column(
                      children: [
                        _Row(label: 'Username', value: session.username ?? ''),
                        if (email.isNotEmpty) ...[
                          Divider(color: c.border, height: 1, thickness: 1),
                          _Row(label: 'Email', value: email, verified: true),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: FcSpace.s3),
                  FcButton(
                    label: 'Log out',
                    large: true,
                    block: true,
                    variant: FcButtonVariant.secondary,
                    onPressed: session.logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(FcColors c, String text) => Semantics(
        header: true,
        child: Text(
          text,
          style: FcText.heading.copyWith(color: c.textPrimary),
        ),
      );
}

/// A settings row: name on the left, value on the right. Wraps at large text.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.verified = false});

  final String label;
  final String value;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FcSpace.s4,
          vertical: FcSpace.s2,
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: FcSpace.s1,
          spacing: FcSpace.s3,
          children: [
            Text(
              label,
              style: FcText.body.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: FcSpace.s2,
              children: [
                Text(
                  value,
                  style: FcText.bodySm.copyWith(color: c.textSecondary),
                ),
                if (verified)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FcIcon(FcIcons.check, size: 16, color: c.textPrimary),
                      const SizedBox(width: FcSpace.s1),
                      Text(
                        'Verified',
                        style: FcText.bodySm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
