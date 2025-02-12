import 'dart:developer';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../styles/colors.dart';

import '../widgets/index.dart';

class BarGraphData {
  final Iterable<BarGroup> barGroups;
  final Map<String, Color> legends;
  late final List<BarChartGroupData> barGroupChartWidgets;
  final double barWidth;

  late final double maxY;
  late final double minY;
  late final int maxTotalRodsPerGroup;

  BarGraphData({
    required this.barGroups,
    required this.legends,
    this.barWidth = 12,
  }) {
    double maxY = 0;
    double minY = barGroups.isNotEmpty ? double.infinity : 0;

    int maxTotalRodsPerGroup = 0;

    barGroupChartWidgets = List.generate(barGroups.length, (i) {
      final barGroup = barGroups.elementAt(i);
      double groupMaxY = barGroup.maxY;
      double groupMinY = barGroup.minY;
      int totalRods = barGroup.barRods.length;

      if (maxY < groupMaxY) maxY = groupMaxY;
      if (minY < groupMinY) minY = groupMinY;
      if (maxTotalRodsPerGroup < totalRods) {
        maxTotalRodsPerGroup = totalRods;
      }

      return barGroup.toChartWidget(i, legends);
    });

    this.maxY = maxY;
    this.minY = minY;
    this.maxTotalRodsPerGroup = maxTotalRodsPerGroup;
  }
}

class BarGroup {
  final String label;
  final Iterable<BarRod> barRods;

  const BarGroup({
    required this.label,
    required this.barRods,
  });

  BarChartGroupData toChartWidget(int index, Map<String, Color> legends,
      {double? barSpace}) {
    return BarChartGroupData(
      x: index,
      barsSpace: barSpace,
      barRods: List.generate(barRods.length, (i) {
        final barRod = barRods.elementAt(i);
        // if (barRod.runtimeType == StackedBarRod) {
        //   return BarChartRodData(
        //     toY: barRod.toY,
        //     rodStackItems: [
        //       BarChartRodStackItem(0, 4, Colors.blue),
        //       BarChartRodStackItem(4, barRod.toY, Colors.orange),
        //     ],
        //   );
        // }
        return barRod.toChartWidget(legends);
      }),
    );
  }

  double get maxY {
    double maxY = 0;
    for (int i = 0; i < barRods.length; i++) {
      double toY = barRods.elementAt(i).toY;
      if (maxY < toY) maxY = toY;
    }

    return maxY;
  }

  double get minY {
    double minY = double.infinity;
    for (int i = 0; i < barRods.length; i++) {
      double fromY = barRods.elementAt(i).fromY;
      if (minY > fromY) minY = fromY;
    }

    return minY;
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
      borderRadius: BorderRadius.zero,
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
      borderRadius: BorderRadius.zero,
      rodStackItems: List.generate(rodStackItems.length, (i) {
        final rodStackItem = rodStackItems.elementAt(i);
        return BarChartRodStackItem(
          rodStackItem.fromY,
          rodStackItem.toY,
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

  late final double _maxY;
  late final int _maxYDecimalPlace;
  late final double _minY;
  late final int _maxRodPerGroup;

  late final List<BarGroup> _barGroups;
  final double _barSpace = 8;
  final double _barWidth = 12;

  @override
  void initState() {
    _barGroups = widget.data.barGroups.toList();
    _maxY = widget.data.maxY;
    _minY = widget.data.minY;
    
    _maxYDecimalPlace = _maxY.toStringAsFixed(0).length;

    _maxRodPerGroup = widget.data.maxTotalRodsPerGroup;
    super.initState();
  }

  AxisTitles _xAxisTitlesBuilder() {
    String? axisTitle = widget.xAxisTitle;
    return AxisTitles(
      axisNameWidget: (axisTitle != null) ? Text(axisTitle) : null,
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 48,
      ),
    );
  }

  AxisTitles _yAxisTitlesBuilder() {
    String? axisTitle = widget.yAxisTitle;
    return AxisTitles(
      axisNameWidget: (axisTitle != null) ? Text(axisTitle) : null,
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 48,
        getTitlesWidget: (value, meta) {
          return Text(_barGroups[value.toInt()].label);
        },
      ),
    );
  }

  // AxisTitles _emptyAxisTitleBuilder() {
  //   return AxisTitles();
  // }

  Widget _chartBuilder() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: List.generate(_barGroups.length, (i) {
          int totalRods = _barGroups[i].barRods.length;

          return _barGroups[i].toChartWidget(
            i,
            widget.data.legends,
            barSpace: (totalRods < _maxRodPerGroup && totalRods > 1)
                ? ((_maxRodPerGroup - totalRods) * _barWidth +
                        (_maxRodPerGroup - totalRods - 1) * _barSpace) /
                    (totalRods - 1)
                : _barSpace,
          );
        }),
        maxY: _maxY + pow(10, _maxYDecimalPlace - 1),
        minY: (_minY < 0) ? _minY - 1 : 0,
        titlesData: FlTitlesData(
          leftTitles: _xAxisTitlesBuilder(),
          bottomTitles: _yAxisTitlesBuilder(),
          rightTitles:
              widget.mirrorXAxisLabels ? _xAxisTitlesBuilder() : AxisTitles(),
          topTitles:
              widget.mirrorYAxisLabels ? _yAxisTitlesBuilder() : AxisTitles(),
        ),
        gridData: FlGridData(
          verticalInterval:
              (_barGroups.isNotEmpty) ? 1 / _barGroups.length : null,
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
      // constraints: BoxConstraints(
      //   maxWidth: layout.size.width,
      //   minHeight: 500,
      //   maxHeight: layout.size.height - 172,
      // ),
      height: max(540, layout.size.height - 172),
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
