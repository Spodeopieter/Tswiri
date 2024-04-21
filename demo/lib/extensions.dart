import 'package:intl/intl.dart';

extension StringExt on String {
  int get barcodeNumber {
    return int.parse(split('_').first);
  }

  String get capitalizeFirstCharacter {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

extension DateTimeExt on DateTime {
  String get formatted {
    return DateFormat('yyyy-MM-dd - HH:mm').format(this);
  }
}
