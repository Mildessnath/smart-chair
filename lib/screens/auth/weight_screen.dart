import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_controller.dart';
import '../../providers/user_session.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../utils/labels_id.dart';
import '../../widgets/ui/buttons.dart';
import 'auth_widgets.dart';

/// Saves the weight to the session and to the (simulated) chair readings.
void applyBodyWeight(BuildContext context, double kg) {
  context.read<UserSession>().setBodyWeight(kg);
  context.read<DashboardController>().setBodyWeight(kg);
}

/// Onboarding: "Masukkan berat badan anda".
class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _value => parseBodyWeight(_controller.text);

  void _step(double delta) {
    final base = _value ?? 65;
    final next = (base + delta).clamp(minBodyWeightKg, maxBodyWeightKg);
    setState(() {
      _controller.text = _format(next);
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
  }

  String _format(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final typed = _controller.text.trim().isNotEmpty;
    final value = _value;
    final invalid = typed && value == null;

    return AuthScaffold(
      step: 2,
      title: 'Berapa berat badanmu?',
      subtitle:
          'Dipakai untuk menyesuaikan pembacaan beban pada kursi. '
          'Bisa diubah nanti di Profil.',
      footer: PrimaryPillButton(
        key: const Key('weightNext'),
        label: 'Lanjut',
        expand: true,
        onPressed: value == null ? null : () => applyBodyWeight(context, value),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RoundIconButton(
                key: const Key('weightMinus'),
                icon: Icons.remove,
                tooltip: 'Kurangi 1 kg',
                size: 52,
                onPressed: () => _step(-1),
              ),
              const SizedBox(width: AppSpace.m),
              SizedBox(
                width: 140,
                child: TextField(
                  key: const Key('weightField'),
                  controller: _controller,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: t.displaySmall,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '70',
                    hintStyle: t.displaySmall!.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    suffixText: 'kg',
                    suffixStyle: t.titleMedium,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.m),
              RoundIconButton(
                key: const Key('weightPlus'),
                icon: Icons.add,
                tooltip: 'Tambah 1 kg',
                size: 52,
                onPressed: () => _step(1),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.m),
          if (invalid)
            FormNotice(
              key: const Key('weightError'),
              error: true,
              icon: AppIcons.error,
              message:
                  'Masukkan angka antara ${minBodyWeightKg.toStringAsFixed(0)} '
                  'dan ${maxBodyWeightKg.toStringAsFixed(0)} kg, '
                  'mis. 68 atau 68,5.',
            )
          else
            Text(
              'Rentang: ${minBodyWeightKg.toStringAsFixed(0)}–'
              '${maxBodyWeightKg.toStringAsFixed(0)} kg',
              style: t.bodySmall,
            ),
        ],
      ),
    );
  }
}
