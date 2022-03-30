import 'package:flutter_google_ml_kit/isar_database/container_entry/container_entry.dart';
import 'package:flutter_google_ml_kit/isar_database/container_photo/container_photo.dart';

//Used to show relevant photos
class ContainerSearchBuilder {
  ContainerSearchBuilder({required this.containerEntry, this.containerPhotos});
  //The contaienr entry is required.
  final ContainerEntry containerEntry;

  //The photos are to show relevant photos for the user.
  List<ContainerPhoto>? containerPhotos;
}
