import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();

  factory AlarmService() => _instance;

  AlarmService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Timer? _vibrateTimer;

  // Alarm sesi çal
  Future<void> playAlarm() async {
    if (_isPlaying) return;

    try {
      // Ses dosyasını assets klasöründen çal
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
      _isPlaying = true;

      // Cihazı titret (3 saniyede bir)
      _startVibration();

      // Ekrana alarm bildirimi göster
      _showAlarmNotification();

      debugPrint('Alarm sesi çalınıyor');
    } catch (e) {
      debugPrint('Alarm sesi çalınamadı: $e');

      // Ses çalınamadığında sadece titreşim ve bildirim göster
      _startVibration();
      _showAlarmNotification();
    }
  }

  // Alarm sesini durdur
  Future<void> stopAlarm() async {
    if (!_isPlaying) return;

    try {
      await _audioPlayer.stop();
      _isPlaying = false;

      // Titreşimi durdur
      _stopVibration();

      debugPrint('Alarm sesi durduruldu');
    } catch (e) {
      debugPrint('Alarm sesi durdurulamadı: $e');
    }
  }

  // Periyodik titreşim başlat
  void _startVibration() {
    // Titreşim zamanlayıcısını temizle
    _vibrateTimer?.cancel();

    // Titreşim için ilk titreşimi başlat
    HapticFeedback.heavyImpact();

    // Periyodik titreşim için zamanlayıcı başlat
    _vibrateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      HapticFeedback.heavyImpact();
    });
  }

  // Titreşimi durdur
  void _stopVibration() {
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
  }

  // Alarm bildirimi göster
  void _showAlarmNotification() {
    Fluttertoast.showToast(
        msg: "⚠️ ALARM! ⚠️ GAZ KAÇAĞI TESPİT EDİLDİ!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 5,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 18.0);
  }

  // Servisi kapat
  void dispose() {
    stopAlarm();
    _audioPlayer.dispose();
    _vibrateTimer?.cancel();
  }
}
