import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dartz/dartz.dart';
import '../models/sensor_data.dart';
import '../models/bluetooth_failure.dart';
import 'alarm_service.dart';

class BluetoothService extends ChangeNotifier {
  // Bluetooth bağlantı durumları
  static const String STATUS_CONNECTING = 'Bağlanıyor...';
  static const String STATUS_CONNECTED = 'Bağlandı';
  static const String STATUS_DISCONNECTED = 'Bağlantı Kesildi';
  static const String STATUS_ERROR = 'Hata';
  static const String STATUS_PERMISSION_DENIED = 'İzin Reddedildi';

  // Arduino komutları
  static const String CMD_VANA_AC = 'VANA_AC';
  static const String CMD_VANA_KAPAT = 'VANA_KAPAT';
  static const String CMD_DURUM = 'DURUM';

  // Bluetooth instance
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;

  // Durum değişkenleri
  String _status = STATUS_DISCONNECTED;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isDisconnecting = false;

  // Veri akışı
  StreamSubscription<Uint8List>? _dataStreamSubscription;
  final List<SensorData> _sensorDataList = [];
  SensorData? _latestData;
  StreamController<SensorData>? _dataStreamController;

  // Veri tamponu - parça parça gelen verileri birleştirmek için
  String _dataBuffer = "";

  // Diğer servisler
  final AlarmService _alarmService = AlarmService();

  // Son alarm durumu
  bool _sonAlarmDurumu = false;

  // Getters
  String get status => _status;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get isDisconnecting => _isDisconnecting;
  List<SensorData> get sensorDataList => _sensorDataList;
  SensorData? get latestData => _latestData;
  Stream<SensorData> get dataStream {
    _dataStreamController ??= StreamController<SensorData>.broadcast();
    return _dataStreamController!.stream;
  }

  // En son bağlanılan cihazın adresini kaydet
  Future<void> saveLastConnectedDevice(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastConnectedDevice', address);
  }

