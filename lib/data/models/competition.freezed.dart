// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'competition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Competition _$CompetitionFromJson(Map<String, dynamic> json) {
  return _Competition.fromJson(json);
}

/// @nodoc
mixin _$Competition {
// ─── required ──────────────────────────────────────────────────────────
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @GameTypeConverter()
  GameType get game => throw _privateConstructorUsedError;
  @TournamentFormatConverter()
  TournamentFormat get format => throw _privateConstructorUsedError;
  DateTime get startDate =>
      throw _privateConstructorUsedError; // ─── defaults ──────────────────────────────────────────────────────────
  @CompetitionStatusConverter()
  CompetitionStatus get status => throw _privateConstructorUsedError;
  int get maxPlayers => throw _privateConstructorUsedError;
  int get currentPlayers => throw _privateConstructorUsedError;
  double get registrationFee => throw _privateConstructorUsedError;
  String get registrationCurrency => throw _privateConstructorUsedError;
  double get commissionPct => throw _privateConstructorUsedError;
  double get prizePoolLocal => throw _privateConstructorUsedError;
  double get commissionXaf => throw _privateConstructorUsedError;
  double get sponsorBonusLocal =>
      throw _privateConstructorUsedError; // ─── optional / nullable ───────────────────────────────────────────────
  String? get description => throw _privateConstructorUsedError;
  String? get bannerUrl => throw _privateConstructorUsedError;
  DateTime? get registrationOpensAt => throw _privateConstructorUsedError;
  DateTime? get registrationClosesAt => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  String? get prizePoolCurrency => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Merchant codes saisis par l'admin créateur — affichés sur P2
  /// quand le joueur choisit la méthode correspondante. PHASE 11bis.
  String? get orangeMoneyCode => throw _privateConstructorUsedError;
  String? get mtnMomoCode => throw _privateConstructorUsedError;

  /// Répartition des gains par rang d'arrivée, en **montants** (monnaie
  /// locale, ex. `[100000, 50000, 25000, 10000]`). Saisie dans le
  /// wizard admin ; `prizePoolLocal` en est la somme.
  List<int> get prizeDistribution => throw _privateConstructorUsedError;

  /// Minutes entre la fin d'un round et le scheduled_at du round suivant
  /// (Lot A — auto-management). Typiquement 30/60/120/240/1440.
  /// Le trigger DB `try_schedule_next_round` lit cette valeur.
  int get matchIntervalMinutes => throw _privateConstructorUsedError;

  /// Si vrai, le bracket est généré automatiquement dès que max_players
  /// est atteint. V1 : single_elimination uniquement. Le trigger DB
  /// `trigger_auto_generate_bracket` consume ce flag.
  bool get autoGenerateBracket => throw _privateConstructorUsedError;

  /// Lot D — quota de parrainages requis avant qu'un joueur puisse
  /// s'inscrire. 0 = pas de gating (la majorité des comp.). Utilisé
  /// uniquement pour les comp. gratuites avec récompense (variante
  /// « invite N amis pour t'inscrire »). Trigger DB
  /// `enforce_referral_quota_on_registration` consume cette colonne.
  int get referralQuota => throw _privateConstructorUsedError;

  /// Serializes this Competition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Competition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompetitionCopyWith<Competition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompetitionCopyWith<$Res> {
  factory $CompetitionCopyWith(
          Competition value, $Res Function(Competition) then) =
      _$CompetitionCopyWithImpl<$Res, Competition>;
  @useResult
  $Res call(
      {String id,
      String name,
      @GameTypeConverter() GameType game,
      @TournamentFormatConverter() TournamentFormat format,
      DateTime startDate,
      @CompetitionStatusConverter() CompetitionStatus status,
      int maxPlayers,
      int currentPlayers,
      double registrationFee,
      String registrationCurrency,
      double commissionPct,
      double prizePoolLocal,
      double commissionXaf,
      double sponsorBonusLocal,
      String? description,
      String? bannerUrl,
      DateTime? registrationOpensAt,
      DateTime? registrationClosesAt,
      DateTime? endDate,
      String? prizePoolCurrency,
      String? createdBy,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? orangeMoneyCode,
      String? mtnMomoCode,
      List<int> prizeDistribution,
      int matchIntervalMinutes,
      bool autoGenerateBracket,
      int referralQuota});
}

