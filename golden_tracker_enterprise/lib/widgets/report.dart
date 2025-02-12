import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../widgets/bar_graph.dart';

abstract class Report {
  final DateTime fromDate;
  final DateTime toDate;
  final String title;

  Report({
    required this.title,
    required this.fromDate,
    required this.toDate,
  });

  final Map<String, Color> _legends = {};

  Widget toGraphWidget();
}

enum SalesReport {
  monthlySales,
  salesPerInventory,
  yearlySalesOverall;

  Report? generate(List data, DateTime fromDate, DateTime toDate) {
    switch (this) {
      case SalesReport.monthlySales:
        return _MonthlySalesReport(
          sales: data,
          fromDate: fromDate,
          toDate: toDate,
        );
      default:
        return null;
    }
  }
}

class _MonthlySalesReport implements Report {
  late final Map<String, double> monthlySales;

  @override
  final DateTime fromDate;

  @override
  final DateTime toDate;

  @override
  final String title = 'Monthly Sales';

  @override
  final Map<String, Color> _legends = {'Sales': Colors.green};

  _MonthlySalesReport({
    required List sales,
    required this.fromDate,
    required this.toDate,
  }) {
    // Compute monthly sales
    Map<String, double> monthlySales = {};

    final DateFormat dateFormatter = DateFormat(
      fromDate.year != toDate.year ? 'MMM yyyy' : 'MMM',
    );

    DateTime startDate = DateTime(fromDate.year, fromDate.month);

    while(startDate.isBefore(toDate)) {
      monthlySales[dateFormatter.format(startDate)] = 0;
      startDate = startDate.copyWith(month: startDate.month + 1);
    }

    for (var sale in sales) {
      DateTime date = DateTime.parse(sale['reservation_date']);
      String key = dateFormatter.format(date);

      String cleanPrice =
          sale['total_contract_price'].replaceAll(RegExp(r'[^\d.]'), '');

      double price = double.parse(cleanPrice);

      monthlySales[key] = (monthlySales[key] ?? 0) + price;
    }

    this.monthlySales = monthlySales;
  }

  @override
  Widget toGraphWidget() {
    Iterable<String> months = monthlySales.keys;
    return BarGraph(
      title: title,
      data: BarGraphData(
        legends: _legends,
        barGroups: List.generate(monthlySales.length, (i) {
          String month = months.elementAt(i);
          return BarGroup(
            label: month,
            barRods: [
              SolidBarRod(label: 'Sales', toY: monthlySales[month] ?? 0)
            ],
          );
        }),
      ),
    );
  }
}