import 'package:flutter/material.dart';
import 'package:tswiri/models/container_filter.dart';

import 'package:tswiri/providers.dart';
import 'package:tswiri/routes.dart';
import 'package:tswiri/views/abstract_screen.dart';
import 'package:tswiri/widgets/container_list_tile.dart';
import 'package:tswiri_database/collections/collections_export.dart';
import 'package:tswiri_database/space/space.dart';

class ContainersScreen extends ConsumerStatefulWidget {
  const ContainersScreen({super.key});

  @override
  ConsumerState<ContainersScreen> createState() => _ContainersScreenState();
}

enum ContainerScreenState {
  normal,
  searching,
  editing,
}

class _ContainersScreenState extends AbstractScreen<ContainersScreen> {
  final stateNotifier = ValueNotifier(ContainerScreenState.normal);
  ContainerScreenState get state => stateNotifier.value;
  set state(ContainerScreenState state) {
    stateNotifier.value = state;
  }

  bool get isNormal => state == ContainerScreenState.normal;
  bool get isEditing => state == ContainerScreenState.editing;
  bool get isSearching => state == ContainerScreenState.searching;

  final searchFocusNode = FocusNode();

  late final containerFilter = ContainerFilter(space);

  @override
  void dispose() {
    super.dispose();
    // containerFilterIsolate.then((value) => value.close());
    containerFilter.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late final searchAction = IconButton(
      onPressed: _startSearch,
      icon: const Icon(Icons.search),
    );

    late final scanAction = IconButton(
      tooltip: 'Scan Barcode',
      onPressed: _scanBarcode,
      icon: const Icon(Icons.scanner),
    );

    late final editButton = IconButton(
      onPressed: _startEdit,
      icon: const Icon(Icons.edit),
    );

    late final cancelButton = IconButton(
      tooltip: 'Cancel',
      onPressed: _resetState,
      icon: const Icon(Icons.close),
    );

    late final searchBar = TextFormField(
      focusNode: searchFocusNode,
      controller: containerFilter.textEditingController,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      ),
    );

    final appBar = ValueListenableBuilder(
      valueListenable: stateNotifier,
      builder: (context, value, child) {
        return SliverAppBar(
          pinned: true,
          leading: isNormal ? editButton : null,
          title: isSearching ? searchBar : null,
          actions: [
            if (isNormal) ...[
              scanAction,
              searchAction,
            ],
            if (!isNormal) cancelButton,
          ],
        );
      },
    );

    final searchChips = ValueListenableBuilder(
      valueListenable: stateNotifier,
      builder: (context, value, child) {
        if (!isSearching) return const SliverToBoxAdapter();

        return ValueListenableBuilder(
          valueListenable: containerFilter.selectedContainerTypes,
          builder: (context, value, child) {
            final containerTypes = containerFilter.containerTypes;
            if (containerTypes.isEmpty) return const SliverToBoxAdapter();

            final selectedTypes = containerFilter.selectedContainerTypes.value;

            final chips = containerTypes.map((containerType) {
              return FilterChip(
                label: Text(containerType.name),
                onSelected: (value) {
                  containerFilter.toggleContainerType(containerType);
                },
                selected: selectedTypes.contains(containerType),
              );
            });

            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 4,
                  children: chips.toList(),
                ),
              ),
            );
          },
        );
      },
    );

    final containersView = ValueListenableBuilder(
      valueListenable: containerFilter.results,
      builder: (context, containers, child) {
        if (containers.isEmpty && containerFilter.isInitialized) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Text('No containers found'),
            ),
          );
        } else if (containers.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return SliverList.builder(
          itemCount: containers.length,
          itemBuilder: (context, index) {
            final item = containers[index];
            return CatalogedContainerListTile(
              container: item,
              onTap: _onTileTap,
            );
          },
        );
      },
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          appBar,
          searchChips,
          containersView,
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, Routes.createContainer);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Container'),
      ),
    );
  }

  void _scanBarcode() async {
    final barcodeUUID = await scanBarcode();
    if (barcodeUUID == null) return;

    final container = await space.getCatalogedContainer(
      barcodeUUID: barcodeUUID,
    );

    if (container == null) {
      showSnackbar('No container linked');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushNamed(Routes.container, arguments: container);
  }

  void _startEdit() {
    state = ContainerScreenState.editing;
  }

  void _startSearch() {
    state = ContainerScreenState.searching;
    searchFocusNode.requestFocus();
  }

  void _resetState() {
    state = ContainerScreenState.normal;
    searchFocusNode.unfocus();
    containerFilter.clearFilters();
  }

  void _onTileTap(CatalogedContainer container) {
    if (isEditing) {
      /// TODO: add to editing list.
    } else {
      Navigator.pushNamed(
        context,
        Routes.container,
        arguments: container,
      );
    }
  }
}
