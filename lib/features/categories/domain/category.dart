import 'package:flutter/foundation.dart' show immutable;

/// Une catégorie classe soit des dépenses, soit des revenus.
enum CategoryKind {
  expense('expense', 'exp.other'),
  income('income', 'inc.other');

  const CategoryKind(this.storageValue, this.fallbackId);

  final String storageValue;

  /// « Autre » : catégorie de repli (jamais masquée ni supprimée), qui reçoit
  /// les opérations d'une catégorie personnalisée supprimée.
  final String fallbackId;

  static CategoryKind fromStorage(String value) =>
      values.firstWhere((kind) => kind.storageValue == value);
}

/// Catégorie ou sous-catégorie (si [parentId] est renseigné).
@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconKey,
    this.parentId,
    this.isCustom = false,
    this.hiddenAt,
  });

  final String id;
  final String name;
  final CategoryKind kind;

  /// Clé d'icône (voir `categoryIcon`). Une sous-catégorie reprend l'icône de
  /// sa catégorie parente.
  final String iconKey;
  final String? parentId;

  /// Créée par l'utilisateur : renommable et supprimable. Une catégorie
  /// prédéfinie peut seulement être masquée.
  final bool isCustom;

  /// Masquée : plus proposée à la saisie, gardée par les opérations
  /// existantes.
  final DateTime? hiddenAt;

  bool get isSubcategory => parentId != null;
  bool get isHidden => hiddenAt != null;
  bool get isFallback => id == kind.fallbackId;

  /// Actions autorisées (règles de la maquette Catégories).
  bool get canHide => !isCustom && !isFallback;
  bool get canRename => isCustom;
  bool get canDelete => isCustom;
}

/// Catégorie principale et ses sous-catégories, dans l'ordre d'affichage.
@immutable
class CategoryGroup {
  const CategoryGroup({required this.category, required this.children});

  final Category category;
  final List<Category> children;

  /// Sous-catégories proposées à la saisie (non masquées).
  List<Category> get visibleChildren => [
    for (final child in children)
      if (!child.isHidden) child,
  ];
}
