KATKIT — Gestion de boutique

Fonctions incluses : authentification Supabase, produits avec prix d'achat et prix de vente, stock, ventes avec plusieurs articles, total automatique, reçu imprimable affichant uniquement les prix de vente, clients, dettes et remboursements, dépenses, tableau de bord, rapports et export CSV.

INSTALLATION / MISE À JOUR
1. Dans Supabase, ouvrez SQL Editor et exécutez tout le fichier SUPABASE.sql.
2. Remplacez les fichiers de votre projet GitHub/Vercel par ceux de ce ZIP et redéployez.
3. Modifiez les anciens produits et saisissez leur prix d'achat réel (valeur initiale 0).

Le bénéfice estimé = ventes - coût des articles vendus - dépenses. Le reçu client ne révèle pas le prix d'achat.


MISE À JOUR STOCK ET CAMÉRA
- Le formulaire produit contient le prix d'achat, le prix de détail, le prix de gros et le stock.
- La page Stocks permet d'enregistrer les entrées et les sorties; les ventes diminuent le stock automatiquement.
- Exécutez de nouveau le fichier SUPABASE.sql complet dans Supabase > SQL Editor avant de publier les fichiers. Le script utilise des colonnes/tables IF NOT EXISTS pour préserver les données existantes.
- La caméra permet l'aperçu et l'enregistrement local en fichier vidéo sur l'appareil. La diffusion distante n'est PAS active dans ce ZIP : elle nécessite un service de streaming sécurisé et une configuration serveur supplémentaire. Ne présentez pas le bouton « Voir la diffusion » comme opérationnel.
