# ORKYN

ORKYN est une équipe d'assistants pour Claude Code. Vous dites ce que vous voulez avec vos mots, et ORKYN s'occupe du reste : il choisit les bons assistants, fait le travail, le vérifie et vous explique ce qui a été fait.

Il sait aussi créer des applications mobiles, chercher et corriger les failles de sécurité de votre projet et lire votre boîte mail sans jamais rien y modifier.

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

Il n'y a qu'une seule commande à retenir : tapez /orkyn suivi de ce que vous voulez, avec vos mots. ORKYN regarde votre projet, comprend de quoi il s'agit et s'adapte tout seul.

```
/orkyn ajoute un formulaire de contact à mon site
/orkyn ajoute un écran de profil à mon application
/orkyn trouve les failles de sécurité de mon projet
/orkyn cherche pourquoi ce test échoue
/orkyn lis mes mails
```

ORKYN travaille en pilote automatique, du début à la fin, sans vous poser de question. S'il lui manque une information, il la cherche lui-même, dans votre projet ou sur le web, en privilégiant les sources du mois en cours. Quand un choix se présente, il prend l'option la plus prudente, celle qu'on peut défaire, et vous le dit dans son compte rendu.

Les actions importantes (mettre en ligne, publier, supprimer, dépenser) ne sont jamais faites sans vous. ORKYN ne s'arrête pas pour autant : il termine tout le reste, prépare ces actions et vous les présente ensemble à la fin. Répondez « ok tout », « ok 1 » ou « non ».

Pour décider quoi faire seul, il passe chaque tâche à trois filtres : est-ce que ça revient chaque semaine, est-ce que ça s'explique en trois phrases, est-ce une corvée que personne ne veut faire. Ce qui revient chaque semaine et suit une règle simple, il l'automatise. Il vous demande seulement avant d'installer quelque chose en dehors de votre projet. Les corvées, il les fait d'office.

Il n'y a rien à régler : pour chaque demande, ORKYN décide lui-même s'il faut aller vite ou y passer plus de temps, selon la taille et les risques de la tâche. Tapez /orkyn aide pour voir ce que sait faire ORKYN.

ORKYN est aussi économe : il fait lui-même les petites tâches au lieu de lancer des assistants, ne lit que ce qui est utile et écrit des comptes rendus courts. Vos limites Claude durent ainsi plus longtemps.

## Tableau de bord et budget

Dès que vous tapez /orkyn, un panneau s'ouvre à côté de la conversation (si votre fenêtre est assez large, sinon tapez /orkyn-panneau). Il affiche la mission en cours, le niveau choisi, les tokens consommés par ORKYN et par chacun de ses assistants, et une barre de budget.

Chaque mission a un budget de tokens : 60 000 pour une petite demande, 300 000 pour une demande moyenne, 1 million pour une grosse. À 80 %, ORKYN est prévenu et termine sans ouvrir de nouveau chantier. À 100 %, il conclut et ne peut plus lancer d'assistant. Pour changer le budget : /orkyn-budget 500k, ou /orkyn-budget auto pour revenir aux valeurs par défaut.

Quand ORKYN attend votre accord, des boutons « ok 1 », « ok tout » et « non » apparaissent dans le panneau : un clic suffit.

## Tout ce qu'ORKYN fait seul

- Il retient les commandes de test et de vérification de votre projet, pour ne pas les rechercher à chaque fois.
- Il ne peut pas annoncer qu'il a fini s'il a modifié du code sans le vérifier ensuite.
- Après un /orkyn, il surveille votre intégration continue GitHub (si l'outil gh est installé et connecté) et réagit si elle passe au rouge.
- Si vous utilisez l'application Claude sur votre téléphone, il vous envoie une notification quand une longue mission se termine ou attend votre accord.

## Veille

Tapez /orkyn veille : ORKYN cherche les failles connues dans vos composants, les mises à jour importantes, l'état de votre intégration continue et, pour une application mobile, les nouvelles règles des stores. Il corrige ce qui peut l'être sans risque et vous présente le reste. Demandez « fais la veille chaque semaine » : il vous prépare la ligne à taper pour la programmer.

## À fond

Pour un audit de sécurité ou une relecture vraiment approfondis, tapez /orkyn:audit ou /orkyn:revue. Plusieurs assistants travaillent en parallèle et chaque problème trouvé est contre-vérifié par un autre avant de vous être présenté. C'est plus long et plus coûteux : à réserver aux moments importants.

## Applications mobiles

ORKYN crée et corrige des applications pour Android et iPhone, quelle que soit la technologie de votre projet : Kotlin, Swift, Flutter, React Native ou Expo. Il la reconnaît tout seul.

Il écrit le code, vérifie qu'il est correct, lance les tests, construit l'application et, si un simulateur est installé sur votre ordinateur, la lance pour vérifier qu'elle démarre. Il connaît les règles actuelles de l'App Store et de Google Play et vous prévient si votre application risque d'être refusée.

Pour tester une application iPhone, il faut un Mac avec Xcode. Pour une application Android, il faut Android Studio avec un téléphone virtuel déjà créé. Sans eux, ORKYN écrit quand même le code et vous dit ce qu'il n'a pas pu tester.

ORKYN ne publie jamais votre application sur les stores et n'envoie jamais de mise à jour à vos utilisateurs sans votre accord.

## Sécurité de votre projet

Demandez « trouve les failles de mon projet » : ORKYN cherche les mots de passe et clés oubliés dans le code, les composants dépassés ou piégés, les erreurs qui permettraient à quelqu'un d'accéder à des données qui ne sont pas les siennes, et les points faibles des applications mobiles et des fonctions d'intelligence artificielle. Il corrige ensuite ce qui peut l'être, revérifie, et vous liste ce qui reste à faire de votre côté.

Vous n'avez pas besoin de le demander à chaque fois : dès qu'une modification touche à quelque chose de sensible (connexion, paiement, données personnelles, nouveaux composants), ORKYN fait une vérification de sécurité automatique avant de vous rendre la main.

Il utilise les outils de détection installés sur votre ordinateur s'il y en a, et fait une relecture attentive sinon. Il ne lit jamais la valeur de vos mots de passe et de vos clés, et n'envoie jamais votre code à un service extérieur.

Si une clé secrète a été publiée par erreur, ORKYN la retire du code, mais il faudra aussi la changer chez le service concerné : il vous dira laquelle et comment.

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

ORKYN est prudent : il vous demande votre accord avant toute action importante, comme mettre votre code en ligne, supprimer des fichiers, publier une application ou installer un logiciel sur votre ordinateur. Ses assistants ne peuvent pas lire vos fichiers de mots de passe et de clés. Si un mail, une page web ou un fichier contient une consigne cachée, ORKYN ne la suit pas et vous la signale.

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
