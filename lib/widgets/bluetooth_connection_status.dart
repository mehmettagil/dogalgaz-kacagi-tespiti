import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/bluetooth_service.dart';
import '../screens/bluetooth_settings_screen.dart';

class BluetoothConnectionStatus extends StatelessWidget {
  final BluetoothService service;

  const BluetoothConnectionStatus({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    if (service.isConnecting) {
      return const ConnectionLoadingView();
    }

    if (!service.isConnected) {
      return NotConnectedView(status: service.status);
    }

    return const SizedBox
        .shrink(); // Bağlıysa boş widget döndür, içerik ana ekranda gösterilecek
  }
}

class ConnectionLoadingView extends StatelessWidget {
  const ConnectionLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cihaza bağlanıyor...'),
        ],
      ),
    );
  }
}

class NotConnectedView extends StatelessWidget {
  final String status;

  const NotConnectedView({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth_disabled, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Bluetooth cihazına bağlı değil',
              style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('Cihaza Bağlan'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BluetoothSettingsScreen()),
              );
            },
          ),
          if (status == BluetoothService.STATUS_PERMISSION_DENIED) ...[
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Bluetooth izinleri verilmediği için cihaza bağlanılamıyor. '
                'Lütfen uygulama ayarlarından gerekli izinleri verin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
              ),
              child: const Text('Uygulama Ayarlarını Aç'),
            ),
          ],
        ],
      ),
    );
  }
}
