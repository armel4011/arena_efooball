// ════════════════════════════════════════════════════════════════════
// ARENA — main.dart exemple (avec splash intégré)
// ════════════════════════════════════════════════════════════════════
// Ce fichier montre comment câbler le splash screen dans la vraie app.
// Adapte selon ta structure existante Phase 9.
// 
// Si tu as déjà un main.dart, identifie les sections marquées par 
// "⭐ AJOUTER" et insère-les au bon endroit.
// ════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ⭐ AJOUTER : import du splash
import 'features/splash/splash_router.dart';

// ─── Tes imports existants ARENA ─────────────────────────────────────
// import 'core/theme/arena_theme.dart';
// import 'core/services/supabase_service.dart';
// import 'core/routing/arena_router.dart';
// import 'firebase_options.dart';


// ════════════════════════════════════════════════════════════════════
// MAIN — Point d'entrée
// ════════════════════════════════════════════════════════════════════
void main() async {
  // ⭐ AJOUTER : préserver le splash NATIF pendant l'initialisation
  // (sinon flash blanc entre splash natif et widget Flutter)
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Configuration système (orientation, status bar)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0F),
    ),
  );
  
  // ─── Initialisations critiques (Supabase, Firebase, etc.) ──────
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await Supabase.initialize(
  //   url: 'https://xxxxx.supabase.co',
  //   anonKey: 'xxxxx',
  // );
  
  // Lance l'app
  runApp(const ProviderScope(child: ArenaApp()));
  
  // ⭐ AJOUTER : retire le splash NATIF
  // Le widget SplashScreen prend alors le relais avec son animation
  FlutterNativeSplash.remove();
}


// ════════════════════════════════════════════════════════════════════
// APP ROOT
// ════════════════════════════════════════════════════════════════════
class ArenaApp extends ConsumerWidget {
  const ArenaApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'ARENA',
      debugShowCheckedModeBanner: false,
      
      // ─── Theme (utilise ton arena_theme.dart) ──────────────────
      // theme: buildArenaTheme(),
      
      // ⭐ AJOUTER : home = SplashPage
      // Le splash décide ensuite où aller (login ou home)
      home: const SplashPage(
        isAdmin: false,           // ⭐ Pour ADMIN : true
        nextRoute: '/login',      // Adapte selon ton routing
      ),
      
      // ─── Tes routes existantes ─────────────────────────────────
      routes: {
        '/login': (context) => const _PlaceholderPage(title: 'Login'),
        // '/home': (context) => const HomePage(),
        // ... toutes tes routes ARENA
      },
    );
  }
}


// ════════════════════════════════════════════════════════════════════
// ALTERNATIVE : avec GoRouter (recommandé pour ARENA)
// ════════════════════════════════════════════════════════════════════
// Si tu utilises GoRouter, voici comment intégrer :
// 
// final arenaRouter = GoRouter(
//   initialLocation: '/splash',
//   routes: [
//     GoRoute(
//       path: '/splash',
//       builder: (ctx, state) => SplashPage(
//         isAdmin: false,
//         nextRoute: '/login',
//       ),
//     ),
//     GoRoute(path: '/login', builder: (ctx, state) => const LoginPage()),
//     GoRoute(path: '/home', builder: (ctx, state) => const HomePage()),
//     // ... autres routes
//   ],
// );
// 
// Dans ArenaApp :
//   return MaterialApp.router(
//     routerConfig: arenaRouter,
//     // ...
//   );
// ════════════════════════════════════════════════════════════════════


// ════════════════════════════════════════════════════════════════════
// FLAVORS USER / ADMIN — Entrypoints séparés
// ════════════════════════════════════════════════════════════════════
// Si tu utilises des flavors, crée 2 entrypoints :
// 
// ── lib/main_user.dart ─────────────────────────────────────────────
// void main() async {
//   final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
//   FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
//   // ... init
//   runApp(const ProviderScope(child: ArenaApp(isAdmin: false)));
//   FlutterNativeSplash.remove();
// }
// 
// ── lib/main_admin.dart ────────────────────────────────────────────
// void main() async {
//   final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
//   FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
//   // ... init
//   runApp(const ProviderScope(child: ArenaApp(isAdmin: true)));
//   FlutterNativeSplash.remove();
// }
// 
// Et dans ArenaApp :
//   ArenaApp({super.key, this.isAdmin = false});
//   final bool isAdmin;
//   
//   ...
//   home: SplashPage(
//     isAdmin: isAdmin,
//     nextRoute: isAdmin ? '/admin/login' : '/login',
//   ),
// ════════════════════════════════════════════════════════════════════


// ─── Placeholder pour l'exemple ──────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
