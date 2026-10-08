import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/domain/action_card.dart';
import '../../core/widgets/shared.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(cardsProvider);
    final l = context.l;
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),
              Text(l.inbox, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 10),
              Text(
                l.reviewCount(
                  data.value
                          ?.where((c) => c.status == CardStatus.review)
                          .length ??
                      0,
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              data.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    ErrorPanel(retry: () => ref.invalidate(cardsProvider)),
                data: (all) {
                  final items = all
                      .where((c) => c.status == CardStatus.review)
                      .toList();
                  return items.isEmpty
                      ? EmptyPanel(
                          title: l.emptyInbox,
                          body: l.emptyInboxBody,
                          icon: Icons.inbox_outlined,
                        )
                      : Column(
                          children: items
                              .map(
                                (c) => ActionTile(
                                  c,
                                  key: ValueKey(c.id),
                                  review: true,
                                ),
                              )
                              .toList(),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