/// @nodoc
class _$CompetitionCopyWithImpl<$Res, $Val extends Competition>
    implements $CompetitionCopyWith<$Res> {
  _$CompetitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Competition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? game = null,
    Object? format = null,
    Object? startDate = null,
    Object? status = null,
    Object? maxPlayers = null,
    Object? currentPlayers = null,
    Object? registrationFee = null,
    Object? registrationCurrency = null,
    Object? commissionPct = null,
    Object? prizePoolLocal = null,
    Object? commissionXaf = null,
    Object? sponsorBonusLocal = null,
    Object? description = freezed,
    Object? bannerUrl = freezed,
    Object? registrationOpensAt = freezed,
    Object? registrationClosesAt = freezed,
    Object? endDate = freezed,
    Object? prizePoolCurrency = freezed,
    Object? createdBy = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? orangeMoneyCode = freezed,
    Object? mtnMomoCode = freezed,
    Object? prizeDistribution = null,
    Object? matchIntervalMinutes = null,
    Object? autoGenerateBracket = null,
    Object? referralQuota = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      game: null == game
          ? _value.game
          : game // ignore: cast_nullable_to_non_nullable
              as GameType,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as TournamentFormat,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as CompetitionStatus,
      maxPlayers: null == maxPlayers
          ? _value.maxPlayers
          : maxPlayers // ignore: cast_nullable_to_non_nullable
              as int,
      currentPlayers: null == currentPlayers
          ? _value.currentPlayers
          : currentPlayers // ignore: cast_nullable_to_non_nullable
              as int,
      registrationFee: null == registrationFee
          ? _value.registrationFee
          : registrationFee // ignore: cast_nullable_to_non_nullable
              as double,
      registrationCurrency: null == registrationCurrency
          ? _value.registrationCurrency
          : registrationCurrency // ignore: cast_nullable_to_non_nullable
              as String,
      commissionPct: null == commissionPct
          ? _value.commissionPct
          : commissionPct // ignore: cast_nullable_to_non_nullable
              as double,
      prizePoolLocal: null == prizePoolLocal
          ? _value.prizePoolLocal
          : prizePoolLocal // ignore: cast_nullable_to_non_nullable
              as double,
      commissionXaf: null == commissionXaf
          ? _value.commissionXaf
          : commissionXaf // ignore: cast_nullable_to_non_nullable
              as double,
      sponsorBonusLocal: null == sponsorBonusLocal
          ? _value.sponsorBonusLocal
          : sponsorBonusLocal // ignore: cast_nullable_to_non_nullable
              as double,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      bannerUrl: freezed == bannerUrl
          ? _value.bannerUrl
          : bannerUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      registrationOpensAt: freezed == registrationOpensAt
          ? _value.registrationOpensAt
          : registrationOpensAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      registrationClosesAt: freezed == registrationClosesAt
          ? _value.registrationClosesAt
          : registrationClosesAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      prizePoolCurrency: freezed == prizePoolCurrency
          ? _value.prizePoolCurrency
          : prizePoolCurrency // ignore: cast_nullable_to_non_nullable
              as String?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      orangeMoneyCode: freezed == orangeMoneyCode
          ? _value.orangeMoneyCode
          : orangeMoneyCode // ignore: cast_nullable_to_non_nullable
              as String?,
      mtnMomoCode: freezed == mtnMomoCode
          ? _value.mtnMomoCode
          : mtnMomoCode // ignore: cast_nullable_to_non_nullable
              as String?,
      prizeDistribution: null == prizeDistribution
          ? _value.prizeDistribution
          : prizeDistribution // ignore: cast_nullable_to_non_nullable
              as List<int>,
      matchIntervalMinutes: null == matchIntervalMinutes
          ? _value.matchIntervalMinutes
          : matchIntervalMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      autoGenerateBracket: null == autoGenerateBracket
          ? _value.autoGenerateBracket
          : autoGenerateBracket // ignore: cast_nullable_to_non_nullable
              as bool,
      referralQuota: null == referralQuota
          ? _value.referralQuota
          : referralQuota // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CompetitionImplCopyWith<$Res>
    implements $CompetitionCopyWith<$Res> {
  factory _$$CompetitionImplCopyWith(
          _$CompetitionImpl value, $Res Function(_$CompetitionImpl) then) =
      __$$CompetitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      @GameTypeConverter() GameType game,
      @TournamentFormatConverter() TournamentFormat format,
      DateTime startDate,
      @CompetitionStatusConverter() CompetitionStatus status,
      int maxPlayers,
      int currentPlayers,
      double registrationFee,
      String registrationCurrency,
      double commissionPct,
      double prizePoolLocal,
      double commissionXaf,
      double sponsorBonusLocal,
      String? description,
      String? bannerUrl,
      DateTime? registrationOpensAt,
      DateTime? registrationClosesAt,
      DateTime? endDate,
      String? prizePoolCurrency,
      String? createdBy,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? orangeMoneyCode,
      String? mtnMomoCode,
      List<int> prizeDistribution,
      int matchIntervalMinutes,
      bool autoGenerateBracket,
      int referralQuota});
}

