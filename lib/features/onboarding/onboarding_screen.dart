import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/domain/action_card.dart';
import '../../core/widgets/shared.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.disclosureOnly = false});
  final bool disclosureOnly;
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int page = 0;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    if (widget.disclosureOnly) page = 3;
  }

  Future<void> finish(bool access) async {
    setState(() => busy = true);
    final ok = await runAction(context, () async {
      await ref.read(preferencesProvider.notifier).change(onboarded: true);
      if (access) await ref.read(repositoryProvider).openAccess();
    });
    if (mounted) {
      setState(() => busy = false);
      if (ok) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final titles = [
      l.onboardValue,
      l.onboardTransform,
      l.privacyTitle,
      l.onboardAccess,
    ];
    final bodies = [
      l.onboardValueBody,
      l.onboardTransformBody,
      l.privacyBody,
      '',
    ];
    return Scaffold(
      appBar: widget.disclosureOnly ? AppBar() : null,
      body: SafeArea(
        child: PageBody(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          BrandMark(size: 32),
                          SizedBox(width: 10),
                          Text(
                            'UNUTMA',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      if (page < 3) ...[
                        const SizedBox(height: 32),
                        OnboardingArt(page: page),
                        const SizedBox(height: 32),
                      ],
                      if (page == 3) const SizedBox(height: 28),
                      Text(
                        titles[page],
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 16),
                      if (page < 3)
                        Text(
                          bodies[page],
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      if (page == 3) ...[
                        DisclosureRow(
                          icon: Icons.text_snippet_outlined,
                          title: l.accessWhat,
                          body: l.accessWhatBody,
                        ),
                        DisclosureRow(
                          icon: Icons.filter_alt_outlined,
                          title: l.accessWhy,
                          body: l.accessWhyBody,
                        ),
                        DisclosureRow(
                          icon: Icons.lock_outline_rounded,
                          title: l.accessWhere,
                          body: l.accessWhereBody,
                        ),
                      ],
                      const SizedBox(height: 32),
                      if (!widget.disclosureOnly)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (i) => Container(
                              width: i == page ? 24 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: i == page
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: busy
                            ? null
                            : page == 3
                            ? () => finish(true)
                            : () => setState(() => page++),
                        child: Text(
                          page == 3
                              ? l.enableNotificationAccess
                              : l.continueLabel,
                        ),
                      ),
                      if (page == 3)
                        TextButton(
                          onPressed: busy ? null : () => finish(false),
                          child: Text(l.skip),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DisclosureRow extends StatelessWidget {
  const DisclosureRow({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(body),
            ],
          ),
        ),
      ],
    ),
  );
}

class OnboardingArt extends StatelessWidget {
  const OnboardingArt({super.key, required this.page});
  final int page;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(28),
      ),
      child: page == 2
          ? Column(
              children: [
                Container(
                  width: 144,
                  height: 170,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(color: scheme.outlineVariant, width: 3),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16815D).withValues(alpha: .1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF16815D),
                        size: 48,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.localBadge,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            )
          : Column(
              children: [
                if (page == 0) ...[
                  const SizedBox(height: 12),
                  const BrandMark(size: 92),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CategoryMark(Category.bill),
                      const SizedBox(width: 12),
                      const CategoryMark(Category.appointment),
                      const SizedBox(width: 12),
                      const CategoryMark(Category.packageDelivery),
                    ],
                  ),
                ] else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            color: Color(0xFFD66A14),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l.exampleNotification,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.south_rounded, size: 22),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CategoryMark(Category.bill, size: 38),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.exampleBill,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(l.exampleDate),
                                Text(
                                  l.oneDay,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
