import 'package:isar/isar.dart';
part 'cataloged_container.g.dart';

///Stores details about a container (Created by user).
///
///  - ```containerUID``` Unique identifier.
///  - ```containerTypeID``` Type of container [ContainerType].
///  - ```name``` Name of the container.
///  - ```description``` Description of the container.
///  - ```barcodeUID``` Barcode linked to this container.
@Collection()
@Name("CatalogedContainer")
class CatalogedContainer {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String containerUUID;
  late String typeUUID;
  late String? name;
  late String? description;
  late String? barcodeUUID;

  @override
  String toString() {
    return '\nUID: $containerUUID, Type: $typeUUID, Name: $name, Description: $description, BarcodeUID $barcodeUUID';
  }

  @ignore
  Map get json => {
        'id': id,
        'containerUID': containerUUID,
        'containerTypeID': typeUUID,
        'name': name,
        'description': description,
        'barcodeUID': barcodeUUID,
      };

  CatalogedContainer fromJson(Map<String, dynamic> json) {
    return CatalogedContainer()
      ..id = json['id']
      ..containerUUID = json['containerUID']
      ..typeUUID = json['containerTypeID']
      ..name = json['name']
      ..description = json['description']
      ..barcodeUUID = json['barcodeUID'];
  }

  CatalogedContainer clone() {
    return CatalogedContainer()
      ..id = id
      ..containerUUID = containerUUID
      ..typeUUID = typeUUID
      ..name = name
      ..description = description
      ..barcodeUUID = barcodeUUID;
  }

  @override
  bool operator ==(Object other) {
    return other is CatalogedContainer &&
        other.containerUUID == containerUUID &&
        other.typeUUID == typeUUID &&
        other.name == name &&
        other.description == description &&
        other.barcodeUUID == barcodeUUID;
  }

  @override
  int get hashCode => Object.hash(
        containerUUID,
        typeUUID,
        name,
        description,
        barcodeUUID,
      );
}
