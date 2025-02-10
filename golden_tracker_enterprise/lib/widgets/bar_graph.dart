import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/index.dart';

class BarGraph extends StatefulWidget {
  const BarGraph({
    super.key,
    required this.title,
    this.mirrorXAxisLabels = false,
    this.mirrorYAxisLabels = false,
  });

  final String title;
  final bool mirrorXAxisLabels;
  final bool mirrorYAxisLabels;

  @override
  State<BarGraph> createState() => _BarGraphState();
}

class _BarGraphState extends State<BarGraph> {
  BarChart _chartBuilder() {
    // TODO: Add slider for scrolling
    return BarChart(BarChartData());
  }

  Widget _responsiveBuild(BuildContext context, Layout layout) {
    return Container(
      width: layout.size.width,
      height: layout.size.height,
      padding: EdgeInsets.all(12),
      child: Flex(
        direction: Axis.vertical,
        children: [Text(widget.title), Expanded(child: _chartBuilder())],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _responsiveBuild(context, ResponsiveLayout.layoutOf(context));
  }
}
