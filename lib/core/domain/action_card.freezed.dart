// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'action_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActionCard {

 String get id; Category get category; String get title; String get sourceLabel; String get sourcePackage; DateTime? get dueAt; String? get amount; String? get currency; CardStatus get status; double get confidence; DateTime get createdAt; DateTime? get completedAt; List<int> get reminderOffsets; DateTime? get snoozedUntil; int get parserVersion; String? get note; String? get sourceMessage; int get revision;
/// Create a copy of ActionCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionCardCopyWith<ActionCard> get copyWith => _$ActionCardCopyWithImpl<ActionCard>(this as ActionCard, _$identity);

  /// Serializes this ActionCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ActionCard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionCard&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.sourceLabel, _this.sourceLabel) || other.sourceLabel == _this.sourceLabel)&&(identical(other.sourcePackage, _this.sourcePackage) || other.sourcePackage == _this.sourcePackage)&&(identical(other.dueAt, _this.dueAt) || other.dueAt == _this.dueAt)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.confidence, _this.confidence) || other.confidence == _this.confidence)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt)&&const DeepCollectionEquality().equals(other.reminderOffsets, _this.reminderOffsets)&&(identical(other.snoozedUntil, _this.snoozedUntil) || other.snoozedUntil == _this.snoozedUntil)&&(identical(other.parserVersion, _this.parserVersion) || other.parserVersion == _this.parserVersion)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.sourceMessage, _this.sourceMessage) || other.sourceMessage == _this.sourceMessage)&&(identical(other.revision, _this.revision) || other.revision == _this.revision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ActionCard;
  return Object.hash(runtimeType,_this.id,_this.category,_this.title,_this.sourceLabel,_this.sourcePackage,_this.dueAt,_this.amount,_this.currency,_this.status,_this.confidence,_this.createdAt,_this.completedAt,const DeepCollectionEquality().hash(_this.reminderOffsets),_this.snoozedUntil,_this.parserVersion,_this.note,_this.sourceMessage,_this.revision);
}

@override
String toString() {
  final _this = this as ActionCard;
  return 'ActionCard(id: ${_this.id}, category: ${_this.category}, title: ${_this.title}, sourceLabel: ${_this.sourceLabel}, sourcePackage: ${_this.sourcePackage}, dueAt: ${_this.dueAt}, amount: ${_this.amount}, currency: ${_this.currency}, status: ${_this.status}, confidence: ${_this.confidence}, createdAt: ${_this.createdAt}, completedAt: ${_this.completedAt}, reminderOffsets: ${_this.reminderOffsets}, snoozedUntil: ${_this.snoozedUntil}, parserVersion: ${_this.parserVersion}, note: ${_this.note}, sourceMessage: ${_this.sourceMessage}, revision: ${_this.revision})';
}


}

