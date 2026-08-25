import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../logic/rechtstexte.dart';
import 'rechtsdokument_texte.dart';
import '../../../core/l10n/texte.dart';

/// Übersicht der Rechtstexte.
///
/// Ersetzt die frühere Snackbar „Rechtstext folgt." — die war ein Platzhalter,
/// der wie ein Fehler aussah. Solange ein Dokument keine Quelle hat, sagt der
/// Eintrag das ausdrücklich und lässt sich gar nicht erst antippen.
class LegalScreen extends ConsumerWidget {
  const LegalScreen({super.key});

  /// Öffnet ein einzelnes Dokument – von hier, aus dem Onboarding und aus
  /// dem Login-Screen aus derselben Stelle.
  static Future<void> oeffneDokument(
    BuildContext context,
    Rechtsdokument dokument,
  ) =>
      _DokumentEintrag.oeffne(context, dokument);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPage(
      title: 'Rechtliches',
      children: [
        SectionCard(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.gapXs),
          child: Column(
            children: [
              for (final dokument in Rechtsdokument.values) ...[
                if (dokument != Rechtsdokument.values.first)
                  const Divider(
                    indent: AppTheme.gapM,
                    endIndent: AppTheme.gapM,
                  ),
                _DokumentEintrag(dokument: dokument),
              ],
            ],
          ),
        ),
        if (!Rechtstexte.vollstaendig) ...[
          const SizedBox(height: AppTheme.gapS),
          const _EntwurfsHinweis(),
        ],
        const SizedBox(height: AppTheme.gapM),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gapXs),
          child: MutedText(context.texte.legalFotosText),
        ),
      ],
    );
  }
}

class _DokumentEintrag extends StatelessWidget {
  const _DokumentEintrag({required this.dokument});

  final Rechtsdokument dokument;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;
    final quelle = Rechtstexte.quelle(dokument);

    return ListTile(
      onTap: quelle.vorhanden ? () => oeffne(context, dokument) : null,
      enabled: quelle.vorhanden,
      leading: Icon(_symbol, color: farben.akzent),
      title: Text(
        dokument.titel(texte),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        quelle.vorhanden ? dokument.beschreibung(texte) : texte.dokumentFolgt,
        style: TextStyle(
          fontSize: 13,
          color: quelle.vorhanden ? farben.textSekundaer : farben.warnung,
        ),
      ),
      trailing: Icon(
        quelle.hatUrl ? Icons.open_in_new : Icons.chevron_right,
        size: 20,
        color: farben.textSekundaer,
      ),
    );
  }

  IconData get _symbol => switch (dokument) {
        Rechtsdokument.datenschutz => Icons.privacy_tip_outlined,
        Rechtsdokument.nutzungsbedingungen => Icons.gavel_outlined,
        Rechtsdokument.impressum => Icons.description_outlined,
      };

  /// Öffnet ein Dokument: bevorzugt im Browser, sonst in der App.
  ///
  /// Die Webseite ist der Normalfall — sie ist immer aktuell, während ein
  /// mitgeliefertes Markdown den Stand des letzten App-Updates zeigt.
  /// Scheitert das Öffnen (kein Browser, kein Netz), greift die In-App-Ansicht.
  static Future<void> oeffne(
    BuildContext context,
    Rechtsdokument dokument,
  ) async {
    final quelle = Rechtstexte.quelle(dokument);

    if (quelle.hatUrl) {
      final adresse = Uri.tryParse(quelle.url!);
      if (adresse != null) {
        final geoeffnet = await launchUrl(
          adresse,
          mode: LaunchMode.externalApplication,
        ).catchError((_) => false);
        if (geoeffnet) return;
      }
    }

    if (!context.mounted) return;

    if (quelle.hatAsset) {
      context.push(Routes.rechtstextFuer(dokument));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.texte.legalNichtOeffenbar(dokument.titel(context.texte)),
        ),
      ),
    );
  }
}

/// Sichtbarer Hinweis, solange Texte fehlen.
///
/// Steht bewusst in der App und nicht nur im Log: Wer die App vor dem Launch
/// jemandem zeigt, soll sofort sehen, dass hier noch etwas offen ist.
class _EntwurfsHinweis extends StatelessWidget {
  const _EntwurfsHinweis();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.texte.legalStehenAusTitel,
      icon: Icons.pending_outlined,
      child: MutedText(
        context.texte.legalEntwurfHinweis(Rechtstexte.fehlerbericht),
      ),
    );
  }
}
