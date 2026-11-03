# Checklist sécurité (chargée à la demande)

Ne traite que les points que le changement touche réellement.

- **Entrées** : validation côté serveur (schéma, type, taille), pas de confiance dans les données du client.
- **Injection** : requêtes SQL/NoSQL paramétrées (attention aux opérateurs `$where`/`$regex` injectés en MongoDB), pas de `exec`/`eval`/shell avec des données externes, chemins de fichiers normalisés (path traversal).
- **XSS** : pas de `dangerouslySetInnerHTML` / `innerHTML` sur du contenu non assaini. Pour les URL fournies par l'utilisateur, schéma vérifié (`javascript:`).
- **AuthN/AuthZ** : chaque route ou action serveur vérifie l'identité *et* le droit sur la ressource (IDOR). Pas de contrôle uniquement côté client.
- **Sessions et tokens** : cookies `HttpOnly`/`Secure`/`SameSite`, expiration, comparaison en temps constant, rate limiting sur les points sensibles (login, formulaires).
- **Secrets** : rien en dur ni dans le bundle client (préfixes `NEXT_PUBLIC_` et équivalents), rien dans les logs, `.env` ignoré par git.
- **Dépendances** : pas de nouvelle dépendance inutile. Signale les paquets abandonnés ou typosquattés.
- **Données personnelles** : minimisation, chiffrement si requis, pas d'exposition dans les réponses ou les erreurs.
- **Erreurs** : pas de stack trace ni de détail interne renvoyé au client.
- **SSRF / fetch serveur** : URL contrôlées par l'utilisateur filtrées (hôtes internes, métadonnées cloud).
