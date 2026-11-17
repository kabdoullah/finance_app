import 'package:flutter/foundation.dart' show immutable;

import 'category.dart';

enum CategoryFieldError {
  nameMissing,
  nameTooLong,

  /// Une catégorie sœur porte déjà ce nom (vérifié par le repository).
  nameTaken,

  /// Parent inexistant, d'un autre type ou lui-même sous-catégorie.
  parentInvalid,
}

/// Saisie de la feuille « Nouvelle catégorie / sous-catégorie ».
@immutable
class CategoryDraft {
  const CategoryDraft({
    required this.kind,
    required this.name,
    this.parentId,
    this.iconKey = defaultIcon,
  });

  static const maxNameLength = 40;
  static const defaultIcon = 'tag';

  /// Icônes proposées pour une catégorie principale (maquette).
  static const icons = [
    'tag',
    'gift',
    'hand-coins',
    'device-mobile',
    'heartbeat',
    'graduation-cap',
    'users',
    't-shirt',
    'house-line',
    'ticket',
    'taxi',
    'basket',
  ];

  static final _spaces = RegExp(r'\s+');

  final CategoryKind kind;
  final String name;

  /// Catégorie principale de rattachement (`null` = catégorie principale).
  final String? parentId;

  /// Ignorée pour une sous-catégorie, qui reprend l'icône de son parent.
  final String iconKey;

  String get normalizedName => normalize(name);

  Set<CategoryFieldError> validate() => validateName(normalizedName);

  static String normalize(String name) => name.trim().replaceAll(_spaces, ' ');

  static Set<CategoryFieldError> validateName(String name) => {
    if (name.isEmpty) CategoryFieldError.nameMissing,
    if (name.length > maxNameLength) CategoryFieldError.nameTooLong,
  };
}
