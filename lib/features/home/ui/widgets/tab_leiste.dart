import 'package:flutter/material.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../logic/home_tab.dart';

/// Die Leiste am unteren Rand.
///
/// Bewusst handgebaut statt `NavigationBar`: Material 3 legt hinter das
/// aktive Symbol eine gefüllte Pille in `secondaryContainer`, und die gibt es
/// in diesem Farbsystem nicht. Nachgerüstet wäre es mehr Code als die Leiste
/// selbst — und eine zweite Stelle, an der Farben entstehen.
///
/// Die Leiste trägt den Kartenton des jeweiligen Modus mit einer feinen
/// Kontur nach oben, der aktive Tab die Farbe für Erreichtes (DECISIONS 65).
class TabLeiste extends StatelessWidget {
  const TabLeiste({
    super.key,
    required this.aktiv,
    required this.onWechsel,
    required this.punktAmHeute,
  });

  final HomeTab aktiv;
  final ValueChanged<HomeTab> onWechsel;

  /// Der kleine Punkt am „Heute"-Tab, solange der Tag noch nicht gesichert
  /// ist. Er verschwindet mit dem ersten Haken.
  final bool punktAmHeute;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: farben.flaeche,
        border: Border(top: BorderSide(color: farben.kartenrand)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (final tab in HomeTab.values)
                Expanded(
                  child: _Knopf(
                    tab: tab,
                    aktiv: tab == aktiv,
                    mitPunkt: tab == HomeTab.heute && punktAmHeute,
                    onTap: () => onWechsel(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Knopf extends StatelessWidget {
  const _Knopf({
    required this.tab,
    required this.aktiv,
    required this.mitPunkt,
    required this.onTap,
  });

  final HomeTab tab;
  final bool aktiv;
  final bool mitPunkt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final texte = context.texte;

    // Symbol und Flaeche tragen den Flaechen-Ton, die Beschriftung den
    // Schrift-Ton – dieselbe Trennung wie ueberall sonst (DECISIONS 64).
    final symbol = aktiv ? farben.erreichtFlaeche : farben.textSekundaer;
    final schrift = aktiv ? farben.erreicht : farben.textSekundaer;

    return Semantics(
      selected: aktiv,
      button: true,
      label: tab.label(texte),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Der Kasten ist breiter als das Symbol, damit der Punkt daneben
            // Platz hat. Ausserhalb der Stack-Grenzen wurde er auf dem Geraet
            // abgeschnitten – sichtbar war er nur im Widget-Baum.
            SizedBox(
              width: 34,
              height: 24,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      aktiv ? tab.iconAktiv : tab.icon,
                      size: 24,
                      color: symbol,
                    ),
                  ),
                  if (mitPunkt)
                    Positioned(
                      key: const Key('punkt-heute'),
                      right: 0,
                      top: 1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          // Der Akzent, nicht die Erreicht-Farbe: Auf dem
                          // aktiven Tab ist das Symbol selbst schon amber,
                          // und ein amberner Punkt darauf waere unsichtbar.
                          // Der Punkt sagt „hier ist noch etwas offen" – das
                          // ist kein Erreichtes.
                          color: farben.akzent,
                          shape: BoxShape.circle,
                          // Ein Ring in der Leistenfarbe setzt ihn ab, egal
                          // welches Symbol daneben steht.
                          border: Border.all(color: farben.flaeche, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tab.label(texte),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: aktiv ? FontWeight.w800 : FontWeight.w600,
                color: schrift,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Der Rahmen eines Tab-Inhalts: dieselben Ränder wie in [AppPage], plus die
/// Scroll-Position, die den Tabwechsel überlebt.
///
/// Sie überlebt ihn nicht von selbst — der `IndexedStack` hält die vier
/// Zustände zwar am Leben, aber die Position hängt am `ScrollController`.
/// Der `PageStorageKey` sorgt dafür, dass jeder Tab seinen eigenen behält.
class TabInhalt extends StatelessWidget {
  const TabInhalt({super.key, required this.tab, required this.children});

  final HomeTab tab;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: PageStorageKey<String>('tab-${tab.name}'),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gapM,
        AppTheme.gapS,
        AppTheme.gapM,
        AppTheme.gapXl,
      ),
      children: children,
    );
  }
}
