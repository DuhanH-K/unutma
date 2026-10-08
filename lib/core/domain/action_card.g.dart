// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActionCard _$ActionCardFromJson(Map<String, dynamic> json) => _ActionCard(
  id: json['id'] as String,
  category: $enumDecode(_$CategoryEnumMap, json['category']),
  title: json['title'] as String,
  sourceLabel: json['sourceLabel'] as String,
  sourcePackage: json['sourcePackage'] as String,
  dueAt: json['dueAt'] == null ? null : DateTime.parse(json['dueAt'] as String),
  amount: json['amount'] as String?,
  currency: json['currency'] as String?,
  status: $enumDecode(_$CardStatusEnumMap, json['status']),
  confidence: (json['confidence'] as num).toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  reminderOffsets:
      (json['reminderOffsets'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  snoozedUntil: json['snoozedUntil'] == null
      ? null
      : DateTime.parse(json['snoozedUntil'] as String),
  parserVersion: (json['parserVersion'] as num?)?.toInt() ?? 1,
  note: json['note'] as String?,
  sourceMessage: json['sourceMessage'] as String?,
  revision: (json['revision'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ActionCardToJson(_ActionCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': _$CategoryEnumMap[instance.category]!,
      'title': instance.title,
      'sourceLabel': instance.sourceLabel,
      'sourcePackage': instance.sourcePackage,
      'dueAt': instance.dueAt?.toIso8601String(),
      'amount': instance.amount,
      'currency': instance.currency,
      'status': _$CardStatusEnumMap[instance.status]!,
      'confidence': instance.confidence,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'reminderOffsets': instance.reminderOffsets,
      'snoozedUntil': instance.snoozedUntil?.toIso8601String(),
      'parserVersion': instance.parserVersion,
      'note': instance.note,
      'sourceMessage': instance.sourceMessage,
      'revision': instance.revision,
    };

const _$CategoryEnumMap = {
  Category.bill: 'bill',
  Category.paymentDue: 'paymentDue',
  Category.packageDelivery: 'packageDelivery',
  Category.packagePickup: 'packagePickup',
  Category.appointment: 'appointment',
  Category.reservation: 'reservation',
  Category.subscriptionRenewal: 'subscriptionRenewal',
  Category.returnWindow: 'returnWindow',
  Category.ticketEvent: 'ticketEvent',
  Category.travel: 'travel',
  Category.deadline: 'deadline',
  Category.other: 'other',
};

const _$CardStatusEnumMap = {
  CardStatus.active: 'active',
  CardStatus.review: 'review',
  CardStatus.done: 'done',
  CardStatus.snoozed: 'snoozed',
  CardStatus.archived: 'archived',
  CardStatus.expired: 'expired',
};
