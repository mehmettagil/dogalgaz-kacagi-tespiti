import 'dart:async';
import 'package:dogalgaz_kacagi_tespiti/services/bluetooth_service.dart';
import 'package:dogalgaz_kacagi_tespiti/widgets/bluetooth_connection_status.dart';
import 'package:dogalgaz_kacagi_tespiti/widgets/data_history_card.dart';
import 'package:dogalgaz_kacagi_tespiti/widgets/gas_level_chart.dart';
import 'package:dogalgaz_kacagi_tespiti/widgets/sensor_readings_card.dart';
import 'package:dogalgaz_kacagi_tespiti/widgets/status_card.dart';
import 'package:dogalgaz_kacagi_tespiti/widgets/valve_control_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'bluetooth_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Otomatik durum sorgulaması için timer başlat
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final service = Provider.of<BluetoothService>(context, listen: false);
      if (service.isConnected) {
        service.requestStatus();
      }
    });

    // İlk açılışta son bağlantıyı yeniden kurmaya çalış
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryReconnectLastDevice();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Son bağlanılan cihaza tekrar bağlanmayı dene
  Future<void> _tryReconnectLastDevice() async {
    final service = Provider.of<BluetoothService>(context, listen: false);

    final lastDeviceAddress = await service.getLastConnectedDevice();
    if (lastDeviceAddress != null) {
      final devicesResult = await service.scanDevices();

      devicesResult.fold((failure) {
        // İzin hatası veya başka bir hata durumunda toast göster
        _showToastMessage(failure.message, true);
      }, (devices) async {
        final lastDevice =
            devices.where((d) => d.address == lastDeviceAddress).toList();

        if (lastDevice.isNotEmpty) {
          final connectResult = await service.connectToDevice(lastDevice.first);

          connectResult.fold(
            (failure) {
              // Bağlantı hatası durumunda
              _showToastMessage(
                  'Otomatik bağlantı başarısız: ${failure.message}', true);
            },
            (success) {
              _showToastMessage('Cihaza otomatik olarak bağlandı', false);
            },
          );
        }
      });
    }
  }

  // Toast mesajı göster
  void _showToastMessage(String message, bool isError) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        backgroundColor: isError ? Colors.red : Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doğalgaz Kaçağı Tespit Sistemi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<BluetoothService>(
            builder: (context, service, child) {
              return IconButton(
                icon: Icon(service.isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BluetoothSettingsScreen()),
                  );
                },
                tooltip: 'Bluetooth Ayarları',
              );
            },
          ),
        ],
      ),
      body: Consumer<BluetoothService>(
        builder: (context, service, child) {
          return Stack(
            children: [
              // Bağlantı durumu kontrol ekranı
              BluetoothConnectionStatus(service: service),

              // Ana içerik (cihaz bağlıysa görünür)
              if (service.isConnected) _buildMainContent(service),
            ],
          );
        },
      ),
    );
  }

  // Ana içerik
  Widget _buildMainContent(BluetoothService service) {
    return RefreshIndicator(
      onRefresh: () async {
        await service.requestStatus();
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Durum kartı
            StatusCard(service: service),

            const SizedBox(height: 16),

            // Sensör değerleri
            SensorReadingsCard(data: service.latestData),

            const SizedBox(height: 16),

            // Vana kontrolü
            ValveControlCard(service: service),

            const SizedBox(height: 16),

            // Gaz seviyesi grafiği
            if (service.sensorDataList.isNotEmpty)
              GasLevelChart(dataList: service.sensorDataList),

            const SizedBox(height: 16),

            // Veri geçmişi
            DataHistoryCard(dataList: service.sensorDataList),
          ],
        ),
      ),
    );
  }
}
