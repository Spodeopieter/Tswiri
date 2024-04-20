part of space;

extension CatalogedBarcodeExtension on Space {
  /// Get the [CatalogedBarcode] with the given barcodeUUID.
  ///
  /// TODO: remove all sync methods.
  CatalogedBarcode? getCatalogedBarcode(String? barcodeUUID) {
    _assertLoaded();

    if (barcodeUUID == null) return null;
    return db?.catalogedBarcodes
        .filter()
        .barcodeUUIDEqualTo(barcodeUUID)
        .findFirstSync();
  }
}
