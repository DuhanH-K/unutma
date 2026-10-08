import 'package:unutma/core/data/card_repository.dart';
import 'package:unutma/core/domain/action_card.dart';
import 'package:unutma/core/platform/unutma_api.g.dart';

/// Test-only data source. Never imported by lib/ or included in release routes.
class MemoryRepository implements CardRepository {
  List<ActionCard> items = [];
  PreferencesDto prefs = PreferencesDto(
    onboarded: true,
    language: 'tr',
    theme: 'light',
    reminderMinutes: 1440,
  );
  bool listener = true, reminders = true, fail = false;
  String? pendingSharedText;
  String? pendingOpenedCard;
  String? importedText;
  String? importResult;
  final ignored = <String, bool>{};
  @override
  Future<List<ActionCard>> cards() async {
    if (fail) throw const AppFailure(FailureKind.storage);
    return List.of(items);
  }

  @override
  Future<ActionCard> save(ActionCard card) async {
    final result = card.copyWith(
      id: card.id.isEmpty ? 'manual-${items.length}' : card.id,
      revision: card.revision + 1,
    );
    items.removeWhere((c) => c.id == result.id);
    items.add(result);
    return result;
  }

  @override
  Future<void> transition(ActionCard card, String action) async {
    items = items
        .map(
          (c) => c.id != card.id
              ? c
              : c.copyWith(
                  status: switch (action) {
                    'confirm' => CardStatus.active,
                    'done' => CardStatus.done,
                    'snooze' => CardStatus.snoozed,
                    _ => CardStatus.archived,
                  },
                  revision: c.revision + 1,
                ),
        )
        .toList();
  }

  @override
  Future<void> clearSourceMessage(String id) async {
    items = items
        .map(
          (card) => card.id == id ? card.copyWith(sourceMessage: null) : card,
        )
        .toList();
  }

  @override
  Future<void> deleteAll() async {
    items.clear();
    ignored.clear();
  }

  @override
  Future<AccessDto> access() async =>
      AccessDto(listenerEnabled: listener, remindersEnabled: reminders);
  @override
  Future<void> openAccess() async {}
  @override
  Future<void> requestReminders() async {}
  @override
  Future<PreferencesDto> preferences() async => prefs;
  @override
  Future<void> setPreferences(PreferencesDto preferences) async {
    prefs = preferences;
  }

  @override
  Future<List<SourceDto>> sources() async => [];
  @override
  Future<void> ignoreSource(String packageName, bool value) async {
    ignored[packageName] = value;
  }

  @override
  Future<void> reconcile() async {}
  @override
  Future<String?> openedCard() async {
    final value = pendingOpenedCard;
    pendingOpenedCard = null;
    return value;
  }

  @override
  Future<String?> sharedText() async {
    final value = pendingSharedText;
    pendingSharedText = null;
    return value;
  }

  @override
  Future<String?> importSharedText(String text) async {
    importedText = text;
    return importResult;
  }
}

final fixtureNow = DateTime(2026, 9, 7, 8);
List<ActionCard> fixtureCards() => [
  ActionCard(
    id: 'bill',
    category: Category.bill,
    title: 'İnternet faturası',
    sourceLabel: 'Türk Telekom',
    sourcePackage: 'test.telekom',
    dueAt: DateTime(2026, 9, 7, 18),
    amount: '549,90',
    currency: 'TRY',
    status: CardStatus.active,
    confidence: .96,
    createdAt: fixtureNow,
    reminderOffsets: [1440],
    revision: 1,
  ),
  ActionCard(
    id: 'appointment',
    category: Category.appointment,
    title: 'Dişçi randevusu',
    sourceLabel: 'MHRS',
    sourcePackage: 'test.mhrs',
    dueAt: DateTime(2026, 9, 8, 14, 30),
    status: CardStatus.active,
    confidence: .96,
    createdAt: fixtureNow,
    reminderOffsets: [1440, 60],
    revision: 1,
  ),
  ActionCard(
    id: 'package',
    category: Category.packagePickup,
    title: 'Paketini teslim al',
    sourceLabel: 'Yurtiçi Kargo',
    sourcePackage: 'test.kargo',
    dueAt: DateTime(2026, 9, 10, 17),
    status: CardStatus.active,
    confidence: .94,
    createdAt: fixtureNow,
    reminderOffsets: [1440],
    revision: 1,
  ),
];
