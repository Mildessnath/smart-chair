# Firebase Schema (rencana — belum diintegrasikan)

Status: **draft untuk tahap 2.** Belum ada Firebase project, kredensial, atau
`firebase_options.dart` di repo ini. Skema mengikuti `toMap()` / `fromMap()`
pada model di `lib/models/`, jadi `FirebaseChairRepository` bisa memakai model
yang sama tanpa mengubah widget.

Target: **Firebase Realtime Database** (cocok untuk ESP32 yang menulis data
kecil berfrekuensi tinggi). Struktur yang sama bisa dipetakan ke Firestore
(lihat catatan di akhir).

Konvensi:
- Timestamp = epoch milidetik (`int`), ditulis ESP32 dari NTP atau
  `{".sv": "timestamp"}` (server value).
- Sudut dalam derajat; positif = sandaran ke belakang (recline).
- Beban dalam kilogram (`kg`).
- `source`: `"sensor"` untuk data perangkat, `"simulated"` untuk data uji.

```
/devices/{deviceId}/
  latest            -> Latest telemetry
  telemetry/{pushId}-> Telemetry history
  status            -> Device status
  config            -> Device configuration
  events/{pushId}   -> Event log
  heartbeat         -> Device heartbeat
  daily/{yyyy-MM-dd}-> Ringkasan durasi postur harian
```

## 1. Latest telemetry — `/devices/{id}/latest`
Ditimpa setiap sampel (mis. 1 Hz). Dashboard berlangganan node ini.
Model: `ChairTelemetry`.
```json
{
  "ts": 1792131233000,
  "loadCells": {
    "fl": {"kg": 13.1, "health": "ok"},
    "fr": {"kg": 12.8, "health": "ok"},
    "rl": {"kg": null, "health": "fault"},
    "rr": {"kg": 17.2, "health": "ok"}
  },
  "tiltDeg": 1.4,
  "posture": "upright",
  "correction": {
    "actualDeg": 1.4,
    "targetDeg": 0.0,
    "status": "withinLimit",
    "source": "sensor",
    "phase": "monitor",
    "paused": false,
    "dwellRemaining": null
  },
  "source": "sensor"
}
```
- `posture`: `upright | leaningForward | leaningBackward | leaningLeft | leaningRight | crossedLegs | unknown`
  (`crossedLegs` = pola beban diagonal; klasifikasi heuristik, belum divalidasi)
- `health`: `ok | fault | noSignal`
- `correction.status`: `withinLimit | pending | correcting | paused | unavailable | fault`
- `correction.phase`: `monitor | dwell | correct | hold`. Postur buruk depan/belakang
  yang melewati batas → `dwell` (hitung mundur `config.dwellSeconds`) →
  `correct` → `hold` (10 dtk) → `monitor`. Miring samping tidak pernah dikoreksi.
- `correction.paused`: koreksi dijeda pengguna; aktuator tidak bergerak tetapi
  deteksi dan notifikasi tetap berjalan. Perintah: `setCorrectionPaused`.
- `correction.dwellRemaining`: detik tersisa (hanya saat `phase = dwell`).
- Field `phase`, `paused`, `dwellRemaining` opsional; payload lama tanpa field
  ini tetap terbaca.
- Center of pressure **tidak disimpan**; dihitung di klien dari 4 load cell.

## 2. Telemetry history — `/devices/{id}/telemetry/{pushId}`
Isi sama dengan `latest`. Disarankan downsample (mis. 1 sampel / 5 s) dan
retensi terbatas (Cloud Function / cron menghapus data > N hari).
Query: `orderByChild("ts").startAt(now - window)`.

## 3. Device status — `/devices/{id}/status`
Model: `DeviceStatus`.
```json
{
  "connection": "online",
  "lastHeartbeat": 1792131233000,
  "sensors": {"fl": "ok", "fr": "ok", "rl": "fault", "rr": "ok", "tilt": "ok"},
  "firmware": "0.1.0",
  "rssi": -61
}
```
`connection` sebaiknya **diturunkan di klien** dari umur heartbeat (mis.
> 10 s → offline), atau via `onDisconnect()` pada ESP32 yang menulis
`"offline"`. Nilai `demo` hanya dipakai repository mock.

