import 'package:isar/isar.dart';
part 'container_photo.g.dart';

@Collection()
class ContainerPhoto {
  int id = Isar.autoIncrement;

  late String containerUID;

  late String photoPath;

  @override
  String toString() {
    return 'UID: $containerUID: Tag: $photoPath';
  }
}
