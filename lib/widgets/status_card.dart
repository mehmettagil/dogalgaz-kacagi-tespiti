import 'package:dogalgaz_kacagi_tespiti/widgets/animated_alarm_icon.dart';
import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class StatusCard extends StatelessWidget {
  final BluetoothService service;

  const StatusCard({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final latestData = service.latestData;
    final bool isAlarm = latestData?.alarmDurumu ?? false;

    return Card(
      elevation: 4,
      color: isAlarm ? Colors.red.shade100 : Colors.green.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                isAlarm
                    ? const AnimatedAlarmIcon()
                    : const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 40,
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAlarm ? 'ALARM DURUMU!' : 'Sistem Normal',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isAlarm ? Colors.red : Colors.green.shade700,
                        ),
                      ),
                      Text(
                        isAlarm
                            ? 'Gaz kaçağı veya anormal değişim algılandı'
                            : 'Herhangi bir sorun algılanmadı',
                        style: TextStyle(
                          fontSize: 14,
                          color: isAlarm
                              ? Colors.red.shade700
                              : Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isAlarm) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Vanayı Aç'),
                    onPressed: () {
                      service.openValve();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Durum Sorgula'),
                    onPressed: () {
                      service.requestStatus();
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
