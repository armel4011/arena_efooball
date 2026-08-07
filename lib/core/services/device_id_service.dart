import 'dart:io';

import 'package:android_id/android_id.dart';

/// Empreinte d'appareil (Settings.Secure.ANDROID_ID) — anti-faux-comptes à
/// l'inscription (max 5 comptes/appareil + blocage auto-parrainage). Stable
/// à travers les réinstallations pour une même clé de signature.
///
/// Renvoie `null` hors Android ou si l'ID n'est pas disponible : dans ce cas
/// aucune garde n'est appliquée (on ne bloque jamais une inscription faute
/// d'empreinte — c'est un signal, pas un mur).
Future<String?> readDeviceId() async {
  if (!Platform.isAndroid) return null;
  try {
    final id = await const AndroidId().getId();
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  } catch (_) {
    return null;
  }
}
