import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/bluetooth_service.dart';
import '../models/bluetooth_failure.dart';

class BluetoothSettingsScreen extends StatefulWidget {
  const BluetoothSettingsScreen({super.key});

  @override
  State<BluetoothSettingsScreen> createState() =>
      _BluetoothSettingsScreenState();
}

class _BluetoothSettingsScreenState extends State<BluetoothSettingsScreen> {
  List<BluetoothDevice> _devices = [];
  bool _isLoading = true;
  bool _isScanning = false;
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStreamSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _discoveryStreamSubscription?.cancel();
    super.dispose();
  }

  // İzinleri kontrol et
  Future<void> _checkPermissions() async {
    // İzinleri iste
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    if (allGranted) {
      _loadPairedDevices();
    } else {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // İzinlerin neden gerekli olduğunu açıklayan daha detaylı bir mesaj göster
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('İzinler Gerekli'),
            content: const Text(
              'Bluetooth cihazları ile iletişim kurabilmek için bu izinler gereklidir. '
              'Uygulama sadece doğalgaz kaçağı tespiti için kullanılan cihazlara bağlanmak üzere bu izinleri kullanır. '
              'İzinleri vermezseniz, cihazla bağlantı kuramazsınız.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Tamam'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings(); // Kullanıcıyı ayarlara yönlendir
                },
                child: const Text('Ayarları Aç'),
              ),
            ],
          ),
        );
      }
    }
  }

  // Eşleşmiş cihazları yükle
  Future<void> _loadPairedDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = Provider.of<BluetoothService>(context, listen: false);
      final result = await service.scanDevices();

      result.fold(
        (failure) {
          if (mounted) {
            _showToastMessage(failure.message, true);
          }
          setState(() {
            _devices = [];
          });
        },
        (devices) {
          setState(() {
            _devices = devices;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        _showToastMessage('Hata oluştu: $e', true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  // Yeni cihazları tara
  Future<void> _startDiscovery() async {
    // Önce izinleri tekrar kontrol et
    final service = Provider.of<BluetoothService>(context, listen: false);
    final permissionsResult = await service.requestBluetoothPermissions();

    bool canProceed = false;
    permissionsResult.fold(
      (failure) {
        _showToastMessage(failure.message, true);
      },
      (_) {
        canProceed = true;
      },
    );

    if (!canProceed) return;

    setState(() {
      _isScanning = true;
    });

    try {
      // Bluetooth adaptörünü al
      final bluetoothInstance = FlutterBluetoothSerial.instance;

      // Taramayı başlat
      _discoveryStreamSubscription = bluetoothInstance.startDiscovery().listen(
        (r) {
          // Yeni cihaz ekle
          final existingIndex =
              _devices.indexWhere((d) => d.address == r.device.address);
          if (existingIndex >= 0) {
            setState(() {
              _devices[existingIndex] = r.device;
            });
          } else {
            setState(() {
              _devices.add(r.device);
            });
          }
        },
        onDone: () {
          setState(() {
            _isScanning = false;
          });
        },
        onError: (error) {
          setState(() {
            _isScanning = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tarama sırasında hata oluştu: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      setState(() {
        _isScanning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tarama başlatılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Cihaza bağlan
  Future<void> _connectToDevice(BluetoothDevice device) async {
    final service = Provider.of<BluetoothService>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await service.connectToDevice(device);

      result.fold(
        (failure) {
          if (mounted) {
            _showToastMessage(failure.message, true);

            // Bağlantı hatası dialog ile daha detaylı göster
            if (failure is ConnectionFailure) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Bağlantı Hatası'),
                  content: Text(failure.message),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Tamam'),
                    ),
                  ],
                ),
              );
            }
          }
        },
        (success) {
          if (mounted) {
            _showToastMessage('Cihaza bağlanıldı', false);
            Navigator.pop(context); // Ayarlar ekranından çık
          }
        },
      );
    } catch (e) {
      if (mounted) {
        _showToastMessage('Bağlantı hatası: $e', true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothService = Provider.of<BluetoothService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Ayarları'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bağlantı Durumu
                Container(
                  color: bluetoothService.isConnected
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        bluetoothService.isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: bluetoothService.isConnected
                            ? Colors.green
                            : Colors.grey,
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
                              bluetoothService.status,
                              style: TextStyle(
                                color: bluetoothService.isConnected
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (bluetoothService.isConnected)
                        ElevatedButton(
                          onPressed: () async {
                            await bluetoothService.disconnect();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Bağlantıyı Kes'),
                        ),
                    ],
                  ),
                ),

                // Cihaz Listesi Başlığı
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
                          if (_isScanning)
                            Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(right: 8),
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          IconButton(
                            icon:
                                Icon(_isScanning ? Icons.stop : Icons.refresh),
                            onPressed: _isScanning
                                ? () {
                                    _discoveryStreamSubscription?.cancel();
                                    setState(() {
                                      _isScanning = false;
                                    });
                                  }
                                : _startDiscovery,
                            tooltip: _isScanning ? 'Taramayı Durdur' : 'Yenile',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Cihaz Listesi
                Expanded(
                  child: _devices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bluetooth_searching,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('Hiçbir Bluetooth cihazı bulunamadı'),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('Cihazları Tara'),
                                onPressed: _startDiscovery,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            final device = _devices[index];
                            final bool isConnected =
                                bluetoothService.isConnected;

                            return ListTile(
                              title: Text(
                                device.name ?? 'Bilinmeyen Cihaz',
                                style: TextStyle(
                                  fontWeight: isConnected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
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
                                onPressed: isConnected
                                    ? null
                                    : () => _connectToDevice(device),
                                child: Text(isConnected ? 'Bağlı' : 'Bağlan'),
                              ),
                              onTap: isConnected
                                  ? null
                                  : () => _connectToDevice(device),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
