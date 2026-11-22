# Publication iOS — App Store

Comment Finao a été publiée sur l'App Store (version 1.0.0, novembre 2026),
les erreurs rencontrées et la marche à suivre pour les versions suivantes.

> Le dépôt est public : ne jamais mettre ici de mot de passe, de clé d'API
> ni de numéro de téléphone.

## Identité de l'app

| Élément | Valeur |
|---|---|
| Nom sur l'App Store | Finao : budget et dépenses |
| Identifiant iOS (bundle ID) | `com.finao.ios` |
| Identifiant Android | `com.finao.app` (inchangé) |
| Équipe Apple | 3NRR8L4663 (compte payant Apple Developer Program) |
| App Apple ID | 6837922719 |
| Appareils | iPhone seulement (`TARGETED_DEVICE_FAMILY = 1`) |
| iOS minimum | 15.0 |
| Politique de confidentialité | https://kabdoullah.github.io/finance_app/confidentialite/ |
| Assistance | https://kabdoullah.github.io/finance_app/support/ |

Les deux pages web sont sur la branche `gh-pages` (HTML statique, sans
Jekyll). Les textes de la fiche sont dans [fiche-fr.md](fiche-fr.md). Les
captures 6,9" sont dans [captures-iphone-6.9/](captures-iphone-6.9/) ;
`capture-iphone/` contient les mêmes écrans en 6,3" (1206 × 2622), mis en
page avec un titre au-dessus de chaque capture.

## Ce qui a été configuré dans le projet

- `ios/Runner/Info.plist`
  - `ITSAppUsesNonExemptEncryption = false` : le chiffrement (base SQLite
    chiffrée, sauvegardes, PBKDF2 du code) ne sert qu'à protéger les données
    de l'utilisateur, ce qui n'est pas la fonction principale de l'app →
    exempté (catégorie 5, partie 2, note 4). Évite la question à chaque envoi.
  - Textes d'autorisation : micro, reconnaissance vocale, Face ID,
    photothèque (voir erreur 4).
  - Orientations iPad supprimées (app iPhone seulement).
- `ios/Runner/PrivacyInfo.xcprivacy` : manifeste de confidentialité. Aucun
  suivi, aucune donnée collectée ; API « espace disque » déclarée (raison
  `E174.1`, vérification avant le téléchargement du modèle IA). Ajouté aux
  ressources du projet Xcode.
- `ios/Runner/Runner.entitlements` : `extended-virtual-addressing` et
  `increased-memory-limit`, nécessaires pour charger Gemma (≈ 2,5 Go).
  Refusées aux équipes gratuites, acceptées avec le compte payant.
- `project.pbxproj` : équipe 3NRR8L4663, `CODE_SIGN_ENTITLEMENTS`,
  bundle ID `com.finao.ios`, iPhone seulement.

## Déroulé de la publication 1.0.0

1. Préparation du projet (section ci-dessus), commit `911ca91`.
2. Pages web : politique de confidentialité et assistance publiées sur
   GitHub Pages (branche `gh-pages`).
