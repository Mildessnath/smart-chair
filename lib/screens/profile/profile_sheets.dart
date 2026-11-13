import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/posture_state.dart';
import '../../providers/dashboard_controller.dart';
import '../../providers/monitoring_controller.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../utils/labels_id.dart';
import '../../widgets/simulation_controls_panel.dart';
import '../../widgets/ui/buttons.dart';
import '../auth/auth_widgets.dart' show FormNotice;
import '../auth/weight_screen.dart' show applyBodyWeight;

/// Wraps sheet content with the standard padding and keyboard inset.
class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.screen,
        0,
        AppSpace.screen,
        AppSpace.l + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpace.m),
            child,
          ],
        ),
      ),
    ),
  );
}

/// Slider + Save sheet for a numeric setting.
Future<void> showSliderSheet(
  BuildContext context, {
  required String title,
  required String description,
  required double min,
  required double max,
  required int divisions,
  required double initial,
  required String Function(double) format,
  required Future<void> Function(double) onSave,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _SheetBody(
    title: title,
    child: _SliderForm(
      description: description,
      min: min,
      max: max,
      divisions: divisions,
      initial: initial,
      format: format,
      onSave: onSave,
    ),
  ),
);

class _SliderForm extends StatefulWidget {
  const _SliderForm({
    required this.description,
    required this.min,
    required this.max,
    required this.divisions,
    required this.initial,
    required this.format,
    required this.onSave,
  });

  final String description;
  final double min;
  final double max;
  final int divisions;
  final double initial;
  final String Function(double) format;
  final Future<void> Function(double) onSave;

  @override
  State<_SliderForm> createState() => _SliderFormState();
}

class _SliderFormState extends State<_SliderForm> {
  late double _value = widget.initial.clamp(widget.min, widget.max);
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final dirty = (_value - widget.initial).abs() > 1e-9;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.format(_value),
          key: const Key('sheetValue'),
          style: t.displaySmall,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(widget.description, style: t.bodySmall),
        Slider(
          key: const Key('sheetSlider'),
          value: _value,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          label: widget.format(_value),
          onChanged: _saving ? null : (v) => setState(() => _value = v),
        ),
        const SizedBox(height: AppSpace.s),
        PrimaryPillButton(
          key: const Key('sheetSave'),
          label: 'Simpan',
          expand: true,
          onPressed: dirty && !_saving
              ? () async {
                  setState(() => _saving = true);
                  final nav = Navigator.of(context);
                  await widget.onSave(_value);
                  if (nav.mounted) nav.pop();
                }
              : null,
        ),
      ],
    );
  }
}

/// Edit body weight (same validation as onboarding).
Future<void> showWeightSheet(
  BuildContext context, {
  required double? current,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _SheetBody(
    title: 'Berat badan',
    child: _WeightForm(current: current),
  ),
);

class _WeightForm extends StatefulWidget {
  const _WeightForm({required this.current});
  final double? current;

  @override
  State<_WeightForm> createState() => _WeightFormState();
}

class _WeightFormState extends State<_WeightForm> {
  late final _controller = TextEditingController(
    text: widget.current == null
        ? ''
        : (widget.current! == widget.current!.roundToDouble()
              ? widget.current!.toStringAsFixed(0)
              : widget.current!.toStringAsFixed(1)),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = parseBodyWeight(_controller.text);
    final invalid = _controller.text.trim().isNotEmpty && value == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('sheetWeightField'),
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Berat badan',
            suffixText: 'kg',
            prefixIcon: Icon(AppIcons.weight),
          ),
        ),
        if (invalid) ...[
          const SizedBox(height: AppSpace.s),
          FormNotice(
            error: true,
            icon: AppIcons.error,
            message:
                'Masukkan angka ${minBodyWeightKg.toStringAsFixed(0)}–'
                '${maxBodyWeightKg.toStringAsFixed(0)} kg.',
          ),
        ],
        const SizedBox(height: AppSpace.m),
        PrimaryPillButton(
          key: const Key('sheetWeightSave'),
          label: 'Simpan',
          expand: true,
          onPressed: value == null
              ? null
              : () {
                  applyBodyWeight(context, value);
                  Navigator.of(context).pop();
                },
        ),
      ],
    );
  }
}

/// Simulation controls, for exercising every UI state in Demo Mode.
Future<void> showSimulationSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) =>
          const _SheetBody(title: 'Kontrol simulasi', child: _SimulationForm()),
    );

class _SimulationForm extends StatelessWidget {
  const _SimulationForm();

  static const _delays = [
    (Duration(minutes: 5), '5 menit'),
    (Duration(seconds: 30), '30 detik (uji)'),
    (Duration(seconds: 10), '10 detik (uji)'),
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final monitoring = context.watch<MonitoringController>();
    final t = Theme.of(context).textTheme;

    final latest = ctrl.latest;
    final PostureState posture = latest != null && latest.posture.isBad
        ? latest.posture
        : PostureState.leaningForward;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notifikasi tekanan', style: t.titleSmall),
        const SizedBox(height: AppSpace.xs),
        Text(
          'Muncul jika pola beban tidak normal terus-menerus selama:',
          style: t.bodySmall,
        ),
        const SizedBox(height: AppSpace.s),
        Wrap(
          spacing: AppSpace.s,
          children: [
            for (final (d, label) in _delays)
              ChoiceChip(
                label: Text(label),
                selected: monitoring.alertAfter == d,
                onSelected: (_) => monitoring.alertAfter = d,
              ),
          ],
        ),
        const SizedBox(height: AppSpace.m),
        OutlinedButton.icon(
          key: const Key('triggerAlert'),
          onPressed: () =>
              monitoring.raisePressureAlert(posture, monitoring.alertAfter),
          icon: const Icon(AppIcons.notifications, size: 18),
          label: const Text('Picu notifikasi sekarang'),
        ),
        const Divider(height: AppSpace.xl),
        Text('Data simulasi', style: t.titleSmall),
        const SizedBox(height: AppSpace.xs),
        Text(
          'Postur yang dipaksa tetap dinilai oleh classifier. '
          '${postureTitleId(PostureState.crossedLegs)} adalah pola beban '
          'diagonal.',
          style: t.bodySmall,
        ),
        SimulationControlsPanel(ctrl: ctrl),
      ],
    );
  }
}