/// @nodoc
class __$$CompetitionImplCopyWithImpl<$Res>
    extends _$CompetitionCopyWithImpl<$Res, _$CompetitionImpl>
    implements _$$CompetitionImplCopyWith<$Res> {
  __$$CompetitionImplCopyWithImpl(
      _$CompetitionImpl _value, $Res Function(_$CompetitionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Competition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? game = null,
    Object? format = null,
    Object? startDate = null,
    Object? status = null,
    Object? maxPlayers = null,
    Object? currentPlayers = null,
    Object? registrationFee = null,
    Object? registrationCurrency = null,
    Object? commissionPct = null,
    Object? prizePoolLocal = null,
    Object? commissionXaf = null,
    Object? sponsorBonusLocal = null,
    Object? description = freezed,
    Object? bannerUrl = freezed,
    Object? registrationOpensAt = freezed,
    Object? registrationClosesAt = freezed,
    Object? endDate = freezed,
    Object? prizePoolCurrency = freezed,
    Object? createdBy = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? orangeMoneyCode = freezed,
    Object? mtnMomoCode = freezed,
    Object? prizeDistribution = null,
    Object? matchIntervalMinutes = null,
    Object? autoGenerateBracket = null,
    Object? referralQuota = null,
  }) {
    return _then(_$CompetitionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      game: null == game
          ? _value.game
          : game // ignore: cast_nullable_to_non_nullable
              as GameType,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as TournamentFormat,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as CompetitionStatus,
      maxPlayers: null == maxPlayers
          ? _value.maxPlayers
          : maxPlayers // ignore: cast_nullable_to_non_nullable
              as int,
      currentPlayers: null == currentPlayers
          ? _value.currentPlayers
          : currentPlayers // ignore: cast_nullable_to_non_nullable
              as int,
      registrationFee: null == registrationFee
          ? _value.registrationFee
          : registrationFee // ignore: cast_nullable_to_non_nullable
              as double,
      registrationCurrency: null == registrationCurrency
          ? _value.registrationCurrency
          : registrationCurrency // ignore: cast_nullable_to_non_nullable
              as String,
      commissionPct: null == commissionPct
          ? _value.commissionPct
          : commissionPct // ignore: cast_nullable_to_non_nullable
              as double,
      prizePoolLocal: null == prizePoolLocal
          ? _value.prizePoolLocal
          : prizePoolLocal // ignore: cast_nullable_to_non_nullable
              as double,
      commissionXaf: null == commissionXaf
          ? _value.commissionXaf
          : commissionXaf // ignore: cast_nullable_to_non_nullable
              as double,
      sponsorBonusLocal: null == sponsorBonusLocal
          ? _value.sponsorBonusLocal
          : sponsorBonusLocal // ignore: cast_nullable_to_non_nullable
              as double,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      bannerUrl: freezed == bannerUrl
          ? _value.bannerUrl
          : bannerUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      registrationOpensAt: freezed == registrationOpensAt
          ? _value.registrationOpensAt
          : registrationOpensAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      registrationClosesAt: freezed == registrationClosesAt
          ? _value.registrationClosesAt
          : registrationClosesAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      prizePoolCurrency: freezed == prizePoolCurrency
          ? _value.prizePoolCurrency
          : prizePoolCurrency // ignore: cast_nullable_to_non_nullable
              as String?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      orangeMoneyCode: freezed == orangeMoneyCode
          ? _value.orangeMoneyCode
          : orangeMoneyCode // ignore: cast_nullable_to_non_nullable
              as String?,
      mtnMomoCode: freezed == mtnMomoCode
          ? _value.mtnMomoCode
          : mtnMomoCode // ignore: cast_nullable_to_non_nullable
              as String?,
      prizeDistribution: null == prizeDistribution
          ? _value._prizeDistribution
          : prizeDistribution // ignore: cast_nullable_to_non_nullable
              as List<int>,
      matchIntervalMinutes: null == matchIntervalMinutes
          ? _value.matchIntervalMinutes
          : matchIntervalMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      autoGenerateBracket: null == autoGenerateBracket
          ? _value.autoGenerateBracket
          : autoGenerateBracket // ignore: cast_nullable_to_non_nullable
              as bool,
      referralQuota: null == referralQuota
          ? _value.referralQuota
          : referralQuota // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CompetitionImpl extends _Competition {
  const _$CompetitionImpl(
      {required this.id,
      required this.name,
      @GameTypeConverter() required this.game,
      @TournamentFormatConverter() required this.format,
      required this.startDate,
      @CompetitionStatusConverter() this.status = CompetitionStatus.draft,
      this.maxPlayers = 2,
      this.currentPlayers = 0,
      this.registrationFee = 0,
      this.registrationCurrency = 'XAF',
      this.commissionPct = 10,
      this.prizePoolLocal = 0,
      this.commissionXaf = 0,
      this.sponsorBonusLocal = 0,
      this.description,
      this.bannerUrl,
      this.registrationOpensAt,
      this.registrationClosesAt,
      this.endDate,
      this.prizePoolCurrency,
      this.createdBy,
      this.createdAt,
      this.updatedAt,
      this.orangeMoneyCode,
      this.mtnMomoCode,
      final List<int> prizeDistribution = const <int>[0, 0, 0, 0],
      this.matchIntervalMinutes = 60,
      this.autoGenerateBracket = true,
      this.referralQuota = 0})
      : _prizeDistribution = prizeDistribution,
        super._();

  factory _$CompetitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompetitionImplFromJson(json);

// ─── required ──────────────────────────────────────────────────────────
  @override
  final String id;
  @override
  final String name;
  @override
  @GameTypeConverter()
  final GameType game;
  @override
  @TournamentFormatConverter()
  final TournamentFormat format;
  @override
  final DateTime startDate;
// ─── defaults ──────────────────────────────────────────────────────────
  @override
  @JsonKey()
  @CompetitionStatusConverter()
  final CompetitionStatus status;
  @override
  @JsonKey()
  final int maxPlayers;
  @override
  @JsonKey()
  final int currentPlayers;
  @override
  @JsonKey()
  final double registrationFee;
  @override
  @JsonKey()
  final String registrationCurrency;
  @override
  @JsonKey()
  final double commissionPct;
  @override
  @JsonKey()
  final double prizePoolLocal;
  @override
  @JsonKey()
  final double commissionXaf;
  @override
  @JsonKey()
  final double sponsorBonusLocal;
// ─── optional / nullable ───────────────────────────────────────────────
  @override
  final String? description;
  @override
  final String? bannerUrl;
  @override
  final DateTime? registrationOpensAt;
  @override
  final DateTime? registrationClosesAt;
  @override
  final DateTime? endDate;
  @override
  final String? prizePoolCurrency;
  @override
  final String? createdBy;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  /// Merchant codes saisis par l'admin créateur — affichés sur P2
  /// quand le joueur choisit la méthode correspondante. PHASE 11bis.
  @override
  final String? orangeMoneyCode;
  @override
  final String? mtnMomoCode;

  /// Répartition des gains par rang d'arrivée, en **montants** (monnaie
  /// locale, ex. `[100000, 50000, 25000, 10000]`). Saisie dans le
  /// wizard admin ; `prizePoolLocal` en est la somme.
  final List<int> _prizeDistribution;

  /// Répartition des gains par rang d'arrivée, en **montants** (monnaie
  /// locale, ex. `[100000, 50000, 25000, 10000]`). Saisie dans le
  /// wizard admin ; `prizePoolLocal` en est la somme.
  @override
  @JsonKey()
  List<int> get prizeDistribution {
    if (_prizeDistribution is EqualUnmodifiableListView)
      return _prizeDistribution;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_prizeDistribution);
  }

  /// Minutes entre la fin d'un round et le scheduled_at du round suivant
  /// (Lot A — auto-management). Typiquement 30/60/120/240/1440.
  /// Le trigger DB `try_schedule_next_round` lit cette valeur.
  @override
  @JsonKey()
  final int matchIntervalMinutes;

  /// Si vrai, le bracket est généré automatiquement dès que max_players
  /// est atteint. V1 : single_elimination uniquement. Le trigger DB
  /// `trigger_auto_generate_bracket` consume ce flag.
  @override
  @JsonKey()
  final bool autoGenerateBracket;

  /// Lot D — quota de parrainages requis avant qu'un joueur puisse
  /// s'inscrire. 0 = pas de gating (la majorité des comp.). Utilisé
  /// uniquement pour les comp. gratuites avec récompense (variante
  /// « invite N amis pour t'inscrire »). Trigger DB
  /// `enforce_referral_quota_on_registration` consume cette colonne.
  @override
  @JsonKey()
  final int referralQuota;

  @override
  String toString() {
    return 'Competition(id: $id, name: $name, game: $game, format: $format, startDate: $startDate, status: $status, maxPlayers: $maxPlayers, currentPlayers: $currentPlayers, registrationFee: $registrationFee, registrationCurrency: $registrationCurrency, commissionPct: $commissionPct, prizePoolLocal: $prizePoolLocal, commissionXaf: $commissionXaf, sponsorBonusLocal: $sponsorBonusLocal, description: $description, bannerUrl: $bannerUrl, registrationOpensAt: $registrationOpensAt, registrationClosesAt: $registrationClosesAt, endDate: $endDate, prizePoolCurrency: $prizePoolCurrency, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, orangeMoneyCode: $orangeMoneyCode, mtnMomoCode: $mtnMomoCode, prizeDistribution: $prizeDistribution, matchIntervalMinutes: $matchIntervalMinutes, autoGenerateBracket: $autoGenerateBracket, referralQuota: $referralQuota)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompetitionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.game, game) || other.game == game) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.maxPlayers, maxPlayers) ||
                other.maxPlayers == maxPlayers) &&
            (identical(other.currentPlayers, currentPlayers) ||
                other.currentPlayers == currentPlayers) &&
            (identical(other.registrationFee, registrationFee) ||
                other.registrationFee == registrationFee) &&
            (identical(other.registrationCurrency, registrationCurrency) ||
                other.registrationCurrency == registrationCurrency) &&
            (identical(other.commissionPct, commissionPct) ||
                other.commissionPct == commissionPct) &&
            (identical(other.prizePoolLocal, prizePoolLocal) ||
                other.prizePoolLocal == prizePoolLocal) &&
            (identical(other.commissionXaf, commissionXaf) ||
                other.commissionXaf == commissionXaf) &&
            (identical(other.sponsorBonusLocal, sponsorBonusLocal) ||
                other.sponsorBonusLocal == sponsorBonusLocal) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.bannerUrl, bannerUrl) ||
                other.bannerUrl == bannerUrl) &&
            (identical(other.registrationOpensAt, registrationOpensAt) ||
                other.registrationOpensAt == registrationOpensAt) &&
            (identical(other.registrationClosesAt, registrationClosesAt) ||
                other.registrationClosesAt == registrationClosesAt) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.prizePoolCurrency, prizePoolCurrency) ||
                other.prizePoolCurrency == prizePoolCurrency) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.orangeMoneyCode, orangeMoneyCode) ||
                other.orangeMoneyCode == orangeMoneyCode) &&
            (identical(other.mtnMomoCode, mtnMomoCode) ||
                other.mtnMomoCode == mtnMomoCode) &&
            const DeepCollectionEquality()
                .equals(other._prizeDistribution, _prizeDistribution) &&
            (identical(other.matchIntervalMinutes, matchIntervalMinutes) ||
                other.matchIntervalMinutes == matchIntervalMinutes) &&
            (identical(other.autoGenerateBracket, autoGenerateBracket) ||
                other.autoGenerateBracket == autoGenerateBracket) &&
            (identical(other.referralQuota, referralQuota) ||
                other.referralQuota == referralQuota));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        game,
        format,
        startDate,
        status,
        maxPlayers,
        currentPlayers,
        registrationFee,
        registrationCurrency,
        commissionPct,
        prizePoolLocal,
        commissionXaf,
        sponsorBonusLocal,
        description,
        bannerUrl,
        registrationOpensAt,
        registrationClosesAt,
        endDate,
        prizePoolCurrency,
        createdBy,
        createdAt,
        updatedAt,
        orangeMoneyCode,
        mtnMomoCode,
        const DeepCollectionEquality().hash(_prizeDistribution),
        matchIntervalMinutes,
        autoGenerateBracket,
        referralQuota
      ]);

  /// Create a copy of Competition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompetitionImplCopyWith<_$CompetitionImpl> get copyWith =>
      __$$CompetitionImplCopyWithImpl<_$CompetitionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompetitionImplToJson(
      this,
    );
  }
}

