import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/bluetooth_service.dart';

class BluetoothDeviceList extends StatelessWidget {
  final List<BluetoothDevice> devices;
  final bool isScanning;
  final BluetoothService bluetoothService;
  final Function(BluetoothDevice) onDeviceConnect;
  final VoidCallback onRefreshPressed;
  final VoidCallback onScanStopPressed;

  const BluetoothDeviceList({
    super.key,
    required this.devices,
    required this.isScanning,
    required this.bluetoothService,
    required this.onDeviceConnect,
    required this.onRefreshPressed,
    required this.onScanStopPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Cihaz Listesi Başlığı
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kullanılabilir Cihazlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  if (isScanning)
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 8),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  IconButton(
                    icon: Icon(isScanning ? Icons.stop : Icons.refresh),
                    onPressed:
                        isScanning ? onScanStopPressed : onRefreshPressed,
                    tooltip: isScanning ? 'Taramayı Durdur' : 'Yenile',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Cihaz Listesi
        Expanded(
          child: devices.isEmpty
              ? _buildEmptyDeviceList()
              : _buildDeviceListView(context),
        ),
      ],
    );
  }

  Widget _buildEmptyDeviceList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bluetooth_disabled,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Bluetooth cihazı bulunamadı',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRefreshPressed,
            icon: const Icon(Icons.refresh),
            label: const Text('Yeniden Tara'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceListView(BuildContext context) {
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        final bool isConnected = bluetoothService.isConnected;

        return ListTile(
          title: Text(
            device.name ?? 'Bilinmeyen Cihaz',
            style: TextStyle(
              fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(device.address),
          leading: Icon(
            device.bondState == BluetoothBondState.bonded
                ? Icons.bluetooth_connected
                : Icons.bluetooth,
            color: isConnected ? Colors.blue : Colors.grey,
          ),
          trailing: ElevatedButton(
            onPressed: isConnected ? null : () => onDeviceConnect(device),
            child: Text(isConnected ? 'Bağlı' : 'Bağlan'),
          ),
          onTap: isConnected ? null : () => onDeviceConnect(device),
        );
      },
    );
  }
}
