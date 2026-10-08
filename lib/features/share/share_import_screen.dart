import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/widgets/shared.dart';

class ShareImportScreen extends ConsumerStatefulWidget {
  const ShareImportScreen({super.key, required this.text});
  final String text;
  @override
  ConsumerState<ShareImportScreen> createState() => _ShareImportScreenState();
}

class _ShareImportScreenState extends ConsumerState<ShareImportScreen> {
  bool busy = false;

  Future<void> analyze() async {
    if (widget.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      final id = await ref
          .read(repositoryProvider)
          .importSharedText(widget.text);
      if (!mounted) return;
      ref.invalidate(cardsProvider);
      if (id != null) {
        context.go('/card/$id');
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.shareNoMatch)));
        context.go('/new', extra: widget.text);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.errorTitle)));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text.trim();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l.shareTitle),
        leading: IconButton(
          tooltip: context.l.cancel,
          onPressed: busy
              ? null
              : () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.ios_share_rounded,
              size: 52,
              color: Color(0xFF2F6FED),
            ),
            const SizedBox(height: 20),
            Text(
              context.l.shareTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              context.l.shareBody,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SectionLabel(context.l.sharePreview),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: SelectableText(text.isEmpty ? context.l.shareEmpty : text),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: busy || text.isEmpty ? null : analyze,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(context.l.shareAnalyze),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: busy ? null : () => context.go('/'),
              child: Text(context.l.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
