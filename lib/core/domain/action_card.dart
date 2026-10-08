import 'package:freezed_annotation/freezed_annotation.dart';

import '../platform/unutma_api.g.dart';
part 'action_card.freezed.dart';
part 'action_card.g.dart';

enum Category {
  bill,
  paymentDue,
  packageDelivery,
  packagePickup,
  appointment,
  reservation,
  subscriptionRenewal,
  returnWindow,
  ticketEvent,
  travel,
  deadline,
  other,
}

enum CardStatus { active, review, done, snoozed, archived, expired }

const categoryCodes = [
  'BILL',
  'PAYMENT_DUE',
  'PACKAGE_DELIVERY',
  'PACKAGE_PICKUP',
  'APPOINTMENT',
  'RESERVATION',
  'SUBSCRIPTION_RENEWAL',
  'RETURN_WINDOW',
  'TICKET_EVENT',
  'TRAVEL',
  'DEADLINE',
  'OTHER',
];

@freezed
abstract class ActionCard with _$ActionCard {
  const ActionCard._();
  const factory ActionCard({
    required String id,
    required Category category,
    required String title,
    required String sourceLabel,
    required String sourcePackage,
    DateTime? dueAt,
    String? amount,
    String? currency,
    required CardStatus status,
    required double confidence,
    required DateTime createdAt,
    DateTime? completedAt,
    @Default(<int>[]) List<int> reminderOffsets,
    DateTime? snoozedUntil,
    @Default(1) int parserVersion,
    String? note,
    String? sourceMessage,
    @Default(0) int revision,
  }) = _ActionCard;
  factory ActionCard.fromJson(Map<String, Object?> json) =>
      _$ActionCardFromJson(json);
  factory ActionCard.fromDto(CardDto dto) => ActionCard(
    id: dto.id,
    category:
        Category.values[categoryCodes
            .indexOf(dto.category)
            .clamp(0, Category.values.length - 1)],
    title: dto.title,
    sourceLabel: dto.sourceLabel,
    sourcePackage: dto.sourcePackage,
    dueAt: dto.dueAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(dto.dueAt!),
    amount: dto.amount,
    currency: dto.currency,
    status: CardStatus.values.byName(dto.status.toLowerCase()),
    confidence: dto.confidence,
    createdAt: DateTime.fromMillisecondsSinceEpoch(dto.createdAt),
    completedAt: dto.completedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(dto.completedAt!),
    reminderOffsets: dto.reminderOffsets,
    snoozedUntil: dto.snoozedUntil == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(dto.snoozedUntil!),
    parserVersion: dto.parserVersion,
    note: dto.note,
    sourceMessage: dto.sourceMessage,
    revision: dto.revision,
  );
  CardDto toDto() => CardDto(
    id: id,
    category: categoryCodes[category.index],
    title: title,
    sourceLabel: sourceLabel,
    sourcePackage: sourcePackage,
    dueAt: dueAt?.millisecondsSinceEpoch,
    amount: amount,
    currency: currency,
    status: status.name.toUpperCase(),
    confidence: confidence,
    createdAt: createdAt.millisecondsSinceEpoch,
    completedAt: completedAt?.millisecondsSinceEpoch,
    reminderOffsets: reminderOffsets,
    snoozedUntil: snoozedUntil?.millisecondsSinceEpoch,
    parserVersion: parserVersion,
    note: note,
    sourceMessage: sourceMessage,
    revision: revision,
  );
  bool get isActive =>
      status == CardStatus.active || status == CardStatus.snoozed;
}

enum DateGroup { overdue, today, tomorrow, week, later }

DateGroup groupFor(ActionCard card, DateTime now) {
  final d = card.snoozedUntil ?? card.dueAt;
  if (d == null) return DateGroup.later;
  final base = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  if (day.isBefore(base)) return DateGroup.overdue;
  if (day == base) return DateGroup.today;
  if (day == DateTime(now.year, now.month, now.day + 1)) {
    return DateGroup.tomorrow;
  }
  if (day.isBefore(DateTime(now.year, now.month, now.day + 7))) {
    return DateGroup.week;
  }
  return DateGroup.later;
}
