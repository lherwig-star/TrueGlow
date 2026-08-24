# R8-Regeln fuer den Release-Build.
#
# Hintergrund: minifyEnabled entfernt ungenutzten Code und benennt den Rest um.
# Alles, was zur Laufzeit ueber Reflexion oder ueber native Bruecken gefunden
# wird, sieht R8 nicht — es faellt dann erst im Release-Build auf, oft als
# ClassNotFoundException auf einem fremden Geraet.
#
# Nach jeder Aenderung hier: vollstaendiger Durchlauf im Release-Build,
# nicht nur ein erfolgreicher Compile (SETUP.md, Abschnitt 12.3).

# --- ML Kit (Gesichtserkennung im Sucher) ----------------------------------
#
# ML Kit laedt seine Modelle ueber Play services und findet die zugehoerigen
# Klassen ueber Reflexion. Ohne diese Regeln laeuft die Kamera im Debug-Build,
# aber nicht im Release.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-dontwarn com.google.mlkit.**

# ML Kit bringt optionale Abhaengigkeiten auf andere Modelle mit, die wir nicht
# einbinden. Die Warnungen sind erwartbar.
-dontwarn com.google.android.gms.internal.**

# --- Hive ------------------------------------------------------------------
#
# Hive selbst ist reines Dart und von R8 gar nicht betroffen. Die App legt
# ausserdem alles als JSON-String ab, also ohne generierte TypeAdapter —
# es gibt hier bewusst nichts zu schuetzen. Der Eintrag steht trotzdem da,
# damit beim naechsten Lesen niemand nach der fehlenden Regel sucht.

# --- Firebase --------------------------------------------------------------
#
# Die Firebase-SDKs bringen eigene consumer-Regeln mit; das Meiste ist damit
# abgedeckt. Zwei Dinge fallen trotzdem durchs Raster:
#
# 1. Firestore serialisiert ueber Reflexion. Die App legt zwar nur Maps ab,
#    aber die internen Modelle des SDK brauchen ihre Namen.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.firebase.**

# 2. Play Integrity (App Check) prueft die Signatur der App gegen Klassen, die
#    ueber Reflexion aufgeloest werden.
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# --- Flutter und Plugins ---------------------------------------------------
#
# Der Flutter-Embedder ruft Plugin-Registrare ueber Reflexion auf.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# flutter_local_notifications stellt geplante Erinnerungen ueber einen
# BroadcastReceiver wieder her, den das System namentlich sucht.
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# --- Zeilennummern in Absturzberichten -------------------------------------
#
# Ohne das sind Stacktraces im Release unlesbar. Ab Phase 4 (Crashlytics)
# haengt daran, ob ein Absturzbericht ueberhaupt etwas wert ist.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
