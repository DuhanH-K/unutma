import 'package:flutter/services.dart';

import '../domain/action_card.dart';
import '../platform/unutma_api.g.dart';

enum FailureKind { permission, storage, invalidInput, bridge }

class AppFailure implements Exception {
  const AppFailure(this.kind);
  final FailureKind kind;
}

abstract interface class CardRepository {
  Future<List<ActionCard>> cards();
  Future<ActionCard> save(ActionCard card);
  Future<void> transition(ActionCard card, String action);
  Future<void> clearSourceMessage(String id);
  Future<void> deleteAll();
  Future<AccessDto> access();
  Future<void> openAccess();
  Future<void> requestReminders();
  Future<PreferencesDto> preferences();
  Future<void> setPreferences(PreferencesDto preferences);
  Future<List<SourceDto>> sources();
  Future<void> ignoreSource(String packageName, bool ignored);
  Future<void> reconcile();
  Future<String?> openedCard();
  Future<String?> sharedText();
  Future<String?> importSharedText(String text);
}

class NativeCardRepository implements CardRepository {
  NativeCardRepository([UnutmaApi? api]) : _api = api ?? UnutmaApi();
  final UnutmaApi _api;
  Future<T> _call<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      throw AppFailure(switch (e.code) {
        'invalid_input' => FailureKind.invalidInput,
        'storage_failure' => FailureKind.storage,
        _ => FailureKind.bridge,
      });
    } on MissingPluginException {
      throw const AppFailure(FailureKind.bridge);
    }
  }

  @override
  Future<List<ActionCard>> cards() => _call(
    () async =>
        (await _api.getCards()).map(ActionCard.fromDto).toList(growable: false),
  );
  @override
  Future<ActionCard> save(ActionCard card) =>
      _call(() async => ActionCard.fromDto(await _api.saveCard(card.toDto())));
  @override
  Future<void> transition(ActionCard card, String action) =>
      _call(() => _api.transition(card.id, action, card.revision));
  @override
  Future<void> clearSourceMessage(String id) =>
      _call(() => _api.clearSourceMessage(id));
  @override
  Future<void> deleteAll() => _call(_api.deleteAllData);
  @override
  Future<AccessDto> access() => _call(_api.getAccess);
  @override
  Future<void> openAccess() => _call(_api.openNotificationAccess);
  @override
  Future<void> requestReminders() => _call(_api.requestReminderPermission);
  @override
  Future<PreferencesDto> preferences() => _call(_api.getPreferences);
  @override
  Future<void> setPreferences(PreferencesDto preferences) =>
      _call(() => _api.setPreferences(preferences));
  @override
  Future<List<SourceDto>> sources() => _call(_api.getSources);
  @override
  Future<void> ignoreSource(String packageName, bool ignored) =>
      _call(() => _api.setSourceIgnored(packageName, ignored));
  @override
  Future<void> reconcile() => _call(_api.reconcile);
  @override
  Future<String?> openedCard() => _call(_api.takeOpenedCard);
  @override
  Future<String?> sharedText() => _call(_api.takeSharedText);
  @override
  Future<String?> importSharedText(String text) =>
      _call(() => _api.importSharedText(text));
}
