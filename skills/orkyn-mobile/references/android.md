# Android natif (Kotlin, Compose) et Kotlin Multiplatform

Repères au 2026-11-03 : Kotlin 2.4.x, Android Gradle Plugin 9.5 (Gradle 9.6 minimum, JDK 17), Compose BOM 2026.09, Android Studio 2026.2, KSP2 (KSP1 incompatible avec AGP 9 et Kotlin 2.3 et plus), K2 compilateur par défaut. Lis toujours `gradle/libs.versions.toml` et `gradle/wrapper/gradle-wrapper.properties` d'abord.

## Conventions
- Kotlin DSL (`build.gradle.kts`) et catalogue de versions : toute nouvelle dépendance passe par `libs.versions.toml`.
- AGP 9 intègre Kotlin : le plugin `org.jetbrains.kotlin.android` n'est plus appliqué dans un projet AGP 9. Ne l'ajoute pas. Ne migre pas un projet AGP 8 sans demande.
- Interface : Jetpack Compose avec Material 3, état remonté (state hoisting), `ViewModel` exposant un `StateFlow`, collecte avec `collectAsStateWithLifecycle()`. Pas de logique métier dans les composables.
- Concurrence : coroutines structurées (`viewModelScope`, `lifecycleScope`), jamais `GlobalScope`, `Dispatchers.IO` pour les entrées et sorties.
- `enableEdgeToEdge()` dans l'activité et gestion des `WindowInsets`.
- Injection : celle du projet (Hilt, Koin, manuelle). Persistance : Room, DataStore.
- Écrans de 600 dp et plus : en ciblant API 37, l'application ne peut plus bloquer l'orientation ni le redimensionnement. Prévois des mises en page adaptatives.

## Vérification (Windows : `gradlew.bat`)
```
./gradlew tasks --all              # découvrir les tâches réelles du projet
./gradlew lintDebug
./gradlew testDebugUnitTest
./gradlew assembleDebug
./gradlew ktlintCheck detekt       # seulement si ces plugins sont configurés
```
Émulateur, seulement si un AVD existe :
```
emulator -list-avds
emulator -avd <nom> -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect &
adb wait-for-device && adb shell getprop sys.boot_completed   # attendre 1
./gradlew connectedDebugAndroidTest
adb install -r app/build/outputs/apk/debug/app-debug.apk && adb logcat -d -t 300
adb emu kill                       # arrêter l'émulateur que tu as lancé
```
Pages de 16 Ko (code natif) : `zipalign -c -P 16 -v 4 app.apk`.

## Pièges fréquents
- Gradle exige le bon JDK : lis `java -version` et la `jvmToolchain` du projet avant d'accuser le code.
- `compileSdk` et `targetSdk` différents de 36 : signale le retard (exigence Play), ne les change pas sans demande.
- Un test Robolectric ou Compose qui échoue seulement en CI : vérifie la locale et le fuseau.

## Kotlin Multiplatform et Compose Multiplatform
Compose Multiplatform 1.12 (octobre 2026), stable pour iOS depuis la 1.8. Le code partagé va dans `commonMain`, les implémentations de plateforme dans `androidMain` et `iosMain` avec `expect` et `actual`.
```
./gradlew :shared:allTests
./gradlew :composeApp:assembleDebug
./gradlew iosSimulatorArm64Test    # macOS avec Xcode seulement
```
Les noms de modules varient : `./gradlew projects` puis `tasks --all`.
