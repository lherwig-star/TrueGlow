import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Standard-Karte der App: abgerundet, dezenter Rahmen, optionaler Kopfbereich.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.all(AppTheme.gapM),
    this.onTap,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    final content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: farben.akzent),
                  const SizedBox(width: AppTheme.gapXs + 2),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: farben.textPrimaer,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppTheme.gapS),
          ],
          child,
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Kleiner Fliesstext in Sekundaerfarbe – fuer Beschreibungen unter Titeln.
class MutedText extends StatelessWidget {
  const MutedText(this.text, {super.key, this.align = TextAlign.start});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: context.farben.textSekundaer,
        ),
      );
}
