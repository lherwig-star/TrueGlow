import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Einheitliches Seitengeruest: AppBar (optional), scrollbarer Inhalt mit
/// konsistenten Raendern und optionaler, fest angehefteter Aktionsleiste unten.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.children,
    this.title,
    this.actions,
    this.bottomBar,
    this.showBackButton = true,
    this.bottomFade = false,
    this.leading,
  });

  final List<Widget> children;
  final String? title;
  final List<Widget>? actions;
  final Widget? bottomBar;
  final bool showBackButton;

  /// Legt einen Verlauf ueber den oberen Rand der Aktionsleiste, damit
  /// scrollender Inhalt darunter ausblendet statt hart abzuschneiden.
  final bool bottomFade;

  /// Ersetzt den Standard-Zurueck-Button in der AppBar.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    // Der Verlauf liegt hinter dem Scaffold und nicht darin: So faerbt er
    // auch die Flaeche hinter AppBar und Aktionsleiste, und die Seite hat
    // von oben bis unten genau einen Grund.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [farben.hintergrund, farben.hintergrundTief],
        ),
      ),
      child: _geruest(context),
    );
  }

  Widget _geruest(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              actions: actions,
              leading: leading,
              automaticallyImplyLeading: showBackButton,
            ),
      body: SafeArea(
        top: title == null,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gapM,
            AppTheme.gapS,
            AppTheme.gapM,
            AppTheme.gapXl,
          ),
          children: children,
        ),
      ),
      bottomNavigationBar: bottomBar == null
          ? null
          : _Aktionsleiste(mitVerlauf: bottomFade, child: bottomBar!),
    );
  }
}

/// Fest angeheftete Aktionsleiste am unteren Rand.
class _Aktionsleiste extends StatelessWidget {
  const _Aktionsleiste({required this.child, required this.mitVerlauf});

  final Widget child;
  final bool mitVerlauf;

  @override
  Widget build(BuildContext context) {
    // Der tiefe Ton, nicht der obere: Die Leiste sitzt am unteren Ende des
    // Seitenverlaufs, und dort ist der Grund fast schwarzblau.
    final hintergrund = context.farben.hintergrundTief;

    return DecoratedBox(
      decoration: mitVerlauf
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [hintergrund.withValues(alpha: 0), hintergrund],
                stops: const [0, 0.35],
              ),
            )
          : const BoxDecoration(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gapM,
            AppTheme.gapM,
            AppTheme.gapM,
            AppTheme.gapM,
          ),
          child: child,
        ),
      ),
    );
  }
}
