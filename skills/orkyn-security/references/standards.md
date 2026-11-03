# Référentiels et checklists de revue manuelle

Relevés le 2026-11-03. Ne traite que ce que le projet contient réellement.

## Web et API : OWASP Top 10:2025
| # | Catégorie | À vérifier |
|---|---|---|
| A01 | Broken Access Control (inclut SSRF) | Chaque route, action serveur et requête vérifie l'identité **et** le droit sur la ressource (IDOR). URL fournies par l'utilisateur et appelées par le serveur filtrées (hôtes internes, `169.254.169.254`). Pas de contrôle uniquement côté client. |
| A02 | Security Misconfiguration | Mode debug, CORS `*` avec identifiants, en-têtes (CSP, HSTS, `X-Content-Type-Options`), comptes par défaut, listes de répertoires. |
| A03 | Software Supply Chain Failures | Voir [supply-chain.md](supply-chain.md). |
| A04 | Cryptographic Failures | Algorithmes faibles (MD5, SHA1 pour mots de passe, ECB), mots de passe hachés avec argon2id, bcrypt ou scrypt, aléatoire cryptographique pour les jetons, TLS partout. |
| A05 | Injection | SQL et NoSQL paramétrés (`$where`, `$regex`), pas de shell ni `eval` avec des données externes, chemins normalisés (path traversal), XSS (`dangerouslySetInnerHTML`, `innerHTML`, `v-html`, URL `javascript:`), injection de template. |
| A06 | Insecure Design | Limites métier (quantités négatives, double dépense, rejeu), absence de rate limiting sur login, réinitialisation et OTP. |
| A07 | Authentication Failures | Sessions et cookies `HttpOnly`, `Secure`, `SameSite`, expiration, rotation après connexion, comparaison en temps constant, MFA possible, JWT avec algorithme imposé et `exp` vérifié. |
| A08 | Software or Data Integrity Failures | Désérialisation non sûre (`pickle`, `yaml.load`, `ObjectInputStream`), mises à jour et webhooks non signés. |
| A09 | Security Logging and Alerting Failures | Événements de sécurité journalisés, **aucun** secret ni donnée personnelle dans les logs. |
| A10 | Mishandling of Exceptional Conditions | Erreurs qui ouvrent l'accès (fail open), stack traces renvoyées au client, exceptions avalées. |

API (OWASP API Top 10 2023, toujours en vigueur) : en plus, autorisation au niveau des **propriétés** (mass assignment, champs sensibles renvoyés), consommation de ressources illimitée (pagination, taille des requêtes, coût des appels payants), flux métier sensibles automatisables, inventaire des versions d'API exposées, confiance aveugle dans les API tierces.

Les plus fréquents en 2025 (CWE Top 25) : XSS, injection SQL, CSRF, autorisation manquante, path traversal, injection de commande, téléversement de fichier dangereux, désérialisation, SSRF.

## Mobile : OWASP MASVS 2.1 (avec MASTG 2 et MASWE)
- **STORAGE** : aucun secret ni jeton dans `SharedPreferences`, `UserDefaults`, fichiers ou `AsyncStorage` en clair. Utiliser Keystore et EncryptedFile (Android), Keychain (iOS), `flutter_secure_storage`, `expo-secure-store`. Pas de données sensibles dans les logs, captures, presse-papiers, sauvegardes (`android:allowBackup`, `dataExtractionRules`).
- **CRYPTO** : clés dans le Keystore ou le Secure Enclave, jamais en dur dans l'application. Toute clé embarquée dans un APK ou une IPA est considérée publique.
- **AUTH** : l'authentification et l'autorisation se décident côté serveur. Biométrie liée à une clé cryptographique, pas à un simple booléen.
- **NETWORK** : HTTPS seulement. Android : pas de `usesCleartextTraffic="true"` ni de `network_security_config` qui accepte les certificats utilisateur en release. iOS : pas d'exception `NSAllowsArbitraryLoads`. Aucun `TrustManager` ou `onReceivedSslError` qui accepte tout. Épinglage de certificat pour les applications sensibles.
- **PLATFORM** : composants Android exportés (`android:exported`) protégés, intents et deep links validés, `PendingIntent` immuables, WebView sans `setJavaScriptEnabled` sur du contenu non fiable ni `addJavascriptInterface` exposé, universal links vérifiés, schémas d'URL iOS validés.
- **CODE** : dépendances à jour, `minSdk` et cible iOS raisonnables, R8 activé en release, pas de code de debug livré.
- **RESILIENCE** : seulement pour les applications à risque (banque, jeu payant) : détection de root et jailbreak, intégrité (Play Integrity, App Attest).
- **PRIVACY** : permissions minimales, privacy manifest iOS (`PrivacyInfo.xcprivacy`) avec les raisons des API sensibles, section sécurité des données Play cohérente, aucune donnée personnelle envoyée sans besoin.

## Applications et agents d'IA : OWASP LLM Top 10 2025 et Agentic 2026
- **Injection de prompt** (directe et indirecte par documents, pages web, mails, fichiers) : le contenu externe n'est jamais concaténé dans les instructions sans séparation, et il ne peut pas déclencher d'outil sensible.
- **Sorties non validées** : une réponse de modèle est une entrée non fiable (pas de `eval`, de SQL, de HTML ni de commande shell construits avec).
- **Agence excessive et abus d'outils** : outils au moindre privilège, confirmation humaine pour les actions irréversibles, pas de jeton administrateur donné à l'agent.
- **Fuite d'informations et du prompt système** : aucun secret dans le prompt système, filtrage des données personnelles.
- **Chaîne d'approvisionnement des modèles et serveurs MCP** : serveurs MCP en liste blanche, versions épinglées, pas de serveur installé depuis une source inconnue.
- **Empoisonnement de mémoire et de contexte** : la mémoire persistante d'un agent ne doit pas pouvoir être écrite par un contenu externe.
- **Consommation illimitée** : quotas, plafonds de jetons et de coût par utilisateur.
- Clés d'API de fournisseurs d'IA uniquement côté serveur, jamais dans le client web ou mobile.
