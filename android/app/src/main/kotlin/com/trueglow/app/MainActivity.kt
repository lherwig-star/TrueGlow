package com.trueglow.app

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

/**
 * Die einzige Activity der App.
 *
 * Sie tut genau eine Sache über das Übliche hinaus: Sie blendet den
 * Start-Bildschirm des Systems selbst aus, statt Android das zu überlassen.
 *
 * **Warum überhaupt.** Ab Android 12 zeichnet das System den
 * Start-Bildschirm und nimmt ihn weg, sobald die App gezeichnet hat. Der
 * Inhalt der App wird dabei aber erst *nach* der Wegnahme sichtbar. Am Gerät
 * gemessen (27.08.2026, Samsung SM A525F) waren das drei Einzelbilder, in
 * denen weder das Zeichen des Systems noch das der App zu sehen war – nur
 * die leere Fläche. Das war das gemeldete Blinken.
 *
 * **Warum die Überblendung hier liegt und nicht in Flutter.** Eine Blende in
 * Dart lief zwar, aber unsichtbar: Sie startet, sobald der Startbildschirm
 * gebaut ist, und bis der Inhalt der App auf dem Schirm ankam, war sie
 * vorbei. Zweimal gemessen, zweimal derselbe Befund – der erste sichtbare
 * Frame zeigte schon den Endzustand.
 *
 * Hier ist die Reihenfolge dagegen zwingend: Der Inhalt der App liegt fertig
 * darunter, und darüber wird die Fläche des Systems weggeblendet. Was man
 * sieht, ist eine echte Überblendung von der flachen Farbe des Systems auf
 * den fertigen Startbildschirm.
 *
 * **Warum das Zeichen dabei nicht dunkler wird.** Beide Lagen zeigen dasselbe
 * Zeichen in derselben Größe an derselben Stelle (DECISIONS 52). Beim
 * Überblenden ergibt das an jeder Stelle wieder genau dieses Zeichen – es
 * kann gar nicht flackern.
 *
 * Vor Android 12 gibt es diesen Mechanismus nicht; dort ist der
 * Start-Bildschirm der Fensterhintergrund und verschwindet, sobald Flutter
 * malt. Deshalb die Abfrage.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        /**
         * Dauer der Überblendung.
         *
         * Kurz genug, dass sie den Start nicht vorführt, lang genug, dass sie
         * nicht als Schnitt gelesen wird. `splash_test.dart` besteht auf
         * einem Wert in diesem Rahmen.
         */
        const val BLENDE_MS = 300L
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { ansicht ->
                ansicht.animate()
                    .alpha(0f)
                    .setDuration(BLENDE_MS)
                    // Steht die System-Einstellung "Animationen entfernen" auf
                    // an, macht Android daraus einen Sprung. Das ist richtig
                    // so – genau darum bittet diese Einstellung.
                    .withEndAction { ansicht.remove() }
                    .start()
            }
        }
    }
}
