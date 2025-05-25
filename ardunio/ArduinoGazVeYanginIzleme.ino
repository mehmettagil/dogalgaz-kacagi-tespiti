#include <SoftwareSerial.h>
#include <DHT.h>

// Pin Tanımlamaları
#define DHT_PIN 5     // DHT11 sensör pini
#define MQ4_PIN A0    // MQ-4 gaz sensörü pini
#define BUZZER_PIN 8  // Buzzer pini
#define VANA_PIN 9    // Selenoid vana pini

#define BT_RX 12  // HC-05 RX pini (Arduino'nun TX pini)
#define BT_TX 13  // HC-05 TX pini (Arduino'nun RX pini)

#define DHTTYPE DHT11

const int GAZ_ESIK = 300;
const float SICAKLIK_DEGISIM_ESIK = 5.0;
const float NEM_DEGISIM_ESIK = 5.0;

const unsigned long VERI_YAZDIRMA_ARALIGI = 2500;

DHT dht(DHT_PIN, DHTTYPE);
SoftwareSerial btSerial(BT_TX, BT_RX);

float sonSicaklik = 0;
float sonNem = 0;
unsigned long sonVeriYazdirmaZamani = 0;
bool alarmDurumu = false;

void setup() {
  Serial.begin(9600);
  btSerial.begin(9600);

  pinMode(MQ4_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(VANA_PIN, OUTPUT);

  digitalWrite(VANA_PIN, LOW);  // Başlangıçta vana açık

  dht.begin();

  sicaklikNemOku();

  jsonMesaj("bilgi", "Sistem başlatıldı. Gaz ve yangın izleme aktif.");
}

void loop() {
  float sicaklik = dht.readTemperature();
  float nem = dht.readHumidity();
  int gazDegeri = analogRead(MQ4_PIN);

  if (gazDegeri > GAZ_ESIK) {
    gazKacagiAlarm();
  }

  if (!isnan(sicaklik) && !isnan(nem)) {
    if (abs(sicaklik - sonSicaklik) > SICAKLIK_DEGISIM_ESIK) {
      yanginAlarm("sicaklik", "Ani sıcaklık değişimi tespit edildi!");
    }

    if (abs(nem - sonNem) > NEM_DEGISIM_ESIK) {
      yanginAlarm("nem", "Ani nem değişimi tespit edildi!");
    }

    sonSicaklik = sicaklik;
    sonNem = nem;
  }

  unsigned long simdikiZaman = millis();
  if (simdikiZaman - sonVeriYazdirmaZamani >= VERI_YAZDIRMA_ARALIGI) {
    veriGonderJSON(sicaklik, nem, gazDegeri, alarmDurumu);
    sonVeriYazdirmaZamani = simdikiZaman;
  }

  if (alarmDurumu) {
    bool gazNormal = analogRead(MQ4_PIN) <= GAZ_ESIK;
    bool sicaklikNormal = abs(dht.readTemperature() - sonSicaklik) <= SICAKLIK_DEGISIM_ESIK;
    bool nemNormal = abs(dht.readHumidity() - sonNem) <= NEM_DEGISIM_ESIK;

    if (gazNormal && sicaklikNormal && nemNormal) {
      alarmDurumu = false;
      digitalWrite(VANA_PIN, LOW);  // Vana tekrar açılıyor
      jsonMesaj("bilgi", "Alarm durumu sona erdi. Vana sıfırlandı.");
    }
  }

  bluetoothKomutKontrol();
  delay(100);
}

void gazKacagiAlarm() {
  digitalWrite(VANA_PIN, HIGH);
  alarmCal();

  alarmDurumu = true;

  jsonAlarm("gaz", "GAZ KAÇAĞI TESPİT EDİLDİ!");
  veriGonderJSON(sonSicaklik, sonNem, analogRead(MQ4_PIN), alarmDurumu);
}

void yanginAlarm(String kaynak, String mesaj) {
  digitalWrite(VANA_PIN, HIGH);
  alarmCal();

  alarmDurumu = true;

  jsonAlarm(kaynak, mesaj);
  veriGonderJSON(sonSicaklik, sonNem, analogRead(MQ4_PIN), alarmDurumu);
}

void alarmCal() {
  for (int i = 0; i < 3; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(300);
    digitalWrite(BUZZER_PIN, LOW);
    delay(200);
  }

  digitalWrite(BUZZER_PIN, HIGH);
  delay(1000);
  digitalWrite(BUZZER_PIN, LOW);
}

void sicaklikNemOku() {
  sonSicaklik = dht.readTemperature();
  sonNem = dht.readHumidity();

  if (isnan(sonSicaklik) || isnan(sonNem)) {
    jsonMesaj("hata", "DHT11 sensöründen veri okunamadı!");
  } else {
    veriGonderJSON(sonSicaklik, sonNem, analogRead(MQ4_PIN), alarmDurumu);
  }
}

void bluetoothKomutKontrol() {
  String komut = "";

  while (btSerial.available() > 0) {
    delay(10);
    char c = btSerial.read();
    if (c >= 32 && c <= 126) {
      komut += c;
    }
    if (c == '\n' || c == '\r') {
      break;
    }
  }

  komut.trim();

  if (komut.length() > 0) {
    if (komut == "VANA_AC") {
      digitalWrite(VANA_PIN, LOW);
      alarmDurumu = false;
      jsonKomut(komut, "Vana açıldı");
    } else if (komut == "VANA_KAPAT") {
      digitalWrite(VANA_PIN, HIGH);
      jsonKomut(komut, "Vana kapatıldı");
    } else if (komut == "DURUM") {
      veriGonderJSON(sonSicaklik, sonNem, analogRead(MQ4_PIN), alarmDurumu);
    }

    while (btSerial.available() > 0) {
      btSerial.read();
    }
  }
}

// === JSON GÖNDERİCİLER ===

void jsonMesaj(String tip, String mesaj) {
  String json = "{\"tip\":\"" + tip + "\",\"mesaj\":\"" + mesaj + "\"}";
  Serial.println(json);
  btSerial.println(json);
}

void jsonKomut(String komut, String mesaj) {
  String json = "{\"tip\":\"komut\",\"komut\":\"" + komut + "\",\"mesaj\":\"" + mesaj + "\"}";
  Serial.println(json);
  btSerial.println(json);
}

void jsonAlarm(String kaynak, String mesaj) {
  String json = "{\"tip\":\"alarm\",\"kaynak\":\"" + kaynak + "\",\"mesaj\":\"" + mesaj + "\",\"vana\":\"kapali\",\"buzzer\":\"aktif\"}";
  Serial.println(json);
  btSerial.println(json);
}

void veriGonderJSON(float sicaklik, float nem, int gaz, bool alarm) {
  String json = "{";
  json += "\"tip\":\"veri\"";
  json += ",\"sicaklik\":" + String(sicaklik, 1);
  json += ",\"nem\":" + String(nem, 1);
  json += ",\"gaz\":" + String(gaz);
  json += ",\"alarm\":" + String(alarm ? 1 : 0);
  json += ",\"durum\":\"" + String(gaz > GAZ_ESIK ? "GAZ_YUKSEK" : "NORMAL") + "\"";
  json += "}";

  Serial.println(json);
  btSerial.println(json);
}