3. Fiche : textes rédigés dans `fiche-fr.md` (limites de caractères vérifiées).
4. Captures : simulateur iPhone 18 Pro Max (6,9", 1320 × 2868) avec des
   données fictives (voir « Refaire les captures »).
5. Création de l'app dans App Store Connect (langue principale : français).
6. Archive et envoi : `flutter build ipa --release`, puis envoi depuis
   l'Organizer d'Xcode (voir erreur 5).
7. Build 1 refusé au traitement (erreur 4) → build 2 corrigé et envoyé.
8. Formulaires App Store Connect : classification par âge, confidentialité,
   droits sur le contenu, pays (erreur 6), notes pour la vérification.
9. Test du build 2 sur iPhone via TestFlight : installation OK, **Gemma
   téléchargé et fonctionnel** avec les autorisations de mémoire étendue.
10. Soumission à la vérification Apple le 22 novembre 2026.

## Erreurs rencontrées et solutions

### 1. Équipe gratuite : pas de publication possible
**Symptôme** : seuls des certificats « Apple Development » sur le Mac ;
profil de l'équipe KNZLU929KY valable 7 jours.
**Cause** : KNZLU929KY est une équipe personnelle gratuite. L'App Store
exige l'Apple Developer Program (payant).
**Solution** : signer avec l'équipe payante 3NRR8L4663.
**Astuce** : pour savoir si une équipe est gratuite, regarder la durée de
ses profils dans `~/Library/Developer/Xcode/UserData/Provisioning Profiles`
(7 jours = gratuite).

### 2. Identifiant `com.finao.app` indisponible
**Symptôme** (`flutter build ipa`) :
`Failed Registering Bundle Identifier: The app identifier "com.finao.app"
cannot be registered to your development team because it is not available.`
**Cause** : un identifiant iOS est unique chez Apple. `com.finao.app` avait
déjà été enregistré par l'équipe gratuite lors des installations de
développement sur l'iPhone.
**Solution** : nouvel identifiant iOS `com.finao.ios` (Android garde
`com.finao.app`).
**Conséquence** : la Finao installée en développement et celle de
l'App Store sont deux apps distinctes ; pour passer ses données de l'une à
l'autre, faire une sauvegarde puis une restauration.
**À retenir** : choisir l'identifiant définitif et l'enregistrer avec
l'équipe de publication AVANT toute installation de développement.

### 3. Autorisations Gemma refusées par le profil
**Symptôme** : `Provisioning profile "iOS Team Provisioning Profile: *"
doesn't include the Extended Virtual Addressing capability` (idem pour
Increased Memory Limit).
**Cause** : conséquence de l'erreur 2 (profil générique utilisé faute
d'identifiant enregistré).
**Solution** : résolue d'elle-même une fois `com.finao.ios` enregistré : la
signature automatique d'Xcode a ajouté les deux capacités à l'App ID.

### 4. Build refusé au traitement : ITMS-90683
**Symptôme** : le build n'apparaît ni dans TestFlight ni dans la section
Build ; e-mail d'Apple « Action needed: The uploaded build for Finao has one
or more issues » :
`ITMS-90683: Missing purpose string in Info.plist … should contain a
NSPhotoLibraryUsageDescription key`.
**Cause** : deux bibliothèques contiennent du code d'accès aux photos que
Finao n'appelle jamais : `file_picker` (restauration de sauvegarde) et
`background_downloader` (téléchargement de Gemma). Apple analyse le binaire
et exige quand même un texte.
**Solution** : texte honnête dans `Info.plist`
(« Finao n'utilise pas tes photos… ») et numéro de build incrémenté
(commit `db8e289`).
**À retenir** : un build refusé ne s'affiche nulle part dans App Store
Connect ; la seule trace est l'e-mail envoyé à la personne qui a fait
l'envoi. Après chaque envoi, vérifier sa boîte mail.

### 5. L'archive n'apparaît pas dans Xcode / export impossible
**Symptôme** : l'Organizer d'Xcode ne montre que les autres apps de
l'équipe. Au build 2, `flutter build ipa` échoue à l'export :
`exportArchive No signing certificate "iOS Distribution" found`.
**Cause** : `flutter build ipa` range l'archive dans
`build/ios/archive/Runner.xcarchive`, pas dans le dossier des archives
d'Xcode. Le Mac n'a pas de certificat de distribution local ; seul l'envoi
depuis Xcode utilise le certificat géré par Apple (« Cloud Managed Apple
Distribution »).
**Solution** : `open build/ios/archive/Runner.xcarchive` pour l'ajouter à
l'Organizer, puis Distribute App → App Store Connect → Upload.

### 6. « Unable to Add for Review »
**Symptômes et solutions** :
- *Security Assessment / AIGC declaration required for China mainland* :
  exigences propres à la Chine continentale → pays retiré dans Pricing and
  Availability.
- *You must set up Content Rights Information* : App Information → Content
  Rights → « contient du contenu de tiers » + « j'ai les droits » (modèle
  Gemma de Google, police Manrope sous SIL OFL).
- *You must choose a build* : attendre la fin du traitement du build (et
  vérifier l'e-mail, cf. erreur 4).

### 7. Démo du simulateur : variable d'environnement ignorée
**Symptôme** : `SIMCTL_CHILD_DEMO_ROUTE=… xcrun simctl launch` ne change
pas d'écran.
**Solution** : passer la route par `--dart-define=DEMO_ROUTE=…` avec
`flutter run`.

## Réponses données dans App Store Connect

- Classification par âge : « No » / « None » partout → 4+.
  Advertising : **No** (à changer quand les publicités arriveront).
- Confidentialité de l'app : « Données non collectées ».
- Content Rights : contenu de tiers, droits détenus.
- Pays : tous sauf la Chine continentale.
- Catégories : Finance, puis Productivité. Prix : gratuit.
- Vérification : pas de compte de démo (« Sign-in required » décoché) ;
  notes en anglais dans `fiche-fr.md`.

## Publier une nouvelle version

1. Incrémenter `version:` dans `pubspec.yaml` : la partie avant `+` pour une
   nouvelle version (1.0.1, 1.1.0…), le numéro après `+` à **chaque** envoi
   (Apple refuse deux envois avec le même numéro).
2. `flutter build ipa --release`, puis
   `open build/ios/archive/Runner.xcarchive` → Distribute App → Upload.
3. Vérifier l'e-mail d'Apple (≈ 10 min) ; sinon le build apparaît dans
   TestFlight.
4. Tester via TestFlight (Gemma, dictée, Face ID, sauvegarde).
5. App Store Connect : nouvelle version, notes de version, choix du build,
   soumission.

### Installer un build via TestFlight

1. App Store Connect → TestFlight → Internal Testing → créer un groupe,
   s'y ajouter comme testeur (il faut être membre de l'équipe dans Users and
   Access), ajouter le build.
2. Sur l'iPhone : app TestFlight (même identifiant Apple ou lien de l'e-mail
   d'invitation) → Installer. Pas de vérification Apple pour les testeurs
   internes ; un build expire après 90 jours.

### Refaire les captures

```
flutter run -d <id du simulateur> -t tool/demo/main_demo.dart \
  --dart-define=DEMO_ROUTE=/budgets
xcrun simctl status_bar <id> override --time 9:41 --batteryState discharging --batteryLevel 100
xcrun simctl io <id> screenshot capture.png
```

Routes utilisées : `/` (accueil), `/quick-entry?mode=text&text=…`,
`/budgets`, `/forecast`, `/budgets/goals`, `/transactions`. Les données sont
fictives et recréées à chaque lancement (base en mémoire, rien de réel n'est
touché).

### Quand les publicités seront ajoutées

Dans la même mise à jour :
- politique de confidentialité (branche `gh-pages`) ;
- `PrivacyInfo.xcprivacy` (données collectées par la régie, suivi éventuel) ;
- App Store Connect : confidentialité de l'app (« Données non collectées »
  ne sera plus vrai), classification par âge (Advertising → Yes), et
  demande d'autorisation de suivi (App Tracking Transparency) si la régie
  l'exige.