/// @nodoc
abstract mixin class $ActionCardCopyWith<$Res>  {
  factory $ActionCardCopyWith(ActionCard value, $Res Function(ActionCard) _then) = _$ActionCardCopyWithImpl;
@useResult
$Res call({
 String id, Category category, String title, String sourceLabel, String sourcePackage, DateTime? dueAt, String? amount, String? currency, CardStatus status, double confidence, DateTime createdAt, DateTime? completedAt, List<int> reminderOffsets, DateTime? snoozedUntil, int parserVersion, String? note, String? sourceMessage, int revision
});




}
/// @nodoc
class _$ActionCardCopyWithImpl<$Res>
    implements $ActionCardCopyWith<$Res> {
  _$ActionCardCopyWithImpl(this._self, this._then);

  final ActionCard _self;
  final $Res Function(ActionCard) _then;

/// Create a copy of ActionCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? title = null,Object? sourceLabel = null,Object? sourcePackage = null,Object? dueAt = freezed,Object? amount = freezed,Object? currency = freezed,Object? status = null,Object? confidence = null,Object? createdAt = null,Object? completedAt = freezed,Object? reminderOffsets = null,Object? snoozedUntil = freezed,Object? parserVersion = null,Object? note = freezed,Object? sourceMessage = freezed,Object? revision = null,}) {
  return _then(ActionCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sourceLabel: null == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String,sourcePackage: null == sourcePackage ? _self.sourcePackage : sourcePackage // ignore: cast_nullable_to_non_nullable
as String,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CardStatus,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reminderOffsets: null == reminderOffsets ? _self.reminderOffsets : reminderOffsets // ignore: cast_nullable_to_non_nullable
as List<int>,snoozedUntil: freezed == snoozedUntil ? _self.snoozedUntil : snoozedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,parserVersion: null == parserVersion ? _self.parserVersion : parserVersion // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,sourceMessage: freezed == sourceMessage ? _self.sourceMessage : sourceMessage // ignore: cast_nullable_to_non_nullable
as String?,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionCard].
extension ActionCardPatterns on ActionCard {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionCard() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionCard value)  $default,){
final _that = this;
switch (_that) {
case _ActionCard():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionCard value)?  $default,){
final _that = this;
switch (_that) {
case _ActionCard() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Category category,  String title,  String sourceLabel,  String sourcePackage,  DateTime? dueAt,  String? amount,  String? currency,  CardStatus status,  double confidence,  DateTime createdAt,  DateTime? completedAt,  List<int> reminderOffsets,  DateTime? snoozedUntil,  int parserVersion,  String? note,  String? sourceMessage,  int revision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionCard() when $default != null:
return $default(_that.id,_that.category,_that.title,_that.sourceLabel,_that.sourcePackage,_that.dueAt,_that.amount,_that.currency,_that.status,_that.confidence,_that.createdAt,_that.completedAt,_that.reminderOffsets,_that.snoozedUntil,_that.parserVersion,_that.note,_that.sourceMessage,_that.revision);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Category category,  String title,  String sourceLabel,  String sourcePackage,  DateTime? dueAt,  String? amount,  String? currency,  CardStatus status,  double confidence,  DateTime createdAt,  DateTime? completedAt,  List<int> reminderOffsets,  DateTime? snoozedUntil,  int parserVersion,  String? note,  String? sourceMessage,  int revision)  $default,) {final _that = this;
switch (_that) {
case _ActionCard():
return $default(_that.id,_that.category,_that.title,_that.sourceLabel,_that.sourcePackage,_that.dueAt,_that.amount,_that.currency,_that.status,_that.confidence,_that.createdAt,_that.completedAt,_that.reminderOffsets,_that.snoozedUntil,_that.parserVersion,_that.note,_that.sourceMessage,_that.revision);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Category category,  String title,  String sourceLabel,  String sourcePackage,  DateTime? dueAt,  String? amount,  String? currency,  CardStatus status,  double confidence,  DateTime createdAt,  DateTime? completedAt,  List<int> reminderOffsets,  DateTime? snoozedUntil,  int parserVersion,  String? note,  String? sourceMessage,  int revision)?  $default,) {final _that = this;
switch (_that) {
case _ActionCard() when $default != null:
return $default(_that.id,_that.category,_that.title,_that.sourceLabel,_that.sourcePackage,_that.dueAt,_that.amount,_that.currency,_that.status,_that.confidence,_that.createdAt,_that.completedAt,_that.reminderOffsets,_that.snoozedUntil,_that.parserVersion,_that.note,_that.sourceMessage,_that.revision);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActionCard extends ActionCard {
  const _ActionCard({required this.id, required this.category, required this.title, required this.sourceLabel, required this.sourcePackage, this.dueAt, this.amount, this.currency, required this.status, required this.confidence, required this.createdAt, this.completedAt,  List<int> reminderOffsets = const <int>[], this.snoozedUntil, this.parserVersion = 1, this.note, this.sourceMessage, this.revision = 0}): _reminderOffsets = reminderOffsets,super._();
  factory _ActionCard.fromJson(Map<String, dynamic> json) => _$ActionCardFromJson(json);

@override final  String id;
@override final  Category category;
@override final  String title;
@override final  String sourceLabel;
@override final  String sourcePackage;
@override final  DateTime? dueAt;
@override final  String? amount;
@override final  String? currency;
@override final  CardStatus status;
@override final  double confidence;
@override final  DateTime createdAt;
@override final  DateTime? completedAt;
 final  List<int> _reminderOffsets;
@override@JsonKey() List<int> get reminderOffsets {
  if (_reminderOffsets is EqualUnmodifiableListView) return _reminderOffsets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reminderOffsets);
}

@override final  DateTime? snoozedUntil;
@override@JsonKey() final  int parserVersion;
@override final  String? note;
@override final  String? sourceMessage;
@override@JsonKey() final  int revision;

/// Create a copy of ActionCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionCardCopyWith<_ActionCard> get copyWith => __$ActionCardCopyWithImpl<_ActionCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActionCardToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionCard&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.title, title) || other.title == title)&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel)&&(identical(other.sourcePackage, sourcePackage) || other.sourcePackage == sourcePackage)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&const DeepCollectionEquality().equals(other.reminderOffsets, _reminderOffsets)&&(identical(other.snoozedUntil, snoozedUntil) || other.snoozedUntil == snoozedUntil)&&(identical(other.parserVersion, parserVersion) || other.parserVersion == parserVersion)&&(identical(other.note, note) || other.note == note)&&(identical(other.sourceMessage, sourceMessage) || other.sourceMessage == sourceMessage)&&(identical(other.revision, revision) || other.revision == revision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,category,title,sourceLabel,sourcePackage,dueAt,amount,currency,status,confidence,createdAt,completedAt,const DeepCollectionEquality().hash(_reminderOffsets),snoozedUntil,parserVersion,note,sourceMessage,revision);
}

@override
String toString() {
    return 'ActionCard(id: $id, category: $category, title: $title, sourceLabel: $sourceLabel, sourcePackage: $sourcePackage, dueAt: $dueAt, amount: $amount, currency: $currency, status: $status, confidence: $confidence, createdAt: $createdAt, completedAt: $completedAt, reminderOffsets: $reminderOffsets, snoozedUntil: $snoozedUntil, parserVersion: $parserVersion, note: $note, sourceMessage: $sourceMessage, revision: $revision)';
}


}

