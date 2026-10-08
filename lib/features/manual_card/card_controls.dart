import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/domain/action_card.dart';
import '../../core/services/ad_providers.dart';
import '../../core/widgets/shared.dart';

class CardControls extends ConsumerStatefulWidget {
  const CardControls({super.key, required this.card});
  final ActionCard card;
  @override
  ConsumerState<CardControls> createState() => _CardControlsState();
}

class _CardControlsState extends ConsumerState<CardControls> {
  bool busy = false;
  Future<void> act(String action) async {
    setState(() => busy = true);
    final success = await runAction(
      context,
      () => ref.read(cardsProvider.notifier).transition(widget.card, action),
      haptic: true,
    );
    if (success && (action == 'confirm' || action == 'done')) {
      scheduleEligibleAdAction(ref);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.card;
    final l = context.l;
    final review = c.status == CardStatus.review;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16815D),
              foregroundColor: Colors.white,
            ),
            onPressed: busy
                ? null
                : review && c.dueAt == null
                ? () => context.push('/edit/${c.id}')
                : () => act(review ? 'confirm' : 'done'),
            icon: const Icon(Icons.check_rounded, size: 20),
            label: Text(
              review
                  ? l.confirm
                  : c.category == Category.bill
                  ? l.paid
                  : l.done,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: busy ? null : () => act(review ? 'ignore' : 'snooze'),
            child: Text(
              review ? l.ignore : l.snooze,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
