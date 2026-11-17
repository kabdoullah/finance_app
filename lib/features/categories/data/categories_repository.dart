import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/result.dart';
import '../domain/category.dart';
import '../domain/category_draft.dart';

/// Catégories : lecture, création, renommage, masquage, suppression.
///
/// Règles (maquette Catégories) : une catégorie prédéfinie peut seulement
/// être masquée (« Autre » jamais) ; une catégorie personnalisée peut être
/// renommée ou supprimée, ses opérations passant alors vers « Autre » (ou vers
/// la catégorie parente pour une sous-catégorie).
class CategoriesRepository {
  CategoriesRepository(this._db, this._clock, {String Function()? newId})
    : _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final Clock _clock;
  final String Function() _newId;

  $CategoriesTable get _categories => _db.categories;

  /// Catégories principales d'un type, chacune avec ses sous-catégories
  /// (masquées comprises : à filtrer selon l'usage).
  Stream<List<CategoryGroup>> watchGroups(CategoryKind kind) =>
      (_db.select(_categories)
            ..where((c) => c.kind.equals(kind.storageValue))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .watch()
          .map((rows) {
            final categories = rows.map(toCategory).toList();
            return [
              for (final main in categories.where((c) => !c.isSubcategory))
                CategoryGroup(
                  category: main,
                  children: [
                    for (final child in categories)
                      if (child.parentId == main.id) child,
                  ],
                ),
            ];
          });

  Future<Result<Category>> create(CategoryDraft draft) => _guard(() async {
    final name = draft.normalizedName;
    final errors = draft.validate();

    var iconKey = draft.iconKey;
    final parentId = draft.parentId;
    if (parentId != null) {
      final parent = await _get(parentId);
      if (parent == null || parent.isSubcategory || parent.kind != draft.kind) {
        errors.add(CategoryFieldError.parentInvalid);
      } else {
        // Une sous-catégorie reprend l'icône de son parent.
        iconKey = parent.iconKey;
      }
    }
    if (errors.isEmpty &&
        await _isNameTaken(name, draft.kind, parentId: parentId)) {
      errors.add(CategoryFieldError.nameTaken);
    }
    if (errors.isNotEmpty) return Err(ValidationFailure(errors));

    final id = _newId();
    final now = _nowMs();
    await _categories.insertOne(
      CategoriesCompanion.insert(
        id: id,
        name: name,
        kind: draft.kind.storageValue,
        icon: iconKey,
        parentId: Value(parentId),
        sortOrder: await _nextSortOrder(),
        isCustom: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return Ok((await _get(id))!);
  });

  Future<Result<Category>> rename(String id, String newName) =>
      _guard(() async {
        final category = await _get(id);
        if (category == null) return const Err(NotFoundFailure());
        if (!category.canRename) return const Err(NotAllowedFailure());

        final name = CategoryDraft.normalize(newName);
        final errors = CategoryDraft.validateName(name);
        if (errors.isEmpty &&
            await _isNameTaken(
              name,
              category.kind,
              parentId: category.parentId,
              excludeId: id,
            )) {
          errors.add(CategoryFieldError.nameTaken);
        }
        if (errors.isNotEmpty) return Err(ValidationFailure(errors));

        await (_db.update(_categories)..where((c) => c.id.equals(id))).write(
          CategoriesCompanion(name: Value(name), updatedAt: Value(_nowMs())),
        );
        return Ok((await _get(id))!);
      });

  Future<Result<void>> setHidden(String id, {required bool hidden}) =>
      _guard(() async {
        final category = await _get(id);
        if (category == null) return const Err(NotFoundFailure());
        if (!category.canHide) return const Err(NotAllowedFailure());

        final now = _nowMs();
        await (_db.update(_categories)..where((c) => c.id.equals(id))).write(
          CategoriesCompanion(
            hiddenAt: Value(hidden ? now : null),
            updatedAt: Value(now),
          ),
        );
        return const Ok(null);
      });

  /// Nombre d'opérations rattachées à la catégorie et à ses sous-catégories
  /// (message de confirmation de suppression).
  Future<int> operationCount(String id) async {
    final ids = await _withChildren(id);
    final count = _db.transactions.id.count();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([count])
      ..where(_db.transactions.categoryId.isIn(ids));
    return (await query.getSingle()).read(count) ?? 0;
  }

  /// Supprime une catégorie personnalisée. Ses opérations passent vers
  /// « Autre » (catégorie principale) ou vers la catégorie parente
  /// (sous-catégorie). Tout ou rien : une seule transaction SQLite.
  Future<Result<void>> delete(String id) => _guard(() async {
    final category = await _get(id);
    if (category == null) return const Err(NotFoundFailure());
    if (!category.canDelete) return const Err(NotAllowedFailure());

    final target = category.parentId ?? category.kind.fallbackId;
    final ids = await _withChildren(id);
    await _db.transaction(() async {
      await (_db.update(
        _db.transactions,
      )..where((t) => t.categoryId.isIn(ids))).write(
        TransactionsCompanion(
          categoryId: Value(target),
          updatedAt: Value(_nowMs()),
        ),
      );
      // Les sous-catégories d'abord (clé étrangère vers le parent).
      await (_db.delete(_categories)..where((c) => c.parentId.equals(id))).go();
      await (_db.delete(_categories)..where((c) => c.id.equals(id))).go();
    });
    return const Ok(null);
  });

  Future<List<String>> _withChildren(String id) async {
    final children = await (_db.select(
      _categories,
    )..where((c) => c.parentId.equals(id))).get();
    return [id, for (final child in children) child.id];
  }

  /// Noms uniques entre catégories sœurs (même type et même parent), sans
  /// tenir compte de la casse.
  Future<bool> _isNameTaken(
    String name,
    CategoryKind kind, {
    String? parentId,
    String? excludeId,
  }) async {
    final c = _categories;
    final query = _db.selectOnly(c)
      ..addColumns([c.id])
      ..where(
        c.kind.equals(kind.storageValue) &
            c.name.lower().equalsExp(Variable(name).lower()) &
            (parentId == null
                ? c.parentId.isNull()
                : c.parentId.equals(parentId)) &
            (excludeId == null
                ? const Constant(true)
                : c.id.equals(excludeId).not()),
      )
      ..limit(1);
    return (await query.getSingleOrNull()) != null;
  }

  Future<int> _nextSortOrder() async {
    final max = _categories.sortOrder.max();
    final row = await (_db.selectOnly(
      _categories,
    )..addColumns([max])).getSingle();
    return (row.read(max) ?? 0) + 1;
  }

  Future<Category?> _get(String id) async {
    final row = await (_db.select(
      _categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : toCategory(row);
  }

  int _nowMs() => _clock().toUtc().millisecondsSinceEpoch;

  /// Convertit les erreurs SQLite inattendues en [StorageFailure].
  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      return Err(StorageFailure(error, stackTrace));
    }
  }

  static Category toCategory(CategoryRow row) => Category(
    id: row.id,
    name: row.name,
    kind: CategoryKind.fromStorage(row.kind),
    iconKey: row.icon,
    parentId: row.parentId,
    isCustom: row.isCustom,
    hiddenAt: row.hiddenAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.hiddenAt!, isUtc: true),
  );
}
