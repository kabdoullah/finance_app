# Finao

Application de finances personnelles pour la Côte d'Ivoire (FCFA), qui
fonctionne entièrement sur le téléphone : comptes, opérations, budgets,
prévisions, objectifs d'épargne, saisie par la voix et assistant IA
(Gemma 4) hors connexion. Android et iOS, Flutter.

- **Spécifications** : [docs/specs/](docs/specs/README.md)
- **Identifiant** : `com.finao.app`

## Développement

```sh
flutter pub get
flutter test                      # ~260 tests
flutter run                       # Android
flutter build ios --release       # iPhone (signature Xcode requise)
```

Après une modification du schéma de la base :
`dart run build_runner build` puis `dart run drift_dev make-migrations`.
