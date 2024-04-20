part of space;

extension ContainerTypeExtension on Space {
  /// The list of all container types in the current space.
  List<ContainerType> get containerTypes {
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

