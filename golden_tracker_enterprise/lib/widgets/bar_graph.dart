import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../styles/colors.dart';

import '../widgets/index.dart';

class BarGraphData {
  final Iterable<BarGroup> barGroups;
  final Map<String, Color> legends;

  const BarGraphData({required this.barGroups, required this.legends});

  BarChartData toChartWidget() {
    return BarChartData(
      barGroups: List.generate(barGroups.length, (i) {
        return barGroups.elementAt(i).toChartWidget(i, legends);
      }),
    );
  }
}

class BarGroup {
  final String label;
  final Iterable<BarRod> barRods;

  const BarGroup({
    required this.label,
    required this.barRods,
  });

  BarChartGroupData toChartWidget(int index, Map<String, Color> legends) {
    return BarChartGroupData(
        x: index,
        barRods: List.generate(barRods.length, (i) {
          final barRod = barRods.elementAt(i);
          return barRod.toChartWidget(legends);
        }));
  }
}

abstract class BarRod {
  final double fromY;
  final double toY;

  const BarRod({
    required this.toY,
    this.fromY = 0,
  });

  BarChartRodData toChartWidget(Map<String, Color> legends);
}

class SolidBarRod extends BarRod {
  final String label;

  const SolidBarRod({
    required this.label,
    required super.toY,
    super.fromY,
  });

  @override
  BarChartRodData toChartWidget(Map<String, Color> legends) {
    return BarChartRodData(
      toY: toY,
      fromY: fromY,
      color: legends[label] ?? kSecondaryContainer,
    );
  }
}

class StackedBarRod extends BarRod {
  final Iterable<BarRodStackItem> rodStackItems;

  const StackedBarRod({
    required super.toY,
    super.fromY,
    required this.rodStackItems,
  });

  @override
  BarChartRodData toChartWidget(Map<String, Color> legends) {
    return BarChartRodData(
      toY: toY,
      fromY: fromY,
      rodStackItems: List.generate(rodStackItems.length, (i) {
        final rodStackItem = rodStackItems.elementAt(i);
        return BarChartRodStackItem(
          fromY,
          toY,
          legends[rodStackItem.label] ?? kSecondaryContainer,
        );
      }),
    );
  }
}

class BarRodStackItem {
  final String label;
  final double fromY;
  final double toY;

  const BarRodStackItem({
    required this.label,
    required this.fromY,
    required this.toY,
  });
}

class BarGraph extends StatefulWidget {
  const BarGraph({
    super.key,
    required this.title,
    required this.data,
    this.xAxisTitle,
    this.yAxisTitle,
    this.rodSpacing,
    this.barWidth = 24,
    this.mirrorXAxisLabels = false,
    this.mirrorYAxisLabels = false,
  });

  final String title;
  final String? xAxisTitle;
  final String? yAxisTitle;
  final double barWidth;
  final double? rodSpacing;

  final bool mirrorXAxisLabels;
  final bool mirrorYAxisLabels;
  final BarGraphData data;

  @override
  State<BarGraph> createState() => _BarGraphState();
}

class _BarGraphState extends State<BarGraph> {
  double _scrollPosition = 0.5;
  List<BarGroup> _visibleBarGroups = [];

  final double _maxY = 15;
  final double _minY = -1;

  AxisTitles _xAxisTitlesBuilder() {
    String? axisTitle = widget.xAxisTitle;
    return AxisTitles(
      axisNameWidget: (axisTitle != null) ? Text(axisTitle) : null,
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 40,
        // getTitlesWidget: (value, meta) => SideTitleWidget(
        //   // axisSide: AxisSide.bottom,
        //   child: Text(_visibleBarGroups[value.toInt()].label),
        //   meta: ,
        // ),
      ),
    );
  }

  Widget _chartBuilder() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 15)]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(toY: 15),
            BarChartRodData(toY: 8),
            BarChartRodData(toY: 12.5, fromY: -1),
            BarChartRodData(toY: 15),
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(toY: 15),
            BarChartRodData(toY: 8),
            BarChartRodData(toY: 12.5),
          ]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15)]),
          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 15)]),
          BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 15)]),
        ],
        maxY: _maxY + 1,
        minY: (_minY < 0) ? _minY - 1 : 0,
        gridData: FlGridData(
          verticalInterval: 1 / 6,
          getDrawingVerticalLine: (value) {
            return const FlLine(
              color: Colors.black12,
              strokeWidth: 1,
              dashArray: [8, 4],
            );
          },
          getDrawingHorizontalLine: (value) {
            if (value == 0) {
              return const FlLine(
                color: Colors.black,
                strokeWidth: 1,
                dashArray: [8, 4],
              );
            }

            return const FlLine(
              color: Colors.black12,
              strokeWidth: 1,
              dashArray: [8, 4],
            );
          },
        ),
      ),
    );
  }

  Widget _responsiveBuild(BuildContext context, Layout layout) {
    return Container(
      constraints: BoxConstraints(
          maxWidth: layout.size.width, maxHeight: layout.size.height),
      padding: EdgeInsets.all(12),
      child: Flex(
        direction: Axis.vertical,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 12),
          Expanded(child: _chartBuilder()),
          Slider(
            activeColor: kPrimaryContainer,
            inactiveColor: kPrimaryContainer,
            // secondaryActiveColor: kSecondary,
            thumbColor: kPrimary,
            value: _scrollPosition,
            onChanged: (value) => setState(() {
              _scrollPosition = value;
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _responsiveBuild(context, ResponsiveLayout.layoutOf(context));
  }
}
