# iOS (Swift, SwiftUI)

Repères au 2026-11-03 : Xcode 27 avec Swift 6.4 (Apple silicon et macOS Tahoe 26.4 ou plus), Xcode 26 et SDK 26 exigés par l'App Store, SDK 27 exigé à partir d'avril 2027. **macOS uniquement** : ailleurs, écris le code et note la vérification iOS « non vérifiée, macOS requis ».

## Conventions
- Lis la version de Swift du projet (`swift-tools-version` dans `Package.swift`, `SWIFT_VERSION` dans le projet Xcode) et son mode de concurrence. Respecte-le.
- Swift 6 : concurrence stricte. Isolation `@MainActor` pour l'interface, `actor` pour l'état partagé, types `Sendable`, `async`/`await` plutôt que des callbacks. Ne fais pas taire une erreur de concurrence avec `@unchecked Sendable` ou `nonisolated(unsafe)` sans justification écrite.
- SwiftUI : `@Observable` (framework Observation) pour les modèles, `@State` pour l'état local, `NavigationStack`. Pas de logique métier dans les vues.
- Tests : Swift Testing (`import Testing`, `@Test`, `#expect`) pour les nouveaux tests, XCTest si le projet l'utilise déjà.
- Value types par défaut (`struct`, `enum`), erreurs typées avec `throws`, pas de `try!` ni de `!` hors tests.
- Cycle de vie par scènes (UIScene) : obligatoire avec le SDK 27. Signale une app qui ne l'a pas.
- `PrivacyInfo.xcprivacy` : à mettre à jour quand tu ajoutes une API à raison obligatoire (horodatage de fichier, `UserDefaults`, espace disque...).
- Secrets : Keychain. Jamais `UserDefaults` pour un jeton.

## Vérification
```
xcodebuild -list                                   # schémas et cibles
xcrun simctl list devices available                # choisir un simulateur existant
xcodebuild -scheme <S> -destination 'platform=iOS Simulator,name=<iPhone existant>' \
  CODE_SIGNING_ALLOWED=NO build test | tail -50
swift build && swift test                          # paquets SwiftPM
swift format lint -r Sources                       # si le projet l'utilise
swiftlint                                          # si .swiftlint.yml existe
```
Lancement : `xcrun simctl boot <id>`, `xcrun simctl install booted <App.app>`, `xcrun simctl launch --console booted <bundle id>`. Arrête le simulateur que tu as démarré (`xcrun simctl shutdown <id>`).
Projet avec `.xcworkspace` (CocoaPods) : `-workspace X.xcworkspace` au lieu du projet.
XcodeGen ou Tuist : régénère le projet (`xcodegen generate`, `tuist generate`) au lieu d'éditer le `.pbxproj` à la main.

## Interdit sans accord
`-allowProvisioningUpdates`, `xcrun altool`, `notarytool`, `-exportArchive` vers l'App Store, fastlane `match`, `pilot`, `deliver`, modification des certificats ou profils.
