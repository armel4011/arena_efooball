# =============================================================================
# ARENA — Règles ProGuard/R8 pour les builds release (minify + shrink)
# =============================================================================
# Le plugin Gradle Flutter fournit déjà les keeps de l'engine Dart/Flutter.
# Ce fichier n'ajoute QUE les keeps des plugins natifs qui chargent des
# classes par réflexion/JNI ou désérialisent du JSON — un keep manquant ne
# casse pas le build R8 mais provoque un crash runtime en release.
# Régles volontairement larges : on privilégie la robustesse à la taille.

# ----- Agora RTC + RTM (JNI massif, classes résolues par réflexion) ----------
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# ----- Firebase / FCM / Google Play services ---------------------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ----- Sentry (capture d'exceptions, intégrations chargées dynamiquement) -----
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# ----- flutter_local_notifications (Gson : (dé)sérialise les objets de notif) -
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.dexterous.**

# ----- flutter_callkit_incoming (appels entrants) ----------------------------
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-dontwarn com.hiennv.flutter_callkit_incoming.**

# ----- Play Core (Flutter deferred components / split install) ----------------
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ----- Réflexion : préserve annotations, signatures génériques, inner classes -
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
