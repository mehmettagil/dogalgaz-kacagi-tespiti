import 'package:flutter/services.dart';

abstract class BluetoothFailure {
  final String message;

  const BluetoothFailure(this.message);

  @override
  String toString() => message;
}

class PermissionFailure extends BluetoothFailure {
  const PermissionFailure() : super('Bluetooth izinleri reddedildi');
}

class ConnectionFailure extends BluetoothFailure {
  const ConnectionFailure(String message) : super(message);

  factory ConnectionFailure.fromException(dynamic e) {
    if (e is PlatformException) {
      if (e.code == 'connect_error') {
        return ConnectionFailure(
            'Bağlantı hatası: Cihaz bağlantıyı reddetti veya bulunamadı');
      } else {
        return ConnectionFailure('Bağlantı hatası: ${e.message}');
      }
    } else if (e is Exception) {
      return ConnectionFailure('Bağlantı hatası: ${e.toString()}');
    } else {
      return const ConnectionFailure('Bilinmeyen bağlantı hatası');
    }
  }
}

class TimeoutFailure extends BluetoothFailure {
  const TimeoutFailure() : super('Bağlantı zaman aşımına uğradı');
}

class BluetoothDisabledFailure extends BluetoothFailure {
  const BluetoothDisabledFailure() : super('Bluetooth kapalı');
}

class DeviceNotFoundFailure extends BluetoothFailure {
  const DeviceNotFoundFailure() : super('Cihaz bulunamadı');
}

class SendCommandFailure extends BluetoothFailure {
  const SendCommandFailure(String message)
      : super('Komut gönderme hatası: $message');
}