  // En son bağlanılan cihazın adresini al
  Future<String?> getLastConnectedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastConnectedDevice');
  }

  // İzinleri kontrol et ve iste
  Future<Either<BluetoothFailure, bool>> requestBluetoothPermissions() async {
    try {
      // Android 12 ve üzeri için yeni izinler
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      // Tüm izinlerin verilip verilmediğini kontrol et
      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          debugPrint('İzin reddedildi: $permission');
          allGranted = false;
        }
      });

      if (allGranted) {
        return right(true);
      } else {
        return left(const PermissionFailure());
      }
    } catch (e) {
      return left(
          ConnectionFailure('İzin işlemi sırasında hata: ${e.toString()}'));
    }
  }

  // Bluetooth cihazlarını tara
  Future<Either<BluetoothFailure, List<BluetoothDevice>>> scanDevices() async {
    try {
      // Önce izinleri kontrol et
      final permissionsResult = await requestBluetoothPermissions();

      return permissionsResult.fold(
        (failure) {
          _status = STATUS_PERMISSION_DENIED;
          notifyListeners();
          return left(failure);
        },
        (_) async {
          try {
            bool? isEnabled = await _bluetooth.isEnabled;

            if (isEnabled != null && isEnabled) {
              final devices = await _bluetooth.getBondedDevices();
              return right(devices);
            } else {
              return left(const BluetoothDisabledFailure());
            }
          } catch (e) {
            debugPrint('Bluetooth taraması sırasında hata: $e');
            return left(ConnectionFailure.fromException(e));
          }
        },
      );
    } catch (e) {
      debugPrint('Bluetooth taraması sırasında hata: $e');
      return left(ConnectionFailure.fromException(e));
    }
  }

  // Bluetooth cihazına bağlan
  Future<Either<BluetoothFailure, bool>> connectToDevice(
      BluetoothDevice device) async {
    if (_isConnected) {
      await disconnect();
    }

    // İzinleri kontrol et
    final permissionsResult = await requestBluetoothPermissions();

    return permissionsResult.fold((failure) {
      _status = STATUS_PERMISSION_DENIED;
      notifyListeners();
      return left(failure);
    }, (_) async {
      _isConnecting = true;
      _status = STATUS_CONNECTING;
      notifyListeners();

      try {
        _connection =
            await BluetoothConnection.toAddress(device.address).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Bağlantı zaman aşımına uğradı');
          },
        );

        _isConnected = true;
        _isConnecting = false;
        _status = STATUS_CONNECTED;

        // Adresin kaydedilmesi
        await saveLastConnectedDevice(device.address);

        // Veri dinlemeyi başlat
        _startListening();

        notifyListeners();
        return right(true);
      } catch (e) {
        _isConnected = false;
        _isConnecting = false;

        if (e is TimeoutException) {
          _status = '$STATUS_ERROR: Bağlantı zaman aşımına uğradı';
          log('Bağlantı hatası: Zaman aşımı');
          notifyListeners();
          return left(const TimeoutFailure());
        } else {
          _status = '$STATUS_ERROR: ${e.toString()}';
          log('Bağlantı hatası: ${e.toString()}');
          notifyListeners();
          return left(ConnectionFailure.fromException(e));
        }
      }
    });
  }

  // Bağlantıyı kes
  Future<void> disconnect() async {
    if (!_isConnected) return;

    _isDisconnecting = true;
    notifyListeners();

    // Veri akışını durdur
    await _dataStreamSubscription?.cancel();
    _dataStreamSubscription = null;

    // Stream Controller'ı kapat ve yeniden başlat
    if (_dataStreamController != null && !_dataStreamController!.isClosed) {
      await _dataStreamController!.close();
      _dataStreamController = null;
    }

    // Bağlantıyı kapat
    await _connection?.finish();
    _connection = null;

    // Veri tamponunu temizle
    _dataBuffer = "";

    _isConnected = false;
    _isDisconnecting = false;
    _status = STATUS_DISCONNECTED;
    notifyListeners();
  }

  // Veri gönder
  Future<void> sendCommand(String command) async {
    final timestamp = DateTime.now();
    final formattedTime =
        "${timestamp.hour}:${timestamp.minute}:${timestamp.second}.${timestamp.millisecond}";

    if (_connection == null || !_isConnected) {
      debugPrint('[$formattedTime] Komut gönderilemiyor: Cihaz bağlı değil');
      return;
    }

    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode('$command\r\n')));
      await _connection!.output.allSent;
      debugPrint('[$formattedTime] Gönderilen komut: $command');
    } catch (e) {
      debugPrint('[$formattedTime] Komut gönderilirken hata oluştu: $e');
    }
  }

  // Vanayı aç ve alarmı sıfırla
  Future<void> openValve() async {
    final timestamp = DateTime.now();
    final formattedTime =
        "${timestamp.hour}:${timestamp.minute}:${timestamp.second}.${timestamp.millisecond}";
    debugPrint('[$formattedTime] Vana açma komutu gönderiliyor');
    await sendCommand(CMD_VANA_AC);
    _alarmService.stopAlarm();
    _sonAlarmDurumu = false;
  }

  // Vanayı kapat
  Future<void> closeValve() async {
    final timestamp = DateTime.now();
    final formattedTime =
        "${timestamp.hour}:${timestamp.minute}:${timestamp.second}.${timestamp.millisecond}";
    debugPrint('[$formattedTime] Vana kapatma komutu gönderiliyor');
    await sendCommand(CMD_VANA_KAPAT);
  }

  // Durum sorgula
  Future<void> requestStatus() async {
    final timestamp = DateTime.now();
    final formattedTime =
        "${timestamp.hour}:${timestamp.minute}:${timestamp.second}.${timestamp.millisecond}";
    debugPrint('[$formattedTime] Durum sorgulama komutu gönderiliyor');
    await sendCommand(CMD_DURUM);
  }

  // Veri dinlemeyi başlat
  void _startListening() {
    if (_connection == null) return;

    // Veri tamponunu sıfırla
    _dataBuffer = "";

    _dataStreamSubscription = _connection!.input?.listen(
      (Uint8List data) {
        final String dataString = utf8.decode(data);
        final timestamp = DateTime.now();
        final formattedTime =
            "${timestamp.hour}:${timestamp.minute}:${timestamp.second}.${timestamp.millisecond}";
        if (dataString == "") {
          return;
        }

        // Gelen veriyi tampona ekle
        _dataBuffer += dataString;
        log('[$formattedTime] Alınan veri: $dataString');
        log('[$formattedTime] Güncel tampon: $_dataBuffer');

        // JSON formatındaki veriyi işle
        try {
          // JSON formatını kontrol et ve ayıkla
          final List<String> jsonStrings = _extractJsons(_dataBuffer);

          // Bulunan tüm JSON nesnelerini işle
          for (var jsonString in jsonStrings) {
            if (jsonString.isNotEmpty) {
              try {
                final Map<String, dynamic> json = jsonDecode(jsonString);
                final sensorData = SensorData.fromJson(json);

                // Log işlenen veriyi
                log('[$formattedTime] İşlenen veri: ${sensorData.ozet}');

                // Veriyi listeye ekle
                _sensorDataList.add(sensorData);
                if (_sensorDataList.length > 100) {
                  _sensorDataList.removeAt(0); // Eski verileri temizle
                }

                // En son veriyi güncelle
                _latestData = sensorData;

                // Alarm durumunu kontrol et
                _checkAlarmStatus(sensorData);

                // Veri akışına gönder
                if (_dataStreamController != null &&
                    !_dataStreamController!.isClosed) {
                  _dataStreamController!.add(sensorData);
                }

                // UI güncellemesi
                notifyListeners();
              } catch (e) {
                log('[$formattedTime] JSON işlenirken hata: $e, JSON: $jsonString');
              }
            }
          }
        } catch (e) {
          debugPrint('[$formattedTime] Veri işlenirken hata oluştu: $e');
        }
      },
      onDone: () {
        // Bağlantı kesildi
        _isConnected = false;
        _status = STATUS_DISCONNECTED;
        notifyListeners();
      },
      onError: (error) {
        // Hata oluştu
        _isConnected = false;
        _status = '$STATUS_ERROR: $error';
        notifyListeners();
      },
    );
  }

  // JSON verilerini çıkar (Arduino'dan gelen JSON verisini temizle)
  List<String> _extractJsons(String input) {
    List<String> results = [];

    // Veri çok parçalı geldiğinde, tam bir JSON yapısı oluşana kadar biriktirme stratejisi

    // Eğer tampon çok uzarsa ve hala işlenemeyen veriler varsa, tamponu temizleyelim
    if (input.length > 1000) {
      log('Tampon çok uzun, temizleniyor: ${input.length} karakter');
      _dataBuffer =
          input.substring(input.length - 500); // Son 500 karakteri tut
    }

    // Tamponu temizle - fazla boşlukları ve yeni satırları kaldır
    input = input.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Elimizde tam bir JSON olup olmadığını kontrol et
    try {
      int startIndex = input.indexOf('{');
      if (startIndex != -1) {
        int endIndex = input.lastIndexOf('}');
        if (endIndex > startIndex) {
          // Tam bir JSON var
          String potentialJson = input.substring(startIndex, endIndex + 1);

          // JSON'u temizle - başında veya sonunda istenmeyen karakterleri kaldır
          potentialJson = potentialJson.trim();

          // JSON içindeki problemli karakterleri düzelt
          potentialJson = _cleanJsonString(potentialJson);

          // Bu gerçekten geçerli bir JSON mu kontrol et
          try {
            // JSON olarak ayrıştırmayı dene
            jsonDecode(potentialJson);

            // Başarılı ise sonuçlara ekle
            results.add(potentialJson);

            // Tamponu güncelle - işlenen veriyi çıkar
            if (endIndex + 1 < input.length) {
              _dataBuffer = input.substring(endIndex + 1);
            } else {
              _dataBuffer = "";
            }
          } catch (e) {
            // JSON geçerli değil, muhtemelen parçalı hala
            log('Geçersiz JSON formatı: $e');

            // Eğer parantez arasında tam veri yoksa ve tampon çok uzarsa, temizle
            if (_dataBuffer.length > 200) {
              _dataBuffer = "";
              log('JSON işlenemediği için tampon temizlendi');
            }
          }
        }
      }
    } catch (e) {
      log('JSON çıkarma hatası: $e');
    }

    return results;
  }

  // JSON string'ini temizleyen yardımcı fonksiyon
  String _cleanJsonString(String jsonStr) {
    // Fazla boşlukları ve yeni satırları kaldır
    jsonStr = jsonStr.replaceAll(RegExp(r'\s+'), ' ').trim();

    // JSON içinde olabilecek birden fazla JSON'u engelle
    final firstOpenBrace = jsonStr.indexOf('{');
    final lastCloseBrace = jsonStr.lastIndexOf('}');

    if (firstOpenBrace != -1 &&
        lastCloseBrace != -1 &&
        firstOpenBrace < lastCloseBrace) {
      return jsonStr.substring(firstOpenBrace, lastCloseBrace + 1);
    }

    return jsonStr;
  }

  // Eski JSON çıkarma metodu (geriye uyumluluk için)
  String _extractJson(String input) {
    List<String> results = _extractJsons(input);
    return results.isNotEmpty ? results.first : '';
  }

  // Alarm durumunu kontrol et ve gerekirse alarm çalıştır
  void _checkAlarmStatus(SensorData data) {
    final timestamp = DateTime.now();
    final formattedTime =
        "${timestamp.hour}:${timestamp.minute}:${timestamp.second}.${timestamp.millisecond}";

    debugPrint(
        '[$formattedTime] Alarm kontrolü - Gaz: ${data.gazSeviyesi}, Alarm: ${data.alarmDurumu}, Yüksek: ${data.isGazYuksek}, Durum: ${data.durum}');

    // Acil durum (GAZ_YUKSEK veya alarm=1 veya durum=GAZ_YUKSEK)
    bool acilDurum = data.isGazYuksek ||
        data.alarmDurumu ||
        data.durum.toUpperCase().contains('GAZ_YUKSEK') ||
        data.durum.toUpperCase().contains('YUKSEK');

    if (acilDurum) {
      // Eğer önceki durum alarm değilse alarmı çalıştır
      if (!_sonAlarmDurumu) {
        _alarmService.playAlarm();
        _sonAlarmDurumu = true;
        debugPrint(
            '[$formattedTime] Alarm başlatıldı: Gaz seviyesi=${data.gazSeviyesi}, AlarmDurumu=${data.alarmDurumu}, Durum=${data.durum}');
        // UI güncelleme
        notifyListeners();
      }
    } else if (data.durum.toUpperCase().contains('NORMAL')) {
      // Eğer önceki durum alarm ise alarmı durdur
      if (_sonAlarmDurumu) {
        _alarmService.stopAlarm();
        _sonAlarmDurumu = false;
        debugPrint('[$formattedTime] Alarm durduruldu: Durum normale döndü');
        // UI güncelleme
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _dataStreamSubscription?.cancel();

    if (_dataStreamController != null && !_dataStreamController!.isClosed) {
      _dataStreamController!.close();
    }

    _connection?.finish();
    _alarmService.dispose();
    super.dispose();
  }
}
