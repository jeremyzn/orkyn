# React Native et Expo

Repères au 2026-11-03 : React Native 0.88 (React 19.3), Expo SDK 58 (embarque RN 0.88, Node 22.13 ou plus requis). Nouvelle architecture obligatoire depuis Expo SDK 55. Lis `package.json` et `app.json` ou `app.config.ts` d'abord, puis invoque `orkyn-typescript` pour le code TypeScript.

## Conventions
- Expo : installe les modules natifs avec `npx expo install <paquet>` (versions compatibles avec le SDK), jamais `npm install` pour un module natif Expo.
- Expo Router si le projet l'utilise (routes en fichiers dans `app/`). React Navigation sinon.
- Animations et gestes : Reanimated et Gesture Handler. Le travail lourd ne bloque pas le thread JS.
- Projet géré (pas de dossiers `android/` et `ios/` commités) : la configuration native passe par `app.json` et les config plugins, pas par l'édition des dossiers générés.
- Secrets : `expo-secure-store`. Les variables `EXPO_PUBLIC_*` sont publiques et visibles dans le binaire.
- Depuis RN 0.87, l'API TypeScript stricte est le défaut.

## Vérification (rien n'est envoyé à Expo)
```
npx expo-doctor
npx expo install --check
npx tsc --noEmit
npx expo lint                       # ou le script lint du projet
npm test                            # avec le gestionnaire du lockfile
npx expo export --platform all      # bundle local, détecte les erreurs de résolution
npx expo prebuild --no-install      # seulement dans un dossier temporaire ou si le projet commite déjà android/ et ios/
npx expo run:android                # build local, émulateur requis
npx expo run:ios                    # build local, macOS requis
```
React Native sans Expo : `npx react-native doctor`, puis la vérification Android (`cd android && ./gradlew assembleDebug`) et iOS de [android.md](android.md) et [ios.md](ios.md).

## Interdit sans accord (bloqué par le garde-fou)
`eas submit`, `eas update` et `eas channel:*` (mise à jour OTA envoyée aux utilisateurs réels), `eas build` distant (quota du compte), `eas deploy`, `eas credentials`, `eas env:*`, `expo publish`. `eas build --local` reste permis.
