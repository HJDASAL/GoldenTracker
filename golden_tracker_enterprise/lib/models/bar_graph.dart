import 'dart:math' show max, min;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BarGraphData {
  final String title;
  final List<BarGroup> barGroups;
  final double barWidth;
  final String? xAxisTitle;
  final String? yAxisTitle;
  late final Map<String, Color> legends;

  BarGraphData(
      this.barGroups, {
        required this.title,
        this.barWidth = 16,
        Map<String, Color> legends = const {},
        this.xAxisTitle,
        this.yAxisTitle,
      }) {
    Iterable<String> legendKeys = legends.keys;
    this.legends = {};

    for (String label in barLabels) {
      if (!legendKeys.contains(label)) {
        this.legends['Unrecognized'] = Colors.grey;
        continue;
      }

      this.legends[label] = legends[label]!;
    }
  }

  double get minY {
    List<double> minYs = barGroups.map((group) => group.minY).toList();
    double minY = double.infinity;
    for (double y in minYs) {
      if (y < minY) {
        minY = y;
      }
    }

    return minY + (minY * 0.05);
  }

  double get maxY {
    List<double> maxYs = barGroups.map((group) => group.maxY).toList();
    double maxY = 0;
    for (double y in maxYs) {
      if (y > maxY) {
        maxY = y;
      }
    }

    if (maxY <= 0) {
      return 24;
    }

    return maxY + (maxY * 0.1);
  }

  List<String> get barLabels {
    List<String> labels = [];
    for (BarGroup group in barGroups) {
      for (int i = 0; i < group._barRods.length; i++) {
        String label = group._barRods[i].label;
        if (!labels.contains(label)) {
          labels.add(label);
        }

        List<BarRodStackItem>? rodStacks = group._barRods[i].rodStacks;

        for (int j = 0; j < rodStacks.length; j++) {
          String label = rodStacks[j].label;
          if (!labels.contains(label)) {
            labels.add(label);
          }
        }
      }
    }

    return labels;
  }
}

const BarRod _kProxyBarRod = BarRod(label: 'Proxy', toY: 0);

class BarGroup {
  final String title;
  late final List<BarRod> _barRods;
  // final Map<String, Color> legend;
  final double? rodSpacing;

  BarGroup({
    required this.title,
    this.rodSpacing,
    // this.legend = const {},
    Iterable<BarRod> barRods = const [],
  }) {
    _barRods = barRods.toList(growable: false);
  }

  List<BarRod> get barRods => _barRods;

  BarChartGroupData toChartWidget(
      int index, {
        required Map<String, Color> legends,
        double width = 16,
        double? maxY,
        int? matchRodTotal,
      }) {
    int totalRods = max(_barRods.length, matchRodTotal ?? 0);
    int originalTotalRods = _barRods.length;

    maxY = maxY ?? this.maxY;
    List<BarChartRodData> barRods = List.generate(
      originalTotalRods,
          (i) {
        final BarRod rod = _barRods[i];
        Color? rodColor = legends[rod.label];
        List<BarChartRodStackItem> barRodStacks = List.generate(
          rod.rodStacks.length,
              (j) {
            Color? stackColor = legends[rod.rodStacks[j].label];
            return rod.rodStacks[j].toChartWidget(
              color: stackColor ?? rodColor,
            );
          },
        );
        return _barRods[i].toChartWidget(
          color: rodColor,
          width: width,
          rodStackWidgets: barRodStacks,
        );
      },
    );

    // If the current length is already greater than or equal to the desired length, return the original list
    int paddingStart = 0;
    int paddingEnd = 0;
    if (originalTotalRods < totalRods) {
      int totalPadding = totalRods - originalTotalRods;
      if (originalTotalRods.isEven && totalRods.isOdd) {
        totalPadding--;
      } else if (originalTotalRods.isOdd && totalRods.isEven) {
        totalPadding--;
      }

      paddingStart = totalPadding ~/ 2; // Padding to add at the start
      paddingEnd = totalPadding - paddingStart; // Padding to add at the end
    }

    return BarChartGroupData(
      x: index,
      showingTooltipIndicators: [
        for (int i = 0; i < _barRods.length; i++)
          if ((_barRods[i].toY / maxY).abs() < 0.25) (i + paddingStart),
      ],
      barRods: List.filled(
        paddingStart,
        _kProxyBarRod.toChartWidget(width: width),
      ) +
          barRods +
          List.filled(
            paddingEnd,
            _kProxyBarRod.toChartWidget(width: width),
          ),
      barsSpace: 4,
    );
  }

  void addRod(BarRod rodData) => _barRods.add(rodData);

  double get maxY {
    double maxY = double.negativeInfinity;
    for (BarRod rod in _barRods) {
      double maxRodY = max(rod.fromY, rod.toY);
      if (maxRodY > maxY) {
        maxY = maxRodY;
      }
    }

    return maxY;
  }

  double get minY {
    double minY = double.infinity;
    for (BarRod rod in _barRods) {
      double minRodY = min(rod.fromY, rod.toY);
      if (minRodY < minY) {
        minY = minRodY;
      }
    }

    return minY;
  }
}

class BarRod {
  final String label;
  final List<BarRodStackItem> rodStacks;
  final double fromY;
  final double toY;
  final double width;

  const BarRod({
    required this.label,
    required this.toY,
    // this.primaryColor,
    this.rodStacks = const [],
    this.fromY = 0,
    this.width = 16,
  });

  BarChartRodData toChartWidget({
    double? width,
    Color? color,
    List<BarChartRodStackItem> rodStackWidgets = const [],
  }) {
    return BarChartRodData(
      toY: toY,
      fromY: fromY,
      borderRadius: BorderRadius.zero,
      width: width ?? this.width,
      color: rodStackWidgets.isEmpty
          ? (color ?? Colors.grey)
          : rodStackWidgets.first.color,
      rodStackItems: rodStackWidgets,
    );
  }
}

class BarRodStackItem {
  final double fromY;
  final double toY;
  final String label;
  final Color? color;

  const BarRodStackItem(
      this.fromY,
      this.toY, {
        required this.label,
        this.color,
      });

  BarChartRodStackItem toChartWidget({Color? color}) {
    return BarChartRodStackItem(fromY, toY, color ?? Colors.grey);
  }
}

enum BarRodStackScheme { gradient, rainbow }

enum SideTitlesVisibility {
  top,
  bottom,
  left,
  right,
  horizontal,
  vertical;

  List<SideTitlesVisibility> only({
    bool top = false,
    bool bottom = false,
    bool right = false,
    bool left = false,
  }) {
    return [
      if (top) SideTitlesVisibility.top,
      if (bottom) SideTitlesVisibility.bottom,
      if (right) SideTitlesVisibility.right,
      if (left) SideTitlesVisibility.left,
    ];
  }
}
