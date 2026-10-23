# ADR 0001 — App Mac native en Swift (SwiftPM), sans Xcode project

Statut : accepted — 2026-10-23

## Contexte
Pressoir est un historique du presse-papier façon Windows (Win+V) : un raccourci global
ouvre, sous la souris, la liste des derniers textes copiés ; on en choisit un, il est collé
dans l'app au premier plan. Il faut un raccourci global, un panneau flottant qui ne vole pas
le focus, la lecture du presse-papier et l'envoi d'un ⌘V synthétique.

## Décision
- Swift 6 (mode de langage 6, concurrence stricte), AppKit pour le système, SwiftUI pour le panneau.
- Paquet SwiftPM, sans `.xcodeproj` (comme Ramure et Helios) ; `.app` assemblé par `Scripts/build-app.sh`.
- Deux cibles : `PressoirCore` (domaine pur, sans AppKit, testé ≥ 80 %) et `PressoirApp`
  (adaptateurs système + UI, recette manuelle).
- Raccourci global via Carbon `RegisterEventHotKey` : aucune permission requise pour écouter.
- Collage via `CGEvent` ⌘V : nécessite la permission Accessibilité. Sans elle, le texte est
  quand même copié et l'utilisateur colle à la main.
- Aucune dépendance tierce.

## Conséquences
- \+ Léger (aucun runtime), lancement instantané, binaire universel arm64 + x86_64.
- \+ Le domaine se teste sans écran ni presse-papier réel.
- − Signature ad hoc : macOS peut redemander l'Accessibilité après chaque rebuild
  (la permission est liée à la signature). Une signature Developer ID réglerait ça.
- − Le presse-papier est sondé (0,5 s) : macOS n'émet pas de notification de changement.