/// @nodoc
abstract mixin class _$ActionCardCopyWith<$Res> implements $ActionCardCopyWith<$Res> {
  factory _$ActionCardCopyWith(_ActionCard value, $Res Function(_ActionCard) _then) = __$ActionCardCopyWithImpl;
@override @useResult
$Res call({
 String id, Category category, String title, String sourceLabel, String sourcePackage, DateTime? dueAt, String? amount, String? currency, CardStatus status, double confidence, DateTime createdAt, DateTime? completedAt, List<int> reminderOffsets, DateTime? snoozedUntil, int parserVersion, String? note, String? sourceMessage, int revision
});




}
/// @nodoc
class __$ActionCardCopyWithImpl<$Res>
    implements _$ActionCardCopyWith<$Res> {
  __$ActionCardCopyWithImpl(this._self, this._then);

  final _ActionCard _self;
  final $Res Function(_ActionCard) _then;

/// Create a copy of ActionCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? title = null,Object? sourceLabel = null,Object? sourcePackage = null,Object? dueAt = freezed,Object? amount = freezed,Object? currency = freezed,Object? status = null,Object? confidence = null,Object? createdAt = null,Object? completedAt = freezed,Object? reminderOffsets = null,Object? snoozedUntil = freezed,Object? parserVersion = null,Object? note = freezed,Object? sourceMessage = freezed,Object? revision = null,}) {
  return _then(_ActionCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sourceLabel: null == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String,sourcePackage: null == sourcePackage ? _self.sourcePackage : sourcePackage // ignore: cast_nullable_to_non_nullable
as String,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CardStatus,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reminderOffsets: null == reminderOffsets ? _self._reminderOffsets : reminderOffsets // ignore: cast_nullable_to_non_nullable
as List<int>,snoozedUntil: freezed == snoozedUntil ? _self.snoozedUntil : snoozedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,parserVersion: null == parserVersion ? _self.parserVersion : parserVersion // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,sourceMessage: freezed == sourceMessage ? _self.sourceMessage : sourceMessage // ignore: cast_nullable_to_non_nullable
as String?,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
