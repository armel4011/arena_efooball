import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mocks Supabase partagés par les tests de repositories.
///
/// Le builder PostgREST est une chaîne fluide (`from().select().eq()...`)
/// dont chaque maillon renvoie un builder, le dernier étant un `Future`.
/// [FakeQueryChain] modélise ça : toutes les méthodes de chaînage
/// renvoient un maillon (souvent `this`), et l'`await` final est résolu
/// par le `Future` fourni à la construction.
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

/// Branche `client.from(table)` sur une chaîne dont l'`await` final renvoie
/// [result]. Renvoie le [QueryProbe] partagé pour asserter colonnes/filtres.
///
/// On expose le probe (et non le builder) car [SupabaseQueryBuilder] est lui
/// même un `Future` → le renvoyer déclencherait `unawaited_futures`.
QueryProbe stubFrom(MockSupabaseClient client, String table, Object? result) {
  final from = FakeFromBuilder(Future<dynamic>.value(result));
  when(() => client.from(table)).thenAnswer((_) => from);
  return from.probe;
}

/// Variante séquentielle : chaque appel successif à `client.from(table)`
/// renvoie le résultat suivant de [results] (le dernier est répété). Utile
/// quand un repo interroge la même table plusieurs fois (ex. read-then-insert).
void stubFromQueue(
  MockSupabaseClient client,
  String table,
  List<Object?> results,
) {
  var i = 0;
  when(() => client.from(table)).thenAnswer((_) {
    final r = results[i < results.length ? i : results.length - 1];
    i++;
    return FakeFromBuilder(Future<dynamic>.value(r));
  });
}

/// Branche `client.auth.currentUser` sur un user d'id [userId] (ou `null`).
void stubAuthUser(MockSupabaseClient client, String? userId) {
  final auth = MockGoTrueClient();
  when(() => client.auth).thenReturn(auth);
  if (userId == null) {
    when(() => auth.currentUser).thenReturn(null);
  } else {
    final user = MockUser();
    when(() => user.id).thenReturn(userId);
    when(() => auth.currentUser).thenReturn(user);
  }
}

/// État partagé entre tous les maillons d'une même chaîne — permet
/// d'inspecter colonnes/filtres quel que soit le maillon retourné.
class QueryProbe {
  /// Colonnes passées au dernier `.select(...)` (`*` par défaut).
  String? selectedColumns;

  /// Valeurs passées au dernier `insert(...)` (pour asserter le payload).
  Object? insertedValues;

  /// Valeurs passées au dernier `upsert(...)`.
  Object? upsertedValues;

  /// Valeurs passées au dernier `update(...)`.
  Map<dynamic, dynamic>? updatedValues;

  /// Filtres appliqués, sous forme lisible `op:column=value`.
  final List<String> filters = <String>[];

  void record(String op, String column, Object? value) {
    filters.add('$op:$column=$value');
  }

  bool hasFilter(String op, String column) =>
      filters.any((f) => f.startsWith('$op:$column='));
}

/// Un maillon de chaîne PostgREST générique sur [T] (le type de payload
/// que l'`await` renverra). Les transitions de type de la vraie API
/// (`select` → `FilterBuilder<List>`, `maybeSingle` → `TransformBuilder<Map?>`)
/// sont rendues en créant un nouveau maillon typé qui partage le même
/// [probe] et le même `Future` résultat.
class FakeQueryChain<T> extends Fake implements PostgrestFilterBuilder<T> {
  FakeQueryChain(this._result, [QueryProbe? probe])
      : probe = probe ?? QueryProbe();

  final Future<dynamic> _result;
  final QueryProbe probe;

  String? get selectedColumns => probe.selectedColumns;
  List<String> get filters => probe.filters;
  bool hasFilter(String op, String column) => probe.hasFilter(op, column);

  FakeQueryChain<U> _retype<U>() => FakeQueryChain<U>(_result, probe);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    probe.selectedColumns = columns;
    return _retype<List<Map<String, dynamic>>>();
  }

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) {
    probe.record('eq', column, value);
    return this;
  }

  @override
  PostgrestFilterBuilder<T> neq(String column, Object value) {
    probe.record('neq', column, value);
    return this;
  }

  @override
  PostgrestFilterBuilder<T> ilike(String column, String pattern) {
    probe.record('ilike', column, pattern);
    return this;
  }

  @override
  PostgrestFilterBuilder<T> gte(String column, Object value) {
    probe.record('gte', column, value);
    return this;
  }

  @override
  PostgrestFilterBuilder<T> inFilter(String column, List<Object?> values) {
    probe.record('in', column, values);
    return this;
  }

  @override
  PostgrestFilterBuilder<T> or(String filters, {String? referencedTable}) {
    probe.record('or', filters, null);
    return this;
  }

  @override
  PostgrestFilterBuilder<T> not(String column, String operator, Object? value) {
    probe.record('not', column, '$operator:$value');
    return this;
  }

  @override
  PostgrestFilterBuilder<T> isFilter(String column, Object? value) {
    probe.record('is', column, value);
    return this;
  }

  @override
  PostgrestTransformBuilder<T> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    probe.record('order', column, ascending);
    return this;
  }

  @override
  PostgrestTransformBuilder<T> limit(int count, {String? referencedTable}) {
    probe.record('limit', '_', count);
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    probe.record('maybeSingle', '_', null);
    return _retype<Map<String, dynamic>?>();
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    probe.record('single', '_', null);
    return _retype<Map<String, dynamic>>();
  }

  // ── Fin de chaîne awaitée → délègue au Future préparé. ──
  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return _result.then(
      (dynamic v) => onValue(v as T),
      onError: onError,
    );
  }

  @override
  Stream<T> asStream() => _result.asStream().cast<T>();

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    return _result.then((dynamic v) => v as T).catchError(onError, test: test);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return _result.then((dynamic v) => v as T).whenComplete(action);
  }
}

