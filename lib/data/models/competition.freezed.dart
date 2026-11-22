// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'competition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Competition {

 String get id; String get name;@GameTypeConverter() GameType get game;@TournamentFormatConverter() TournamentFormat get format; DateTime get startDate;@CompetitionStatusConverter() CompetitionStatus get status; int get maxPlayers; int get currentPlayers; double get registrationFee; String get registrationCurrency;/// Pays organisateur (ISO alpha-2, ex. `'CM'`). Sert au scoping admin par
/// pays (un admin restreint ne gère que les compétitions de son pays).
/// ⚠️ DIFFÉRENT des pays d'inscription autorisés (voir
/// `CompetitionPaymentOption`). Mappé sur `country_code`.
 String get countryCode; double get commissionPct; double get prizePoolLocal; double get commissionXaf; double get sponsorBonusLocal; String? get description; String? get bannerUrl; DateTime? get registrationOpensAt; DateTime? get registrationClosesAt; DateTime? get endDate; String? get prizePoolCurrency; String? get createdBy; DateTime? get createdAt; DateTime? get updatedAt;/// Merchant codes saisis par l'admin créateur — affichés sur P2
/// quand le joueur choisit la méthode correspondante. PHASE 11bis.
 String? get orangeMoneyCode; String? get mtnMomoCode;/// Répartition des gains par rang d'arrivée, en **montants** (monnaie
/// locale, ex. `[100000, 50000, 25000, 10000]`). Saisie dans le
/// wizard admin ; `prizePoolLocal` en est la somme.
 List<int> get prizeDistribution;/// Minutes entre la fin d'un round et le scheduled_at du round suivant
/// (Lot A — auto-management). Typiquement 30/60/120/240/1440.
/// Le trigger DB `try_schedule_next_round` lit cette valeur.
 int get matchIntervalMinutes;/// Si vrai, le bracket est généré automatiquement dès que max_players
/// est atteint. V1 : single_elimination uniquement. Le trigger DB
/// `trigger_auto_generate_bracket` consume ce flag.
 bool get autoGenerateBracket;/// Si vrai, un match de classement (petite finale / 3e place) est
/// généré en plus de la finale : il oppose les 2 perdants des
/// demi-finales. Opt-in admin. Mappé sur `third_place_match`.
 bool get thirdPlaceMatch;/// Lot D — quota de parrainages requis avant qu'un joueur puisse
/// s'inscrire. 0 = pas de gating (la majorité des comp.). Utilisé
/// uniquement pour les comp. gratuites avec récompense (variante
/// « invite N amis pour t'inscrire »). Trigger DB
/// `enforce_referral_quota_on_registration` consume cette colonne.
 int get referralQuota;/// Lot D.2 — Pondération du compteur parrainage.
/// - `'any'`  : tous les filleuls actifs comptent (défaut)
/// - `'engaged'` : seulement ceux ayant joué un match OU payé une
///   inscription. Bloque l'astuce "10 faux comptes" pour bypasser.
 String get referralActivityMode;/// Lot A.2 — Overrides d'intervalle par round (en minutes). Null =
/// utilise `matchIntervalMinutes` global. `roundIntervals[N-1]` =
/// délai après le round N.
 List<int>? get roundIntervals;/// Lot F.1 — Config dépendante du format. Pour `groups_then_knockout`,
/// peut contenir `{group_count: int, qualifiers_per_group: int}`.
/// Defaults serveur : 4 groupes × 2 qualifiés.
 Map<String, dynamic> get formatConfig;/// Item 1 prompt 2026-05-19 — URLs des stores pour télécharger le
/// jeu utilisé par cette compétition. Null = pas de lien proposé
/// (le joueur se débrouille). Affichés comme 2 boutons sur la
/// page registration_confirm côté user.
 String? get androidStoreUrl; String? get iosStoreUrl;/// Dernier échec de génération/scheduling AUTO du bracket (NULL si aucun).
/// Renseigné par les triggers DB `trigger_auto_generate_bracket` /
/// `trigger_try_schedule_next_round` (migration 20260613120000) à la place
/// d'un WARNING invisible. Affiché en bandeau dans la console admin.
 String? get lastBracketError; DateTime? get lastBracketErrorAt;/// Feature « épinglage admin » — quand `true`, la compétition est
/// remontée en tête des listes côté user (avec un badge « À LA UNE »).
/// `pinnedAt` horodate la dernière mise en avant et sert au tri entre
/// épinglées (la plus récemment épinglée en premier). Mappés sur
/// `is_pinned` / `pinned_at` via `fieldRename: snake`.
 bool get isPinned; DateTime? get pinnedAt;/// Horodatage du passage en `completed` (posé par trigger DB
/// `set_competition_completed_at`). Base du délai d'archivage.
 DateTime? get completedAt;/// Compétition archivée (masquée des listes joueur) — posée par le cron
/// `archive_old_completed_competitions` 7 jours après `completedAt`.
/// NULL = active/visible (migration 20260613160000).
 DateTime? get archivedAt;