abstract class _Competition extends Competition {
  const factory _Competition(
      {required final String id,
      required final String name,
      @GameTypeConverter() required final GameType game,
      @TournamentFormatConverter() required final TournamentFormat format,
      required final DateTime startDate,
      @CompetitionStatusConverter() final CompetitionStatus status,
      final int maxPlayers,
      final int currentPlayers,
      final double registrationFee,
      final String registrationCurrency,
      final double commissionPct,
      final double prizePoolLocal,
      final double commissionXaf,
      final double sponsorBonusLocal,
      final String? description,
      final String? bannerUrl,
      final DateTime? registrationOpensAt,
      final DateTime? registrationClosesAt,
      final DateTime? endDate,
      final String? prizePoolCurrency,
      final String? createdBy,
      final DateTime? createdAt,
      final DateTime? updatedAt,
      final String? orangeMoneyCode,
      final String? mtnMomoCode,
      final List<int> prizeDistribution,
      final int matchIntervalMinutes,
      final bool autoGenerateBracket,
      final int referralQuota}) = _$CompetitionImpl;
  const _Competition._() : super._();

  factory _Competition.fromJson(Map<String, dynamic> json) =
      _$CompetitionImpl.fromJson;

// ─── required ──────────────────────────────────────────────────────────
  @override
  String get id;
  @override
  String get name;
  @override
  @GameTypeConverter()
  GameType get game;
  @override
  @TournamentFormatConverter()
  TournamentFormat get format;
  @override
  DateTime
      get startDate; // ─── defaults ──────────────────────────────────────────────────────────
  @override
  @CompetitionStatusConverter()
  CompetitionStatus get status;
  @override
  int get maxPlayers;
  @override
  int get currentPlayers;
  @override
  double get registrationFee;
  @override
  String get registrationCurrency;
  @override
  double get commissionPct;
  @override
  double get prizePoolLocal;
  @override
  double get commissionXaf;
  @override
  double
      get sponsorBonusLocal; // ─── optional / nullable ───────────────────────────────────────────────
  @override
  String? get description;
  @override
  String? get bannerUrl;
  @override
  DateTime? get registrationOpensAt;
  @override
  DateTime? get registrationClosesAt;
  @override
  DateTime? get endDate;
  @override
  String? get prizePoolCurrency;
  @override
  String? get createdBy;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Merchant codes saisis par l'admin créateur — affichés sur P2
  /// quand le joueur choisit la méthode correspondante. PHASE 11bis.
  @override
  String? get orangeMoneyCode;
  @override
  String? get mtnMomoCode;

