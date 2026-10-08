import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../domain/action_card.dart';
import '../data/providers.dart';

String amountLabel(ActionCard card) {
  final symbol = switch (card.currency) {
    'TRY' => '₺',
    'USD' => '\$',
    'EUR' => '€',
    'GBP' => '£',
    _ => card.currency ?? '',
  };
  return '$symbol${card.amount ?? ''}';
}

extension LocalCopy on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this)!;
}

String categoryLabel(BuildContext c, Category category) => switch (category) {
  Category.bill => c.l.bill,
  Category.paymentDue => c.l.paymentDue,
  Category.packageDelivery => c.l.packageDelivery,
  Category.packagePickup => c.l.packagePickup,
  Category.appointment => c.l.appointment,
  Category.reservation => c.l.reservation,
  Category.subscriptionRenewal => c.l.subscriptionRenewal,
  Category.returnWindow => c.l.returnWindow,
  Category.ticketEvent => c.l.ticketEvent,
  Category.travel => c.l.travel,
  Category.deadline => c.l.deadline,
  Category.other => c.l.other,
};
String cardTitle(BuildContext c, ActionCard card) =>
    card.title.isEmpty ? categoryLabel(c, card.category) : card.title;
String sourceLabel(BuildContext c, ActionCard card) =>
    card.sourcePackage.isEmpty
    ? c.l.manualSource
    : card.sourceLabel.isEmpty
    ? c.l.unknownSource
    : card.sourceLabel;
String dateLabel(BuildContext c, DateTime? value) => value == null
    ? c.l.noDate
    : DateFormat(
        'd MMM yyyy · HH:mm',
        Localizations.localeOf(c).languageCode,
      ).format(value);
String reviewTimeLabel(BuildContext context, ActionCard card) {
  if (card.dueAt != null || card.note?.trim().isEmpty != false) {
    return dateLabel(context, card.snoozedUntil ?? card.dueAt);
  }
  final phrase = card.note!.trim();
  final display = '${phrase[0].toUpperCase()}${phrase.substring(1)}';
  return '${context.l.time} · $display';
}

String compactDateLabel(BuildContext context, ActionCard card, DateTime now) {
  final due = card.snoozedUntil ?? card.dueAt;
  if (due == null) return context.l.noDate;
  final group = groupFor(card, now);
  if ((card.category == Category.bill ||
          card.category == Category.paymentDue) &&
      group == DateGroup.today) {
    return context.l.dueToday;
  }
  if (card.category == Category.appointment && group == DateGroup.tomorrow) {
    return context.l.tomorrowAt(DateFormat('HH:mm').format(due));
  }
  if (card.category == Category.packagePickup && group == DateGroup.week) {
    final days = DateUtils.dateOnly(due)
        .difference(DateUtils.dateOnly(now))
        .inDays;
    return context.l.pickupDaysLeft(days);
  }
  return dateLabel(context, due);
}

String reminderLabel(BuildContext c, int value) => switch (value) {
  0 => c.l.atTime,
  60 => c.l.oneHour,
  1440 => c.l.oneDay,
  4320 => c.l.threeDays,
  _ => '$value ${c.l.customReminder.toLowerCase()}',
};
IconData categoryIcon(Category c) => switch (c) {
  Category.bill => Icons.receipt_long_outlined,
  Category.paymentDue => Icons.payments_outlined,
  Category.packageDelivery => Icons.local_shipping_outlined,
  Category.packagePickup => Icons.inventory_2_outlined,
  Category.appointment => Icons.event_available_outlined,
  Category.reservation => Icons.event_seat_outlined,
  Category.subscriptionRenewal => Icons.autorenew_rounded,
  Category.returnWindow => Icons.assignment_return_outlined,
  Category.ticketEvent => Icons.confirmation_number_outlined,
  Category.travel => Icons.flight_rounded,
  Category.deadline => Icons.hourglass_bottom_rounded,
  Category.other => Icons.more_horiz,
};
Color categoryColor(Category c) => switch (c) {
  Category.bill || Category.paymentDue => const Color(0xFFD66A14),
  Category.appointment || Category.reservation => const Color(0xFF6658CB),
  Category.packageDelivery || Category.packagePickup => const Color(0xFF008B79),
  Category.subscriptionRenewal => const Color(0xFF525DDD),
  Category.returnWindow => const Color(0xFFCB3986),
  Category.ticketEvent || Category.travel => const Color(0xFF2672DB),
  _ => const Color(0xFF63778E),
};

