import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';

class DataHistoryCard extends StatelessWidget {
  final List<SensorData> dataList;

  const DataHistoryCard({
    super.key,
    required this.dataList,
  });

  @override
  Widget build(BuildContext context) {
    if (dataList.isEmpty) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Veri geçmişi henüz oluşturulmadı'),
        ),
      );
    }

    // Son 10 veriyi göster (veya daha az varsa hepsini)
    final displayData = dataList.length > 10
        ? dataList.sublist(dataList.length - 10)
        : dataList;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Ölçümler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayData.length,
              reverse: true,
              itemBuilder: (context, index) {
                final data = displayData[displayData.length - 1 - index];
                return ListTile(
                  dense: true,
                  title: Text(
                    '${DateFormat('HH:mm:ss').format(data.timestamp)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Sıcaklık: ${data.sicaklik.toStringAsFixed(1)}°C | Nem: ${data.nem.toStringAsFixed(1)}%'),
                      Text(
                        'Gaz: ${data.gazSeviyesi} ${data.isGazYuksek ? "⚠️ YÜKSEK" : "✓ normal"}',
                        style: TextStyle(
                          color: data.isGazYuksek ? Colors.red : null,
                          fontWeight: data.isGazYuksek ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                  leading: CircleAvatar(
                    backgroundColor: data.alarmDurumu
                        ? Colors.red
                        : data.isGazYuksek
                            ? Colors.orange
                            : Colors.green,
                    child: Icon(
                      data.alarmDurumu
                          ? Icons.warning
                          : data.isGazYuksek
                              ? Icons.warning_amber
                              : Icons.check,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
