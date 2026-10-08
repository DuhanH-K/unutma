import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/shared.dart';
import '../../core/services/external_services.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final billing = DisabledBillingService();
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.pro)),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const SizedBox(height: 28),
            const Center(child: BrandMark(size: 84)),
            const SizedBox(height: 32),
            Text(l.proTitle, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 16),
            Text(l.proBody, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: billing.available ? () => billing.purchase() : null,
              child: Text(l.billingDisabled),
            ),
            TextButton(
              onPressed: billing.available ? () => billing.restore() : null,
              child: Text(l.restore),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: () => context.push('/privacy'),
                  child: Text(l.privacyPolicy),
                ),
                TextButton(
                  onPressed: () => context.push('/terms'),
                  child: Text(l.terms),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
