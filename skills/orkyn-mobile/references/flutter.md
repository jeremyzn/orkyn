# Flutter et Dart

Repères au 2026-11-03 : Flutter 3.47 stable (3.50 attendue en novembre 2026), Dart 3.x. Lis `pubspec.yaml` (contrainte `environment: sdk`) et `flutter --version` avant d'écrire.

## Conventions
- Flutter 3.47 sort Material et Cupertino dans des paquets séparés (`material_ui`, `cupertino_ui`). Dans un projet qui les a adoptés, importe-les ainsi. Migration : `dart fix --apply --code=migrate_design_widgets`, seulement si le brief le demande.
- Gestion d'état : celle du projet (Riverpod 3, Bloc, Provider, signals). N'en introduis pas une deuxième.
- Widgets petits et `const` partout où c'est possible. Pas de logique métier dans `build`.
- Dart moderne : null safety stricte, `sealed class` et `switch` exhaustif pour les états, records et patterns, raccourcis par point (dot shorthands) si la version de Dart du projet les accepte.
- Analyse : règles de `analysis_options.yaml` (`flutter_lints` ou `very_good_analysis`), jamais désactivées pour faire passer le code.
- Natif : Swift Package Manager est le chemin par défaut côté iOS, CocoaPods est en maintenance. Avec Xcode 27, l'adoption d'UIScene est obligatoire.
- Secrets : `flutter_secure_storage`. Jamais de clé d'API serveur dans le code Dart (le binaire se décompile).

## Vérification
```
flutter pub get                    # lit le lockfile, n'a aucun effet externe
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign            # macOS seulement
flutter test integration_test -d <appareil>        # si un simulateur ou émulateur tourne (flutter devices)
```
`flutter doctor -v` indique ce qui manque sur la machine : signale le, ne l'installe pas.

## Pièges
- AGP 9 peut casser le build Android d'un projet Flutter ancien (plugin Kotlin). Signale, ne migre pas sans demande.
- Code généré (`build_runner`, `freezed`, `json_serializable`) : régénère avec `dart run build_runner build --delete-conflicting-outputs` après modification des sources annotées, n'édite jamais un `*.g.dart` à la main.
- Interdits sans accord : `flutter pub publish`, `flutter upgrade`, `flutter channel`.
