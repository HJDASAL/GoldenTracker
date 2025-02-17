import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../styles/colors.dart';

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
  late final double _maxY;
  late final double _minY;

  late final int _maxRodPerGroup;

  late final List<BarGroup> _barGroups;
  final double _barSpace = 8;
  late final double _barWidth = widget.barWidth;

  double _scrollPosition = 0;
  late double _groupWidth;

  /// Initial index indicating the starting group of the visible bar groups
  int _startIndex = 0;

  /// Last index indicating the ending group of the visible bar groups
  int _endIndex = 0;

  /// Number of bar groups to be shown
  late int _totalVisibleGroups = 1;
  //
  /// NUmber of sections the bar groups are divided by per scroll view
  int _totalSections = 1;

  @override
  void initState() {
    _barGroups = widget.data.barGroups.toList();
    _maxY = widget.data.maxY;
    _minY = widget.data.minY;

    _maxRodPerGroup = widget.data.maxTotalRodsPerGroup;

    _groupWidth = max(
      _barWidth * _maxRodPerGroup + _barSpace * (_maxRodPerGroup - 1) + 36,
      120,
    );

    super.initState();
  }

  void _updateVisibleGroups(double width) {
    _totalVisibleGroups = (width / _groupWidth).floor();
    _endIndex = _startIndex + _totalVisibleGroups;

    if (_barGroups.length == 1 || _endIndex < 1) {
      _endIndex = 1;
    } else if (_endIndex >= _barGroups.length) {
      _endIndex = _barGroups.length - 1;
    }

    _totalSections = (_barGroups.length / _totalVisibleGroups).round();
    // print(_totalSections);
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
        reservedSize: 32,
        getTitlesWidget: (value, meta) => ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _groupWidth),
          child: Text(
            _barGroups[value.toInt()].label,
            softWrap: true,
            textAlign: TextAlign.center,
            overflow: TextOverflow.clip,
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _visibleBarGroupBuilder() {
    return List.generate((_endIndex - _startIndex + 1), (i) {
      int totalRods = _barGroups[_startIndex + i].barRods.length;

      return _barGroups[_startIndex + i].toChartWidget(
        _startIndex + i,
        widget.data.legends,
        barSpace: (totalRods < _maxRodPerGroup && totalRods > 1)
            ? ((_maxRodPerGroup - totalRods) * _barWidth +
                    (_maxRodPerGroup - totalRods - 1) * _barSpace) /
                (totalRods - 1)
            : _barSpace,
      );
    });
  }

  Widget _chartBuilder() {
    int totalSpaces = _endIndex - _startIndex + 1;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: _visibleBarGroupBuilder(),
        maxY: _maxY * 1.1,
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
          verticalInterval: (_barGroups.isNotEmpty || totalSpaces > 0)
              ? 1 / totalSpaces
              : null,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _updateVisibleGroups(constraints.maxWidth);
        return Container(
          constraints: constraints.copyWith(minWidth: 300),
          height: max(constraints.maxHeight, 250),
          padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 12),
              Expanded(child: _chartBuilder()),
              if (_totalSections > 1)
                Padding(
                  padding: const EdgeInsets.only(left: 48, bottom: 12),
                  child: Slider(
                    activeColor: kPrimaryContainer,
                    inactiveColor: kPrimaryContainer,
                    thumbColor: kPrimary,
                    max: (_barGroups.length - _totalVisibleGroups - 1)
                        .toDouble(),
                    value: _scrollPosition,
                    onChanged: (value) {
                      int newIndex = value.floor();

                      if (newIndex <=
                          _barGroups.length - _totalVisibleGroups + 1) {
                        _startIndex = newIndex;
                        setState(() => _scrollPosition = newIndex * 1.0);
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

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

      return barGroup.toChartWidget(i, legends, showTooltipLimit: maxY * 0.1);
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

  BarChartGroupData toChartWidget(
    int index,
    Map<String, Color> legends, {
    double? barSpace,
    double showTooltipLimit = 0,
    double? barRodWidth,
  }) {
    final rods = List.generate(barRods.length, (i) {
      return barRods.elementAt(i).toChartWidget(legends, width: barRodWidth);
    });

    return BarChartGroupData(
      x: index,
      barsSpace: barSpace,
      barRods: rods,
      showingTooltipIndicators: [
        for (int i = 0; i < rods.length; i++)
          if (rods[i].toY <= showTooltipLimit) i
      ],
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
  final double width;

  const BarRod({
    required this.toY,
    this.fromY = 0,
    this.width = 24,
  });

  BarChartRodData toChartWidget(Map<String, Color> legends, {double? width});
}

class SolidBarRod extends BarRod {
  final String label;

  const SolidBarRod({
    required this.label,
    required super.toY,
    super.fromY,
    super.width,
  });

  @override
  BarChartRodData toChartWidget(Map<String, Color> legends, {double? width}) {
    return BarChartRodData(
      borderRadius: BorderRadius.zero,
      toY: toY,
      fromY: fromY,
      color: legends[label] ?? kSecondaryContainer,
      width: width ?? this.width,
    );
  }
}

class StackedBarRod extends BarRod {
  final Iterable<BarRodStackItem> rodStackItems;

  const StackedBarRod({
    required super.toY,
    super.fromY,
    super.width,
    required this.rodStackItems,
  });

  @override
  BarChartRodData toChartWidget(Map<String, Color> legends, {double? width}) {
    return BarChartRodData(
      toY: toY,
      fromY: fromY,
      borderRadius: BorderRadius.zero,
      width: width ?? this.width,
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
