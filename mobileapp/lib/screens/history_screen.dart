import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../models.dart';
import '../theme/fc_tokens.dart';
import '../widgets/fc_button.dart';
import '../widgets/fc_icons.dart';
import '../widgets/fc_surfaces.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// How long ago a check happened: "just now", "5 min ago", "2 h ago",
/// "Yesterday", "3 days ago", then a date like "Oct 18".
String savedTimeLabel(DateTime? time, {DateTime? now}) {
  if (time == null) {
    return '';
  }
  final current = now ?? DateTime.now();
  final local = time.toLocal();
  final diff = current.difference(local);
  if (diff.inMinutes < 1) {
    return 'just now';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes} min ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} h ago';
  }
  final days = _daysAgo(local, current);
  if (days <= 1) {
    return 'Yesterday';
  }
  if (days < 7) {
    return '$days days ago';
  }
  return '${_months[local.month - 1]} ${local.day}';
}

int _daysAgo(DateTime local, DateTime current) {
  final today = DateTime(current.year, current.month, current.day);
  final thatDay = DateTime(local.year, local.month, local.day);
  return today.difference(thatDay).inDays;
}

/// The day heading a history entry sits under.
String historyGroupLabel(DateTime? time, {DateTime? now}) {
  if (time == null) {
    return 'Earlier';
  }
  final days = _daysAgo(time.toLocal(), now ?? DateTime.now());
  if (days <= 0) {
    return 'Today';
  }
  if (days == 1) {
    return 'Yesterday';
  }
  return days < 7 ? 'Earlier this week' : 'Earlier';
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      await SessionScope.of(context).refreshSaved();
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _open(HistoryEntry entry) {
    SessionScope.of(context).openHistoryEntry(entry);
    context.push('/check-restaurant');
  }

  Future<void> _confirmClear() async {
    final session = SessionScope.of(context);
    final confirmed = await showFcSheet<bool>(
      context,
      (sheetContext) => FcSheet(
        title: 'Clear history?',
        body: 'Your favorites will not be affected.',
        actions: [
          FcButton(
            label: 'Cancel',
            large: true,
            variant: FcButtonVariant.secondary,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
          FcButton(
            label: 'Clear',
            large: true,
            variant: FcButtonVariant.destructive,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await session.clearHistory();
    } catch (error) {
      if (mounted) {
        showApiError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final history = SessionScope.of(context).saved.history;

    final Widget content;
    if (_loading && history.isEmpty) {
      content = const ListState(kind: ListStateKind.loading, rows: 4);
    } else if (_failed && history.isEmpty) {
      content = FcCard(
        child: ListState(
          kind: ListStateKind.error,
          title: "Couldn't load your history",
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: _refresh,
        ),
      );
    } else if (history.isEmpty) {
      content = ListState(
        kind: ListStateKind.empty,
        icon: FcIcons.clockCounterClockwise,
        title: 'No history yet',
        body: 'Restaurants you check will show up here.',
        actionLabel: 'Check a restaurant',
        onAction: () => context.go('/'),
      );
    } else {
      content = _groups(c, history);
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FcAppBar(
              title: 'History',
              showBack: false,
              actions: [
                if (history.isNotEmpty)
                  FcButton(
                    label: 'Clear',
                    variant: FcButtonVariant.ghost,
                    onPressed: _confirmClear,
                  ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  FcSpace.s4,
                  FcSpace.s2,
                  FcSpace.s4,
                  FcSpace.s8,
                ),
                children: [content],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groups(FcColors c, List<HistoryEntry> history) {
    // Server order is newest first, so groups come out in order.
    final now = DateTime.now();
    final groups = <String, List<HistoryEntry>>{};
    for (final entry in history) {
      groups
          .putIfAbsent(historyGroupLabel(entry.checkedAt, now: now), () => [])
          .add(entry);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: FcSpace.s2, bottom: FcSpace.s2),
            child: Semantics(
              header: true,
              child: Text(
                group.key,
                style: FcText.label.copyWith(color: c.textSecondary),
              ),
            ),
          ),
          FcCard(
            clip: true,
            child: Column(
              children: [
                for (var i = 0; i < group.value.length; i++) ...[
                  if (i > 0) Divider(color: c.border, height: 1, thickness: 1),
                  _HistoryRow(
                    entry: group.value[i],
                    onTap: () => _open(group.value[i]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: FcSpace.s3),
        ],
        Padding(
          padding: const EdgeInsets.only(top: FcSpace.s3),
          child: Text(
            'Added on its own as you check restaurants. Your 20 most recent.',
            textAlign: TextAlign.center,
            style: FcText.caption.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.onTap});

  final HistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final count = entry.menuItems.length;
    final when = savedTimeLabel(entry.checkedAt);
    final items = '$count ${count == 1 ? 'item' : 'items'}';
    final meta = FcText.tabular(FcText.caption).copyWith(
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
    );
    return Semantics(
      button: true,
      label: [
        entry.restaurant.name,
        if (when.isNotEmpty) when,
        'Menu check',
        items,
      ].join(', '),
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        highlightColor: c.surfacePressed,
        splashColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.surfaceSunken,
                  ),
                  child: Center(
                    child: FcIcon(
                      FcIcons.storefront,
                      size: 20,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: FcSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.restaurant.name,
                        style: FcText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          if (when.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FcIcon(
                                  FcIcons.clockCounterClockwise,
                                  size: 16,
                                  color: c.textPrimary,
                                ),
                                const SizedBox(width: FcSpace.s1),
                                Text(
                                  when,
                                  style: meta.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          Text('·  Menu check  ·  $items', style: meta),
                        ],
                      ),
                    ],
                  ),
                ),
                FcIcon(FcIcons.caretRight, size: 20, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
