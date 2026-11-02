<p align="center">
  <img src="docs/images/logo.png" width="128" height="128" alt="Icône de Pressoir">
</p>

<h1 align="center">Pressoir</h1>

<p align="center">
  <strong>L'historique du presse-papier pour macOS, façon Windows (Win + V).</strong><br>
  <kbd>⇧</kbd><kbd>⌘</kbd><kbd>V</kbd> : vos dernières copies s'ouvrent sous la souris. Choisissez, c'est collé.
</p>

<p align="center">
  <a href="https://github.com/toowame/Pressoir/actions/workflows/ci.yml"><img src="https://github.com/toowame/Pressoir/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-black?logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6">
  <a href="LICENSE"><img src="https://img.shields.io/badge/licence-MIT-blue" alt="Licence MIT"></a>
</p>

<p align="center">
  <a href="README.md">Read in English</a>
</p>

<p align="center">
  <img src="docs/images/panel.svg" width="440" alt="Le panneau d'historique de Pressoir : un champ de recherche, un texte sélectionné, une vignette d'image, un lien épinglé">
</p>

## Pourquoi

macOS ne garde qu'une seule chose dans le presse-papier : copiez autre chose, la précédente disparaît.
Pressoir retient discrètement vos 50 dernières copies, textes et images, et vous les rend d'un raccourci, là où se
trouve la souris. Pas de fenêtre à gérer, pas d'icône dans le Dock, pas de compte, pas de réseau.

## Fonctions

- **S'ouvre sous la souris.** Le panneau apparaît au pointeur et reste visible près des bords, sur tous les écrans.
- **Textes et images.** Captures d'écran et images copiées s'affichent en vignette et se recollent en image.
- **Tout au clavier.** Tapez pour chercher, <kbd>↑</kbd> <kbd>↓</kbd> <kbd>↩</kbd> pour coller, <kbd>⌘1</kbd>…<kbd>⌘9</kbd> pour les neuf premiers.
- **Épinglés.** Les éléments épinglés restent en tête et ne sortent jamais.
- **Colle pour vous.** L'élément choisi arrive directement dans l'app où vous étiez.
- **Chiffré sur le disque.** Historique et images scellés en AES-256-GCM ; la clé est dans votre Trousseau.
- **Léger et natif.** Swift, AppKit et SwiftUI, aucune dépendance tierce, ~450 Ko, Apple Silicon et Intel.

## Installer

