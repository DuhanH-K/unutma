import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../core/domain/action_card.dart';
import '../../core/widgets/shared.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final l = context.l;
    final cards = ref.watch(cardsProvider);
    final access = ref.watch(accessProvider);
    final activeCount = cards.value?.where((card) => card.isActive).length ?? 0;
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          child: RefreshIndicator(
            onRefresh: () => ref.read(cardsProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              children: [
                Row(
                  children: [
                    const BrandMark(size: 32),
                    const SizedBox(width: 9),
                    const Text(
                      'UNUTMA',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      key: const Key('dashboard_add'),
                      tooltip: l.add,
                      onPressed: () => context.push('/new'),
                      icon: const Icon(Icons.add_rounded),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      tooltip: l.settings,
                      onPressed: () => context.go('/settings'),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  DateFormat(
                    'd MMMM EEEE',
                    Localizations.localeOf(context).languageCode,
                  ).format(now),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  now.hour < 12
                      ? l.morning
                      : now.hour < 18
                      ? l.afternoon
                      : l.evening,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  activeCount > 0 ? l.attentionCount(activeCount) : l.allClear,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: .05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: .10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 17,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.localBadge,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const Icon(Icons.check_rounded, size: 17),
                    ],
                  ),
                ),
                if (access.value?.listenerEnabled == false) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.autoOff,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(l.autoOffBody),
                          TextButton(
                            onPressed: () => context.push('/disclosure'),
                            child: Text(l.openAccess),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (access.value?.remindersEnabled == false) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.reminderOff,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(l.reminderPermission),
                          TextButton(
                            onPressed: () async {
                              await runAction(
                                context,
                                ref.read(repositoryProvider).requestReminders,
                              );
                              ref.invalidate(accessProvider);
                            },
                            child: Text(l.openAccess),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                cards.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) =>
                      ErrorPanel(retry: () => ref.invalidate(cardsProvider)),
                  data: (all) {
                    final active = all.where((c) => c.isActive).toList();
                    if (active.isEmpty) {
                      return EmptyPanel(title: l.allClear, body: l.emptyBody);
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final group in DateGroup.values)
                          if (active.any((c) => groupFor(c, now) == group)) ...[
                            SectionLabel(switch (group) {
                              DateGroup.overdue => l.overdue,
                              DateGroup.today => l.today,
                              DateGroup.tomorrow => l.tomorrow,
                              DateGroup.week => l.week,
                              DateGroup.later => l.later,
                            }),
                            ...active
                                .where((c) => groupFor(c, now) == group)
                                .map(
                                  (c) => ActionTile(
                                    c,
                                    key: ValueKey(c.id),
                                    compact: true,
                                  ),
                                ),
                          ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
