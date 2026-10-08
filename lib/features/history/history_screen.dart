import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/domain/action_card.dart';
import '../../core/widgets/shared.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String search = '';
  CardStatus? status;
  Category? category;
  String? source;
  DateTimeRange? range;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final data = ref.watch(cardsProvider);
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),
              Text(l.history, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  hintText: l.search,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => search = v.toLowerCase()),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: Text(l.all),
                    selected: status == null,
                    onSelected: (_) => setState(() => status = null),
                  ),
                  ChoiceChip(
                    label: Text(l.completed),
                    selected: status == CardStatus.done,
                    onSelected: (_) => setState(() => status = CardStatus.done),
                  ),
                  ChoiceChip(
                    label: Text(l.archived),
                    selected: status == CardStatus.archived,
                    onSelected: (_) =>
                        setState(() => status = CardStatus.archived),
                  ),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(l.filter),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.category,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Category>(
                    initialValue: category,
                    isExpanded: true,
                    menuMaxHeight: MediaQuery.sizeOf(context).height * 0.35,
                    borderRadius: BorderRadius.circular(16),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l.all)),
                      ...Category.values.map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(categoryLabel(context, c)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => category = v),
                  ),
                  const SizedBox(height: 16),
                  Text(l.source, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: source,
                    isExpanded: true,
                    menuMaxHeight: MediaQuery.sizeOf(context).height * 0.35,
                    borderRadius: BorderRadius.circular(16),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l.all)),
                      ...{
                        for (final c in data.value ?? <ActionCard>[])
                          c.sourcePackage: sourceLabel(context, c),
                      }.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => source = v),
                  ),
                  TextButton(
                    onPressed: () async {
                      final r = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (mounted) setState(() => range = r);
                    },
                    child: Text(
                      range == null
                          ? l.dateRange
                          : '${dateLabel(context, range!.start)} — ${dateLabel(context, range!.end)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      category = null;
                      source = null;
                      range = null;
                      status = null;
                    }),
                    child: Text(l.clearFilters),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              data.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    ErrorPanel(retry: () => ref.invalidate(cardsProvider)),
                data: (all) {
                  final items =
                      all
                          .where(
                            (c) => !c.isActive && c.status != CardStatus.review,
                          )
                          .where((c) => status == null || c.status == status)
                          .where(
                            (c) => category == null || c.category == category,
                          )
                          .where(
                            (c) => source == null || c.sourcePackage == source,
                          )
                          .where(
                            (c) =>
                                '${cardTitle(context, c)} ${sourceLabel(context, c)}'
                                    .toLowerCase()
                                    .contains(search),
                          )
                          .where((c) {
                            final d = c.completedAt ?? c.createdAt;
                            return range == null ||
                                (!d.isBefore(range!.start) &&
                                    d.isBefore(
                                      range!.end.add(const Duration(days: 1)),
                                    ));
                          })
                          .toList()
                        ..sort(
                          (a, b) => (b.completedAt ?? b.createdAt).compareTo(
                            a.completedAt ?? a.createdAt,
                          ),
                        );
                  return items.isEmpty
                      ? EmptyPanel(
                          title: l.emptyHistory,
                          body: l.historyBody,
                          icon: Icons.history_rounded,
                        )
                      : Column(
                          children: items
                              .map(
                                (c) => ActionTile(
                                  c,
                                  key: ValueKey(c.id),
                                  history: true,
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