1. Téléchargez `Pressoir-x.y.z.dmg` depuis la [dernière version](https://github.com/toowame/Pressoir/releases/latest).
2. Ouvrez-le et glissez **Pressoir** dans **Applications**.
3. Premier lancement : l'app n'est pas notariée par Apple, macOS la bloque. Clic droit sur Pressoir → **Ouvrir**,
   ou **Réglages Système → Confidentialité et sécurité** → **Ouvrir quand même**.
4. Pressoir vit dans la barre de menu (icône presse-papier). Activez **Ouvrir au démarrage** depuis son menu si vous voulez.

### Autorisations

| Autorisation | Pourquoi | Sans elle |
|---|---|---|
| **Accessibilité** | Taper <kbd>⌘V</kbd> dans l'app où vous étiez | L'élément est copié ; faites <kbd>⌘V</kbd> vous-même |
| **Trousseau** | Ranger la clé de chiffrement de l'historique | Historique en mémoire seulement, rien n'est écrit |

Les versions sont signées ad hoc : macOS peut redemander les deux après une mise à jour.

## Clavier

| Touches | Action |
|---|---|
| <kbd>⇧</kbd><kbd>⌘</kbd><kbd>V</kbd> | Ouvrir / fermer l'historique |
| taper | Rechercher (sans casse ni accents, textes seulement) |
| <kbd>↑</kbd> <kbd>↓</kbd> <kbd>↩</kbd> | Naviguer, coller |
| <kbd>⌘1</kbd> … <kbd>⌘9</kbd> | Coller l'élément 1 à 9 |
| <kbd>⌘P</kbd> | Épingler / désépingler |
| <kbd>⌘⌫</kbd> | Supprimer l'élément |
| <kbd>Échap</kbd> ou clic ailleurs | Fermer |

## Confidentialité et sécurité

Tout reste sur votre Mac. Pressoir ne fait aucune requête réseau.

- **Stockage chiffré.** `~/Library/Application Support/Pressoir/` contient `history.enc` et un fichier scellé par image
  (noms aléatoires), AES-256-GCM, droits réservés au propriétaire, exclu de Time Machine.
- **Jamais enregistré :**
  - les copies marquées confidentielles ou transitoires par les gestionnaires de mots de passe (marqueurs [nspasteboard.org](http://nspasteboard.org)) ;
  - ce qui est copié quand 1Password, Bitwarden, KeePassXC, Mots de passe, Trousseau d'accès, Dashlane ou Enpass est au premier plan ;
  - les identifiants reconnaissables : jetons GitHub, AWS, Slack, Stripe, Google, OpenAI et Anthropic, JWT, clés privées ;
  - ce qui vient d'un autre appareil Apple (presse-papier universel), les textes de plus de 1 Mo, les images de plus de 50 Mo ou 64 Mpx.
- **Collage prudent.** Le <kbd>⌘V</kbd> ne part que vers l'app au premier plan à l'ouverture du panneau, jamais dans un
  champ mot de passe.
- **Rien n'est jamais écrasé.** Si l'historique ne se déchiffre plus (clé perdue, fichier abîmé), il est mis de côté
  intact dans `quarantaine-<date>/`, et le menu vous prévient.
- **Invisible au partage d'écran.** Le panneau n'apparaît ni dans les captures ni dans les écrans partagés.
- Le journal (`~/Library/Logs/Pressoir.log`) note des événements et des codes d'erreur, jamais ce que vous copiez.

Limite à connaître : un mot de passe copié depuis une app qui ne le signale pas est enregistré comme un texte.
Supprimez-le avec <kbd>⌘⌫</kbd> ou **Effacer l'historique** dans le menu. Le raisonnement complet est dans
[`docs/adr/`](docs/adr).

## Construire depuis les sources

Prérequis : macOS 14+, Xcode 16+ (Swift 6).

```bash
git clone https://github.com/toowame/Pressoir.git
cd Pressoir
swift test                     # tests du domaine
Scripts/check-coverage.sh      # seuil de couverture (≥ 80 %) sur PressoirCore
Scripts/build-app.sh           # Pressoir.app universel (arm64 + x86_64)
Scripts/build-dmg.sh           # .dmg à glisser-déposer
open Pressoir.app
```

Pour contribuer : `brew install lefthook gitleaks && lefthook install` lance format, build et recherche de secrets
avant chaque commit, et les tests avant chaque push, comme la CI.

## Fonctionnement

```
Sources/
├── PressoirCore/   domaine, sans AppKit : historique immuable, politique de capture,
│                   garde du collage, ouverture du coffre, stockages chiffrés. Testé.
└── PressoirApp/    adaptateurs : sonde du presse-papier, raccourci global (Carbon),
                    Trousseau, ⌘V synthétique, barre de menu, panneau SwiftUI.
```

- macOS n'émet pas d'événement « presse-papier modifié » : son compteur de changements est sondé toutes les 0,5 s.
- Le raccourci global passe par `RegisterEventHotKey`, qui ne demande aucune autorisation.
- Le panneau est un `NSPanel` non activant : l'app en dessous reste au premier plan et reçoit le collage.

Les choix de conception sont consignés dans [`docs/adr/`](docs/adr). Recette manuelle : [`docs/TESTING.md`](docs/TESTING.md).

## Feuille de route

- Raccourci et apps exclues configurables
- Fichiers copiés (Finder)
- Expiration optionnelle des éléments non épinglés
- Versions signées et notariées

## Licence

[MIT](LICENSE).
