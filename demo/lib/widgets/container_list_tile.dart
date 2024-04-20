import 'package:flutter/material.dart';
import 'package:tswiri/providers.dart';
import 'package:tswiri_database/collections/cataloged_container/cataloged_container.dart';
import 'package:tswiri_database/space/space.dart';

class CatalogedContainerListTile extends ConsumerWidget {
  final CatalogedContainer container;
  final void Function(CatalogedContainer container) onTap;

  const CatalogedContainerListTile({
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