class CategoryMark extends StatelessWidget {
  const CategoryMark(this.category, {super.key, this.size = 46});
  final Category category;
  final double size;
  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        categoryIcon(category),
        color: Theme.of(context).brightness == Brightness.dark
            ? Color.lerp(color, Colors.white, .35)
            : color,
        size: size * .52,
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'UNUTMA',
    image: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * .24),
      child: Image.asset(
        'assets/brand/unutma_app_icon_1024.png',
        width: size,
        height: size,
      ),
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: child,
    ),
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.check_circle_outline_rounded,
    this.action,
  });
  final String title, body;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 44,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 24), action!],
      ],
    ),
  );
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.retry});
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => EmptyPanel(
    title: context.l.errorTitle,
    body: context.l.errorBody,
    icon: Icons.cloud_off_outlined,
    action: OutlinedButton(onPressed: retry, child: Text(context.l.retry)),
  );
}

Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  bool haptic = false,
}) async {
  try {
    await action();
    if (haptic) await HapticFeedback.lightImpact();
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l.errorTitle)));
    }
    return false;
  }
}

class ActionTile extends ConsumerStatefulWidget {
  const ActionTile(
    this.card, {
    super.key,
    this.review = false,
    this.history = false,
    this.compact = false,
  });
  final ActionCard card;
  final bool review, history, compact;
  @override
  ConsumerState<ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends ConsumerState<ActionTile> {
  bool busy = false;
  Future<void> act(String action) async {
    setState(() => busy = true);
    await runAction(
      context,
      () => ref.read(cardsProvider.notifier).transition(widget.card, action),
      haptic: action == 'done' || action == 'confirm',
    );
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.card;
    final l = context.l;
    final now = ref.watch(clockProvider)();
    final scheme = Theme.of(context).colorScheme;
    final compact = widget.compact;
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 10 : 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/card/${c.id}'),
          child: Padding(
            padding: EdgeInsets.all(compact ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryMark(c.category, size: compact ? 42 : 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cardTitle(context, c),
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: compact ? 1 : null,
                            overflow: compact ? TextOverflow.ellipsis : null,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sourceLabel(context, c),
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: compact ? 1 : null,
                            overflow: compact ? TextOverflow.ellipsis : null,
                          ),
                        ],
                      ),
                    ),
                    if (widget.history)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.check_circle_outline, size: 20),
                      ),
                  ],
                ),
                if (widget.review &&
                    c.sourceMessage != null &&
                    c.sourceMessage!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: .58,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.sourceMessage,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          c.sourceMessage!.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: compact ? 10 : 14),
                if (compact)
                  Row(
                    children: [
                      Icon(
                        c.status == CardStatus.snoozed
                            ? Icons.snooze_outlined
                            : Icons.schedule_rounded,
                        size: 15,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          compactDateLabel(context, c, now),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (c.amount != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          amountLabel(c),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c.status == CardStatus.snoozed
                                ? Icons.snooze_outlined
                                : Icons.schedule_rounded,
                            size: 15,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              widget.review
                                  ? reviewTimeLabel(context, c)
                                  : dateLabel(
                                      context,
                                      c.snoozedUntil ?? c.dueAt,
                                    ),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (c.amount != null)
                        Text(
                          amountLabel(c),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                if (widget.review) ...[
                  const SizedBox(height: 12),
                  Text(
                    l.reviewLabel,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: busy
                            ? null
                            : c.dueAt == null
                            ? () => context.push('/edit/${c.id}')
                            : () => act('confirm'),
                        child: Text(l.confirm),
                      ),
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => context.push('/edit/${c.id}'),
                        child: Text(l.edit),
                      ),
                      TextButton(
                        onPressed: busy ? null : () => act('ignore'),
                        child: Text(l.ignore),
                      ),
                    ],
                  ),
                ] else if (!widget.history) ...[
                  SizedBox(height: compact ? 10 : 14),
                  if (compact)
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: busy ? null : () => act('done'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              c.category == Category.bill ||
                                      c.category == Category.paymentDue
                                  ? l.paid
                                  : l.done,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton(
                            onPressed: busy ? null : () => act('snooze'),
                            style: TextButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(l.snooze),
                          ),
                        ),
                      ],
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        FilledButton.tonal(
                          onPressed: busy ? null : () => act('done'),
                          child: Text(
                            c.category == Category.bill ||
                                    c.category == Category.paymentDue
                                ? l.paid
                                : l.done,
                          ),
                        ),
                        TextButton(
                          onPressed: busy ? null : () => act('snooze'),
                          child: Text(l.snooze),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
