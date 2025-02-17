import 'dart:math';

import 'package:flutter/material.dart';

export 'sales_report.dart';

abstract class Report {
  final DateTime fromDate;
  final DateTime toDate;
  final String title;

  Report({
    required this.title,
    required this.fromDate,
    required this.toDate,
  });

  Map<String, Color> get legends;

  Widget toGraphWidget();
}

class ReportView extends StatelessWidget {
  const ReportView({
    super.key,
    required this.reports,
    required this.fromDate,
    required this.toDate,
    this.projectCode,
  });

  @override
  Key? get key => Key(Random().nextDouble().toString());

  final String? projectCode;
  final DateTime fromDate;
  final DateTime toDate;
  final List<Report> reports;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(reports.length, (i) {
            return ConstrainedBox(
              constraints: constraints,
              child: reports[i].toGraphWidget(),
            );
          }),
        ),
      ),
    );
  }
}
