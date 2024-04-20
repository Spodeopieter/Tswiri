part of space;

extension ContainerRelationshipExtension on Space {
  /// Get the [ContainerRelationship] describing the parent of the container with the given UUID.
  ///
  /// TODO: remove all sync methods.
  ContainerRelationship? getParent(String containerUUID) {
    _assertLoaded();

    return db?.containerRelationships
        .filter()
        .containerUUIDEqualTo(containerUUID)
        .findFirstSync();
  }

  /// Get the list of all [ContainerRelationship]s describing the children of the container with the given UUID.
  Future<List<ContainerRelationship>> getChildren(String containerUUID) {
    _assertLoaded();

    return db!.containerRelationships
        .filter()
        .parentContainerUUIDEqualTo(containerUUID)
        .findAll();
  }

  // Get a list of all descendant relationships of the containerUUID.
  List<ContainerRelationship> finalAllDescendants(String containerUUID) {
    _assertLoaded();

    final allRelationships = <ContainerRelationship>[];

    // Initialize the list with the direct children of the given containerUUID.
    var previousRelationships = db!.containerRelationships
        .filter()
        .parentContainerUUIDEqualTo(containerUUID)
        .findAllSync();

    allRelationships.addAll(previousRelationships);

    // Set the maximum number of iterations to prevent infinite loops.
    int iterations = 0;
    const max = 1000;

    while (previousRelationships.isNotEmpty && iterations < max) {
      final newRelationships = <ContainerRelationship>[];

      // Loop through the previous relationships and find their children.
      for (final relationship in previousRelationships) {
        final children = db!.containerRelationships
            .filter()
            .parentContainerUUIDEqualTo(relationship.containerUUID)
            .findAllSync();

        newRelationships.addAll(children);
      }

      // Add the new relationships to the list of all relationships.
      allRelationships.addAll(newRelationships);

      // Set the previous relationships to the new relationships.
      previousRelationships = newRelationships;
    }

    // Return the list of all relationships.
    return allRelationships;
  }

  bool isDescendantOf({
    required String parentUUID,
    required String containerUUID,
  }) {
    _assertLoaded();

    // Get a list of all descendant relationships of the containerUUID.
    final allRelationships = finalAllDescendants(containerUUID);

    // Check if the currentContainerUUID is a descendant of the containerUUID.
    final isDescendant = allRelationships.any(
      (relationship) {
        // Check if the relationship contains the current containerUUID.
        final isParent = relationship.containerUUID == parentUUID;
        final isChild = relationship.parentContainerUUID == parentUUID;

        return isParent || isChild;
      },
    );

    return isDescendant;
  }
}
