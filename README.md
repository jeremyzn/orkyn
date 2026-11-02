# ORKYN

ORKYN est une équipe d'assistants pour Claude Code. Vous dites ce que vous voulez avec vos mots, et ORKYN s'occupe du reste : il choisit les bons assistants, fait le travail, le vérifie et vous explique ce qui a été fait.

Il sait aussi créer des jeux Roblox et lire votre boîte mail sans jamais rien y modifier.

ORKYN fonctionne sur Mac, sur Windows et sur Linux.

## Installation

Dans Claude Code, tapez ces deux commandes, l'une après l'autre.

```
/plugin marketplace add https://github.com/jeremyzn/orkyn.git
/plugin install orkyn@orkyn
```

Si Claude Code vous pose des questions sur les mails, laissez la réponse none. Vous pourrez les configurer plus tard.

Redémarrez ensuite Claude Code.

## Utilisation

Tapez /orkyn suivi de votre demande.

```
/orkyn ajoute un formulaire de contact à mon site
/orkyn explique moi comment ce projet est organisé
/orkyn cherche pourquoi ce test échoue
```

ORKYN a trois façons de travailler :

- eco : rapide et économe, pour les petites demandes ;
- balanced : le mode normal, utilisé par défaut ;
- deep : le plus approfondi, pour les gros chantiers.

Pour utiliser un mode une seule fois, écrivez son nom avant la demande.

```
/orkyn deep: refais la page de connexion de mon application
```

Pour changer de mode pour de bon, tapez /orkyn mode suivi du nom du mode. Tapez /orkyn help pour voir toutes les commandes.

## Jeux Roblox

Vous n'avez rien de spécial à faire : parlez simplement de votre jeu Roblox, ORKYN s'en charge. Il écrit le code, lance le jeu pour le tester, corrige ce qui ne va pas et recommence jusqu'à ce que ça marche.

Pour l'instant, les jeux Roblox se font dans Vibe Starter. Installez ORKYN avec les deux commandes ci-dessus, puis demandez ce que vous voulez : tout est automatique, vous n'avez rien à régler.

En dehors de Vibe Starter, ORKYN peut écrire le code de votre jeu, mais il ne peut pas le lancer pour le tester.

ORKYN ne publie jamais votre jeu et ne touche pas à l'argent sans votre accord. Il vous demande aussi avant de dépenser des crédits ou d'ajouter un objet téléchargé depuis la boutique Roblox.

## Lire vos mails

ORKYN peut lire votre boîte mail pour la trier et vous dire ce qui compte. Il ne peut ni répondre, ni envoyer, ni supprimer, ni déplacer un message.

1. Tapez /plugin configure orkyn@orkyn.
2. Choisissez votre fournisseur de mail. S'il n'est pas dans la liste, choisissez autre et recopiez les informations de connexion que votre fournisseur vous donne.
3. Saisissez votre adresse mail.
4. Saisissez un mot de passe d'application, jamais votre mot de passe habituel.
5. Redémarrez Claude Code, puis tapez /orkyn inbox.

Un mot de passe d'application est un mot de passe à part, que vous créez dans les réglages de sécurité de votre compte mail, et que vous pouvez supprimer à tout moment. Pour Gmail et iCloud, il faut d'abord activer la validation en deux étapes.

Pour Proton, installez l'application Proton Mail Bridge, laissez la ouverte, et utilisez le mot de passe qu'elle affiche.

Outlook et Hotmail ne sont pas pris en charge. ORKYN lit un seul compte mail à la fois.

Pour les mails, il faut aussi installer Node.js (version 24 ou plus), gratuit sur nodejs.org.

## Sécurité

ORKYN est prudent : il vous demande votre accord avant toute action importante, comme mettre votre code en ligne, supprimer des fichiers ou publier quelque chose. Si un mail contient une consigne cachée, ORKYN ne la suit pas et vous la signale.

Ces protections réduisent fortement les risques, mais aucun outil n'est parfait : gardez un œil sur ce qui se passe. Elles ne changent rien à votre usage habituel de Claude Code, qui continue de vous demander confirmation comme d'habitude.

## Mise à jour

```
/plugin marketplace update orkyn
/plugin update orkyn@orkyn
```

Redémarrez ensuite Claude Code.

## Désinstallation

```
/plugin uninstall orkyn@orkyn
/plugin marketplace remove orkyn
```

## Licence

ORKYN est un projet personnel publié sous licence MIT. Voir le fichier LICENSE.
