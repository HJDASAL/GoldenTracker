import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'report.dart';
import 'bar_graph.dart';

enum SalesReport {
  monthlySales,
  salesPerInventory,
  yearlySalesOverall;

  Report generate(List data, DateTime fromDate, DateTime toDate) {
    if (this == SalesReport.yearlySalesOverall) {
      return _YearlySalesOverall(
        sales: data,
        fromDate: fromDate,
        toDate: toDate,
      );
    } else {
      return _MonthlySalesReport(
        sales: data,
        fromDate: fromDate,
        toDate: toDate,
      );
    }
  }
}

class _YearlySalesOverall implements Report {
  late final Map<int, double> yearlySales;
  @override
  final DateTime fromDate;

  @override
  final DateTime toDate;

  @override
  late final String title;

  @override
  final Map<String, Color> legends = {'Sales': Colors.green};

  _YearlySalesOverall({
    required List sales,
    required this.fromDate,
    required this.toDate,
  }) {
    // Compute yearly sales
    Map<int, double> yearlySales = {};

    for (int year = fromDate.year; year <= toDate.year; year++) {
      yearlySales[year] = 0;
    }

    for (var sale in sales) {
      DateTime date = DateTime.parse(sale['reservation_date']);

      if (yearlySales.containsKey(date.year)) {
        yearlySales[date.year] = yearlySales[date.year]! + 1;
      }
    }

    // remove leading years with zero sales
    for (int year = fromDate.year; year <= toDate.year; year++) {
      if (yearlySales[year] == 0) {
        yearlySales.remove(year);
      } else {
        break;
      }
    }

    if (yearlySales.length > 1) {
      title =
          'Overall Annual Sales (${yearlySales.keys.first} - ${yearlySales.keys.last})';
    } else if (yearlySales.isNotEmpty) {
      title = 'Overall Annual Sales (${yearlySales.keys.first})';
    } else {
      title = 'Overall Annual Sales';
    }

    this.yearlySales = yearlySales;
  }

  @override
  Widget toGraphWidget() {
    Iterable<int> years = yearlySales.keys;

    return BarGraph(
      title: title,
      data: BarGraphData(
        legends: legends,
        barGroups: List.generate(years.length, (i) {
          int year = years.elementAt(i);
          return BarGroup(
            label: year.toString(),
            barRods: [SolidBarRod(label: 'Sales', toY: yearlySales[year] ?? 0)],
          );
        }),
      ),
    );
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
  final Map<String, Color> legends = {'Sales': Colors.green};

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

    while (!startDate.isAfter(toDate)) {
      monthlySales[dateFormatter.format(startDate)] = 0;
      startDate = startDate.copyWith(month: startDate.month + 1);
    }

    for (var sale in sales) {
      DateTime date = DateTime.parse(sale['reservation_date']);
      if (date.isBefore(fromDate) || date.isAfter(toDate)) {
        continue;
      }

      String key = dateFormatter.format(date);

      if (monthlySales.containsKey(key)) {
        monthlySales[key] = monthlySales[key]! + 1;
      }
    }

    this.monthlySales = monthlySales;
  }

  @override
  Widget toGraphWidget() {
    Iterable<String> months = monthlySales.keys;
    return (months.isEmpty)
        ? Placeholder()
        : BarGraph(
            title: title,
            barWidth: 24,
            data: BarGraphData(
              legends: legends,
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
