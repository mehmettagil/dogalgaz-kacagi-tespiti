class SensorData {
  final double sicaklik;
  final double nem;
  final int gazSeviyesi;
  final bool alarmDurumu;
  final String durum;
  final DateTime timestamp;

  SensorData({
    required this.sicaklik,
    required this.nem,
    required this.gazSeviyesi,
    required this.alarmDurumu,
    required this.durum,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      sicaklik: json['sicaklik']?.toDouble() ?? 0.0,
      nem: json['nem']?.toDouble() ?? 0.0,
      gazSeviyesi: json['gaz']?.toInt() ?? 0,
      alarmDurumu: json['alarm'] == 1,
      durum: json['durum'] ?? 'NORMAL',
      timestamp: DateTime.now(),
    );
  }

  // Gaz seviyesi limitini aşıp aşmadığını kontrol et
  bool get isGazYuksek => gazSeviyesi > 300; // Arduino'daki GAZ_ESIK değeri

  // Gaz seviyesi durumunu metin olarak döndür
  String get gazDurumu {
    if (isGazYuksek) {
      return 'Yüksek';
    } else {
      return 'Normal';
    }
  }

  // Veri özeti döndürür
  String get ozet {
    return 'Sıcaklık: $sicaklik°C, Nem: $nem%, Gaz: $gazSeviyesi, Durum: $durum';
  }
}
