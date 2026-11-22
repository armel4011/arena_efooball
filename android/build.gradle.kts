// AGP 9 vérifie les métadonnées AAR aussi sur les modules plugins : l'embedding
// Flutter 3.50 tire androidx.fragment 1.7.1 (compileSdk ≥ 34 requis). Les
// plugins Agora (agora_rtc_engine, agora_rtm, iris_method_channel) lisent
// `rootProject.ext.compileSdkVersion` via safeExtGet (fallback 31) → on
// l'aligne sur flutter.compileSdkVersion. Compile-time uniquement : le
// comportement runtime reste piloté par le targetSdk de l'app (35).
extra["compileSdkVersion"] = 36

// Même contrainte pour les plugins qui codent compileSdk en dur (< 36, ex.
// file_picker → 34) : on relève tout module Android sous 36. Le hook est
// enregistré AVANT l'évaluation des sous-projets → il passe avant celui
// d'AGP qui fige le DSL / crée les variantes. Appel dynamique (old DSL,
// android.newDsl=false) pour ne pas dépendre des types AGP ici.
subprojects {
    afterEvaluate {
        val android = extensions.findByName("android") ?: return@afterEvaluate
        val current = android.withGroovyBuilder { getProperty("compileSdkVersion") } as? String
        val level = current?.removePrefix("android-")?.toIntOrNull() ?: return@afterEvaluate
        if (level < 36) {
            android.withGroovyBuilder { "compileSdkVersion"(36) }
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
