import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/fc_tokens.dart';
import 'fc_icons.dart';

/// The four main screens, in tab order.
enum FcTab {
  home('Home', '/', FcIcons.house),
  saved('Saved', '/saved', FcIcons.bookmark),
  history('History', '/history', FcIcons.clockCounterClockwise),
  settings('Settings', '/settings', FcIcons.gear);

  const FcTab(this.label, this.path, this.icon);

  final String label;
  final String path;
  final IconData icon;

  /// The tab a route belongs to, or null for screens outside the tab bar.
  static FcTab? forLocation(String location) {
    for (final tab in values) {
      if (tab.path == location) {
        return tab;
      }
    }
    return null;
  }
}

/// Labelled bottom tab bar: raised surface, hairline on top. The active tab
/// shows its icon on an accent-soft pill; a held tab fills with surface-pressed.
class FcTabBar extends StatelessWidget {
  const FcTabBar({super.key, required this.current, required this.onSelect});

  final FcTab current;
  final ValueChanged<FcTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
          FcSpace.s2, FcSpace.s1, FcSpace.s2, FcSpace.s2),
      child: Semantics(
        container: true,
        label: 'Main',
        child: Row(
          children: [
            for (final tab in FcTab.values)
              Expanded(
                child: _TabItem(
                  tab: tab,
                  active: tab == current,
                  onTap: () => onSelect(tab),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem(
      {required this.tab, required this.active, required this.onTap});

  final FcTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final color = active ? c.accent : c.textSecondary;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(FcRadius.input),
    );
    return Semantics(
      button: true,
      selected: active,
      label: tab.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          highlightColor: c.surfacePressed,
          splashColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.only(top: FcSpace.s1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    decoration: ShapeDecoration(
                      color: active ? c.accentSoft : Colors.transparent,
                      shape: const StadiumBorder(),
                    ),
                    child: FcIcon(tab.icon, size: 24, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kFcFontFamily,
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps the four main screens with the tab bar. Hidden while the keyboard is
/// open so it doesn't ride up over a form.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final current = FcTab.forLocation(location) ?? FcTab.home;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: context.fc.bg,
      body: child,
      bottomNavigationBar: keyboardOpen
          ? null
          : SafeArea(
              top: false,
              child: FcTabBar(
                current: current,
                onSelect: (tab) {
                  if (tab != current) {
                    context.go(tab.path);
                  }
                },
              ),
            ),
    );
  }
}
