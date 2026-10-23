# ADR 0003 — Historique chiffré au repos (AES-256-GCM, clé dans le Trousseau)

Statut : accepted — 2026-10-23. Remplace la partie « stockage » de l'ADR 0002.

## Contexte
Les droits 0600 protègent l'historique des autres comptes, pas d'une sauvegarde
(Time Machine, copie de disque) ni d'un outil qui lit les fichiers de l'utilisateur.

## Décision
- Fichier `~/Library/Application Support/Pressoir/history.enc` : JSON de l'historique scellé
  en AES-256-GCM (CryptoKit), nonce aléatoire à chaque sauvegarde, authentifié (fichier
  altéré ou d'une autre clé = rejeté). Droits 0600.
- Clé de 256 bits aléatoire, créée au premier lancement, rangée dans le Trousseau de session
  (`io.github.toowame.Pressoir` / `history-encryption-key`), accessible après le premier
  déverrouillage, liée à ce Mac (`ThisDeviceOnly` : ni iCloud, ni restauration ailleurs).
- Reprise unique de l'ancien `history.json` en clair : rechiffré, puis supprimé.
- La recherche ne laisse aucune trace : filtre en mémoire, rien n'est écrit.

## Conséquences
- \+ Aucun texte copié lisible sur le disque ni dans une sauvegarde du disque.
- − Clé perdue (Trousseau effacé) = historique illisible ; l'app repart à vide et journalise.
- − Signature ad hoc : macOS peut demander l'accès au Trousseau après une recompilation.
- − En mémoire, pendant que l'app tourne, l'historique est en clair (inévitable pour l'afficher).