/// Create a copy of Competition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompetitionCopyWith<Competition> get copyWith => _$CompetitionCopyWithImpl<Competition>(this as Competition, _$identity);

  /// Serializes this Competition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Competition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Competition&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.game, _this.game) || other.game == _this.game)&&(identical(other.format, _this.format) || other.format == _this.format)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.maxPlayers, _this.maxPlayers) || other.maxPlayers == _this.maxPlayers)&&(identical(other.currentPlayers, _this.currentPlayers) || other.currentPlayers == _this.currentPlayers)&&(identical(other.registrationFee, _this.registrationFee) || other.registrationFee == _this.registrationFee)&&(identical(other.registrationCurrency, _this.registrationCurrency) || other.registrationCurrency == _this.registrationCurrency)&&(identical(other.countryCode, _this.countryCode) || other.countryCode == _this.countryCode)&&(identical(other.commissionPct, _this.commissionPct) || other.commissionPct == _this.commissionPct)&&(identical(other.prizePoolLocal, _this.prizePoolLocal) || other.prizePoolLocal == _this.prizePoolLocal)&&(identical(other.commissionXaf, _this.commissionXaf) || other.commissionXaf == _this.commissionXaf)&&(identical(other.sponsorBonusLocal, _this.sponsorBonusLocal) || other.sponsorBonusLocal == _this.sponsorBonusLocal)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.bannerUrl, _this.bannerUrl) || other.bannerUrl == _this.bannerUrl)&&(identical(other.registrationOpensAt, _this.registrationOpensAt) || other.registrationOpensAt == _this.registrationOpensAt)&&(identical(other.registrationClosesAt, _this.registrationClosesAt) || other.registrationClosesAt == _this.registrationClosesAt)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.prizePoolCurrency, _this.prizePoolCurrency) || other.prizePoolCurrency == _this.prizePoolCurrency)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.orangeMoneyCode, _this.orangeMoneyCode) || other.orangeMoneyCode == _this.orangeMoneyCode)&&(identical(other.mtnMomoCode, _this.mtnMomoCode) || other.mtnMomoCode == _this.mtnMomoCode)&&const DeepCollectionEquality().equals(other.prizeDistribution, _this.prizeDistribution)&&(identical(other.matchIntervalMinutes, _this.matchIntervalMinutes) || other.matchIntervalMinutes == _this.matchIntervalMinutes)&&(identical(other.autoGenerateBracket, _this.autoGenerateBracket) || other.autoGenerateBracket == _this.autoGenerateBracket)&&(identical(other.thirdPlaceMatch, _this.thirdPlaceMatch) || other.thirdPlaceMatch == _this.thirdPlaceMatch)&&(identical(other.referralQuota, _this.referralQuota) || other.referralQuota == _this.referralQuota)&&(identical(other.referralActivityMode, _this.referralActivityMode) || other.referralActivityMode == _this.referralActivityMode)&&const DeepCollectionEquality().equals(other.roundIntervals, _this.roundIntervals)&&const DeepCollectionEquality().equals(other.formatConfig, _this.formatConfig)&&(identical(other.androidStoreUrl, _this.androidStoreUrl) || other.androidStoreUrl == _this.androidStoreUrl)&&(identical(other.iosStoreUrl, _this.iosStoreUrl) || other.iosStoreUrl == _this.iosStoreUrl)&&(identical(other.lastBracketError, _this.lastBracketError) || other.lastBracketError == _this.lastBracketError)&&(identical(other.lastBracketErrorAt, _this.lastBracketErrorAt) || other.lastBracketErrorAt == _this.lastBracketErrorAt)&&(identical(other.isPinned, _this.isPinned) || other.isPinned == _this.isPinned)&&(identical(other.pinnedAt, _this.pinnedAt) || other.pinnedAt == _this.pinnedAt)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt)&&(identical(other.archivedAt, _this.archivedAt) || other.archivedAt == _this.archivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Competition;
  return Object.hashAll([runtimeType,_this.id,_this.name,_this.game,_this.format,_this.startDate,_this.status,_this.maxPlayers,_this.currentPlayers,_this.registrationFee,_this.registrationCurrency,_this.countryCode,_this.commissionPct,_this.prizePoolLocal,_this.commissionXaf,_this.sponsorBonusLocal,_this.description,_this.bannerUrl,_this.registrationOpensAt,_this.registrationClosesAt,_this.endDate,_this.prizePoolCurrency,_this.createdBy,_this.createdAt,_this.updatedAt,_this.orangeMoneyCode,_this.mtnMomoCode,const DeepCollectionEquality().hash(_this.prizeDistribution),_this.matchIntervalMinutes,_this.autoGenerateBracket,_this.thirdPlaceMatch,_this.referralQuota,_this.referralActivityMode,const DeepCollectionEquality().hash(_this.roundIntervals),const DeepCollectionEquality().hash(_this.formatConfig),_this.androidStoreUrl,_this.iosStoreUrl,_this.lastBracketError,_this.lastBracketErrorAt,_this.isPinned,_this.pinnedAt,_this.completedAt,_this.archivedAt]);
}

@override
String toString() {
  final _this = this as Competition;
  return 'Competition(id: ${_this.id}, name: ${_this.name}, game: ${_this.game}, format: ${_this.format}, startDate: ${_this.startDate}, status: ${_this.status}, maxPlayers: ${_this.maxPlayers}, currentPlayers: ${_this.currentPlayers}, registrationFee: ${_this.registrationFee}, registrationCurrency: ${_this.registrationCurrency}, countryCode: ${_this.countryCode}, commissionPct: ${_this.commissionPct}, prizePoolLocal: ${_this.prizePoolLocal}, commissionXaf: ${_this.commissionXaf}, sponsorBonusLocal: ${_this.sponsorBonusLocal}, description: ${_this.description}, bannerUrl: ${_this.bannerUrl}, registrationOpensAt: ${_this.registrationOpensAt}, registrationClosesAt: ${_this.registrationClosesAt}, endDate: ${_this.endDate}, prizePoolCurrency: ${_this.prizePoolCurrency}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, orangeMoneyCode: ${_this.orangeMoneyCode}, mtnMomoCode: ${_this.mtnMomoCode}, prizeDistribution: ${_this.prizeDistribution}, matchIntervalMinutes: ${_this.matchIntervalMinutes}, autoGenerateBracket: ${_this.autoGenerateBracket}, thirdPlaceMatch: ${_this.thirdPlaceMatch}, referralQuota: ${_this.referralQuota}, referralActivityMode: ${_this.referralActivityMode}, roundIntervals: ${_this.roundIntervals}, formatConfig: ${_this.formatConfig}, androidStoreUrl: ${_this.androidStoreUrl}, iosStoreUrl: ${_this.iosStoreUrl}, lastBracketError: ${_this.lastBracketError}, lastBracketErrorAt: ${_this.lastBracketErrorAt}, isPinned: ${_this.isPinned}, pinnedAt: ${_this.pinnedAt}, completedAt: ${_this.completedAt}, archivedAt: ${_this.archivedAt})';
}


}

