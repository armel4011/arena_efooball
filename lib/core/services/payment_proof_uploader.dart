import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Capture de paiement choisie par le joueur (image seule).
class PickedPaymentProof {
  const PickedPaymentProof({
    required this.path,
    required this.bytes,
    required this.mimeType,
    required this.displayName,
  });

  final String path;
  final int bytes;
  final String mimeType;
  final String displayName;
}

/// Sélectionne une capture d'écran (image) et l'uploade dans le bucket privé
/// `payment-proofs`. Layout calqué sur `match-proofs` :
///
///   payment-proofs/{paymentId}/{userId}/{epochMs}.{ext}
///
/// RLS : le joueur ne dépose que dans son sous-dossier d'un paiement qui lui
/// appartient (cf. migration `20260710140000_payment_proof_screenshot.sql`).
/// Le chemin storage est ensuite enregistré sur `payments.proof_path` via la
/// RPC `attach_payment_proof` (le client n'écrit pas la table directement).
class PaymentProofUploader {
  PaymentProofUploader(this._client);

  final SupabaseClient _client;

  static const _bucket = 'payment-proofs';
  static const _allowedExts = {'jpg', 'jpeg', 'png', 'webp'};
  static const _maxBytes = 10 * 1024 * 1024; // 10 Mo (aligné bucket)

  /// Ouvre le sélecteur (images). Renvoie `null` si l'utilisateur annule.
  /// Lève si l'extension n'est pas une image supportée ou dépasse 10 Mo.
  Future<PickedPaymentProof?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.single;
    final path = f.path;
    if (path == null || path.isEmpty) {
      throw const FormatException('Fichier sans chemin local');
    }
    final ext = _extOf(path);
    if (!_allowedExts.contains(ext)) {
      throw FormatException(
        'Format non supporté (.$ext). Joins une image (jpg/png/webp).',
      );
    }
    final size = await File(path).length();
    if (size > _maxBytes) {
      throw const FormatException('Image trop lourde — limite 10 Mo.');
    }
    return PickedPaymentProof(
      path: path,
      bytes: size,
      mimeType: _mimeFor(ext),
      displayName: f.name,
    );
  }

  /// Uploade [proof] sous `payment-proofs/{paymentId}/{userId}/{epochMs}.{ext}`
  /// et renvoie la clé storage (bucket privé — signée à la demande côté admin).
  Future<String> upload({
    required String paymentId,
    required String userId,
    required PickedPaymentProof proof,
  }) async {
    final ext = _extOf(proof.path);
    final fileName = ext.isEmpty
        ? '${DateTime.now().millisecondsSinceEpoch}'
        : '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storagePath = '$paymentId/$userId/$fileName';
    await _client.storage.from(_bucket).upload(
          storagePath,
          File(proof.path),
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: proof.mimeType,
          ),
        );
    return storagePath;
  }

  static String _extOf(String filePath) {
    final dot = filePath.lastIndexOf('.');
    if (dot < 0 || dot == filePath.length - 1) return '';
    return filePath.substring(dot + 1).toLowerCase();
  }

  static String _mimeFor(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
    }
    return 'application/octet-stream';
  }
}

final paymentProofUploaderProvider = Provider<PaymentProofUploader>((ref) {
  return PaymentProofUploader(Supabase.instance.client);
});