## 4. Device configuration — `/devices/{id}/config`
Model: `ChairConfig`. Ditulis dashboard, dibaca ESP32.
```json
{ "maxTiltDeg": 3.0, "dwellSeconds": 25, "updatedAt": 1792131233000 }
```
Validasi (Security Rules): `maxTiltDeg` number, `>= 0 && <= 5`;
`dwellSeconds` integer, `>= 20 && <= 30` (default 25).
Disarankan menambah `appliedAt` / `appliedMaxTiltDeg` yang ditulis ESP32
sebagai acknowledgement, agar UI bisa membedakan "tersimpan" vs "diterapkan
perangkat". Sampai itu ada, UI tidak boleh mengklaim konfigurasi sudah aktif.

## 5. Event log — `/devices/{id}/events/{pushId}`
Model: `ChairEvent` (id = push key).
```json
{
  "ts": 1792131233000,
  "type": "tilt",
  "severity": "warning",
  "message": "Tilt +3.4° exceeds limit ±3.0°",
  "simulated": false,
  "code": "tilt_exceeded",
  "args": {"angle": 3.4, "limit": 3.0, "paused": false}
}
```
- `type`: `posture | tilt | correction | sensor | connection | config | system`
- `severity`: `info | warning | error`
- `message`: baris log berbahasa Inggris (fallback). `code` + `args` (opsional)
  membuat teks terlokalisasi di UI (`eventTextId`). Kode yang dikenal:
  `posture_changed {from,to}`, `posture_prolonged {posture,seconds}`,
  `tilt_exceeded {angle,limit,paused}`, `dwell_started {seconds}`,
  `dwell_cancelled {reason}`, `correction_started`, `correction_stopped`,
  `correction_settled {angle}`, `correction_pause_changed {paused}`,
  `sensor_fault_changed {position,faulty}`, `link_lost`, `link_changed`.
  Postur/posisi berupa nama enum; sudut dalam derajat. Kode tak dikenal →
  UI menampilkan `message`.
Query: `orderByChild("ts").limitToLast(100)`.

## 6. Device heartbeat — `/devices/{id}/heartbeat`
```json
{ "ts": 1792131233000, "uptimeSec": 3600, "rssi": -61 }
```
Ditulis ESP32 tiap 5 s. Dashboard menghitung stale/offline dari `ts`.

## 7. Daily summary — `/devices/{id}/daily/{yyyy-MM-dd}`
Model: `DailyPostureSummary` (key = `dateKey`).
```json
{ "goodMinutes": 212.5, "badMinutes": 64.0 }
```
Diakumulasi oleh ESP32 atau Cloud Function. `unknown` (kursi kosong / fault)
tidak dihitung.

## 8. Pengguna & notifikasi (usulan — belum ada backend)
Saat ini hanya ada di memori aplikasi (login demo, tanpa akun nyata):
- Profil: `email`, `bodyWeightKg` (30–200). Berat badan menskalakan beban
  simulasi dan persentase "dari berat badan" di halaman Tekanan.
- Aktivasi kursi: durasi duduk mulai 0 saat diaktifkan, hanya dihitung saat
  kursi aktif dan terisi (total beban ≥ 10 kg).
- Notifikasi (`AppNotification`): dibuat sekali per episode ketika pola beban
  tidak normal (kursi terisi, postur bukan tegak) terus-menerus ≥ 5 menit
  saat kursi aktif.

Jika dipindah ke Firebase: `/users/{uid}/profile {email, bodyWeightKg}` dan
`/users/{uid}/notifications/{pushId} {ts, title, body, kind, read}`. Tentukan
dulu apakah aturan 5 menit dihitung di klien (seperti sekarang) atau di server
(Cloud Function) agar notifikasi tetap terkirim saat aplikasi tertutup.

## Security Rules (sketsa, wajib disesuaikan)
```json
{
  "rules": {
    "devices": {
      "$deviceId": {
        ".read": "auth != null",
        "config": {
          ".write": "auth != null",
          "maxTiltDeg": { ".validate": "newData.isNumber() && newData.val() >= 0 && newData.val() <= 5" }
        },
        "latest":    { ".write": "auth.uid === $deviceId" },
        "telemetry": { ".write": "auth.uid === $deviceId" },
        "status":    { ".write": "auth.uid === $deviceId" },
        "heartbeat": { ".write": "auth.uid === $deviceId" },
        "events":    { ".write": "auth != null" },
        "daily":     { ".write": "auth.uid === $deviceId" }
      }
    }
  }
}
```

## Catatan Firestore
Jika memilih Firestore: `devices/{id}` (dokumen berisi `latest`, `status`,
`config`, `heartbeat` sebagai field map) dengan subkoleksi `telemetry`,
`events`, `daily`. Payload field identik dengan JSON di atas.
