import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sunbird/isar/isar_database.dart';
import 'package:sunbird/views/utilities/grids/new_grid/new_grid_view.dart';

import 'grid/grid_viewer_view.dart';

class MarkersView extends StatefulWidget {
  const MarkersView({Key? key}) : super(key: key);

  @override
  State<MarkersView> createState() => _MarkersViewState();
}

class _MarkersViewState extends State<MarkersView> {
  late List<int> grids =
      isar!.catalogedGrids.where().findAllSync().map((e) => e.id).toList();

  @override
  void initState() {
    log(isar!.markers.where().findAllSync().toString());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: _body(),
    );
  }

  AppBar _appBar() {
    return AppBar(
        title: Text(
          'Grids',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: true);
  }

  Widget _body() {
    return ListView.builder(
      itemCount: grids.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _newGridCard();
        } else {
          return _gridCard(grids[index - 1]);
        }
      },
    );
  }

  Widget _gridCard(int gridUID) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ///ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grid UID:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  gridUID.toString(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const Divider(),

            ///Number of containers.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Barcode(s):',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  isar!.catalogedCoordinates
                      .filter()
                      .gridUIDEqualTo(gridUID)
                      .findAllSync()
                      .length
                      .toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const Divider(),

            ///Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GirdViewer(
                          gridUID: gridUID,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'View',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _newGridCard() {
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const NewGridView(),
          ),
        );

        _updateGrids();
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Text(
                '(new grid)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateGrids() {
    setState(() {
      grids =
          isar!.catalogedGrids.where().findAllSync().map((e) => e.id).toList();
    });
  }
}
