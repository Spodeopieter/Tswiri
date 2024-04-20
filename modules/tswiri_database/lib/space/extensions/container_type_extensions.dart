part of space;

extension ContainerTypeExtension on Space {
  /// Get the list of all container types in the current space. (asynchronous)
  Future<List<ContainerType>> get containerTypes async {
    return db!.containerTypes.where().findAll();
  }

  /// The list of all container types in the current space. (synchronous)
  List<ContainerType> get containerTypesSync {
    _assertLoaded();
    return db!.containerTypes.where().findAllSync();
  }

  /// Get the container type with the given UUID.
  ContainerType? getContainerType(String? typeUUID) {
    _assertLoaded();
    if (typeUUID == null) return null;
    return db?.containerTypes.filter().uuidMatches(typeUUID).findFirstSync();
  }
}
