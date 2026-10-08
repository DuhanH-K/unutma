import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'unutma',
    dartOut: 'lib/core/platform/unutma_api.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/app/unutma/unutma/bridge/UnutmaApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'app.unutma.unutma.bridge'),
  ),
)
class CardDto {
  CardDto({
    required this.id,
    required this.category,
    required this.title,
    required this.sourceLabel,
    required this.sourcePackage,
    this.dueAt,
    this.amount,
    this.currency,
    required this.status,
    required this.confidence,
    required this.createdAt,
    this.completedAt,
    required this.reminderOffsets,
    this.snoozedUntil,
    required this.parserVersion,
    this.note,
    this.sourceMessage,
    required this.revision,
  });
  String id;
  String category;
  String title;
  String sourceLabel;
  String sourcePackage;
  int? dueAt;
  String? amount;
  String? currency;
  String status;
  double confidence;
  int createdAt;
  int? completedAt;
  List<int> reminderOffsets;
  int? snoozedUntil;
  int parserVersion;
  String? note;
  String? sourceMessage;
  int revision;
}

class PreferencesDto {
  PreferencesDto({
    required this.onboarded,
    required this.language,
    required this.theme,
    required this.reminderMinutes,
  });
  bool onboarded;
  String language;
  String theme;
  int reminderMinutes;
}

class AccessDto {
  AccessDto({required this.listenerEnabled, required this.remindersEnabled});
  bool listenerEnabled;
  bool remindersEnabled;
}

class SourceDto {
  SourceDto({
    required this.packageName,
    required this.label,
    required this.ignored,
  });
  String packageName;
  String label;
  bool ignored;
}

@HostApi()
abstract class UnutmaApi {
  @async
  List<CardDto> getCards();
  @async
  CardDto saveCard(CardDto card);
  @async
  void transition(String id, String action, int revision);
  @async
  void clearSourceMessage(String id);
  @async
  void deleteAllData();
  @async
  List<SourceDto> getSources();
  @async
  void setSourceIgnored(String packageName, bool ignored);
  @async
  AccessDto getAccess();
  void openNotificationAccess();
  void requestReminderPermission();
  PreferencesDto getPreferences();
  void setPreferences(PreferencesDto preferences);
  @async
  void reconcile();
  String? takeOpenedCard();
  String? takeSharedText();
  @async
  String? importSharedText(String text);
}

@FlutterApi()
abstract class UnutmaEvents {
  void cardsChanged();
  void sharedTextReceived();
}
