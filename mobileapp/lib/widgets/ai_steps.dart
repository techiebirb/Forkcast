import 'package:flutter/material.dart';

import '../theme/fc_tokens.dart';
import 'fc_button.dart';
import 'fc_icons.dart';

/// Progress steps for an AI job: done steps get a check, the current step a
/// spinner, and waiting steps a hollow dot. The words carry the state, so
/// color is never the only signal.
class AiSteps extends StatelessWidget {
  const AiSteps({super.key, required this.steps, required this.current});

  final List<String> steps;

  /// Index of the step in progress. Earlier steps show as done.
  final int current;

  static String _stateWord(int index, int current) {
    if (index < current) {
      return 'done';
    }
    return index == current ? 'in progress' : 'waiting';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : FcSpace.s2),
            child: Semantics(
              label: '${steps[i]}, ${_stateWord(i, current)}',
              excludeSemantics: true,
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: i < current
                          ? FcIcon(FcIcons.check, size: 16, color: c.accent)
                          : i == current
                              ? FcSpinner(size: 16, color: c.accent)
                              : Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: c.borderStrong,
                                      width: 2,
                                    ),
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(width: FcSpace.s2),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: FcText.bodySm.copyWith(
                        color: i <= current ? c.textPrimary : c.textSecondary,
                        fontWeight:
                            i == current ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
