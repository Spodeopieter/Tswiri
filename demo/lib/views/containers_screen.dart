import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tswiri/providers.dart';
import 'package:tswiri/routes.dart';
import 'package:tswiri/views/abstract_screen.dart';
import 'package:tswiri_database/collections/collections_export.dart';
import 'package:tswiri_database/utils.dart';

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
  /// Returns a list of all [ContainerRelationship]s.
  Future<List<CatalogedContainer>> catalogedContainers() async {
    return db.catalogedContainers.where().findAll();
  }

  ContainerScreenState state = ContainerScreenState.normal;
  bool get isNormal => state == ContainerScreenState.normal;
  bool get isEditing => state == ContainerScreenState.editing;
  bool get isSearching => state == ContainerScreenState.searching;

  final searchFocusNode = FocusNode();

  //TODO: implement custom scroll view with search bar

  @override
  Widget build(BuildContext context) {
    final body = StreamBuilder(
      stream: db.catalogedContainers.watchLazy(),
      builder: (context, snapshot) {
        return FutureBuilder<List<CatalogedContainer>>(
          future: catalogedContainers(),
          initialData: null,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              // If there is an error, display a message on the screen.
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else if (!snapshot.hasData) {
              // If the snapshot is still loading, display a loading indicator.
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.data!.isEmpty) {
              // If there is no data, display a message on the screen.
              return const Center(
                child: Text('No Containers found'),
              );
            } else {
              // If there is data, display a list of items.
              final items = snapshot.data!;

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return CatalogedContainerWidget(
                    container: item,
                    onTap: () => _onTileTap(item),
                  );
                },
              );
            }
          },
        );
      },
    );

    final searchAction = IconButton(
      onPressed: _startSearch,
      icon: const Icon(Icons.search),
    );

    final scanAction = IconButton(
      tooltip: 'Scan Barcode',
      onPressed: _scanBarcode,
      icon: const Icon(Icons.scanner),
    );

    final editButton = IconButton(
      onPressed: _startEdit,
      icon: const Icon(Icons.edit),
    );

    final resetButton = IconButton(
      tooltip: 'Cancel',
      onPressed: _resetState,
      icon: const Icon(Icons.close),
    );

    final searchBar = TextFormField(
      focusNode: searchFocusNode,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      ),
    );

    final appBar = AppBar(
      leading: isNormal ? editButton : null,
      title: isSearching ? searchBar : null,
      actions: [
        if (isNormal) scanAction,
        if (isNormal) searchAction,
        if (!isNormal) resetButton,
      ],
    );

    return Scaffold(
      appBar: appBar,
      body: body,
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

    // ignore: use_build_context_synchronously
    Navigator.of(context).pushNamed(Routes.container, arguments: container);
  }

  void _startEdit() {
    setState(() {
      state = ContainerScreenState.editing;
    });
  }

  void _startSearch() {
    setState(() {
      state = ContainerScreenState.searching;
      searchFocusNode.requestFocus();
    });
  }

  void _resetState() {
    setState(() {
      state = ContainerScreenState.normal;
      searchFocusNode.unfocus();
    });
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
  final void Function() onTap;

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
        onTap: onTap,
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
