import 'dart:convert';
import 'dart:io';

import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of a successful RGPD data export.
class UserDataExport {
  const UserDataExport({
    required this.filePath,
    required this.byteSize,
    required this.recordCounts,
  });

  /// On-device absolute path of the saved JSON file.
  final String filePath;

  /// Size of the file in bytes (for the success snackbar).
  final int byteSize;

  /// `{ matches: 12, payments: 3, … }` — counts per section, used to
  /// reassure the user that the export contains real data.
  final Map<String, int> recordCounts;
}

/// Calls the `export-user-data` Edge Function and persists the resulting
/// JSON to the app's documents directory.
///
/// Returns the file path so the UI can display it; the file is *not*
/// shared automatically — the user gets a snackbar and can pick it up
/// via the OS file manager (V1 keeps the deps minimal, no `share_plus`).
class ExportUserDataRepository {
  const ExportUserDataRepository(this._client);

  final SupabaseClient _client;

  Future<UserDataExport> exportToFile() async {
    final res = await _client.functions.invoke('export-user-data');
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('export-user-data:malformed_response');
    }
    final json = Map<String, dynamic>.from(data);
    final pretty = const JsonEncoder.withIndent('  ').convert(json);
    final bytes = utf8.encode(pretty);

    final dir = await getApplicationDocumentsDirectory();
    final userId = json['userId'] as String? ?? 'unknown';
    final ts = DateTime.now().toUtc().toIso8601String().split('.').first
        .replaceAll(':', '-');
    final file = File('${dir.path}/arena-data-$userId-$ts.json');
    await file.writeAsBytes(bytes, flush: true);

    final counts = <String, int>{};
    for (final entry in json.entries) {
      final v = entry.value;
      if (v is List) counts[entry.key] = v.length;
    }
    return UserDataExport(
      filePath: file.path,
      byteSize: bytes.length,
      recordCounts: counts,
    );
  }
}

final exportUserDataRepositoryProvider =
    Provider<ExportUserDataRepository>((ref) {
  return ExportUserDataRepository(ref.watch(supabaseClientProvider));
});
