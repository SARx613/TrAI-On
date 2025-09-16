# TryOn Safari Web Extension

Cette extension Safari (Manifest v3) injecte un bouton "Try on in TryOn" sur les pages produit Zara/H&M/Mango. Lorsqu'un utilisateur clique, un lien universel `https://tryon.example/try` est ouvert pour déclencher l'app iOS.

## Installation (iOS)
1. Construisez l'extension avec Xcode 15+ depuis le workspace `TryOnMVP` (cible "safari-tryon").
2. Sur votre iPhone, allez dans **Réglages > Safari > Extensions** et activez "TryOn Button".
3. Accordez l'autorisation "Toutes les pages" si demandé.

## Utilisation
- Ouvrez Safari et naviguez vers une page produit Zara/H&M/Mango.
- Un bouton flottant "Try on in TryOn" apparaît en bas à droite.
- Appuyez dessus pour lancer l'app via le lien universel `https://tryon.example/try?u=<URLProduit>&brand=<marque>`.

## Personnalisation
- Modifiez `content.js` pour ajuster les règles de détection des pages produit.
- Remplacez `tryon.example` par votre domaine associé (voir README principal pour la configuration des universal links).
