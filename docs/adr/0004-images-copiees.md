# ADR 0004 — Images copiées : un fichier chiffré par image

Statut : accepted — 2026-11-02. Remplace le « texte seul » de l'ADR 0002.

## Contexte
Une capture d'écran pèse plusieurs Mo. La mettre dans `history.enc` obligerait à
rechiffrer et réécrire tout l'historique (des dizaines de Mo) à chaque copie.

## Décision
- Chaque image est stockée à part : `Application Support/Pressoir/images/<id>.enc`,
  scellée en AES-256-GCM avec la même clé du Trousseau (ADR 0003), droits 0600.
- Le nom du fichier est un identifiant aléatoire : il ne révèle rien de l'image.
  L'empreinte SHA-256 (qui repère une image recopiée) ne vit que dans l'historique chiffré.
- Format stocké : PNG (sans perte, bien plus léger que le TIFF des captures).
- Une image de plus de 20 Mo est ignorée.
- Après chaque changement, les fichiers d'image que l'historique ne référence plus
  (évincés, supprimés, effacés) sont supprimés du disque.
- Quand une copie contient texte et image (Word, Excel), le texte l'emporte.
  Un fichier copié dans le Finder (lien + icône TIFF) n'est pas pris pour une image.
- La recherche ne remonte que les textes ; les images restent visibles sans recherche.
- Au collage, l'image est remise en PNG et en TIFF (compatibilité des vieilles apps).
- Les images comptent dans les 50 éléments non épinglés.

## Conséquences
- \+ Copier du texte reste instantané même avec des images dans l'historique.
- \+ Aucun pixel en clair sur le disque, aucun nom de fichier parlant.
- − Jusqu'à ~50 images × 20 Mo dans le pire cas ; en pratique quelques Mo par capture.
- − Vignettes déchiffrées et gardées en mémoire tant que l'app tourne.
