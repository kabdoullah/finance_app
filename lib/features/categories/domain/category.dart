import 'package:flutter/foundation.dart' show immutable;

/// Une catégorie classe soit des dépenses, soit des revenus.
enum CategoryKind {
  expense('expense'),
  income('income');

  const CategoryKind(this.storageValue);

  final String storageValue;

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
  });

  final String id;
  final String name;
  final CategoryKind kind;

  /// Clé d'icône (voir `categoryIcon`). Une sous-catégorie reprend l'icône de
  /// sa catégorie parente.
  final String iconKey;
  final String? parentId;

  bool get isSubcategory => parentId != null;
}

/// Catégorie principale et ses sous-catégories, dans l'ordre d'affichage.
@immutable
class CategoryGroup {
  const CategoryGroup({required this.category, required this.children});

  final Category category;
  final List<Category> children;
}
