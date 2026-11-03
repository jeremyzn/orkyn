---
name: orkyn-mobile
description: Conventions et boucle de vérification du développement mobile (Android Kotlin et Compose, iOS Swift et SwiftUI, Flutter et Dart, React Native et Expo, Kotlin Multiplatform) avec les exigences des stores de fin 2026. Utiliser pour écrire, corriger, tester ou auditer une application mobile.
---

# Développement mobile

Les fichiers du projet font foi. Les versions citées ici datent du 2026-11-03 et servent à repérer un projet en retard ou une exigence de store, jamais à imposer une montée de version que le brief ne demande pas.

## 1. Détecter, sans demander
| Marqueur | Plateforme | Référence |
|---|---|---|
| `pubspec.yaml` avec `flutter` | Flutter | [references/flutter.md](references/flutter.md) |
| `package.json` avec `expo` ou `react-native` | Expo, React Native | [references/react-native.md](references/react-native.md) |
| dossiers `src/commonMain`, plugin `kotlin("multiplatform")` | Kotlin Multiplatform | [references/android.md](references/android.md) (section KMP) |
| `settings.gradle(.kts)` et plugin `com.android.*` | Android natif | [references/android.md](references/android.md) |
| `*.xcodeproj`, `*.xcworkspace`, `Package.swift`, `project.yml` (XcodeGen), `Project.swift` (Tuist) | iOS, SwiftPM | [references/ios.md](references/ios.md) |

Lis la référence de la plateforme avant d'écrire. Un projet Flutter ou React Native contient aussi `android/` et `ios/` : n'y touche que pour la configuration native (permissions, manifeste, `Info.plist`, Gradle, Podfile).

## 2. Écrire
- Calque le code voisin : architecture (MVVM, Clean, feature folders), gestion d'état, injection de dépendances, navigation, style de test. N'introduis pas de bibliothèque que le projet n'utilise pas.
- Interface : composants accessibles (libellés, tailles de cible de 48 dp ou 44 pt, contraste, texte dynamique), écrans adaptatifs (tablettes, pliables, orientation), bords à bords (edge to edge) et zones sûres.
- Réseau et stockage sûrs par défaut : voir la section mobile de `orkyn-security` (Keystore, Keychain, HTTPS, aucun secret dans l'application).
- Permissions : le minimum, demandées au moment de l'usage, avec leur texte d'explication (`Info.plist`, manifeste).
- Chaînes visibles : dans les fichiers de traduction du projet s'il en a.

## 3. Vérifier, en boucle, sans demander
Par cercles, avec les commandes exactes de la référence de la plateforme :
1. Format et analyse statique (lint, analyzer).
2. Tests unitaires ciblés, puis la suite.
3. Build de debug, sans signature.
4. Si un simulateur ou un émulateur est disponible : installation, lancement, test d'interface ou au minimum démarrage sans crash avec lecture des logs (`adb logcat`, `xcrun simctl spawn booted log stream`).
Corrige et recommence jusqu'au vert, dans la limite des cycles du niveau.

Limites de la machine, à noter « non vérifié » sans les contourner :
- Build et tests iOS : macOS avec Xcode uniquement.
- Émulateur Android : nécessite un AVD existant (`emulator -list-avds`). N'en crée pas et n'installe aucune image système sans accord.
- Appareil réel : jamais sans que l'utilisateur l'ait branché et demandé.

## 4. Exigences des stores à surveiller (fin 2026)
- **Google Play** : cible API 36 obligatoire pour les nouvelles applications et mises à jour depuis le 2026-08-31. Pages mémoire de 16 Ko obligatoires pour les mises à jour à partir du 2027-02-01 (concerne le code natif : NDK r28 et plus). Bords à bords sans échappatoire en API 36.
- **App Store** : build avec Xcode 26 et le SDK iOS 26 au minimum depuis le 2026-04-28. SDK iOS 27 exigé à partir d'avril 2027 : avec lui, cycle de vie par scènes (UIScene) obligatoire et plus d'échappatoire au design Liquid Glass. Privacy manifest obligatoire.
Un projet qui ne respecte pas ces points est signalé dans le rapport, même hors périmètre.

## 5. Interdit sans accord de l'utilisateur
Publication sur un store, TestFlight, distribution aux testeurs, mise à jour OTA, build distant, signature de release, modification des certificats, profils ou keystores, montée de version majeure du framework. Le garde-fou bloque ces commandes : prépare la commande exacte et mets-la dans ton rapport.
