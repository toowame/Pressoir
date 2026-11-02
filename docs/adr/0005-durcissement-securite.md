# ADR 0005 — Durcissement après revue de sécurité

Statut : accepted — 2026-11-02. Complète les ADR 0002 à 0004 ; remplace dans l'ADR 0002
la mention « history.json, droits 0600 » (stockage décrit par les ADR 0003 et 0004).

## Contexte
Une revue de sécurité (2026-11-02) a relevé 3 points élevés : perte possible de tout
l'historique si la clé du Trousseau devenait introuvable, collage possible dans la mauvaise
app, filtrage des mots de passe limité aux apps qui marquent leurs copies.

## Décision
1. **Ne jamais écraser une donnée illisible** (`VaultOpener`, au lancement) :
   - la clé n'est créée que s'il n'existe aucune donnée, ou après mise de côté ;
   - données illisibles (clé absente ou autre) : `history.enc` et `images/` sont déplacés
     dans `quarantaine-<date>/`, intacts, et le menu le signale ;
   - Trousseau qui refuse de répondre : mode sans enregistrement (mémoire seule), rien n'est
     lu ni écrit sur le disque ;
   - la clé est lue une fois au lancement (plus d'aller-retour Trousseau à chaque copie).
2. **Collage gardé** (`PasteGuard`) : le ⌘V ne part que si l'app au premier plan est celle
   d'avant l'ouverture du panneau, et jamais dans un champ mot de passe (`AXSecureTextField`).
   Source d'événement privée : le ⇧ encore enfoncé ne transforme pas ⌘V en ⇧⌘V.
3. **Capture** : jamais gardés en plus des marqueurs nspasteboard.org : copies faites dans
   un gestionnaire de mots de passe connu (1Password, Bitwarden, KeePassXC, Mots de passe,
   Trousseau, Dashlane, Enpass), presse-papier universel (autre appareil Apple), jetons
   reconnaissables (GitHub, AWS, JWT, Slack, Anthropic/OpenAI, Stripe, Google, clés privées),
   textes de plus de 1 Mo. Ce que Pressoir recolle porte un type privé et n'est pas recapturé.
4. **Images** : octets bruts ≤ 50 Mo et ≤ 64 Mpx vérifiés sur l'en-tête avant tout décodage ;
   vignettes via ImageIO sans décoder l'image entière.
5. **Disque et journal** : `umask 077`, dossiers 0700, journal 0600 avec rotation à 1 Mo,
   erreurs journalisées en « domaine#code » (jamais de valeur), dossier exclu de Time Machine.
   Panneau invisible des captures et du partage d'écran.
6. **Chaîne** : signature avec hardened runtime ; actions GitHub épinglées par SHA,
   jeton CI en lecture seule, Dependabot ; gitleaks aussi en pre-commit.
7. Clé créée en `WhenUnlockedThisDeviceOnly` (la clé existante garde son attribut d'origine).
8. **Reprise de l'ancien `history.json` en clair retirée** (ADR 0003) : faite sur le seul Mac
   concerné, elle contournait le coffre et pouvait écraser un historique chiffré si un vieux
   fichier réapparaissait. Un `history.json` éventuel est désormais ignoré.
9. Appels Accessibilité limités à 0,2 s ; décodage des images hors du fil principal.

## Limites assumées
- **Champ focalisé inconnu → on colle.** Si l'app ne publie pas son arbre d'accessibilité
  (certaines apps Electron, Java), le garde ne sait pas s'il s'agit d'un champ mot de passe.
  Bloquer dans ce cas casserait le collage dans Teams, Slack ou VS Code ; l'app d'origine,
  elle, reste vérifiée. À inverser si l'usage le permet (`PasteGuard`).
- **L'app d'origine est lue au sondage** (≤ 0,5 s après la copie) : une copie dans un
  gestionnaire suivie aussitôt d'un ⌘Tab peut être attribuée à l'autre app, et une extension
  de navigateur copie « depuis le navigateur ». Le filtre par app complète les marqueurs
  nspasteboard.org, il ne les remplace pas.
- Deux instances lancées en même temps écriraient le même fichier ; une seule est prévue
  (agent de barre de menu, ouverture au démarrage).

## Non retenu (et pourquoi)
- Trousseau « Data Protection » : exige une signature avec identité Apple stable, pas une
  signature ad hoc.
- Données associées (AAD) liant chaque fichier d'image à son id : changerait le format et
  rendrait illisibles les fichiers existants ; risque local faible (échange de deux fichiers).
- Heuristique « chaîne qui a l'air aléatoire » : trop de faux positifs (empreintes, ids, URL).
- Restauration du presse-papier précédent après collage : comportement inattendu pour l'utilisateur.
- Expiration automatique des éléments non épinglés : laissée en option future (TODO).

## Conséquences
- \+ Une clé perdue ou un accès refusé ne détruit plus rien.
- − Signature ad hoc : chaque recompilation redemande l'accès au Trousseau et l'Accessibilité.
- − Un mot de passe copié depuis une app inconnue et sans marqueur reste capturé :
  ⌘⌫ ou « Effacer l'historique ».
