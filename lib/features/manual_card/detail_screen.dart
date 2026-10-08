import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/domain/action_card.dart';
import '../../core/widgets/shared.dart';
import 'card_controls.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final cardsState = ref.watch(cardsProvider);
    final openedCard = cardsState.value
        ?.where((card) => card.id == id)
        .firstOrNull;
    final fallbackRoute = openedCard?.status == CardStatus.review
        ? '/inbox'
        : '/';
    final canPop = context.canPop();
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && context.mounted) context.go(fallbackRoute);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => canPop ? context.pop() : context.go(fallbackRoute),
          ),
          title: Text(l.detail),
        ),
        body: PageBody(
          child: cardsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                ErrorPanel(retry: () => ref.invalidate(cardsProvider)),
            data: (cards) {
              final card = cards.where((value) => value.id == id).firstOrNull;
              if (card == null) return Center(child: Text(l.notFound));
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight > 24
                          ? constraints.maxHeight - 24
                          : 0,
                    ),
                    child: _DetailContent(card: card),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.card});

  final ActionCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final colors = Theme.of(context).colorScheme;
    final hasSourceMessage = card.sourceMessage?.trim().isNotEmpty == true;
    final reminder = card.status == CardStatus.snoozed
        ? dateLabel(context, card.snoozedUntil)
        : card.reminderOffsets.isEmpty
        ? l.noReminder
        : card.reminderOffsets
              .map((value) => reminderLabel(context, value))
              .join(' · ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            CategoryMark(card.category, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cardTitle(context, card),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (card.title.isNotEmpty)
                    Text(
                      categoryLabel(context, card.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  if (card.amount != null)
                    Text(
                      amountLabel(card),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                ],
              ),
            ),
          ],
        ),
        if (card.status == CardStatus.review) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.reviewBefore,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.event_outlined,
                label: l.dueDate,
                value: dateLabel(context, card.dueAt),
              ),
              const Divider(),
              _DetailRow(
                icon: Icons.alarm_outlined,
                label: l.reminder,
                value: reminder,
              ),
              const Divider(),
              _DetailRow(
                icon: Icons.apps_rounded,
                label: l.source,
                value: sourceLabel(context, card),
              ),
              if (card.note?.isNotEmpty == true) ...[
                const Divider(),
                _DetailRow(
                  icon: Icons.notes_rounded,
                  label: l.note,
                  value: card.note!,
                ),
              ],
            ],
          ),
        ),
        if (hasSourceMessage) ...[
          const SizedBox(height: 10),
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showSourceMessage(context, card.sourceMessage!),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.sourceMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            minimumSize: const Size(40, 40),
                          ),
                          onPressed: () =>
                              _deleteSourceMessage(context, ref, card.id),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          label: Text(l.deleteSourceMessage),
                        ),
                      ],
                    ),
                    Text(
                      card.sourceMessage!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.sourceMessageStored,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        height: 1.2,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          l.approximate,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            height: 1.25,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        if (card.isActive || card.status == CardStatus.review) ...[
          CardControls(card: card),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/edit/${card.id}'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l.edit),
                ),
              ),
              if (card.isActive) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => runAction(
                      context,
                      () => ref
                          .read(cardsProvider.notifier)
                          .transition(card, 'archive'),
                    ),
                    child: Text(l.archive),
                  ),
                ),
              ],
            ],
          ),
        ] else
          Text(
            card.status == CardStatus.done ? l.completed : l.archived,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.2,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<void> _showSourceMessage(BuildContext context, String message) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .75,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheetContext.l.sourceMessage,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SelectionArea(
                  child: Text(
                    message,
                    style: Theme.of(sheetContext).textTheme.bodyLarge
                        ?.copyWith(height: 1.4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  sheetContext.l.sourceMessageStored,
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

Future<void> _deleteSourceMessage(
  BuildContext context,
  WidgetRef ref,
  String cardId,
) async {
  final l = context.l;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.deleteSourceMessageTitle),
      content: Text(l.deleteSourceMessageBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l.deleteSourceMessage),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final success = await runAction(
    context,
    () => ref.read(cardsProvider.notifier).clearSourceMessage(cardId),
    haptic: true,
  );
  if (success && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.sourceMessageDeleted)));
  }
}