  /// Répartition des gains par rang d'arrivée, en **montants** (monnaie
  /// locale, ex. `[100000, 50000, 25000, 10000]`). Saisie dans le
  /// wizard admin ; `prizePoolLocal` en est la somme.
  @override
  List<int> get prizeDistribution;

  /// Minutes entre la fin d'un round et le scheduled_at du round suivant
  /// (Lot A — auto-management). Typiquement 30/60/120/240/1440.
  /// Le trigger DB `try_schedule_next_round` lit cette valeur.
  @override
  int get matchIntervalMinutes;

  /// Si vrai, le bracket est généré automatiquement dès que max_players
  /// est atteint. V1 : single_elimination uniquement. Le trigger DB
  /// `trigger_auto_generate_bracket` consume ce flag.
  @override
  bool get autoGenerateBracket;

  /// Lot D — quota de parrainages requis avant qu'un joueur puisse
  /// s'inscrire. 0 = pas de gating (la majorité des comp.). Utilisé
  /// uniquement pour les comp. gratuites avec récompense (variante
  /// « invite N amis pour t'inscrire »). Trigger DB
  /// `enforce_referral_quota_on_registration` consume cette colonne.
  @override
  int get referralQuota;

  /// Create a copy of Competition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompetitionImplCopyWith<_$CompetitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
