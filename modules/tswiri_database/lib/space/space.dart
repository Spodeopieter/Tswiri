library space;

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:tswiri_database/collections/collections_export.dart';
import 'package:tswiri_database/defaults/default_container_types.dart';

part 'package:tswiri_database/space/extensions/cataloged_container_extensions.dart';
part 'package:tswiri_database/space/extensions/container_type_extensions.dart';
part 'package:tswiri_database/space/extensions/cataloged_barcode_extensions.dart';
part 'package:tswiri_database/space/extensions/cataloged_relationship_extensions.dart';

final schemas = [
  BarcodeBatchSchema,
  CatalogedBarcodeSchema,
  CameraCalibrationEntrySchema,
  CatalogedContainerSchema,
  ContainerRelationshipSchema,
  ContainerTagSchema,
  ContainerTypeSchema,
  CatalogedGridSchema,
  MLDetectedLabelTextSchema,
  MLPhotoLabelSchema,
  PhotoLabelSchema,
  MLObjectSchema,
  MLObjectLabelSchema,
  ObjectLabelSchema,
  MLDetectedElementTextSchema,
  MLTextBlockSchema,
  MLTextElementSchema,
  MLTextLineSchema,
  PhotoSchema,
  MarkerSchema,
  CatalogedCoordinateSchema,
  TagTextSchema,
];

/// TODO: Isar migration: https://isar.dev/recipes/data_migration.html

class Space with ChangeNotifier {
  Space();

  String? _databasePath;
  String? get spacePath => _databasePath;
  String? get photoPath => '$_databasePath/photos';

  Isar? _db;
  Isar? get db => _db;

  bool get isLoaded => _db != null;

  /// Switch to this space.
  Future<void> loadSpace({
    required String spacePath,
    bool inspector = false,
  }) async {
    log('Loading space: $spacePath', name: 'Space');

    // Check if databasePath exists.
    if (!await Directory(spacePath).exists()) {
      _databasePath = (await Directory(spacePath).create()).path;
    } else {
      _databasePath = spacePath;
    }

    // Check if photo path exists.
    if (!await Directory(photoPath!).exists()) {
      await Directory(photoPath!).create();
    }

    _db = await Isar.open(
      schemas,
      directory: spacePath,
      inspector: inspector,
    );

    await _loadDefaults(_db!);

    notifyListeners();
  }

  Future<void> _loadDefaults(Isar isar) async {
    final types = await isar.containerTypes.where().findAll();

    if (types.isNotEmpty) return;

    final defaultTypes = generateDefaultContainerTypes();

    await isar.writeTxn(() async {
      isar.containerTypes.putAll(defaultTypes);
    });
  }

  void _assertLoaded() {
    assert(isLoaded, 'Space must be loaded');
  }
}
