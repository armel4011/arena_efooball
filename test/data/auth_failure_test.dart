import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_shared/auth_common/auth_failure_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthFailure', () {
    test('each subclass exposes a stable code', () {
      expect(const InvalidCredentialsFailure().code, 'invalid_credentials');
      expect(
        const EmailAlreadyRegisteredFailure().code,
        'email_already_registered',
      );
      expect(const WeakPasswordFailure().code, 'weak_password');
      expect(const EmailNotConfirmedFailure().code, 'email_not_confirmed');
      expect(const UserBannedFailure().code, 'user_banned');
      expect(const WrongAppForRoleFailure().code, 'wrong_app_for_role');
      expect(const NetworkFailure().code, 'network');
      expect(const UnknownAuthFailure().code, 'unknown');
    });

    test('preserves cause', () {
      final cause = Exception('original');
      final failure = UnknownAuthFailure(cause);
      expect(failure.cause, cause);
      expect(failure.toString(), contains('original'));
    });
  });

  group('authFailureToMessage', () {
    test('returns user-friendly text for each variant', () {
      // Spot-check a few — switch is exhaustive so all branches compile.
      expect(
        authFailureToMessage(const InvalidCredentialsFailure()),
        contains('incorrect'),
      );
      expect(
        authFailureToMessage(const WrongAppForRoleFailure()),
        contains('ARENA Admin'),
      );
      expect(
        authFailureToMessage(const NetworkFailure()),
        contains('connexion'),
      );
    });
  });
}
