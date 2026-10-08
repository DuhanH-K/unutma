import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/config/app_config.dart';
import '../../core/services/ad_providers.dart';
import '../../core/widgets/shared.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final prefs = ref.watch(preferencesProvider);
    final access = ref.watch(accessProvider);
    final adState = ref.watch(adPrivacyStateProvider).value;
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),
              Text(
                l.settings,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SectionLabel('UNUTMA'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_active_outlined),
                      title: Text(l.notificationAccess),
                      subtitle: Text(
                        access.value?.listenerEnabled == true
                            ? l.enabled
                            : l.disabled,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/disclosure'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.alarm_outlined),
                      title: Text(l.reminderPermission),
                      subtitle: Text(
                        access.value?.remindersEnabled == true
                            ? l.enabled
                            : l.reminderOff,
                      ),
                      onTap: () async {
                        await runAction(
                          context,
                          ref.read(repositoryProvider).requestReminders,
                        );
                        ref.invalidate(accessProvider);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded),
                      title: Text(l.reminderDefaults),
                      subtitle: Text(
                        reminderLabel(
                          context,
                          prefs.value?.reminderMinutes ?? 1440,
                        ),
                      ),
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final n in [0, 60, 1440, 4320])
                                ListTile(
                                  title: Text(reminderLabel(context, n)),
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    await runAction(
                                      context,
                                      () => ref
                                          .read(preferencesProvider.notifier)
                                          .change(reminderMinutes: n),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SectionLabel(l.privacy.toUpperCase()),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.shield_outlined),
                      title: Text(l.privacy),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/privacy'),
                    ),
                    if (adState?.privacyOptionsRequired == true) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.ads_click_outlined),
                        title: Text(l.manageAdPrivacy),
                        subtitle: Text(l.manageAdPrivacyBody),
                        onTap: () async {
                          final ok = await ref
                              .read(adServiceProvider)
                              .showPrivacyOptions();
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.errorBody)),
                            );
                          }
                        },
                      ),
                    ],
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.storage_outlined),
                      title: Text(l.localData),
                      subtitle: Text(l.privacyStorage),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        l.deleteAll,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      onTap: () => deleteDialog(context, ref),
                    ),
                  ],
                ),
              ),
              SectionLabel(l.preferences),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(l.language),
                      trailing: DropdownButton<String>(
                        value: prefs.value?.language ?? '',
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem(value: '', child: Text(l.system)),
                          const DropdownMenuItem(
                            value: 'tr',
                            child: Text('Türkçe'),
                          ),
                          const DropdownMenuItem(
                            value: 'en',
                            child: Text('English'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            runAction(
                              context,
                              () => ref
                                  .read(preferencesProvider.notifier)
                                  .change(language: v),
                            );
                          }
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.contrast_rounded),
                      title: Text(l.theme),
                      trailing: DropdownButton<String>(
                        value: prefs.value?.theme ?? 'system',
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem(
                            value: 'system',
                            child: Text(l.system),
                          ),
                          DropdownMenuItem(
                            value: 'light',
                            child: Text(l.light),
                          ),
                          DropdownMenuItem(value: 'dark', child: Text(l.dark)),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            runAction(
                              context,
                              () => ref
                                  .read(preferencesProvider.notifier)
                                  .change(theme: v),
                            );
                          }
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.filter_alt_outlined),
                      title: Text(l.ignoredSources),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/sources'),
                    ),
                  ],
                ),
              ),
              SectionLabel(l.pro.toUpperCase()),
              Card(
                child: ListTile(
                  leading: const BrandMark(size: 32),
                  title: Text(l.pro),
                  subtitle: Text(l.billingDisabled),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/pro'),
                ),
              ),
              SectionLabel(l.about),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(l.version),
                      trailing: const Text(AppConfig.version),
                    ),
                    const Divider(),
                    ListTile(
                      title: Text(l.privacyPolicy),
                      onTap: () => context.push('/privacy'),
                    ),
                    const Divider(),
                    ListTile(
                      title: Text(l.terms),
                      onTap: () => context.push('/terms'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> deleteDialog(BuildContext context, WidgetRef ref) async {
  final l = context.l;
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.deleteTitle),
      content: SingleChildScrollView(child: Text(l.deleteBody)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.deleteConfirm),
        ),
      ],
    ),
  );
  if (yes == true && context.mounted) {
    final ok = await runAction(
      context,
      ref.read(repositoryProvider).deleteAll,
      haptic: true,
    );
    if (ok) {
      await ref.read(adServiceProvider).resetLocalState();
      ref.invalidate(cardsProvider);
      ref.invalidate(sourcesProvider);
      ref.invalidate(preferencesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.deleted)));
      }
    }
  }
}

class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(context.l.ignoredSources)),
    body: PageBody(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(context.l.sourcesBody),
          const SizedBox(height: 24),
          ref
              .watch(sourcesProvider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    ErrorPanel(retry: () => ref.invalidate(sourcesProvider)),
                data: (sources) => sources.isEmpty
                    ? Text(context.l.noSources)
                    : Column(
                        children: sources
                            .map(
                              (s) => SwitchListTile(
                                title: Text(
                                  s.label.isEmpty
                                      ? context.l.unknownSource
                                      : s.label,
                                ),
                                value: s.ignored,
                                onChanged: (v) async {
                                  await runAction(
                                    context,
                                    () => ref
                                        .read(repositoryProvider)
                                        .ignoreSource(s.packageName, v),
                                  );
                                  ref.invalidate(sourcesProvider);
                                },
                              ),
                            )
                            .toList(),
                      ),
              ),
        ],
      ),
    ),
  );
}

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key, this.terms = false});
  final bool terms;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adState = ref.watch(adPrivacyStateProvider).value;
    final adsEnabled = adState?.enabled == true;
    return Scaffold(
      appBar: AppBar(title: Text(terms ? context.l.terms : context.l.privacy)),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const SizedBox(height: 24),
            Icon(
              terms ? Icons.description_outlined : Icons.verified_user_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 28),
            Text(
              terms ? context.l.terms : context.l.privacyTitle,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            if (!terms) ...[
              const SizedBox(height: 22),
              for (final item in [
                context.l.privacyLocalAnalysis,
                context.l.privacyNoCloud,
                context.l.privacyDeleteAnytime,
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 24),
            Text(
              terms
                  ? adsEnabled
                        ? context.l.termsBodyWithAds
                        : context.l.termsBody
                  : context.l.privacyBody,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (!terms) ...[
              const SizedBox(height: 24),
              Text(
                context.l.privacyStorage,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (adsEnabled) ...[
                const SizedBox(height: 28),
                Text(
                  context.l.adPrivacyTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  context.l.adPrivacyBody,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (adState?.privacyOptionsRequired == true) ...[
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await ref
                          .read(adServiceProvider)
                          .showPrivacyOptions();
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l.errorBody)),
                        );
                      }
                    },
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(context.l.manageAdPrivacy),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}
