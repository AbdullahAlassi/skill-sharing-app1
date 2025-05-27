import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/progress_provider.dart';

class PracticeChart extends StatelessWidget {
  const PracticeChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final practiceHistory = progressProvider.practiceHistory;
        final spots = _generateSpots(practiceHistory);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Practice Time',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}m',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ];
                              if (value >= 0 && value < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Theme.of(context).primaryColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                        ),
                      ],
                      minY: 0,
                      maxY: _getMaxY(spots),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<FlSpot> _generateSpots(List<Map<String, dynamic>> practiceHistory) {
    final spots = <FlSpot>[];
    for (var i = 0; i < practiceHistory.length; i++) {
      final entry = practiceHistory[i];
      spots.add(FlSpot(
        i.toDouble(),
        (entry['minutes'] as num).toDouble(),
      ));
    }
    return spots;
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 60;
    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return maxY * 1.2; // Add 20% padding
  }
}
