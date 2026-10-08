import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/action_card.dart';
import '../platform/unutma_api.g.dart';
import 'card_repository.dart';

final repositoryProvider = Provider<CardRepository>(
  (ref) => NativeCardRepository(),
);
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final accessProvider = FutureProvider<AccessDto>(
  (ref) => ref.watch(repositoryProvider).access(),
);
final sourcesProvider = FutureProvider<List<SourceDto>>(
  (ref) => ref.watch(repositoryProvider).sources(),
);
final cardsProvider = AsyncNotifierProvider<CardsController, List<ActionCard>>(
  CardsController.new,
);

class CardsController extends AsyncNotifier<List<ActionCard>> {
  @override
  Future<List<ActionCard>> build() => ref.watch(repositoryProvider).cards();
  Future<void> refresh() async {
    state = await AsyncValue.guard(ref.read(repositoryProvider).cards);
  }

  Future<void> transition(ActionCard card, String action) async {
    await ref.read(repositoryProvider).transition(card, action);
    await refresh();
  }

  Future<void> clearSourceMessage(String id) async {
    await ref.read(repositoryProvider).clearSourceMessage(id);
    await refresh();
  }

  Future<void> save(ActionCard card) async {
    await ref.read(repositoryProvider).save(card);
    await refresh();
  }
}

final preferencesProvider =
    AsyncNotifierProvider<PreferencesController, PreferencesDto>(
      PreferencesController.new,
    );

class PreferencesController extends AsyncNotifier<PreferencesDto> {
  @override
  Future<PreferencesDto> build() => ref.watch(repositoryProvider).preferences();
  Future<void> change({
    bool? onboarded,
    String? language,
    String? theme,
    int? reminderMinutes,
  }) async {
    final old = await future;
    final next = PreferencesDto(
      onboarded: onboarded ?? old.onboarded,
      language: language ?? old.language,
      theme: theme ?? old.theme,
      reminderMinutes: reminderMinutes ?? old.reminderMinutes,
    );
    await ref.read(repositoryProvider).setPreferences(next);
    state = AsyncData(next);
  }
}
