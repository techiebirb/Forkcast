import 'package:flutter/material.dart';

import '../theme/fc_tokens.dart';
import 'fc_button.dart';

/// Lays [child] out under a slim "Waking up the server" bar. The bar is docked
/// above the app bar and pushes content down, so nothing is covered, and it
/// never takes taps. While it is shown it handles the status-bar inset itself,
/// so the content below drops its top padding.
class WakingBannerHost extends StatelessWidget {
  const WakingBannerHost({
    super.key,
    required this.show,
    required this.child,
  });

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final topInset = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        AnimatedSize(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 250),
          curve: const Cubic(0.2, 0, 0, 1),
          alignment: Alignment.topCenter,
          child: show
              ? IgnorePointer(
                  child: Semantics(
                    liveRegion: true,
                    container: true,
                    label: 'Waking up the server. This can take up to a '
                        'minute.',
                    // The banner sits above the Navigator, so it has no
                    // Material ancestor of its own. Without one, text falls
                    // back to the debug style with a yellow underline.
                    child: Material(
                      color: c.accent,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 36),
                        padding: EdgeInsets.fromLTRB(
                          FcSpace.s4,
                          topInset + FcSpace.s2,
                          FcSpace.s4,
                          FcSpace.s2,
                        ),
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FcSpinner(size: 14, color: c.onAccent),
                              const SizedBox(width: FcSpace.s2),
                              Flexible(
                                child: Text(
                                  'Waking up the server — this can take up to '
                                  'a minute.',
                                  textAlign: TextAlign.center,
                                  style: FcText.caption.copyWith(
                                    color: c.onAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: show,
            child: child,
          ),
        ),
      ],
    );
  }
}
