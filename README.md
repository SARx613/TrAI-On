# TryOn MVP

Ce monorepo contient un MVP de l'expérience **TryOn** :
- Application iOS/React Native avec une vue ARKit native pour le body tracking et le rendu RealityKit.
- Extension Safari (Manifest v3) qui injecte un bouton « Try on in TryOn » sur les pages produit Zara/H&M/Mango.
- Fichier Apple App Site Association (AASA) d'exemple pour configurer les Universal Links.

> ⚠️ Le binaire USDZ réel (`tshirt.usdz`) n'est pas versionné. Le fichier présent dans le dépôt est un placeholder : remplacez-le par un asset skinné (même nom) avant compilation.

## Arborescence
```
tryon/
  apps/
    mobile/
      App.tsx
      src/
        native/BodyTryOnView.tsx
        screens/TryOnScreen.tsx
      ios/
        BodyTryOn/
          BodyTryOnView.swift
          BodyTryOnViewManager.swift
          BodyTryOnViewManager.m
          GarmentJointMap.json
        TryOnMVP/
          AppDelegate.swift
          Info.plist
          TryOnDeepLinkStore.swift
          Resources/tshirt.usdz (placeholder)
        Podfile
        TryOnMVP.xcodeproj/
        TryOnMVP.xcworkspace/
  extensions/
    safari-tryon/
      manifest.json
      content.js
      README.md
  tools/
    aasa/apple-app-site-association
  package.json
  yarn.lock
```

## Prérequis
- macOS Sonoma + Xcode 15.4 minimum.
- iOS 17+ sur un iPhone avec puce A12 ou supérieure (Body Tracking ARKit).
- Node.js 18+, Yarn 1.x, Watchman (optionnel).
- CocoaPods 1.14+ (`sudo gem install cocoapods`).

## Installation & build
```bash
# À la racine du repo
yarn

# Installer les dépendances React Native
cd apps/mobile
yarn

# Installer les pods iOS
cd ios
pod install

# Lancer l'app en développement (ouvre l'iOS Simulator par défaut)
cd ..
yarn ios
```

Scripts utiles (exécutables depuis la racine grâce aux workspaces Yarn) :
- `yarn ios` : lance `react-native run-ios --scheme TryOnMVP`.
- `yarn pods` : exécute `pod install` dans `apps/mobile/ios`.
- `yarn lint` / `yarn typecheck` : vérifications ESLint & TypeScript (strict).

## Asset 3D
1. Remplacez `apps/mobile/ios/TryOnMVP/Resources/tshirt.usdz` par l'asset USDZ skinné (même nom, même extension).
2. Vérifiez que l'asset possède une skeleton compatible RealityKit (bones nommés comme dans `GarmentJointMap.json`).

## Vue native BodyTryOn
- `BodyTryOnView.swift` initialise un `ARView` RealityKit, exécute `ARBodyTrackingConfiguration` et charge l'USDZ.
- La pose ARKit est transférée vers le rig via `SkeletalPosesComponent` (iOS 17+). Si l'API évolue, adaptez le code (TODO en commentaire).
- Fallback : si la skeleton n'est pas disponible, le vêtement est aligné sur `spine7` pour éviter les crashs.
- Échelle : calculée dynamiquement via la distance épaule-épaule détectée.
- Le mapping joints ARKit → bones se trouve dans `GarmentJointMap.json`. Les clés manquantes sont ignorées proprement.

## Universal Links
1. Hébergez `tools/aasa/apple-app-site-association` sur `https://tryon.example/.well-known/apple-app-site-association` (n'oubliez pas de servir en `application/json` sans redirection).
2. Dans Xcode, activez l'entitlement **Associated Domains** de la cible iOS et ajoutez `applinks:tryon.example`.
3. Le `AppDelegate` Swift analyse les URLs reçues (`u=<productURL>&brand=<...>`) et diffuse l'évènement via `NotificationCenter` pour la couche React Native.
4. Pour un test rapide : copiez un lien `https://tryon.example/try?u=<URLProduit>&brand=zara` dans Notes iOS et touchez-le – l'app doit s'ouvrir et logguer la payload dans Xcode.

## Extension Safari (iOS)
- Code source : `extensions/safari-tryon`.
- Le content script détecte les pages produit Zara/H&M/Mango et injecte un bouton flottant.
- Au clic, un Universal Link `https://tryon.example/try?u=<...>` est ouvert (l'app se lance si l'entitlement est configuré).
- Consultez `extensions/safari-tryon/README.md` pour l'activation depuis **Réglages > Safari > Extensions** sur iOS.

## Privacy & sécurité
- Tout le traitement AR reste on-device. Aucun flux caméra n'est envoyé à un backend.
- Aucun tracking / analytics intégré.
- Logs concis, uniquement pour le debug des liens universels ou du chargement d'assets.

## Tests & QA manuelle
Checklist recommandée (voir également la section « 🧪 Checklist de test » en bas du fichier) :
1. `cd apps/mobile && yarn && cd ios && pod install && cd .. && yarn ios`
2. Sur iPhone compatible, vérifier l'ouverture de la caméra + absence de crash.
3. Déposer `tshirt.usdz` skinné → rebuild → bouger les bras : le vêtement suit les articulations.
4. Héberger l'AASA, activer Associated Domains, ouvrir un lien `https://tryon.example/try?...` depuis Notes → vérifier la réception dans Xcode.
5. Activer l'extension Safari, visiter une fiche Zara/H&M/Mango → le bouton apparaît → le clic ouvre l'app.

## Dépannage
- **ARBodyTracking non supporté** : message dans la console et la session ne démarre pas (appareil incompatible).
- **USDZ manquant** : log d'erreur explicite et fallback torse actif (aucun crash).
- **Joints non mappés** : ignorés silencieusement, ajoutez les clés manquantes dans `GarmentJointMap.json`.
- **L'Universal Link n'ouvre pas l'app** : vérifiez le domaine dans l'entitlement, le fichier AASA et le HTTPS sans redirection.
- **Extension Safari invisible** : assurez-vous que Safari > Extensions > TryOn Button est activée et autorisée pour les sites cibles.

---

## 🧪 Checklist de test (QA manuelle)

1. Build iOS :
   ```bash
   cd apps/mobile && yarn && cd ios && pod install && cd .. && yarn ios
   ```
2. Sur iPhone compatible, l’app s’ouvre, caméra ON, pas de crash.
3. Déposer `tshirt.usdz` (mesh skinné) dans `ios/TryOnMVP/Resources/` → rebuild → bouger les bras : le vêtement suit.
4. Héberger le fichier AASA, activer Associated Domains → ouvrir `https://tryon.example/try?u=<...>` depuis Notes → l’app reçoit l’URL (log).
5. Activer l’extension Safari sur iOS → aller sur un produit Zara → bouton “Try on” présent → clic → l’app s’ouvre.

