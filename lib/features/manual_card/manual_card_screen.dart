import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/domain/action_card.dart';
import '../../core/services/ad_providers.dart';
import '../../core/widgets/shared.dart';

class ManualCardScreen extends ConsumerWidget {
  const ManualCardScreen({super.key, this.id, this.initialText});
  final String? id;
  final String? initialText;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id == null) return CardForm(initialText: initialText);
    return ref
        .watch(cardsProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(
            body: ErrorPanel(retry: () => ref.invalidate(cardsProvider)),
          ),
          data: (cards) {
            final card = cards.where((c) => c.id == id).firstOrNull;
            return card == null
                ? Scaffold(
                    appBar: AppBar(),
                    body: Center(child: Text(context.l.notFound)),
                  )
                : CardForm(key: ValueKey(card.id), existing: card);
          },
        );
  }
}

class CardForm extends ConsumerStatefulWidget {
  const CardForm({super.key, this.existing, this.initialText});
  final ActionCard? existing;
  final String? initialText;
  @override
  ConsumerState<CardForm> createState() => _CardFormState();
}

class _CardFormState extends ConsumerState<CardForm> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      amount = TextEditingController(),
      note = TextEditingController(),
      custom = TextEditingController();
  Category category = Category.other;
  DateTime? due;
  String currency = 'TRY';
  Set<int> offsets = {1440};
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    if (c != null) {
      title.text = c.title;
      amount.text = c.amount ?? '';
      note.text = c.note ?? '';
      category = c.category;
      due = c.dueAt;
      currency = c.currency ?? 'TRY';
      offsets = c.reminderOffsets.toSet();
    } else {
      final shared = widget.initialText?.trim();
      if (shared?.isNotEmpty == true) {
        final first = shared!
            .split(RegExp(r'[\r\n]+'))
            .firstWhere((v) => v.trim().isNotEmpty, orElse: () => shared)
            .trim();
        title.text = first.length <= 120 ? first : first.substring(0, 120);
        note.text = shared.length <= 500 ? shared : shared.substring(0, 500);
      }
      offsets = {ref.read(preferencesProvider).value?.reminderMinutes ?? 1440};
    }
  }

  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    note.dispose();
    custom.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final now = ref.read(clockProvider)();
    final initial = due ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      setState(
        () => due = DateTime(
          date.year,
          date.month,
          date.day,
          due?.hour ?? 9,
          due?.minute ?? 0,
        ),
      );
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: due == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay.fromDateTime(due!),
    );
    if (time != null && mounted) {
      final date = due ?? ref.read(clockProvider)();
      setState(
        () => due = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (due == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l.requiredDate)));
      return;
    }
    setState(() => busy = true);
    final old = widget.existing;
    final card = ActionCard(
      id: old?.id ?? '',
      category: category,
      title: title.text.trim(),
      sourceLabel: old?.sourceLabel ?? '',
      sourcePackage: old?.sourcePackage ?? '',
      dueAt: due,
      amount: amount.text.trim().isEmpty ? null : amount.text.trim(),
      currency: amount.text.trim().isEmpty ? null : currency,
      status: old?.status ?? CardStatus.active,
      confidence: old?.confidence ?? 1,
      createdAt: old?.createdAt ?? ref.read(clockProvider)(),
      reminderOffsets: offsets.toList()..sort(),
      note: note.text.trim().isEmpty ? null : note.text.trim(),
      sourceMessage: old?.sourceMessage,
      revision: old?.revision ?? 0,
    );
    final ok = await runAction(
      context,
      () => ref.read(cardsProvider.notifier).save(card),
    );
    if (mounted) {
      setState(() => busy = false);
      if (ok) {
        if (old == null) scheduleEligibleAdAction(ref);
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? l.add : l.editCard)),
      body: PageBody(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l.newCard,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: title,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: l.what,
                  hintText: l.titleHint,
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? l.requiredTitle : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Category>(
                initialValue: category,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.category),
                items: Category.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Icon(
                              categoryIcon(c),
                              size: 20,
                              color: categoryColor(c),
                            ),
                            const SizedBox(width: 12),
                            Text(categoryLabel(context, c)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (v) {
                        if (v != null) setState(() => category = v);
                      },
              ),
              SectionLabel(l.when.toUpperCase()),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: busy ? null : pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      due == null
                          ? l.chooseDate
                          : dateLabel(context, due).split(' · ').first,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : pickTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(
                      due == null
                          ? l.time
                          : TimeOfDay.fromDateTime(due!).format(context),
                    ),
                  ),
                ],
              ),
              SectionLabel(l.reminder.toUpperCase()),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final value in [0, 60, 1440, 4320])
                    FilterChip(
                      label: Text(reminderLabel(context, value)),
                      selected: offsets.contains(value),
                      onSelected: busy
                          ? null
                          : (yes) => setState(() {
                              if (yes) {
                                offsets.add(value);
                              } else {
                                offsets.remove(value);
                              }
                            }),
                    ),
                  FilterChip(
                    label: Text(l.noReminder),
                    selected: offsets.isEmpty,
                    onSelected: busy ? null : (_) => setState(offsets.clear),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(l.optional),
                children: [
                  TextFormField(
                    controller: amount,
                    maxLength: 24,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: l.amount),
                    validator: (v) =>
                        v != null &&
                            v.isNotEmpty &&
                            !RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(v.trim())
                        ? l.invalidAmount
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: currency,
                    decoration: InputDecoration(labelText: l.currency),
                    items: ['TRY', 'USD', 'EUR', 'GBP']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => currency = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: note,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: l.note),
                  ),
                  TextFormField(
                    controller: custom,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l.customReminder,
                      suffixIcon: IconButton(
                        tooltip: l.add,
                        onPressed: () {
                          final n = int.tryParse(custom.text);
                          if (n != null &&
                              n >= 0 &&
                              n <= 525600 &&
                              offsets.length < 5) {
                            setState(() {
                              offsets.add(n);
                              custom.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ),
                  ),
                  if (offsets.any((v) => ![0, 60, 1440, 4320].contains(v)))
                    Wrap(
                      spacing: 8,
                      children: offsets
                          .where((v) => ![0, 60, 1440, 4320].contains(v))
                          .map(
                            (v) => InputChip(
                              label: Text(reminderLabel(context, v)),
                              onDeleted: () =>
                                  setState(() => offsets.remove(v)),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l.approximate,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (due != null &&
                  offsets.any(
                    (v) => due!
                        .subtract(Duration(minutes: v))
                        .isBefore(ref.read(clockProvider)()),
                  ))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l.pastReminder,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (ref.watch(accessProvider).value?.remindersEnabled == false)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(l.reminderOff),
                ),
              const SizedBox(height: 28),
              FilledButton(onPressed: busy ? null : save, child: Text(l.save)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
