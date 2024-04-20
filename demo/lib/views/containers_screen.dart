import 'package:flutter/material.dart';
import 'package:tswiri/isolates/container_filter_isolate.dart';

import 'package:tswiri/providers.dart';
import 'package:tswiri/routes.dart';
import 'package:tswiri/views/abstract_screen.dart';
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
  final searchFocusNode = FocusNode();
  final searchTextEditingController = TextEditingController();

  final stateNotifier = ValueNotifier(ContainerScreenState.normal);
  ContainerScreenState get state => stateNotifier.value;
  set state(ContainerScreenState state) {
    stateNotifier.value = state;
  }

  bool get isNormal => state == ContainerScreenState.normal;
  bool get isEditing => state == ContainerScreenState.editing;
  bool get isSearching => state == ContainerScreenState.searching;

  late final containerFilterIsolate = ContainerFilterIsolate.spawn();

  @override
  void initState() {
    super.initState();

    containerFilterIsolate.then((value) async {
      // Send the cataloged containers to the isolate.
      value.updateIsolateData(
        containers: await catalogedContainers,
        containerTypes: await containerTypes,
      );

      //  Listen for changes to the cataloged containers.
      db.catalogedContainers.watchLazy().listen((event) async {
        value.updateIsolateData(
          containers: await catalogedContainers,
          containerTypes: await containerTypes,
        );
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    containerFilterIsolate.then((value) => value.close());
  }

  @override
  Widget build(BuildContext context) {
    final containersView = FutureBuilder(
      future: containerFilterIsolate,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          final worker = snapshot.data!;

          return ValueListenableBuilder(
            valueListenable: worker.results,
            builder: (context, items, child) {
              return SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return CatalogedContainerWidget(
                    container: item,
                    onTap: _onTileTap,
                  );
                },
              );
            },
          );
        }
      },
    );

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

    late final resetButton = IconButton(
      tooltip: 'Cancel',
      onPressed: _resetState,
      icon: const Icon(Icons.close),
    );

    late final searchBar = TextFormField(
      focusNode: searchFocusNode,
      controller: searchTextEditingController,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      ),
      onFieldSubmitted: (value) {},
      onChanged: (keyWord) {
        containerFilterIsolate.then((value) {
          value.filter(keyWord);
        });
      },
    );

    late final searchChips = ValueListenableBuilder(
      valueListenable: stateNotifier,
      builder: (context, value, child) {
        if (!isSearching) return const SliverToBoxAdapter();

        return FutureBuilder(
          future: containerTypes,
          builder: (context, snapshot) {
            if (snapshot.hasError) return const SliverToBoxAdapter();
            if (!snapshot.hasData) return const SliverToBoxAdapter();
            final containerTypes = snapshot.data!;

            final chips = containerTypes.map((containerType) {
              return Chip(
                label: Text(containerType.name),
                onDeleted: () {},
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
            if (!isNormal) resetButton,
          ],
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

class CatalogedContainerWidget extends ConsumerWidget {
  final CatalogedContainer container;
  final void Function(CatalogedContainer container) onTap;

  const CatalogedContainerWidget({
    super.key,
    required this.container,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.read(spaceProvider);
    final containerType = space.getContainerType(container.typeUUID);
    final name = Text(container.name.toString());
    final description =
        container.description != null && container.description!.isNotEmpty
            ? Text(container.description.toString())
            : null;

    final leading = Tooltip(
      message: containerType?.name,
      child: Icon(
        containerType?.iconData.iconData,
        color: containerType?.color.color,
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(container),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: leading,
              title: name,
              subtitle: description,
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: Text(
                container.barcodeUUID.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
