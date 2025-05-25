import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data.dart';

class GasLevelChart extends StatelessWidget {
  final List<SensorData> dataList;

  const GasLevelChart({
    super.key,
    required this.dataList,
  });

  @override
  Widget build(BuildContext context) {
    // Sadece son 20 veriyi göster (veya daha az varsa hepsini)
    final displayData = dataList.length > 20
        ? dataList.sublist(dataList.length - 20)
        : dataList;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gaz Seviyesi Grafiği',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: SideTitles(showTitles: true, reservedSize: 30),
                    bottomTitles: SideTitles(showTitles: false),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: displayData.length.toDouble() - 1,
                  minY: 0,
                  maxY: 1023, // Gaz sensörünün maksimum değeri
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        displayData.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          displayData[index].gazSeviyesi.toDouble(),
                        ),
                      ),
                      isCurved: true,
                      colors: const [Colors.red],
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        colors: [Colors.red.withOpacity(0.2)],
                      ),
                    ),
                    // Gaz eşik çizgisi (300)
                    LineChartBarData(
                      spots: List.generate(
                        displayData.length,
                        (index) => FlSpot(index.toDouble(), 300),
                      ),
                      isCurved: false,
                      colors: const [Colors.orange],
                      barWidth: 1,
                      isStrokeCapRound: false,
                      dotData: FlDotData(show: false),
                      dashArray: [5, 5], // Kesikli çizgi
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                const Text('Gaz Seviyesi'),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                const Text('Eşik Değeri (200)'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
