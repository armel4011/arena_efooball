// Audit 2026-05-19 — couvre le helper `arenaErrorMessage`. Pour le moment
// la map Postgres/Auth/Function/Socket → message FR fait le minimum ; ce
// test verrouille le contrat pour éviter une régression silencieuse.

import 'dart:io';

import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('arenaErrorMessage', () {
    test('AuthFailure invalid_credentials → message clair', () {
      expect(
        arenaErrorMessage(const InvalidCredentialsFailure()),
        'Email ou mot de passe incorrect.',
      );
    });

    test('AuthFailure username_already_taken → message clair', () {
      expect(
        arenaErrorMessage(const UsernameAlreadyTakenFailure()),
        'Ce pseudo est déjà pris.',
      );
    });

    test('AuthException renvoie son `message` brut', () {
      expect(
        arenaErrorMessage(const AuthException('bad jwt')),
        'bad jwt',
      );
    });

    test('PostgrestException 23505 → message contrainte unique', () {
      const e = PostgrestException(
        message: 'duplicate key value',
        code: '23505',
      );
      expect(arenaErrorMessage(e), 'Cette valeur est déjà utilisée.');
    });

    test('PostgrestException 42501 → message permission', () {
      const e = PostgrestException(
        message: 'permission denied',
        code: '42501',
      );
      expect(arenaErrorMessage(e), "Vous n'avez pas la permission.");
    });

    test('PostgrestException code unknown → fallback sur `message`', () {
      const e = PostgrestException(
        message: 'some db error',
        code: '99999',
      );
      expect(arenaErrorMessage(e), 'some db error');
    });

    test('SocketException → message réseau', () {
      expect(
        arenaErrorMessage(const SocketException('connection refused')),
        'Pas de connexion réseau.',
      );
    });

    test('Object inconnu → fallback `toString`', () {
      expect(arenaErrorMessage('boom'), 'boom');
    });
  });
}
