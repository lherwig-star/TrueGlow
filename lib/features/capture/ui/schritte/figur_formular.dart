import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../modules/logic/module_controller.dart';
import '../../../modules/models/modul_eingaben.dart';

/// Koerpergroesse und Gewicht fuer "Figur & Passform".
class FigurFormular extends ConsumerStatefulWidget {
  const FigurFormular({super.key});

  @override
  ConsumerState<FigurFormular> createState() => _FigurFormularState();
}

class _FigurFormularState extends ConsumerState<FigurFormular> {
  /// Plausible Bereiche – fangen Tippfehler ab, ohne jemanden auszuschliessen.
  static const _groesseVon = 120;
  static const _groesseBis = 230;
  static const _gewichtVon = 35;
  static const _gewichtBis = 250;

  late final TextEditingController _groesse;
  late final TextEditingController _gewicht;

  @override
  void initState() {
    super.initState();
    final angaben = ref.read(moduleControllerProvider).eingaben.figur;
    _groesse = TextEditingController(text: angaben.groesseCm?.toString() ?? '');
    _gewicht = TextEditingController(text: angaben.gewichtKg?.toString() ?? '');
  }

  @override
  void dispose() {
    _groesse.dispose();
    _gewicht.dispose();
    super.dispose();
  }

  /// Schreibt nur gueltige Werte in den Controller – ein halb getippter Wert
  /// soll den Weiter-Button nicht freigeben.
  void _uebernehmen() {
    final angaben = FigurAngaben(
      groesseCm: _imBereich(_groesse.text, _groesseVon, _groesseBis),
      gewichtKg: _imBereich(_gewicht.text, _gewichtVon, _gewichtBis),
    );
    ref.read(moduleControllerProvider.notifier).setzeFigur(angaben);
  }

  static int? _imBereich(String text, int von, int bis) {
    final wert = int.tryParse(text.trim());
    if (wert == null || wert < von || wert > bis) return null;
    return wert;
  }

  @override
  Widget build(BuildContext context) {
    final angaben = ref.watch(moduleControllerProvider).eingaben.figur;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          S.figurFormularTitel,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        const MutedText(S.figurFormularText),
        const SizedBox(height: AppTheme.gapM),
        _Feld(
          controller: _groesse,
          label: S.figurGroesse,
          einheit: 'cm',
          icon: Icons.straighten,
          fehler: _groesse.text.trim().isEmpty || angaben.groesseCm != null
              ? null
              : S.figurGroesseFehler,
          onChanged: (_) => setState(_uebernehmen),
        ),
        const SizedBox(height: AppTheme.gapS),
        _Feld(
          controller: _gewicht,
          label: S.figurGewicht,
          einheit: 'kg',
          icon: Icons.monitor_weight_outlined,
          fehler: _gewicht.text.trim().isEmpty || angaben.gewichtKg != null
              ? null
              : S.figurGewichtFehler,
          onChanged: (_) => setState(_uebernehmen),
        ),
        const SizedBox(height: AppTheme.gapS),
        SectionCard(
          title: 'Bleibt auf dem Gerät',
          icon: Icons.lock_outline,
          child: const MutedText(
            'Größe und Gewicht werden nur für die Passform-Empfehlung '
            'mitgeschickt und nicht dauerhaft beim Analyse-Dienst gespeichert.',
          ),
        ),
      ],
    );
  }
}

class _Feld extends StatelessWidget {
  const _Feld({
    required this.controller,
    required this.label,
    required this.einheit,
    required this.icon,
    required this.onChanged,
    this.fehler,
  });

  final TextEditingController controller;
  final String label;
  final String einheit;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final String? fehler;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        errorText: fehler,
        prefixIcon: Icon(icon, color: farben.akzent),
        suffixText: einheit,
        suffixStyle: TextStyle(
          color: farben.textSekundaer,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: farben.flaeche,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          borderSide: BorderSide(color: farben.rand),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          borderSide: BorderSide(color: farben.akzent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          borderSide: BorderSide(color: farben.warnung),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          borderSide: BorderSide(color: farben.warnung, width: 1.6),
        ),
      ),
    );
  }
}
