import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared.dart';

class IOSReminderEntry extends StatelessWidget {
  const IOSReminderEntry({super.key});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l.iosRemindersTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(context.l.iosRemindersBody),
          TextButton.icon(
            onPressed: () => context.push('/new'),
            icon: const Icon(Icons.add_rounded),
            label: Text(context.l.add),
          ),
          TextButton.icon(
            onPressed: () async {
              final controller = TextEditingController();
              final text = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(context.l.iosPasteTitle),
                  content: TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 4000,
                    autofocus: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.l.cancel),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, controller.text.trim()),
                      child: Text(context.l.continueLabel),
                    ),
                  ],
                ),
              );
              // The route may still be animating out and reading its controller.
              await Future<void>.delayed(const Duration(milliseconds: 300));
              controller.dispose();
              if (context.mounted && text?.isNotEmpty == true) {
                context.push('/share', extra: text);
              }
            },
            icon: const Icon(Icons.content_paste_rounded),
            label: Text(context.l.iosPasteTitle),
          ),
        ],
      ),
    ),
  );
}
