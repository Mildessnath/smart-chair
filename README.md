# Smart Chair

Aplikasi Flutter Web untuk memantau postur duduk dan koreksi kemiringan kursi
otomatis. UI mobile-first (kolom selebar ponsel di layar lebar), bahasa
Indonesia.

**Demo langsung:** https://mildessnath.github.io/smart-chair/ — masuk dengan
email berformat valid apa saja dan kata sandi minimal 4 karakter. Di-deploy
otomatis dari `main` lewat GitHub Actions (`.github/workflows/pages.yml`),
hanya jika `flutter analyze` dan `flutter test` lulus.

> **Status: UI + data simulasi.** Belum ada Firebase, ESP32, atau akun nyata.
> Semua data berasal dari simulator deterministik dan diberi label
> "simulasi". Login hanya tiruan (tidak ada server akun).

## Fitur

| Halaman | Isi |
|---|---|
| Splash → Masuk → Berat badan → Aktifkan kursi | Alur awal. Berat badan menskalakan beban simulasi. Durasi duduk baru mulai setelah kursi diaktifkan. |
| **Beranda** | Hero status postur (lime/amber/coral, hitung mundur saat DWELL), ringkasan live: tekanan, sudut kursi, durasi duduk. Tombol Aktifkan kursi / Pause koreksi. |
| **Tekanan** | Peta kursi tampak atas dari 4 load cell, data tiap load cell (kg, %), total beban, persen terhadap berat badan, titik tekanan. |
| **Notifikasi** | Muncul jika tekanan tidak normal terus-menerus > 5 menit (kursi aktif dan terisi). Dikelompokkan Hari ini / Kemarin. |
| **Riwayat** | Grafik durasi postur 7 hari atau sudut kursi, ringkasan, dan daftar kejadian dengan filter. |
| **Profil** | Akun, aktivasi kursi, berat badan, batas kemiringan (0–5°), waktu tunggu koreksi (20–30 dtk), Mode demo, kontrol simulasi, keluar. |

Postur: tegak, condong depan/belakang, miring kiri/kanan, **melipat kaki**
(pola beban diagonal), kursi kosong/sensor bermasalah. Klasifikasi adalah
heuristik center-of-pressure untuk simulasi dan **belum divalidasi** pada
pengguna sungguhan.

Siklus koreksi: `MONITOR → DWELL (20–30 dtk) → CORRECT → HOLD → MONITOR`.
Hanya condong depan/belakang yang dikoreksi; postur membaik saat DWELL
membatalkannya; saat dijeda aktuator tidak bergerak tetapi deteksi dan
notifikasi tetap jalan.

Peta tekanan memakai hanya empat titik ukur: warna menunjukkan beban per
sudut, **bukan** distribusi tekanan fisik yang terukur.

## Menjalankan

Butuh Flutter (stable, dicoba dengan 3.47) dan Chrome.

```bash
flutter pub get
flutter run -d chrome          # aplikasi
flutter analyze
dart format lib test
flutter test                   # 119 tes
flutter build web              # build/web
```

Windows PowerShell, bila Flutter belum ada di PATH:
`$env:Path = "C:\path\ke\flutter\bin;$env:Path"`.

Masuk dengan email berformat valid apa saja (mis. `nama@contoh.com`) dan kata
sandi minimal 4 karakter.

Menguji tanpa menunggu: **Profil → Kontrol simulasi** (paksa postur, sensor
rusak, picu notifikasi, percepat ambang notifikasi jadi 10 detik).

### Entrypoint pengembangan

- `lib/main_states.dart` — app yang sama dengan preset simulator lewat query
  URL, untuk meninjau atau memotret keadaan UI:
  `flutter run -d chrome -t lib/main_states.dart` lalu buka
  `/?posture=crossed&tab=pressure&weight=70`. Parameter: `posture`
  (upright/forward/backward/left/right/crossed/empty), `paused=1`, `active=0`,
  `weight`, `tab` (pressure/notifications/history/profile), `step`
  (login/weight/activation).
- `lib/theme_preview.dart` — katalog token tema (warna, tipografi, tombol).

## Struktur

```
lib/
  main.dart, app.dart           entry point + provider
  models/                       ChairTelemetry, LoadCellReading, DeviceStatus,
                                ChairConfig, ChairEvent, CorrectionState,
                                AppNotification, DailyPostureSummary, PostureState
  repositories/                 ChairRepository (kontrak), MockChairRepository,
                                DisconnectedChairRepository, SimulationControls
  services/chair_simulator.dart simulasi beban, sudut, aktuator, fase koreksi
  providers/
    dashboard_controller.dart   state data/UI dari repository
    monitoring_controller.dart  aktivasi kursi, durasi duduk, notifikasi 5 menit
    user_session.dart           login demo, berat badan
  screens/                      auth/, home/, pressure/, notifications/,
                                history/, profile/, app_shell.dart, app_root.dart
  widgets/                      home/, pressure/, history/, ui/ (komponen umum)
  theme/                        app_theme.dart (token), app_icons.dart
  utils/                        classifier postur, center of pressure,
                                statistik, formatter, label bahasa Indonesia
assets/fonts/                   Plus Jakarta Sans (OFL), Phosphor Light (MIT)
docs/firebase_schema.md         rancangan skema Firebase
test/                           unit + widget test
```

Aliran data: `Repository → DashboardController → MonitoringController →
widgets`. Widget tidak pernah mengakses repository langsung.

Folder lama (`lib/screens/*_screen.dart` bergaya dashboard desktop dan
`lib/widgets/*` terkait) masih ada karena dipakai `DashboardShell`, tata letak
tahap 1 yang tetap menjadi `home` bawaan `SmartChairApp` supaya tes lamanya
tetap berjalan. `main.dart` memakai UI baru (`AppRoot`).

## Mengganti mock dengan Firebase (tahap berikutnya)

1. `flutterfire configure` (jangan menyimpan secret di repo; konfigurasi web
   publik boleh).
2. Tambah `firebase_core` + `firebase_database` (atau `cloud_firestore`).
3. Buat `FirebaseChairRepository implements ChairRepository`: `fetch*` →
   `ref.get()`, `watch*` → `onValue`/`onChildAdded`, dipetakan dengan
   `Model.fromMap`. `saveConfig` → `config.toMap()`; `setCorrectionPaused` →
   menulis perintah ke perangkat.
4. Ubah satu baris di `lib/app.dart`:
   `demoMode ? MockChairRepository(...) : FirebaseChairRepository(...)`.
5. Skema dan keputusan terbuka (mis. di mana aturan notifikasi 5 menit
   dihitung): `docs/firebase_schema.md`.

## Lisensi font

Plus Jakarta Sans: SIL OFL 1.1 (`assets/fonts/OFL.txt`). Phosphor Icons:
MIT (`assets/fonts/PHOSPHOR-LICENSE.txt`).