/// @nodoc
abstract mixin class $CompetitionCopyWith<$Res>  {
  factory $CompetitionCopyWith(Competition value, $Res Function(Competition) _then) = _$CompetitionCopyWithImpl;
@useResult
$Res call({
 String id, String name,@GameTypeConverter() GameType game,@TournamentFormatConverter() TournamentFormat format, DateTime startDate,@CompetitionStatusConverter() CompetitionStatus status, int maxPlayers, int currentPlayers, double registrationFee, String registrationCurrency, String countryCode, double commissionPct, double prizePoolLocal, double commissionXaf, double sponsorBonusLocal, String? description, String? bannerUrl, DateTime? registrationOpensAt, DateTime? registrationClosesAt, DateTime? endDate, String? prizePoolCurrency, String? createdBy, DateTime? createdAt, DateTime? updatedAt, String? orangeMoneyCode, String? mtnMomoCode, List<int> prizeDistribution, int matchIntervalMinutes, bool autoGenerateBracket, bool thirdPlaceMatch, int referralQuota, String referralActivityMode, List<int>? roundIntervals, Map<String, dynamic> formatConfig, String? androidStoreUrl, String? iosStoreUrl, String? lastBracketError, DateTime? lastBracketErrorAt, bool isPinned, DateTime? pinnedAt, DateTime? completedAt, DateTime? archivedAt
});




}
/// @nodoc
class _$CompetitionCopyWithImpl<$Res>
    implements $CompetitionCopyWith<$Res> {
  _$CompetitionCopyWithImpl(this._self, this._then);

  final Competition _self;
  final $Res Function(Competition) _then;

/// Create a copy of Competition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? game = null,Object? format = null,Object? startDate = null,Object? status = null,Object? maxPlayers = null,Object? currentPlayers = null,Object? registrationFee = null,Object? registrationCurrency = null,Object? countryCode = null,Object? commissionPct = null,Object? prizePoolLocal = null,Object? commissionXaf = null,Object? sponsorBonusLocal = null,Object? description = freezed,Object? bannerUrl = freezed,Object? registrationOpensAt = freezed,Object? registrationClosesAt = freezed,Object? endDate = freezed,Object? prizePoolCurrency = freezed,Object? createdBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? orangeMoneyCode = freezed,Object? mtnMomoCode = freezed,Object? prizeDistribution = null,Object? matchIntervalMinutes = null,Object? autoGenerateBracket = null,Object? thirdPlaceMatch = null,Object? referralQuota = null,Object? referralActivityMode = null,Object? roundIntervals = freezed,Object? formatConfig = null,Object? androidStoreUrl = freezed,Object? iosStoreUrl = freezed,Object? lastBracketError = freezed,Object? lastBracketErrorAt = freezed,Object? isPinned = null,Object? pinnedAt = freezed,Object? completedAt = freezed,Object? archivedAt = freezed,}) {
  return _then(Competition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,game: null == game ? _self.game : game // ignore: cast_nullable_to_non_nullable
as GameType,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as TournamentFormat,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CompetitionStatus,maxPlayers: null == maxPlayers ? _self.maxPlayers : maxPlayers // ignore: cast_nullable_to_non_nullable
as int,currentPlayers: null == currentPlayers ? _self.currentPlayers : currentPlayers // ignore: cast_nullable_to_non_nullable
as int,registrationFee: null == registrationFee ? _self.registrationFee : registrationFee // ignore: cast_nullable_to_non_nullable
as double,registrationCurrency: null == registrationCurrency ? _self.registrationCurrency : registrationCurrency // ignore: cast_nullable_to_non_nullable
as String,countryCode: null == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String,commissionPct: null == commissionPct ? _self.commissionPct : commissionPct // ignore: cast_nullable_to_non_nullable
as double,prizePoolLocal: null == prizePoolLocal ? _self.prizePoolLocal : prizePoolLocal // ignore: cast_nullable_to_non_nullable
as double,commissionXaf: null == commissionXaf ? _self.commissionXaf : commissionXaf // ignore: cast_nullable_to_non_nullable
as double,sponsorBonusLocal: null == sponsorBonusLocal ? _self.sponsorBonusLocal : sponsorBonusLocal // ignore: cast_nullable_to_non_nullable
as double,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,bannerUrl: freezed == bannerUrl ? _self.bannerUrl : bannerUrl // ignore: cast_nullable_to_non_nullable
as String?,registrationOpensAt: freezed == registrationOpensAt ? _self.registrationOpensAt : registrationOpensAt // ignore: cast_nullable_to_non_nullable
as DateTime?,registrationClosesAt: freezed == registrationClosesAt ? _self.registrationClosesAt : registrationClosesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,prizePoolCurrency: freezed == prizePoolCurrency ? _self.prizePoolCurrency : prizePoolCurrency // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,orangeMoneyCode: freezed == orangeMoneyCode ? _self.orangeMoneyCode : orangeMoneyCode // ignore: cast_nullable_to_non_nullable
as String?,mtnMomoCode: freezed == mtnMomoCode ? _self.mtnMomoCode : mtnMomoCode // ignore: cast_nullable_to_non_nullable
as String?,prizeDistribution: null == prizeDistribution ? _self.prizeDistribution : prizeDistribution // ignore: cast_nullable_to_non_nullable
as List<int>,matchIntervalMinutes: null == matchIntervalMinutes ? _self.matchIntervalMinutes : matchIntervalMinutes // ignore: cast_nullable_to_non_nullable
as int,autoGenerateBracket: null == autoGenerateBracket ? _self.autoGenerateBracket : autoGenerateBracket // ignore: cast_nullable_to_non_nullable
as bool,thirdPlaceMatch: null == thirdPlaceMatch ? _self.thirdPlaceMatch : thirdPlaceMatch // ignore: cast_nullable_to_non_nullable
as bool,referralQuota: null == referralQuota ? _self.referralQuota : referralQuota // ignore: cast_nullable_to_non_nullable
as int,referralActivityMode: null == referralActivityMode ? _self.referralActivityMode : referralActivityMode // ignore: cast_nullable_to_non_nullable
as String,roundIntervals: freezed == roundIntervals ? _self.roundIntervals : roundIntervals // ignore: cast_nullable_to_non_nullable
as List<int>?,formatConfig: null == formatConfig ? _self.formatConfig : formatConfig // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,androidStoreUrl: freezed == androidStoreUrl ? _self.androidStoreUrl : androidStoreUrl // ignore: cast_nullable_to_non_nullable
as String?,iosStoreUrl: freezed == iosStoreUrl ? _self.iosStoreUrl : iosStoreUrl // ignore: cast_nullable_to_non_nullable
as String?,lastBracketError: freezed == lastBracketError ? _self.lastBracketError : lastBracketError // ignore: cast_nullable_to_non_nullable
as String?,lastBracketErrorAt: freezed == lastBracketErrorAt ? _self.lastBracketErrorAt : lastBracketErrorAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,pinnedAt: freezed == pinnedAt ? _self.pinnedAt : pinnedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Competition].
extension CompetitionPatterns on Competition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Competition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Competition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Competition value)  $default,){
final _that = this;
switch (_that) {
case _Competition():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Competition value)?  $default,){
final _that = this;
switch (_that) {
case _Competition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @GameTypeConverter()  GameType game, @TournamentFormatConverter()  TournamentFormat format,  DateTime startDate, @CompetitionStatusConverter()  CompetitionStatus status,  int maxPlayers,  int currentPlayers,  double registrationFee,  String registrationCurrency,  String countryCode,  double commissionPct,  double prizePoolLocal,  double commissionXaf,  double sponsorBonusLocal,  String? description,  String? bannerUrl,  DateTime? registrationOpensAt,  DateTime? registrationClosesAt,  DateTime? endDate,  String? prizePoolCurrency,  String? createdBy,  DateTime? createdAt,  DateTime? updatedAt,  String? orangeMoneyCode,  String? mtnMomoCode,  List<int> prizeDistribution,  int matchIntervalMinutes,  bool autoGenerateBracket,  bool thirdPlaceMatch,  int referralQuota,  String referralActivityMode,  List<int>? roundIntervals,  Map<String, dynamic> formatConfig,  String? androidStoreUrl,  String? iosStoreUrl,  String? lastBracketError,  DateTime? lastBracketErrorAt,  bool isPinned,  DateTime? pinnedAt,  DateTime? completedAt,  DateTime? archivedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Competition() when $default != null:
return $default(_that.id,_that.name,_that.game,_that.format,_that.startDate,_that.status,_that.maxPlayers,_that.currentPlayers,_that.registrationFee,_that.registrationCurrency,_that.countryCode,_that.commissionPct,_that.prizePoolLocal,_that.commissionXaf,_that.sponsorBonusLocal,_that.description,_that.bannerUrl,_that.registrationOpensAt,_that.registrationClosesAt,_that.endDate,_that.prizePoolCurrency,_that.createdBy,_that.createdAt,_that.updatedAt,_that.orangeMoneyCode,_that.mtnMomoCode,_that.prizeDistribution,_that.matchIntervalMinutes,_that.autoGenerateBracket,_that.thirdPlaceMatch,_that.referralQuota,_that.referralActivityMode,_that.roundIntervals,_that.formatConfig,_that.androidStoreUrl,_that.iosStoreUrl,_that.lastBracketError,_that.lastBracketErrorAt,_that.isPinned,_that.pinnedAt,_that.completedAt,_that.archivedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @GameTypeConverter()  GameType game, @TournamentFormatConverter()  TournamentFormat format,  DateTime startDate, @CompetitionStatusConverter()  CompetitionStatus status,  int maxPlayers,  int currentPlayers,  double registrationFee,  String registrationCurrency,  String countryCode,  double commissionPct,  double prizePoolLocal,  double commissionXaf,  double sponsorBonusLocal,  String? description,  String? bannerUrl,  DateTime? registrationOpensAt,  DateTime? registrationClosesAt,  DateTime? endDate,  String? prizePoolCurrency,  String? createdBy,  DateTime? createdAt,  DateTime? updatedAt,  String? orangeMoneyCode,  String? mtnMomoCode,  List<int> prizeDistribution,  int matchIntervalMinutes,  bool autoGenerateBracket,  bool thirdPlaceMatch,  int referralQuota,  String referralActivityMode,  List<int>? roundIntervals,  Map<String, dynamic> formatConfig,  String? androidStoreUrl,  String? iosStoreUrl,  String? lastBracketError,  DateTime? lastBracketErrorAt,  bool isPinned,  DateTime? pinnedAt,  DateTime? completedAt,  DateTime? archivedAt)  $default,) {final _that = this;
switch (_that) {
case _Competition():
return $default(_that.id,_that.name,_that.game,_that.format,_that.startDate,_that.status,_that.maxPlayers,_that.currentPlayers,_that.registrationFee,_that.registrationCurrency,_that.countryCode,_that.commissionPct,_that.prizePoolLocal,_that.commissionXaf,_that.sponsorBonusLocal,_that.description,_that.bannerUrl,_that.registrationOpensAt,_that.registrationClosesAt,_that.endDate,_that.prizePoolCurrency,_that.createdBy,_that.createdAt,_that.updatedAt,_that.orangeMoneyCode,_that.mtnMomoCode,_that.prizeDistribution,_that.matchIntervalMinutes,_that.autoGenerateBracket,_that.thirdPlaceMatch,_that.referralQuota,_that.referralActivityMode,_that.roundIntervals,_that.formatConfig,_that.androidStoreUrl,_that.iosStoreUrl,_that.lastBracketError,_that.lastBracketErrorAt,_that.isPinned,_that.pinnedAt,_that.completedAt,_that.archivedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @GameTypeConverter()  GameType game, @TournamentFormatConverter()  TournamentFormat format,  DateTime startDate, @CompetitionStatusConverter()  CompetitionStatus status,  int maxPlayers,  int currentPlayers,  double registrationFee,  String registrationCurrency,  String countryCode,  double commissionPct,  double prizePoolLocal,  double commissionXaf,  double sponsorBonusLocal,  String? description,  String? bannerUrl,  DateTime? registrationOpensAt,  DateTime? registrationClosesAt,  DateTime? endDate,  String? prizePoolCurrency,  String? createdBy,  DateTime? createdAt,  DateTime? updatedAt,  String? orangeMoneyCode,  String? mtnMomoCode,  List<int> prizeDistribution,  int matchIntervalMinutes,  bool autoGenerateBracket,  bool thirdPlaceMatch,  int referralQuota,  String referralActivityMode,  List<int>? roundIntervals,  Map<String, dynamic> formatConfig,  String? androidStoreUrl,  String? iosStoreUrl,  String? lastBracketError,  DateTime? lastBracketErrorAt,  bool isPinned,  DateTime? pinnedAt,  DateTime? completedAt,  DateTime? archivedAt)?  $default,) {final _that = this;
switch (_that) {
case _Competition() when $default != null:
return $default(_that.id,_that.name,_that.game,_that.format,_that.startDate,_that.status,_that.maxPlayers,_that.currentPlayers,_that.registrationFee,_that.registrationCurrency,_that.countryCode,_that.commissionPct,_that.prizePoolLocal,_that.commissionXaf,_that.sponsorBonusLocal,_that.description,_that.bannerUrl,_that.registrationOpensAt,_that.registrationClosesAt,_that.endDate,_that.prizePoolCurrency,_that.createdBy,_that.createdAt,_that.updatedAt,_that.orangeMoneyCode,_that.mtnMomoCode,_that.prizeDistribution,_that.matchIntervalMinutes,_that.autoGenerateBracket,_that.thirdPlaceMatch,_that.referralQuota,_that.referralActivityMode,_that.roundIntervals,_that.formatConfig,_that.androidStoreUrl,_that.iosStoreUrl,_that.lastBracketError,_that.lastBracketErrorAt,_that.isPinned,_that.pinnedAt,_that.completedAt,_that.archivedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Competition extends Competition {
  const _Competition({required this.id, required this.name, @GameTypeConverter() required this.game, @TournamentFormatConverter() required this.format, required this.startDate, @CompetitionStatusConverter() this.status = CompetitionStatus.draft, this.maxPlayers = 2, this.currentPlayers = 0, this.registrationFee = 0, this.registrationCurrency = 'XAF', this.countryCode = 'CM', this.commissionPct = 10, this.prizePoolLocal = 0, this.commissionXaf = 0, this.sponsorBonusLocal = 0, this.description, this.bannerUrl, this.registrationOpensAt, this.registrationClosesAt, this.endDate, this.prizePoolCurrency, this.createdBy, this.createdAt, this.updatedAt, this.orangeMoneyCode, this.mtnMomoCode,  List<int> prizeDistribution = const <int>[0, 0, 0, 0], this.matchIntervalMinutes = 60, this.autoGenerateBracket = true, this.thirdPlaceMatch = false, this.referralQuota = 0, this.referralActivityMode = 'any',  List<int>? roundIntervals,  Map<String, dynamic> formatConfig = const <String, dynamic>{}, this.androidStoreUrl, this.iosStoreUrl, this.lastBracketError, this.lastBracketErrorAt, this.isPinned = false, this.pinnedAt, this.completedAt, this.archivedAt}): _prizeDistribution = prizeDistribution,_roundIntervals = roundIntervals,_formatConfig = formatConfig,super._();
  factory _Competition.fromJson(Map<String, dynamic> json) => _$CompetitionFromJson(json);

@override final  String id;
@override final  String name;
@override@GameTypeConverter() final  GameType game;
@override@TournamentFormatConverter() final  TournamentFormat format;
@override final  DateTime startDate;
@override@JsonKey()@CompetitionStatusConverter() final  CompetitionStatus status;
@override@JsonKey() final  int maxPlayers;
@override@JsonKey() final  int currentPlayers;
@override@JsonKey() final  double registrationFee;
@override@JsonKey() final  String registrationCurrency;
/// Pays organisateur (ISO alpha-2, ex. `'CM'`). Sert au scoping admin par
/// pays (un admin restreint ne gère que les compétitions de son pays).
/// ⚠️ DIFFÉRENT des pays d'inscription autorisés (voir
/// `CompetitionPaymentOption`). Mappé sur `country_code`.
@override@JsonKey() final  String countryCode;
@override@JsonKey() final  double commissionPct;
@override@JsonKey() final  double prizePoolLocal;
@override@JsonKey() final  double commissionXaf;
@override@JsonKey() final  double sponsorBonusLocal;
@override final  String? description;
@override final  String? bannerUrl;
@override final  DateTime? registrationOpensAt;
@override final  DateTime? registrationClosesAt;
@override final  DateTime? endDate;
@override final  String? prizePoolCurrency;
@override final  String? createdBy;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
/// Merchant codes saisis par l'admin créateur — affichés sur P2
/// quand le joueur choisit la méthode correspondante. PHASE 11bis.
@override final  String? orangeMoneyCode;
@override final  String? mtnMomoCode;
/// Répartition des gains par rang d'arrivée, en **montants** (monnaie
/// locale, ex. `[100000, 50000, 25000, 10000]`). Saisie dans le
/// wizard admin ; `prizePoolLocal` en est la somme.
 final  List<int> _prizeDistribution;
/// Répartition des gains par rang d'arrivée, en **montants** (monnaie
/// locale, ex. `[100000, 50000, 25000, 10000]`). Saisie dans le
/// wizard admin ; `prizePoolLocal` en est la somme.
@override@JsonKey() List<int> get prizeDistribution {
  if (_prizeDistribution is EqualUnmodifiableListView) return _prizeDistribution;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_prizeDistribution);
}

/// Minutes entre la fin d'un round et le scheduled_at du round suivant
/// (Lot A — auto-management). Typiquement 30/60/120/240/1440.
/// Le trigger DB `try_schedule_next_round` lit cette valeur.
@override@JsonKey() final  int matchIntervalMinutes;
/// Si vrai, le bracket est généré automatiquement dès que max_players
/// est atteint. V1 : single_elimination uniquement. Le trigger DB
/// `trigger_auto_generate_bracket` consume ce flag.
@override@JsonKey() final  bool autoGenerateBracket;
/// Si vrai, un match de classement (petite finale / 3e place) est
/// généré en plus de la finale : il oppose les 2 perdants des
/// demi-finales. Opt-in admin. Mappé sur `third_place_match`.
@override@JsonKey() final  bool thirdPlaceMatch;
/// Lot D — quota de parrainages requis avant qu'un joueur puisse
/// s'inscrire. 0 = pas de gating (la majorité des comp.). Utilisé
/// uniquement pour les comp. gratuites avec récompense (variante
/// « invite N amis pour t'inscrire »). Trigger DB
/// `enforce_referral_quota_on_registration` consume cette colonne.
@override@JsonKey() final  int referralQuota;
/// Lot D.2 — Pondération du compteur parrainage.
/// - `'any'`  : tous les filleuls actifs comptent (défaut)
/// - `'engaged'` : seulement ceux ayant joué un match OU payé une
///   inscription. Bloque l'astuce "10 faux comptes" pour bypasser.
@override@JsonKey() final  String referralActivityMode;
/// Lot A.2 — Overrides d'intervalle par round (en minutes). Null =
/// utilise `matchIntervalMinutes` global. `roundIntervals[N-1]` =
/// délai après le round N.
 final  List<int>? _roundIntervals;
/// Lot A.2 — Overrides d'intervalle par round (en minutes). Null =
/// utilise `matchIntervalMinutes` global. `roundIntervals[N-1]` =
/// délai après le round N.
@override List<int>? get roundIntervals {
  final value = _roundIntervals;
  if (value == null) return null;
  if (_roundIntervals is EqualUnmodifiableListView) return _roundIntervals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Lot F.1 — Config dépendante du format. Pour `groups_then_knockout`,
/// peut contenir `{group_count: int, qualifiers_per_group: int}`.
/// Defaults serveur : 4 groupes × 2 qualifiés.
 final  Map<String, dynamic> _formatConfig;
/// Lot F.1 — Config dépendante du format. Pour `groups_then_knockout`,
/// peut contenir `{group_count: int, qualifiers_per_group: int}`.
/// Defaults serveur : 4 groupes × 2 qualifiés.
@override@JsonKey() Map<String, dynamic> get formatConfig {
  if (_formatConfig is EqualUnmodifiableMapView) return _formatConfig;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_formatConfig);
}

/// Item 1 prompt 2026-05-19 — URLs des stores pour télécharger le
/// jeu utilisé par cette compétition. Null = pas de lien proposé
/// (le joueur se débrouille). Affichés comme 2 boutons sur la
/// page registration_confirm côté user.
@override final  String? androidStoreUrl;
@override final  String? iosStoreUrl;
/// Dernier échec de génération/scheduling AUTO du bracket (NULL si aucun).
/// Renseigné par les triggers DB `trigger_auto_generate_bracket` /
/// `trigger_try_schedule_next_round` (migration 20260613120000) à la place
/// d'un WARNING invisible. Affiché en bandeau dans la console admin.
@override final  String? lastBracketError;
@override final  DateTime? lastBracketErrorAt;
/// Feature « épinglage admin » — quand `true`, la compétition est
/// remontée en tête des listes côté user (avec un badge « À LA UNE »).
/// `pinnedAt` horodate la dernière mise en avant et sert au tri entre
/// épinglées (la plus récemment épinglée en premier). Mappés sur
/// `is_pinned` / `pinned_at` via `fieldRename: snake`.
@override@JsonKey() final  bool isPinned;
@override final  DateTime? pinnedAt;
/// Horodatage du passage en `completed` (posé par trigger DB
/// `set_competition_completed_at`). Base du délai d'archivage.
@override final  DateTime? completedAt;
/// Compétition archivée (masquée des listes joueur) — posée par le cron
/// `archive_old_completed_competitions` 7 jours après `completedAt`.
/// NULL = active/visible (migration 20260613160000).
@override final  DateTime? archivedAt;

/// Create a copy of Competition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompetitionCopyWith<_Competition> get copyWith => __$CompetitionCopyWithImpl<_Competition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompetitionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Competition&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.game, game) || other.game == game)&&(identical(other.format, format) || other.format == format)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.maxPlayers, maxPlayers) || other.maxPlayers == maxPlayers)&&(identical(other.currentPlayers, currentPlayers) || other.currentPlayers == currentPlayers)&&(identical(other.registrationFee, registrationFee) || other.registrationFee == registrationFee)&&(identical(other.registrationCurrency, registrationCurrency) || other.registrationCurrency == registrationCurrency)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.commissionPct, commissionPct) || other.commissionPct == commissionPct)&&(identical(other.prizePoolLocal, prizePoolLocal) || other.prizePoolLocal == prizePoolLocal)&&(identical(other.commissionXaf, commissionXaf) || other.commissionXaf == commissionXaf)&&(identical(other.sponsorBonusLocal, sponsorBonusLocal) || other.sponsorBonusLocal == sponsorBonusLocal)&&(identical(other.description, description) || other.description == description)&&(identical(other.bannerUrl, bannerUrl) || other.bannerUrl == bannerUrl)&&(identical(other.registrationOpensAt, registrationOpensAt) || other.registrationOpensAt == registrationOpensAt)&&(identical(other.registrationClosesAt, registrationClosesAt) || other.registrationClosesAt == registrationClosesAt)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.prizePoolCurrency, prizePoolCurrency) || other.prizePoolCurrency == prizePoolCurrency)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.orangeMoneyCode, orangeMoneyCode) || other.orangeMoneyCode == orangeMoneyCode)&&(identical(other.mtnMomoCode, mtnMomoCode) || other.mtnMomoCode == mtnMomoCode)&&const DeepCollectionEquality().equals(other.prizeDistribution, _prizeDistribution)&&(identical(other.matchIntervalMinutes, matchIntervalMinutes) || other.matchIntervalMinutes == matchIntervalMinutes)&&(identical(other.autoGenerateBracket, autoGenerateBracket) || other.autoGenerateBracket == autoGenerateBracket)&&(identical(other.thirdPlaceMatch, thirdPlaceMatch) || other.thirdPlaceMatch == thirdPlaceMatch)&&(identical(other.referralQuota, referralQuota) || other.referralQuota == referralQuota)&&(identical(other.referralActivityMode, referralActivityMode) || other.referralActivityMode == referralActivityMode)&&const DeepCollectionEquality().equals(other.roundIntervals, _roundIntervals)&&const DeepCollectionEquality().equals(other.formatConfig, _formatConfig)&&(identical(other.androidStoreUrl, androidStoreUrl) || other.androidStoreUrl == androidStoreUrl)&&(identical(other.iosStoreUrl, iosStoreUrl) || other.iosStoreUrl == iosStoreUrl)&&(identical(other.lastBracketError, lastBracketError) || other.lastBracketError == lastBracketError)&&(identical(other.lastBracketErrorAt, lastBracketErrorAt) || other.lastBracketErrorAt == lastBracketErrorAt)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.pinnedAt, pinnedAt) || other.pinnedAt == pinnedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,name,game,format,startDate,status,maxPlayers,currentPlayers,registrationFee,registrationCurrency,countryCode,commissionPct,prizePoolLocal,commissionXaf,sponsorBonusLocal,description,bannerUrl,registrationOpensAt,registrationClosesAt,endDate,prizePoolCurrency,createdBy,createdAt,updatedAt,orangeMoneyCode,mtnMomoCode,const DeepCollectionEquality().hash(_prizeDistribution),matchIntervalMinutes,autoGenerateBracket,thirdPlaceMatch,referralQuota,referralActivityMode,const DeepCollectionEquality().hash(_roundIntervals),const DeepCollectionEquality().hash(_formatConfig),androidStoreUrl,iosStoreUrl,lastBracketError,lastBracketErrorAt,isPinned,pinnedAt,completedAt,archivedAt]);
}

@override
String toString() {
    return 'Competition(id: $id, name: $name, game: $game, format: $format, startDate: $startDate, status: $status, maxPlayers: $maxPlayers, currentPlayers: $currentPlayers, registrationFee: $registrationFee, registrationCurrency: $registrationCurrency, countryCode: $countryCode, commissionPct: $commissionPct, prizePoolLocal: $prizePoolLocal, commissionXaf: $commissionXaf, sponsorBonusLocal: $sponsorBonusLocal, description: $description, bannerUrl: $bannerUrl, registrationOpensAt: $registrationOpensAt, registrationClosesAt: $registrationClosesAt, endDate: $endDate, prizePoolCurrency: $prizePoolCurrency, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, orangeMoneyCode: $orangeMoneyCode, mtnMomoCode: $mtnMomoCode, prizeDistribution: $prizeDistribution, matchIntervalMinutes: $matchIntervalMinutes, autoGenerateBracket: $autoGenerateBracket, thirdPlaceMatch: $thirdPlaceMatch, referralQuota: $referralQuota, referralActivityMode: $referralActivityMode, roundIntervals: $roundIntervals, formatConfig: $formatConfig, androidStoreUrl: $androidStoreUrl, iosStoreUrl: $iosStoreUrl, lastBracketError: $lastBracketError, lastBracketErrorAt: $lastBracketErrorAt, isPinned: $isPinned, pinnedAt: $pinnedAt, completedAt: $completedAt, archivedAt: $archivedAt)';
}


}

/// @nodoc
abstract mixin class _$CompetitionCopyWith<$Res> implements $CompetitionCopyWith<$Res> {
  factory _$CompetitionCopyWith(_Competition value, $Res Function(_Competition) _then) = __$CompetitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@GameTypeConverter() GameType game,@TournamentFormatConverter() TournamentFormat format, DateTime startDate,@CompetitionStatusConverter() CompetitionStatus status, int maxPlayers, int currentPlayers, double registrationFee, String registrationCurrency, String countryCode, double commissionPct, double prizePoolLocal, double commissionXaf, double sponsorBonusLocal, String? description, String? bannerUrl, DateTime? registrationOpensAt, DateTime? registrationClosesAt, DateTime? endDate, String? prizePoolCurrency, String? createdBy, DateTime? createdAt, DateTime? updatedAt, String? orangeMoneyCode, String? mtnMomoCode, List<int> prizeDistribution, int matchIntervalMinutes, bool autoGenerateBracket, bool thirdPlaceMatch, int referralQuota, String referralActivityMode, List<int>? roundIntervals, Map<String, dynamic> formatConfig, String? androidStoreUrl, String? iosStoreUrl, String? lastBracketError, DateTime? lastBracketErrorAt, bool isPinned, DateTime? pinnedAt, DateTime? completedAt, DateTime? archivedAt
});




}
/// @nodoc
class __$CompetitionCopyWithImpl<$Res>
    implements _$CompetitionCopyWith<$Res> {
  __$CompetitionCopyWithImpl(this._self, this._then);

  final _Competition _self;
  final $Res Function(_Competition) _then;

/// Create a copy of Competition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? game = null,Object? format = null,Object? startDate = null,Object? status = null,Object? maxPlayers = null,Object? currentPlayers = null,Object? registrationFee = null,Object? registrationCurrency = null,Object? countryCode = null,Object? commissionPct = null,Object? prizePoolLocal = null,Object? commissionXaf = null,Object? sponsorBonusLocal = null,Object? description = freezed,Object? bannerUrl = freezed,Object? registrationOpensAt = freezed,Object? registrationClosesAt = freezed,Object? endDate = freezed,Object? prizePoolCurrency = freezed,Object? createdBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? orangeMoneyCode = freezed,Object? mtnMomoCode = freezed,Object? prizeDistribution = null,Object? matchIntervalMinutes = null,Object? autoGenerateBracket = null,Object? thirdPlaceMatch = null,Object? referralQuota = null,Object? referralActivityMode = null,Object? roundIntervals = freezed,Object? formatConfig = null,Object? androidStoreUrl = freezed,Object? iosStoreUrl = freezed,Object? lastBracketError = freezed,Object? lastBracketErrorAt = freezed,Object? isPinned = null,Object? pinnedAt = freezed,Object? completedAt = freezed,Object? archivedAt = freezed,}) {
  return _then(_Competition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,game: null == game ? _self.game : game // ignore: cast_nullable_to_non_nullable
as GameType,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as TournamentFormat,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CompetitionStatus,maxPlayers: null == maxPlayers ? _self.maxPlayers : maxPlayers // ignore: cast_nullable_to_non_nullable
as int,currentPlayers: null == currentPlayers ? _self.currentPlayers : currentPlayers // ignore: cast_nullable_to_non_nullable
as int,registrationFee: null == registrationFee ? _self.registrationFee : registrationFee // ignore: cast_nullable_to_non_nullable
as double,registrationCurrency: null == registrationCurrency ? _self.registrationCurrency : registrationCurrency // ignore: cast_nullable_to_non_nullable
as String,countryCode: null == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String,commissionPct: null == commissionPct ? _self.commissionPct : commissionPct // ignore: cast_nullable_to_non_nullable
as double,prizePoolLocal: null == prizePoolLocal ? _self.prizePoolLocal : prizePoolLocal // ignore: cast_nullable_to_non_nullable
as double,commissionXaf: null == commissionXaf ? _self.commissionXaf : commissionXaf // ignore: cast_nullable_to_non_nullable
as double,sponsorBonusLocal: null == sponsorBonusLocal ? _self.sponsorBonusLocal : sponsorBonusLocal // ignore: cast_nullable_to_non_nullable
as double,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,bannerUrl: freezed == bannerUrl ? _self.bannerUrl : bannerUrl // ignore: cast_nullable_to_non_nullable
as String?,registrationOpensAt: freezed == registrationOpensAt ? _self.registrationOpensAt : registrationOpensAt // ignore: cast_nullable_to_non_nullable
as DateTime?,registrationClosesAt: freezed == registrationClosesAt ? _self.registrationClosesAt : registrationClosesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,prizePoolCurrency: freezed == prizePoolCurrency ? _self.prizePoolCurrency : prizePoolCurrency // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,orangeMoneyCode: freezed == orangeMoneyCode ? _self.orangeMoneyCode : orangeMoneyCode // ignore: cast_nullable_to_non_nullable
as String?,mtnMomoCode: freezed == mtnMomoCode ? _self.mtnMomoCode : mtnMomoCode // ignore: cast_nullable_to_non_nullable
as String?,prizeDistribution: null == prizeDistribution ? _self._prizeDistribution : prizeDistribution // ignore: cast_nullable_to_non_nullable
as List<int>,matchIntervalMinutes: null == matchIntervalMinutes ? _self.matchIntervalMinutes : matchIntervalMinutes // ignore: cast_nullable_to_non_nullable
as int,autoGenerateBracket: null == autoGenerateBracket ? _self.autoGenerateBracket : autoGenerateBracket // ignore: cast_nullable_to_non_nullable
as bool,thirdPlaceMatch: null == thirdPlaceMatch ? _self.thirdPlaceMatch : thirdPlaceMatch // ignore: cast_nullable_to_non_nullable
as bool,referralQuota: null == referralQuota ? _self.referralQuota : referralQuota // ignore: cast_nullable_to_non_nullable
as int,referralActivityMode: null == referralActivityMode ? _self.referralActivityMode : referralActivityMode // ignore: cast_nullable_to_non_nullable
as String,roundIntervals: freezed == roundIntervals ? _self._roundIntervals : roundIntervals // ignore: cast_nullable_to_non_nullable
as List<int>?,formatConfig: null == formatConfig ? _self._formatConfig : formatConfig // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,androidStoreUrl: freezed == androidStoreUrl ? _self.androidStoreUrl : androidStoreUrl // ignore: cast_nullable_to_non_nullable
as String?,iosStoreUrl: freezed == iosStoreUrl ? _self.iosStoreUrl : iosStoreUrl // ignore: cast_nullable_to_non_nullable
as String?,lastBracketError: freezed == lastBracketError ? _self.lastBracketError : lastBracketError // ignore: cast_nullable_to_non_nullable
as String?,lastBracketErrorAt: freezed == lastBracketErrorAt ? _self.lastBracketErrorAt : lastBracketErrorAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,pinnedAt: freezed == pinnedAt ? _self.pinnedAt : pinnedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