/// Branche `client.from(table).stream(primaryKey: …)` sur un flux contrôlé
/// d'événements Realtime (chaque événement est la liste complète des rows,
/// comme le vrai builder Supabase). Renvoie le [StreamProbe] partagé pour
/// asserter le primaryKey et le filtre `.eq()` appliqués.
StreamProbe stubStream(
  MockSupabaseClient client,
  String table,
  Stream<List<Map<String, dynamic>>> events,
) {
  final from = FakeStreamFromBuilder(events);
  when(() => client.from(table)).thenAnswer((_) => from);
  return from.streamProbe;
}

/// Inspecte les paramètres passés à `.stream()` / `.eq()`.
class StreamProbe {
  List<String>? primaryKey;
  String? eqColumn;
  Object? eqValue;
}

/// Maillon `from(table).stream(...)` — émule [SupabaseStreamFilterBuilder].
/// `.eq()` renvoie un [SupabaseStreamBuilder] qui EST un `Stream`, donc le
/// `.map(...)` du repo s'applique nativement dessus.
class FakeStreamFromBuilder extends Fake implements SupabaseQueryBuilder {
  FakeStreamFromBuilder(this._events) : streamProbe = StreamProbe();

  final Stream<List<Map<String, dynamic>>> _events;
  final StreamProbe streamProbe;

  @override
  SupabaseStreamFilterBuilder stream({required List<String> primaryKey}) {
    streamProbe.primaryKey = primaryKey;
    return FakeStreamFilterBuilder(_events, streamProbe);
  }
}

class FakeStreamFilterBuilder extends Fake
    implements SupabaseStreamFilterBuilder {
  FakeStreamFilterBuilder(this._events, this._probe);

  final Stream<List<Map<String, dynamic>>> _events;
  final StreamProbe _probe;

  @override
  SupabaseStreamBuilder eq(String column, Object value) {
    _probe
      ..eqColumn = column
      ..eqValue = value;
    return FakeStreamBuilder(_events);
  }

  @override
  SupabaseStreamBuilder order(String column, {bool ascending = false}) {
    return FakeStreamBuilder(_events);
  }
}

/// [SupabaseStreamBuilder] étant un `Stream<SupabaseStreamEvent>`, on délègue
/// les opérateurs de flux utilisés par les repos (`map`, `listen`) au flux de
/// test fourni.
class FakeStreamBuilder extends Fake implements SupabaseStreamBuilder {
  FakeStreamBuilder(this._events);

  final Stream<List<Map<String, dynamic>>> _events;

  @override
  Stream<S> map<S>(S Function(List<Map<String, dynamic>> event) convert) =>
      _events.map(convert);

  @override
  StreamSubscription<List<Map<String, dynamic>>> listen(
    void Function(List<Map<String, dynamic>> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _events.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

/// Niveau `from(table)` : implémente [SupabaseQueryBuilder]. Les verbes
/// `select`/`insert`/`update`/`delete` renvoient un maillon partageant le
/// même [probe] et le même `Future` de résultat.
class FakeFromBuilder extends Fake implements SupabaseQueryBuilder {
  FakeFromBuilder(this._result) : probe = QueryProbe();

  final Future<dynamic> _result;
  final QueryProbe probe;

  FakeQueryChain<U> _chain<U>() => FakeQueryChain<U>(_result, probe);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    probe.selectedColumns = columns;
    return _chain<List<Map<String, dynamic>>>();
  }

  @override
  PostgrestFilterBuilder<dynamic> insert(
    Object values, {
    bool defaultToNull = true,
  }) {
    probe.insertedValues = values;
    return _chain<dynamic>();
  }

  @override
  PostgrestFilterBuilder<dynamic> update(Map<dynamic, dynamic> values) {
    probe.updatedValues = values;
    return _chain<dynamic>();
  }

  @override
  PostgrestFilterBuilder<dynamic> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    probe.upsertedValues = values;
    return _chain<dynamic>();
  }

  @override
  PostgrestFilterBuilder<dynamic> delete() => _chain<dynamic>();
}
