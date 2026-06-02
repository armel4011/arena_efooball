import 'dart:io';

import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/data/repositories/auth_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '_supabase_mocks.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockProfileRepository profiles;
  late AuthRepository repo;

  setUpAll(() {
    registerFallbackValue(OtpType.recovery);
  });

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    profiles = MockProfileRepository();
    when(() => client.auth).thenReturn(auth);
    repo = AuthRepository(client: client, profiles: profiles);
  });

  /// Stub `signInWithPassword` pour qu'il lève [error].
  void signInThrows(Object error) {
    when(
      () => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(error);
  }

  group('signInWithEmail — mapping AuthApiException → AuthFailure', () {
    test('code invalid_credentials → InvalidCredentialsFailure', () async {
      signInThrows(
        AuthApiException('bad', code: 'invalid_credentials', statusCode: '400'),
      );
      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'x'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
    });

    test('code email_exists → EmailAlreadyRegisteredFailure', () async {
      signInThrows(AuthApiException('exists', code: 'email_exists'));
      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'x'),
        throwsA(isA<EmailAlreadyRegisteredFailure>()),
      );
    });

    test('code user_banned → UserBannedFailure', () async {
      signInThrows(AuthApiException('banned', code: 'user_banned'));
      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'x'),
        throwsA(isA<UserBannedFailure>()),
      );
    });

    test('code email_not_confirmed → EmailNotConfirmedFailure', () async {
      signInThrows(AuthApiException('nope', code: 'email_not_confirmed'));
      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'x'),
        throwsA(isA<EmailNotConfirmedFailure>()),
      );
    });

    test('code over_request_rate_limit → RateLimitedFailure', () async {
      signInThrows(AuthApiException('slow', code: 'over_request_rate_limit'));
      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'x'),
        throwsA(isA<RateLimitedFailure>()),
      );
    });

    test('code same_password → WeakPasswordFailure', () async {
      signInThrows(AuthApiException('same', code: 'same_password'));
      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'x'),
        throwsA(isA<WeakPasswordFailure>()),
      );
    });

    test('fallback message-based : "invalid login" → InvalidCredentials',
        () async {
      signInThrows(AuthApiException('Invalid login credentials'));
      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'x'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
    });

    test('fallback message-based : "pwned" → WeakPasswordFailure', () async {
      signInThrows(AuthApiException('password is pwned'));
      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'x'),
        throwsA(isA<WeakPasswordFailure>()),
      );
    });

    test('statusCode 422 sans match → InvalidCredentialsFailure', () async {
      signInThrows(AuthApiException('unprocessable', statusCode: '422'));
      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'x'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
    });

    test('message totalement inconnu → UnknownAuthFailure', () async {
      signInThrows(AuthApiException('quelque chose de bizarre'));
      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'x'),
        throwsA(isA<UnknownAuthFailure>()),
      );
    });
  });

  group("signInWithEmail — autres types d'exception", () {
    test('AuthWeakPasswordException → WeakPasswordFailure', () async {
      signInThrows(
        AuthWeakPasswordException(
          message: 'too weak',
          statusCode: '422',
          reasons: const ['length'],
        ),
      );
      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'x'),
        throwsA(isA<WeakPasswordFailure>()),
      );
    });

    test('AuthException générique réseau → NetworkFailure', () async {
      signInThrows(const AuthException('network connection lost'));
      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'x'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('AuthException générique inconnue → UnknownAuthFailure', () async {
      signInThrows(const AuthException('mystère'));
      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'x'),
        throwsA(isA<UnknownAuthFailure>()),
      );
    });

    test('SocketException → NetworkFailure', () async {
      signInThrows(const SocketException('offline'));
      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'x'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('signInWithEmail — succès et résolution profil', () {
    test('email normalisé (trim + lowercase) avant signInWithPassword',
        () async {
      final response = MockAuthResponse();
      final user = MockUser();
      when(() => user.id).thenReturn('u1');
      when(() => response.user).thenReturn(user);
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);
      when(() => profiles.getById('u1')).thenAnswer(
        (_) async => const Profile(id: 'u1', username: 'x', countryCode: 'CM'),
      );

      final p = await repo.signInWithEmail(
        email: '  A@A.IO  ',
        password: 'pw',
      );
      expect(p.id, 'u1');
      verify(
        () => auth.signInWithPassword(email: 'a@a.io', password: 'pw'),
      ).called(1);
    });

    test('user non-null mais profil absent → UnknownAuthFailure', () async {
      final response = MockAuthResponse();
      final user = MockUser();
      when(() => user.id).thenReturn('u2');
      when(() => response.user).thenReturn(user);
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);
      when(() => profiles.getById('u2')).thenAnswer((_) async => null);

      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'pw'),
        throwsA(isA<UnknownAuthFailure>()),
      );
    });

    test('réponse sans user → UnknownAuthFailure', () async {
      final response = MockAuthResponse();
      when(() => response.user).thenReturn(null);
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);

      await expectLater(
        repo.signInWithEmail(email: 'a@a.io', password: 'pw'),
        throwsA(isA<UnknownAuthFailure>()),
      );
    });
  });

  group('signOut', () {
    test('délègue à auth.signOut', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});
      await repo.signOut();
      verify(() => auth.signOut()).called(1);
    });
  });

  group('session courante', () {
    test('currentSession null quand non authentifié', () {
      when(() => auth.currentSession).thenReturn(null);
      expect(repo.currentSession, isNull);
    });

    test('currentUser null quand non authentifié', () {
      when(() => auth.currentUser).thenReturn(null);
      expect(repo.currentUser, isNull);
    });

    test('currentSession propage la session de gotrue', () {
      final session = MockSession();
      when(() => auth.currentSession).thenReturn(session);
      expect(repo.currentSession, same(session));
    });
  });

  group('sendPasswordResetEmail — mapping OTP', () {
    void verifyOtpThrows(Object error) {
      when(
        () => auth.verifyOTP(
          email: any(named: 'email'),
          token: any(named: 'token'),
          type: any(named: 'type'),
        ),
      ).thenThrow(error);
    }

    test('message "otp expired" → ExpiredPasswordResetCodeFailure', () async {
      verifyOtpThrows(AuthApiException('otp has expired'));
      await expectLater(
        repo.verifyPasswordResetCode(email: 'a@a.io', code: '000000'),
        throwsA(isA<ExpiredPasswordResetCodeFailure>()),
      );
    });

    test('message "token invalid" → InvalidPasswordResetCodeFailure',
        () async {
      verifyOtpThrows(AuthApiException('token is invalid'));
      await expectLater(
        repo.verifyPasswordResetCode(email: 'a@a.io', code: '000000'),
        throwsA(isA<InvalidPasswordResetCodeFailure>()),
      );
    });
  });
}
