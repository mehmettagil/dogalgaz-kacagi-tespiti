import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class BluetoothConnectionStatusBar extends StatelessWidget {
  final BluetoothService service;
  final VoidCallback onDisconnectPressed;

  const BluetoothConnectionStatusBar({
    super.key,
    required this.service,
    required this.onDisconnectPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: service.isConnected
          ? Colors.green.withOpacity(0.1)
          : Colors.grey.withOpacity(0.1),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            service.isConnected
                ? Icons.bluetooth_connected
                : Icons.bluetooth_disabled,
            color: service.isConnected ? Colors.green : Colors.grey,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bağlantı Durumu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  service.status,
                  style: TextStyle(
                    color: service.isConnected ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (service.isConnected)
            ElevatedButton(
              onPressed: onDisconnectPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Bağlantıyı Kes'),
            ),
        ],
      ),
    );
  }
}
