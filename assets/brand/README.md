# Finao — icône et splash screen

Symbole retenu : **le cairn**, trois galets en équilibre (forêt `#174D3A`, sauge `#8EAA91`, ambre `#E8B86D`) sur ivoire `#F3F0E8`.
Le symbole n'est jamais déformé : seule son échelle change d'un format à l'autre.

## Contenu

| Dossier | Fichiers |
|---|---|
| `vector/` | Symbole (clair, sombre, monochrome blanc, encre), mot-symbole, lockups, et `parts/` : les trois galets séparés, dans le même cadre 1000 × 1000 |
| `png/` | Symbole et lockups en 2048 px, fond transparent |
| `ios/` | `AppIcon-1024` (clair), `-dark` (fond forêt profond), `-dark-transparent`, `-tinted` (niveaux de gris). Carrés pleins : iOS applique son masque |
| `android/` | Icône adaptative 108 dp : `ic_launcher_foreground`, `ic_launcher_background`, `ic_launcher_monochrome` (5 densités + SVG sources), icônes classiques carrée et ronde, `play-store-512.png` |
| `splash/` | Lockup centré `@3x`, icône Android 12 (1152 px, symbole dans le cercle de 192 dp), mot-symbole « branding », écrans complets de référence 1290 × 2796 et 1080 × 2400 |
| `flutter/` | `finao_splash.dart` : splash animé 1,3 s puis fondu vers l'app |

Zones de sécurité : iOS, symbole à 62 % de la largeur ; Android adaptatif, rayon maximal 29,6 dp (cercle sûr : 33 dp) ; Android 12 splash, symbole à 54 % de la zone de 192 dp.

## pubspec.yaml

Copier ce dossier dans `assets/brand/` puis :

```yaml
flutter:
  assets:
    - assets/brand/vector/
    - assets/brand/vector/parts/

dev_dependencies:
  flutter_launcher_icons: ^0.14.0
  flutter_native_splash: ^2.4.0

flutter_launcher_icons:
  android: "ic_launcher"
  ios: true
  image_path: "assets/brand/ios/AppIcon-1024.png"
  remove_alpha_ios: true
  image_path_ios_dark_transparent: "assets/brand/ios/AppIcon-1024-dark-transparent.png"
  image_path_ios_tinted_grayscale: "assets/brand/ios/AppIcon-1024-tinted.png"
  adaptive_icon_background: "#F3F0E8"
  adaptive_icon_foreground: "assets/brand/android/mipmap-xxxhdpi/ic_launcher_foreground.png"
  adaptive_icon_monochrome: "assets/brand/android/mipmap-xxxhdpi/ic_launcher_monochrome.png"

# Splash natif : fond seul, pour que l'animation Flutter construise le cairn sans saut.
flutter_native_splash:
  color: "#F3F0E8"
  color_dark: "#174D3A"
  android_12:
    color: "#F3F0E8"
    color_dark: "#174D3A"
    image: assets/brand/splash/android12-splash-icon-light.png
    image_dark: assets/brand/splash/android12-splash-icon-dark.png
```

Vérifie les noms de clés avec la version des paquets installée : ils évoluent d'une version à l'autre.

## Animation

Utilise `FinaoSplash(next: …)` comme premier écran. Sur Android 12 et plus, le système affiche déjà le cairn : passe `stonesAlreadyShown: true` pour que seul le mot apparaisse. Avec « Réduire les animations », l'écran s'affiche directement dans sa position finale, puis passe à l'app par un simple fondu.

Pour une version statique (sans Flutter), utilise `splash/splash-lockup-*@3x.png` comme image centrée sur la couleur de fond.
