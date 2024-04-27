import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tswiri/isolates/container_filter_worker.dart';
import 'package:tswiri_database/collections/collections_export.dart';
import 'package:tswiri_database/space/space.dart';

/// This is a model class that handles the filtering of [CatalogedContainer]s.
/// It uses a [ContainerFilterWorker] to perform the filtering in a separate isolate.
///
/// The [ContainerFilter] class is responsible for initializing the worker,
/// updating the worker's data, and listening for changes in the worker's results.
///
/// The [ContainerFilter] class also listens for changes in the database and updates
/// the worker's data accordingly.
///
/// The [ContainerFilter] class also listens for changes in the textEditingController
/// and updates the worker's data accordingly.
class ContainerFilter {
  ContainerFilter(this._space) {
    _initialize();
  }

  final Space _space;

  ContainerFilterWorker? worker;
  final initialized = ValueNotifier<bool>(false);
  bool get isInitialized => initialized.value && worker != null;

  final containers = <CatalogedContainer>[];
  final containerTypes = <ContainerType>[];

  final selectedContainerTypes = ValueNotifier<List<ContainerType>>([]);

  final textEditingController = TextEditingController();

  final _results = ValueNotifier<List<CatalogedContainer>>([]);
  ValueNotifier<List<CatalogedContainer>> get results {
    return _results;
  }

  Future<void> _initialize() async {
    // Watch for changes in the db.
    _addWatchers();

    worker = await ContainerFilterWorker.spawn(onUpdated: _onUpdated);

    // Load the containers and container types.
    await _updateContainers();
    await _updateContainerTypes();

    // Update the worker's data.
    worker?.updateIsolateData(
      containers: containers,
      containerTypes: containerTypes,
    );

    // Add listeners.
    _addListeners();

    // Set the initialized flag.
    initialized.value = true;
  }

  void _addWatchers() {
    // Watch for changes to the cataloged containers.
    _space.db?.catalogedContainers
        .watchLazy(fireImmediately: true)
        .listen((event) async {
      await _updateContainers();

      worker?.updateIsolateData(
        containers: containers,
        containerTypes: containerTypes,
      );
    });

    // Watch for changes to the container types.
    _space.db?.containerTypes
        .watchLazy(fireImmediately: true)
        .listen((event) async {
      await _updateContainerTypes();

      worker?.updateIsolateData(
        containers: containers,
        containerTypes: containerTypes,
      );
    });
  }

  void _onUpdated() {
    _filterContainers();
  }

  void _addListeners() {
    // Add a listener to the worker's results.
    worker?.results.addListener(_workerListener);

    // Add a listener to the textEditingController.
    textEditingController.addListener(_keywordListener);
  }

  void _removeListeners() {
    worker?.results.removeListener(_workerListener);
    textEditingController.removeListener(_keywordListener);
  }

  void _keywordListener() {
    _filterContainers();
  }

  void _workerListener() {
    _results.value = worker?.results.value ?? [];
  }

  void _filterContainers() {
    final keyword = textEditingController.text;

    worker?.filter(
      keyword: keyword,
      containerTypes: selectedContainerTypes.value,
    );
  }

  void toggleContainerType(ContainerType containerType) {
    final selected = List<ContainerType>.from(selectedContainerTypes.value);

    if (selected.contains(containerType)) {
      selected.remove(containerType);
    } else {
      selected.add(containerType);
    }

    selectedContainerTypes.value = selected;
    _filterContainers();
  }

  void clearFilters() {
    selectedContainerTypes.value.clear();
    textEditingController.clear();
  }

  void dispose() {
    worker?.close();
    _removeListeners();
  }

  /// Load [CatalogedContainer] from the database.
  Future<void> _updateContainers() async {
    containers.clear();
    containers.addAll(await _space.catalogedContainers);
  }

  /// Load [ContainerType] from the database.
  Future<void> _updateContainerTypes() async {
    containerTypes.clear();
    containerTypes.addAll(await _space.containerTypes);
  }
}
