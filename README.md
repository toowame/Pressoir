# Pressoir

L'historique du presse-papier façon Windows (Win+V), pour macOS.

**⇧⌘V** ouvre, sous la souris, la liste des derniers textes et images copiés. Choisissez-en un : il est collé dans l'app au premier plan.

| Touche | Action |
|---|---|
| ↑ ↓ ↩ | naviguer, coller |
| ⌘1 … ⌘9 | coller la ligne n |
| taper | rechercher |
| ⌘P | épingler / désépingler |
| ⌘⌫ | supprimer |
| Échap | fermer |

## Construire

```bash
swift test                        # domaine
Scripts/check-coverage.sh         # couverture PressoirCore ≥ 80 %
Scripts/build-app.sh              # Pressoir.app universel (arm64 + x86_64)
Scripts/build-dmg.sh              # .dmg glisser-déposer
lefthook install                  # hooks pre-commit / pre-push
```

L'historique est chiffré sur le disque (AES-256-GCM, clé dans le Trousseau). Le collage automatique demande la permission **Accessibilité** (Réglages Système › Confidentialité et sécurité).

## Sécurité

- Historique et images chiffrés (AES-256-GCM, clé dans le Trousseau), dossiers privés, hors Time Machine.
- Jamais gardés : copies marquées confidentielles, copies faites dans un gestionnaire de mots de passe, jetons reconnaissables (GitHub, AWS, JWT…), presse-papier universel.
- Le collage automatique ne vise que l'app d'origine, jamais un champ mot de passe.
- Une donnée illisible n'est jamais écrasée : elle est mise de côté (`quarantaine-<date>/`).
- Pas de `.env` : l'app n'a ni configuration ni secret.

Architecture et choix : `docs/adr/`. Plan : `docs/TODO-PRESSOIR.md`. Recette : `docs/TESTING.md`.
