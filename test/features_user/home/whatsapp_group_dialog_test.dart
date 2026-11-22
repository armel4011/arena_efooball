import 'package:arena/data/repositories/whatsapp_group_repository.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/home/whatsapp_group_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeWhatsAppGroupRepository extends Mock
    implements WhatsAppGroupRepository {}

const _title = 'Rejoins la communauté ARENA';
const _invite = 'https://chat.whatsapp.com/ABCdef123';

/// Hôte minimal : un bouton qui déclenche l'étape comme le fait MainLayout.
Widget _app(WhatsAppGroupRepository repo) => ProviderScope(
      overrides: [whatsAppGroupRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => Center(
              child: ElevatedButton(
                onPressed: () => maybePromptWhatsAppGroup(context, ref),
                child: const Text('GO'),
              ),
            ),
          ),
        ),
      ),
    );

Future<void> _open(WidgetTester tester, WhatsAppGroupRepository repo) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(repo));
  await tester.tap(find.text('GO'));
  await tester.pumpAndSettle();
}

ArenaButton _validateButton(WidgetTester tester) =>
    tester.widget<ArenaButton>(find.widgetWithText(ArenaButton, 'Valider'));

void main() {
  late _FakeWhatsAppGroupRepository repo;

  setUp(() => repo = _FakeWhatsAppGroupRepository());

  testWidgets('aucun dialogue si le joueur a déjà validé', (tester) async {
    when(() => repo.fetchMyStatus()).thenAnswer(
      (_) async => const WhatsAppGroupStatus(
        required: true,
        joined: true,
        inviteUrl: _invite,
      ),
    );
    await _open(tester, repo);
    expect(find.text(_title), findsNothing);
  });

  testWidgets('aucun dialogue si aucun groupe n’est configuré', (tester) async {
    when(() => repo.fetchMyStatus()).thenAnswer(
      (_) async => const WhatsAppGroupStatus(required: false, joined: false),
    );
    await _open(tester, repo);
    expect(find.text(_title), findsNothing);
  });

  testWidgets('erreur réseau sur le statut → pas de blocage', (tester) async {
    when(() => repo.fetchMyStatus()).thenThrow(Exception('offline'));
    await _open(tester, repo);
    expect(find.text(_title), findsNothing);
  });

  testWidgets(
    'mauvais nom → message d’erreur ; bon nom → étape validée et fermée',
    (tester) async {
      when(() => repo.fetchMyStatus()).thenAnswer(
        (_) async => const WhatsAppGroupStatus(
          required: true,
          joined: false,
          inviteUrl: _invite,
        ),
      );
      when(() => repo.confirm('Arena Fans')).thenAnswer((_) async => false);
      when(() => repo.confirm('arena communaute'))
          .thenAnswer((_) async => true);

      await _open(tester, repo);
      expect(find.text(_title), findsOneWidget);

      // Champ vide → « Valider » désactivé.
      expect(_validateButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Arena Fans');
      await tester.pump();
      expect(_validateButton(tester).onPressed, isNotNull);
      await tester.tap(find.widgetWithText(ArenaButton, 'Valider'));
      await tester.pumpAndSettle();
      expect(find.textContaining("Ce n'est pas le nom du groupe"), findsOneWidget);
      expect(find.text(_title), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'arena communaute');
      await tester.pump();
      await tester.tap(find.widgetWithText(ArenaButton, 'Valider'));
      await tester.pumpAndSettle();
      expect(find.text(_title), findsNothing);
      verify(() => repo.confirm('arena communaute')).called(1);
    },
  );
}
