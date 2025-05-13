import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class ValveControlCard extends StatelessWidget {
  final BluetoothService service;

  const ValveControlCard({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vana Kontrolü',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Vanayı Aç'),
                    onPressed: () {
                      service.openValve();
                      // Durum güncellemesi için kısa bir bekleme
                      Future.delayed(const Duration(milliseconds: 500), () {
                        service.requestStatus();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Vanayı Kapat'),
                    onPressed: () {
                      service.closeValve();
                      // Durum güncellemesi için kısa bir bekleme
                      Future.delayed(const Duration(milliseconds: 500), () {
                        service.requestStatus();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
