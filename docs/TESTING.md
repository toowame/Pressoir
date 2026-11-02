# Recette manuelle — PressoirApp

Le domaine (`PressoirCore`) est couvert par `swift test`. La couche système se vérifie à la main :

1. `Scripts/build-app.sh release native && open Pressoir.app` → icône presse-papier dans la barre de menu, pas d'icône dans le Dock.
2. Copier 3 textes dans des apps différentes.
3. Dans TextEdit, ⇧⌘V → le panneau s'ouvre sous la souris, 3 éléments, le plus récent en haut.
4. Première fois : macOS demande l'Accessibilité → Réglages Système › Confidentialité › Accessibilité › activer Pressoir.
5. ↓ puis ↩ → le 2ᵉ élément est collé dans TextEdit, le panneau se ferme.
6. ⌘1 → colle le 1ᵉʳ. Taper un mot → la liste se filtre.
7. ⌘P sur un élément → épinglé, reste en tête après de nouvelles copies.
8. Souris près du bord droit / bas de l'écran → le panneau reste entièrement visible.
9. Cliquer ailleurs ou Échap → le panneau se ferme.
10. Copier un mot de passe depuis 1Password / Trousseau → absent de l'historique.
11. Quitter puis relancer → l'historique est conservé ; `strings history.enc` ne montre aucun texte copié.
12. Capture d'écran dans le presse-papier (⌃⇧⌘4) → vignette + « Image · L × H » ; ↩ la colle dans Aperçu › Nouveau depuis le presse-papier.
13. Recopier la même image → elle remonte, pas de doublon.
14. Copier un fichier dans le Finder → rien n'apparaît.
15. Supprimer l'image (⌘⌫) → son fichier disparaît de `images/`.
16. Copier `AKIAIOSFODNN7EXAMPLE` → n'apparaît pas. Copier un mot de passe dans 1Password → n'apparaît pas.
17. Ouvrir le panneau dans TextEdit, cliquer dans une autre app, puis ↩ dans le panneau → rien n'est collé ailleurs.
18. Champ mot de passe focalisé (Safari) → ↩ ne colle pas automatiquement.
19. Refuser l'accès au Trousseau → le menu affiche « Trousseau inaccessible », l'historique existant est intact au lancement suivant.

