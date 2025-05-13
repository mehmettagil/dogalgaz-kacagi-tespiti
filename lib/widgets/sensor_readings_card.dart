import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';

class SensorReadingsCard extends StatelessWidget {
  final SensorData? data;

  const SensorReadingsCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Sensör verileri henüz alınmadı'),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sensör Değerleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Sıcaklık
            _buildSensorRow(
              icon: Icons.thermostat,
              label: 'Sıcaklık',
              value: '${data!.sicaklik.toStringAsFixed(1)} °C',
              color: Colors.orange,
            ),

            const Divider(),

            // Nem
            _buildSensorRow(
              icon: Icons.water_drop,
              label: 'Nem',
              value: '%${data!.nem.toStringAsFixed(1)}',
              color: Colors.blue,
            ),

            const Divider(),

            // Gaz seviyesi
            _buildSensorRow(
              icon: Icons.local_fire_department,
              label: 'Gaz Seviyesi',
              value: '${data!.gazSeviyesi} / 1023',
              color: data!.isGazYuksek ? Colors.red : Colors.green,
              additionalInfo: data!.gazDurumu,
              isAlert: data!.isGazYuksek,
            ),

            const Divider(),

            // Son güncelleme zamanı
            Row(
              children: [
                const Icon(Icons.update, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Son Güncelleme: ${DateFormat('HH:mm:ss').format(data!.timestamp)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Sensör satırı
  Widget _buildSensorRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? additionalInfo,
    bool isAlert = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isAlert ? Colors.red : null,
              ),
            ),
            if (additionalInfo != null)
              Text(
                additionalInfo,
                style: TextStyle(
                  fontSize: 12,
                  color: isAlert ? Colors.red : Colors.grey,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
