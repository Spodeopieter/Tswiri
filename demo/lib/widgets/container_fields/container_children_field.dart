import 'package:flutter/material.dart';
import 'package:tswiri/providers.dart';
import 'package:tswiri/routes.dart';
import 'package:tswiri_database/collections/collections_export.dart';
import 'package:tswiri_database/space/space.dart';

class ContainerChildrenField extends ConsumerWidget {
  const ContainerChildrenField({
    super.key,
    required this.containerUUID,
    this.expanded = false,
    this.onExpansionChanged,
    required this.onAddChild,
  });
  final String containerUUID;
  final bool expanded;
  final Function(bool)? onExpansionChanged;
  final Function() onAddChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.read(spaceProvider);
    final scrollController = ScrollController();

    return FutureBuilder(
      future: space.getChildren(containerUUID),
      initialData: null,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final children = snapshot.data as List<ContainerRelationship>;

        late final emptyTile = InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Children'),
            subtitle: const Text('No children found'),
            trailing: IconButton.filledTonal(
              tooltip: 'Create child',
              onPressed: () {
                onAddChild();
              },
              icon: const Icon(Icons.add),
            ),
          ),
        );

        late final shape = OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        );

        late final collapsedShape = OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        );

        late final addChildCard = Card(
          elevation: 10,
          margin: const EdgeInsets.all(4.0),
          child: ListTile(
            title: const Text('Add Child'),
            onTap: () {
              onAddChild();
            },
            trailing: const Icon(Icons.add),
          ),
        );

        late final childrenScroll = Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          radius: const Radius.circular(4),
          child: ListView.builder(
            controller: scrollController,
            shrinkWrap: true,
            itemCount: children.length,
            itemBuilder: (context, index) {
              final relationship = children[index];

              return FutureBuilder<CatalogedContainer?>(
                future: space.getCatalogedContainer(
                  containerUUID: relationship.containerUUID,
                ),
                builder: (context, snapshot) {
                  final loading =
                      snapshot.connectionState == ConnectionState.waiting;
                  final hasError = snapshot.hasError;
                  final hasData = snapshot.hasData;
                  final data = snapshot.data;

                  final title = loading
                      ? const CircularProgressIndicator()
                      : hasError
                          ? Text('Error: ${snapshot.error}')
                          : hasData
                              ? Text(data!.name.toString())
                              : null;

                  final hasDescription = data?.description != null &&
                      data!.description!.isNotEmpty;

                  final subtitle = loading
                      ? null
                      : hasError
                          ? null
                          : hasData
                              ? Text(
                                  hasDescription ? data.description! : '-',
                                )
                              : null;

                  return Card(
                    elevation: 5,
                    margin: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: title,
                      subtitle: subtitle,
                      trailing: const Icon(Icons.open_in_new_outlined),
                      onTap: () => Navigator.pushNamed(
                        context,
                        Routes.container,
                        arguments: data,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );

        late final expansionTile = ExpansionTile(
          title: const Text('Children'),
          subtitle: Text('${children.length} children'),
          maintainState: true,
          initiallyExpanded: expanded,
          onExpansionChanged: (value) {
            onExpansionChanged?.call(value);
          },
          shape: shape,
          collapsedShape: collapsedShape,
          children: [
            addChildCard,
            const Divider(),
            LimitedBox(
              maxHeight: 300,
              child: childrenScroll,
            )
          ],
        );

        return children.isEmpty ? emptyTile : expansionTile;
      },
    );
  }
}
