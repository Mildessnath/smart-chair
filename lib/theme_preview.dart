// Theme review entrypoint (not part of the app):
//   flutter run -d chrome -t lib/theme_preview.dart
import 'package:flutter/material.dart';

import 'theme/app_icons.dart';
import 'theme/app_theme.dart';
import 'widgets/ui/app_card.dart';
import 'widgets/ui/buttons.dart';
import 'widgets/ui/section_header.dart';
import 'widgets/ui/status_pill.dart';

void main() => runApp(const ThemePreviewApp());

class ThemePreviewApp extends StatelessWidget {
  const ThemePreviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Smart Chair — Theme',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: const ThemePreviewScreen(),
  );
}

class ThemePreviewScreen extends StatefulWidget {
  const ThemePreviewScreen({super.key});

  @override
  State<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends State<ThemePreviewScreen> {
  int _tab = 0;
  int _segment = 0;
  int _chip = 0;
  bool _demo = true;
  double _tilt = 3;

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // Phone-width column so the mobile-first design can be judged on desktop.
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Scaffold(
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(AppIcons.home),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(AppIcons.history),
                  label: 'Riwayat',
                ),
                NavigationDestination(
                  icon: Icon(AppIcons.notifications),
                  label: 'Notifikasi',
                ),
                NavigationDestination(
                  icon: Icon(AppIcons.settings),
                  label: 'Pengaturan',
                ),
              ],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.m,
                  AppSpace.screen,
                  AppSpace.xl,
                ),
                children: [
                  Row(
                    children: [
                      RoundIconButton(
                        icon: AppIcons.back,
                        tooltip: 'Kembali',
                        onPressed: () => _toast('Tombol back'),
                      ),
                      Expanded(
                        child: Text(
                          'Tema Smart Chair',
                          textAlign: TextAlign.center,
                          style: t.titleMedium,
                        ),
                      ),
                      const StatusPill(
                        label: 'Demo',
                        tone: StatusTone.neutral,
                        icon: AppIcons.demo,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.l),
                  Text('We Say Hello!', style: t.headlineMedium),
                  const SizedBox(height: AppSpace.s),
                  Text(
                    'Pratinjau token tema: warna, tipografi, tombol, input, '
                    'kartu dan navigasi.',
                    style: t.bodyMedium!.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpace.l),

                  // Hero sample
                  AppCard(
                    color: AppColors.lime,
                    padding: const EdgeInsets.all(AppSpace.l),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Postur', style: t.labelMedium),
                              const SizedBox(height: AppSpace.xs),
                              Text('Tegak', style: t.displaySmall),
                              const SizedBox(height: AppSpace.s),
                              Text(
                                'Pertahankan, punggung menempel sandaran.',
                                style: t.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpace.m),
                        CircleArrowButton(
                          onPressed: () => _toast('Lingkaran berpanah'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.m),
                  Row(
                    children: [
                      Expanded(
                        child: AppCard(
                          color: AppColors.amber,
                          child: Text(
                            'Condong\nke depan',
                            style: t.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.m),
                      Expanded(
                        child: AppCard(
                          color: AppColors.coral,
                          child: Text(
                            'Terlalu lama\nbersandar',
                            style: t.titleMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),

                  const SectionHeader(title: 'Palet'),
                  const SizedBox(height: AppSpace.s),
                  const Wrap(
                    spacing: AppSpace.s,
                    runSpacing: AppSpace.s,
                    children: [
                      _Swatch('Lime', AppColors.lime),
                      _Swatch('Pressed', AppColors.limePressed),
                      _Swatch('Tint', AppColors.limeTint),
                      _Swatch('Ink', AppColors.ink),
                      _Swatch('Surface', AppColors.surface),
                      _Swatch('Line', AppColors.line),
                      _Swatch('Sekunder', AppColors.textSecondary),
                      _Swatch('Amber', AppColors.amber),
                      _Swatch('Coral', AppColors.coral),
                    ],
                  ),
                  const SizedBox(height: AppSpace.m),
                  Text('Heatmap', style: t.labelMedium),
                  const SizedBox(height: AppSpace.s),
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          for (var i = 0; i <= 10; i++) AppColors.heat(i / 10),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  const SectionHeader(title: 'Tipografi'),
                  const SizedBox(height: AppSpace.s),
                  Text('Display 32 / 800', style: t.displaySmall),
                  Text('Headline 24 / 800', style: t.headlineSmall),
                  Text('Title 20 / 700', style: t.titleLarge),
                  Text('Title 16 / 700', style: t.titleMedium),
                  Text('Body 16 / 500 — teks isi utama.', style: t.bodyLarge),
                  Text(
                    'Body 14 / 500 — teks isi standar.',
                    style: t.bodyMedium,
                  ),
                  Text('Caption 12 / 500 — teks sekunder.', style: t.bodySmall),
                  const SizedBox(height: AppSpace.xl),

                  const SectionHeader(title: 'Input'),
                  const SizedBox(height: AppSpace.s),
                  const TextField(
                    decoration: InputDecoration(
                      hintText: 'Nama perangkat',
                      prefixIcon: Icon(AppIcons.chair),
                    ),
                  ),
                  const SizedBox(height: AppSpace.m),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Kata sandi Wi-Fi',
                      prefixIcon: Icon(AppIcons.online),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  const SectionHeader(title: 'Tombol'),
                  const SizedBox(height: AppSpace.s),
                  PrimaryPillButton(
                    label: 'Pause koreksi',
                    icon: AppIcons.pause,
                    expand: true,
                    onPressed: () => _toast('Primer: pill hitam'),
                  ),
                  const SizedBox(height: AppSpace.m),
                  SecondaryPillButton(
                    label: 'Simpan',
                    expand: true,
                    onPressed: () => _toast('Sekunder: pill lime'),
                  ),
                  const SizedBox(height: AppSpace.m),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _toast('Outline'),
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: AppSpace.s),
                      TextButton(
                        onPressed: () => _toast('Teks'),
                        child: const Text('Skip'),
                      ),
                      const Spacer(),
                      const PrimaryPillButton(
                        label: 'Nonaktif',
                        onPressed: null,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),

                  const SectionHeader(title: 'Kontrol'),
                  const SizedBox(height: AppSpace.s),
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Hari')),
                      ButtonSegment(value: 1, label: Text('Minggu')),
                      ButtonSegment(value: 2, label: Text('Bulan')),
                    ],
                    selected: {_segment},
                    onSelectionChanged: (s) =>
                        setState(() => _segment = s.first),
                  ),
                  const SizedBox(height: AppSpace.m),
                  Wrap(
                    spacing: AppSpace.s,
                    children: [
                      for (final (i, l) in const [
                        'Semua',
                        'Postur',
                        'Perangkat',
                      ].indexed)
                        ChoiceChip(
                          label: Text(l),
                          selected: _chip == i,
                          onSelected: (_) => setState(() => _chip = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.m),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.l - 4,
                      vertical: AppSpace.s,
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Mode demo'),
                          subtitle: const Text('Data simulasi'),
                          value: _demo,
                          onChanged: (v) => setState(() => _demo = v),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpace.s),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Batas kemiringan',
                                  style: t.titleSmall,
                                ),
                              ),
                              Text(
                                '${_tilt.toStringAsFixed(1)}°',
                                style: t.titleSmall,
                              ),
                            ],
                          ),
                        ),
                        Slider(
                          value: _tilt,
                          max: 5,
                          divisions: 50,
                          label: '${_tilt.toStringAsFixed(1)}°',
                          onChanged: (v) => setState(() => _tilt = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.m),
                  const Wrap(
                    spacing: AppSpace.s,
                    runSpacing: AppSpace.s,
                    children: [
                      StatusPill(
                        label: 'Terhubung',
                        tone: StatusTone.good,
                        icon: AppIcons.online,
                      ),
                      StatusPill(
                        label: 'Peringatan',
                        tone: StatusTone.warning,
                        icon: AppIcons.warning,
                      ),
                      StatusPill(
                        label: 'Offline',
                        tone: StatusTone.alert,
                        icon: AppIcons.offline,
                      ),
                      StatusPill(label: 'Demo', icon: AppIcons.demo),
                      StatusPill(
                        label: 'Koreksi',
                        tone: StatusTone.dark,
                        icon: AppIcons.sliders,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color);
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hex = color.toARGB32().toRadixString(16).substring(2).toUpperCase();
    return SizedBox(
      width: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.small),
              border:
                  color == AppColors.background || color == AppColors.surface
                  ? Border.all(color: AppColors.line)
                  : null,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(name, style: Theme.of(context).textTheme.labelMedium),
          Text('#$hex', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
