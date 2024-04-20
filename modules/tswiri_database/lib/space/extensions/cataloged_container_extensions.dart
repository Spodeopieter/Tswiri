part of space;

extension CatalogedContainerExtension on Space {
  Future<List<CatalogedContainer>> get catalogedContainers {
    return db!.catalogedContainers.where().findAll();
  }

  /// Get the [CatalogedContainer] with the given barcodeUUID or containerUUID.
  ///
  /// TODO: remove all sync methods.
  CatalogedContainer? getCatalogedContainerSync({
    String? barcodeUUID,
    String? containerUUID,
  }) {
    _assertLoaded();

    assert(
      (barcodeUUID == null) != (containerUUID == null),
      'Only a barcodeUUID or containerUUID must be provided',
    );

    if (barcodeUUID != null) {
      return db?.catalogedContainers
          .filter()
          .barcodeUUIDEqualTo(barcodeUUID)
          .findFirstSync();
    } else if (containerUUID != null) {
      return db?.catalogedContainers
          .filter()
          .containerUUIDEqualTo(containerUUID)
          .findFirstSync();
    } else {
      return null;
    }
  }

  /// Get the [CatalogedContainer] with the given barcodeUUID or containerUUID.
  Future<CatalogedContainer?> getCatalogedContainer({
    String? barcodeUUID,
    String? containerUUID,
  }) async {
    _assertLoaded();

    assert(
      (barcodeUUID == null) != (containerUUID == null),
      'Only a barcodeUUID or containerUUID must be provided',
    );

    if (barcodeUUID != null) {
      return db?.catalogedContainers
          .filter()
          .barcodeUUIDEqualTo(barcodeUUID)
          .findFirst();
    } else if (containerUUID != null) {
      return db?.catalogedContainers
          .filter()
          .containerUUIDEqualTo(containerUUID)
          .findFirst();
    } else {
      return null;
    }
  }

  /// This deletes the [CatalogedContainer] and all its [ContainerRelationship]s in the database.
  Future<bool> deleteCatalogedContainer(String containerUUID) async {
    _assertLoaded();

    final canDelete = canDeleteContainer(containerUUID);
    if (canDelete == false) {
      return false;
    }

    final result = await db?.writeTxn(() async {
      await db?.catalogedContainers
          .filter()
          .containerUUIDEqualTo(containerUUID)
          .deleteFirst();

      await db?.containerRelationships
          .filter()
          .containerUUIDContains(containerUUID)
          .deleteAll();

      await db?.containerRelationships
          .filter()
          .parentContainerUUIDEqualTo(containerUUID)
          .deleteAll();

      return true;
    });

    return result ?? false;
  }

  /// Check this container can be deleted.
  bool canDeleteContainer(String containerUUID) {
    _assertLoaded();

    final children = db!.containerRelationships
        .filter()
        .parentContainerUUIDEqualTo(containerUUID)
        .findAllSync();

    if (children.isNotEmpty) {
      return false;
    }

    return true;
  }
}
