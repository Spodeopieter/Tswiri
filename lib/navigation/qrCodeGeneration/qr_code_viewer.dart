import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

class Calendar extends StatelessWidget {
  Calendar({
    this.date,
    this.month,
    this.year,
  });

  final DateTime? date;

  final int? month;

  final int? year;

  Widget title(
    Context context,
    DateTime date,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: Text(
        DateFormat.yMMMM().format(date),
        style: const TextStyle(
          color: PdfColors.deepPurple,
          fontSize: 40,
        ),
      ),
    );
  }

  Widget header(
    Context context,
    DateTime date,
  ) {
    return Container(
      color: PdfColors.blue200,
      padding: const EdgeInsets.only(top: 8, left: 8, bottom: 8),
      child: Text(
        DateFormat.EEEE().format(date),
        style: const TextStyle(
          fontSize: 15,
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }

  Widget day(
    Context context,
    DateTime date,
    bool currentMonth,
    bool currentDay,
  ) {
    var text = '${date.day}';
    var style = const TextStyle();
    var color = PdfColors.grey300;

    if (currentDay) {
      style = const TextStyle(color: PdfColors.red);
      color = PdfColors.lightBlue50;
    }

    if (!currentMonth) {
      style = const TextStyle(color: PdfColors.grey);
      color = PdfColors.grey100;
    }

    if (date.day == 1) {
      text += ' ' + DateFormat.MMM().format(date);
    }

    return Container(
      padding: const EdgeInsets.all(4),
      color: color,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: style,
      ),
    );
  }

  @override
  Widget build(Context context) {
    final _date = date ?? DateTime.now();
    final _year = year ?? _date.year;
    final _month = month ?? _date.month;

    final start = DateTime(_year, _month, 1, 12);
    final end = DateTime(_year, _month + 1, 1, 12).subtract(
      const Duration(days: 1),
    );

    final startId = start.weekday - 1;
    final endId = end.difference(start).inDays + startId + 1;

    final head = Row(
      mainAxisSize: MainAxisSize.max,
      children: List<Widget>.generate(7, (int index) {
        final d = start.add(Duration(days: index - startId));
        return Expanded(
          child: Container(
            foregroundDecoration: BoxDecoration(
              border: Border(
                top: const BorderSide(color: PdfColors.grey),
                left: const BorderSide(color: PdfColors.grey),
                right: index % 7 == 6
                    ? const BorderSide(color: PdfColors.grey)
                    : BorderSide.none,
                bottom: const BorderSide(color: PdfColors.grey),
              ),
            ),
            child: header(context, d),
          ),
        );
      }),
    );

    final body = GridView(
      crossAxisCount: 7,
      children: List<Widget>.generate(42, (int index) {
        final d = start.add(Duration(days: index - startId));
        final currentMonth = index >= startId && index < endId;
        final currentDay = d.year == _date.year &&
            d.month == _date.month &&
            d.day == _date.day;
        return Container(
          foregroundDecoration: BoxDecoration(
              border: Border(
            left: const BorderSide(color: PdfColors.grey),
            right: index % 7 == 6
                ? const BorderSide(color: PdfColors.grey)
                : BorderSide.none,
            bottom: const BorderSide(color: PdfColors.grey),
          )),
          child: day(context, d, currentMonth, currentDay),
        );
      }),
    );

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          title(context, DateTime(_year, _month)),
          head,
          Expanded(child: body),
        ],
      ),
    );
  }
}
