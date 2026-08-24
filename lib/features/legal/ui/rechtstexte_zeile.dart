import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../logic/rechtstexte.dart';
import 'legal_screen.dart';

/// Eine Zeile mit Verweisen auf die Rechtstexte.
///
/// Steht überall dort, wo jemand zustimmt oder etwas nachlesen möchte:
/// im Onboarding, auf dem Login-Screen und in den Einstellungen. Sie greift
/// auf dieselbe Quelle zu wie der Rechtliches-Screen — es gibt also keine
/// zweite Stelle, an der eine Adresse gepflegt werden müsste.
///
/// Fehlt ein Dokument noch, erscheint es ausgegraut statt gar nicht: Wer
/// zustimmen soll, muss sehen, worauf sich die Zustimmung bezieht — auch
/// wenn der Text gerade noch aussteht.
class RechtstexteZeile extends StatelessWidget {
  const RechtstexteZeile({
    super.key,
    this.dokumente = Rechtsdokument.values,
    this.ausrichtung = WrapAlignment.start,
  });

  final List<Rechtsdokument> dokumente;
  final WrapAlignment ausrichtung;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Wrap(
      alignment: ausrichtung,
      spacing: AppTheme.gapS,
      runSpacing: AppTheme.gapXs,
      children: [
        for (final dokument in dokumente)
          _Verweis(
            dokument: dokument,
            farbe: Rechtstexte.quelle(dokument).vorhanden
                ? farben.akzent
                : farben.textSekundaer,
          ),
      ],
    );
  }
}

class _Verweis extends StatelessWidget {
  const _Verweis({required this.dokument, required this.farbe});

  final Rechtsdokument dokument;
  final Color farbe;

  @override
  Widget build(BuildContext context) {
    final vorhanden = Rechtstexte.quelle(dokument).vorhanden;

    return InkWell(
      onTap: vorhanden ? () => LegalScreen.oeffneDokument(context, dokument) : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(
          vorhanden ? dokument.titel : '${dokument.titel} (folgt)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: farbe,
            decoration: vorhanden ? TextDecoration.underline : null,
            decorationColor: farbe,
          ),
        ),
      ),
    );
  }
}
