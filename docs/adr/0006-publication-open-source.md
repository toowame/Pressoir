# ADR 0006 — Publication open source

Statut : accepted — 2026-11-02.

## Contexte
Le dépôt devient public, sous licence MIT, avec un DMG téléchargeable.

## Décision
- Identifiant neutre `io.github.toowame.Pressoir` (bundle, service du Trousseau, type
  privé du presse-papier) à la place d'un identifiant portant un nom de personne.
- La clé créée sous l'ancien identifiant est retrouvée par son compte et son libellé
  (`history-encryption-key`, « Pressoir — clé de l'historique »), recopiée sous le nouveau,
  puis l'ancienne entrée est supprimée : l'historique existant reste lisible sans que
  l'ancien identifiant figure dans le code.
- Historique git réécrit avant publication pour en retirer les mentions personnelles
  (sauvegarde de l'état précédent conservée hors dépôt). L'ADR 0003 cite donc le nouvel
  identifiant.
- README en anglais (`README.md`) et en français (`README.fr.md`) ; illustration du panneau
  en SVG, puisque le panneau est volontairement exclu des captures d'écran (ADR 0005).
- Icône dessinée en code (`Scripts/make-icon.swift`) : régénérable, sans outil externe.
- DMG publié en Release GitHub, signé ad hoc (non notarié) : le README explique l'ouverture.

## Conséquences
- \+ Aucun nom de personne dans le code, la doc ni l'historique publiés.
- − Changer d'identifiant redemande les autorisations Accessibilité et Trousseau.
- − Sans notarisation, macOS bloque le premier lancement (contournement documenté).
