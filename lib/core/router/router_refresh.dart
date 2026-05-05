import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bridges a list of Riverpod providers into a [Listenable] that
/// `GoRouter.refreshListenable` understands.
///
/// Whenever any of the watched providers emits a new value, the router
/// is told to re-evaluate `redirect` (and route guards downstream).
class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable(this._ref, this._providers) {
    for (final p in _providers) {
      _subs.add(_ref.listen<Object?>(p, (_, __) => notifyListeners()));
    }
  }

  final Ref _ref;
  final List<ProviderListenable<Object?>> _providers;
  final List<ProviderSubscription<Object?>> _subs = [];

  @override
  void dispose() {
    for (final s in _subs) {
      s.close();
    }
    super.dispose();
  }
}
