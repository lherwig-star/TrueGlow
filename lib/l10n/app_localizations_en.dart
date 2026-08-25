// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'TrueGlow';

  @override
  String get weiter => 'Continue';

  @override
  String get zurueck => 'Back';

  @override
  String get abbrechen => 'Cancel';

  @override
  String get fertig => 'Done';

  @override
  String get erneutVersuchen => 'Try again';

  @override
  String get speichern => 'Save';

  @override
  String get zurStartseite => 'Back to start';

  @override
  String get onbWillkommenTitel => 'Welcome to TrueGlow';

  @override
  String get onbWillkommenText =>
      'We put together a personal plan for your skin, hair, beard and style. No ratings, no scores — just concrete steps.';

  @override
  String get onbAlterTitel => 'How old are you?';

  @override
  String get onbAlterText =>
      'This helps us pick recommendations that suit you.';

  @override
  String get onbBudgetTitel => 'How much do you want to spend?';

  @override
  String get onbBudgetText => 'On grooming products and styling per month.';

  @override
  String get onbZeitTitel => 'How much time do you have each day?';

  @override
  String get onbZeitText => 'We tailor your plan to fit that.';

  @override
  String get onbFokusTitel => 'What do you want to focus on?';

  @override
  String get onbFokusText => 'Pick as many as you like.';

  @override
  String get onbDatenschutzTitel => 'Privacy & important notes';

  @override
  String get homeLeerTitel => 'No analysis yet';

  @override
  String get homeLeerText =>
      'Take two photos and get your personal improvement plan.';

  @override
  String get homeAnalyseStarten => 'Start analysis';

  @override
  String get homeNeueAnalyse => 'New analysis';

  @override
  String get homePlanAnsehen => 'View plan';

  @override
  String get fotoTitelFrontal => 'Front photo';

  @override
  String get fotoTitelProfil => 'Side profile';

  @override
  String get fotoHinweisFrontal =>
      'Look straight into the camera. Neutral expression, good light, nothing on your head.';

  @override
  String get fotoHinweisProfil =>
      'Turn your head 90° to the side. Your ear and jawline should be visible.';

  @override
  String get fotoKamera => 'Camera';

  @override
  String get fotoGalerie => 'Gallery';

  @override
  String get fotoNeuAufnehmen => 'Retake';

  @override
  String get fotoAnalyseStarten => 'Start analysis';

  @override
  String get kameraAusloesen => 'Take photo';

  @override
  String get kameraWechseln => 'Switch camera';

  @override
  String get kameraSchliessen => 'Close';

  @override
  String get kameraStartet => 'Starting camera...';

  @override
  String get kameraKeinGesicht => 'Line your face up with the outline';

  @override
  String get kameraZuWeitWeg => 'Move closer';

  @override
  String get kameraZuNah => 'Move back a little';

  @override
  String get kameraNichtMittig => 'Centre yourself';

  @override
  String get kameraPerfekt => 'Perfect — take the photo';

  @override
  String get kameraZuDunkel => 'Needs more light';

  @override
  String get koerperNiemand => 'Step into the frame';

  @override
  String get koerperNichtGanz => 'All of you — head and feet';

  @override
  String get koerperZuWeitWeg => 'A few steps closer';

  @override
  String get koerperZuNah => 'A few steps back';

  @override
  String get koerperNichtMittig => 'Stand in the middle';

  @override
  String get koerperBereit => 'That’s it — hold still';

  @override
  String get koerperAutoHinweis =>
      'Prop your phone up, step back and line yourself up with the outline. Once you are fully in frame, the app counts down and takes the photo itself. You can also shoot manually at any time.';

  @override
  String get kameraKeineBerechtigungTitel => 'Camera access needed';

  @override
  String get kameraKeineBerechtigungText =>
      'TrueGlow needs camera access to show the live preview with its framing guide. You can grant access in your app settings — or pick a photo from your gallery instead.';

  @override
  String get kameraEinstellungenOeffnen => 'Open app settings';

  @override
  String get kameraNichtVerfuegbarTitel => 'Camera unavailable';

  @override
  String get kameraNichtVerfuegbarText =>
      'No camera could be started on this device. Pick a photo from your gallery instead.';

  @override
  String get aufnahmeFehlgeschlagen =>
      'That photo did not work — please try again';

  @override
  String get moduleTitel => 'Build your analysis';

  @override
  String get moduleEyebrow => 'Your analysis';

  @override
  String get moduleUeberschrift => 'What should we look at?';

  @override
  String get moduleEinleitung =>
      'Face, hair and beard are always included. Everything else is up to you — and you can add more later.';

  @override
  String get moduleBasisBadge => 'Core';

  @override
  String get moduleStartBasis => 'Start photos · Core';

  @override
  String get moduleErweitern => 'Add to your analysis';

  @override
  String get moduleErweiternText =>
      'Your analysis is still missing these areas. Your existing photos stay as they are — you only take the new ones.';

  @override
  String get vorschauTitel => 'Happy with this?';

  @override
  String get vorschauUebernehmen => 'Keep it';

  @override
  String get vorschauWiederholen => 'Retake';

  @override
  String get vorschauHinweis => 'The photo is only saved once you confirm.';

  @override
  String get kontingentTagesgrenze => 'No analyses left today';

  @override
  String get kontingentTagesgrenzeText =>
      'Three analyses a day — you have used them all. You can pick up again tomorrow morning. Your plan, checklist and check-in stay available in the meantime.';

  @override
  String get kontingentMonatsgrenze => 'No analyses left this month';

  @override
  String get kontingentMonatsgrenzeText =>
      'Thirty analyses a month — you have used them all. Your allowance resets at the start of next month.';

  @override
  String kontingentUebrig(int uebrig, int gesamt) {
    String _temp0 = intl.Intl.pluralLogic(
      uebrig,
      locale: localeName,
      other: '$uebrig of $gesamt analyses left today',
      one: '1 of $gesamt analyses left today',
    );
    return '$_temp0';
  }

  @override
  String get richtungTitel => 'Your direction';

  @override
  String get richtungEyebrow => 'Optional';

  @override
  String get richtungUeberschrift => 'Where do you want your look to go?';

  @override
  String get richtungEinleitung =>
      'Tell us what you are aiming for and we will shape the recommendations around it. You can skip this step too — then we look at your photos without any particular angle.';

  @override
  String get richtungChipsTitel => 'Pick what fits';

  @override
  String get richtungChipsText => 'Pick as many as you like.';

  @override
  String get richtungFreitextTitel => 'Say it in your own words';

  @override
  String get richtungFreitextPlatzhalter =>
      'Describe what you are after — people you look up to, occasions, things you are unsure about, absolute no-gos. The more specific, the better your plan.';

  @override
  String get richtungFreitextHinweis =>
      'This is not a chat: your text goes into the analysis once and otherwise stays on your device.';

  @override
  String get richtungWeiter => 'On to the photos';

  @override
  String get richtungSpeichern => 'Save direction';

  @override
  String get richtungLeer => 'No direction set yet.';

  @override
  String get richtungLeerText =>
      'Give the analysis some goals of your own and the recommendations will follow them.';

  @override
  String get richtungAngeben => 'Set a direction';

  @override
  String get richtungAendern => 'Change';

  @override
  String get richtungAktualisieren => 'Update plan with new direction';

  @override
  String get richtungAktualisierenText =>
      'Your direction has changed since this analysis. We rebuild the plan from your existing photos — no new ones needed.';

  @override
  String get flowUeberspringen => 'Skip';

  @override
  String get flowAbbrechen => 'Stop here?';

  @override
  String get flowAbbrechenText =>
      'The photos you have taken so far are saved. You can pick up later right where you left off.';

  @override
  String get flowWeitermachen => 'Keep going';

  @override
  String get lichtTitel => 'Before you start';

  @override
  String get lichtText =>
      'Three things make the biggest difference to a usable analysis:';

  @override
  String get lichtTageslicht => 'Daylight';

  @override
  String get lichtTageslichtText =>
      'Stand by a window. Indirect daylight from the front — no backlight, no coloured ceiling lamp.';

  @override
  String get lichtKeinFilter => 'No filters';

  @override
  String get lichtKeinFilterText =>
      'Turn off beauty mode, filters and smoothing in your camera — otherwise we are analysing the edit, not you.';

  @override
  String get lichtRuhigeHand => 'Steady hand';

  @override
  String get lichtRuhigeHandText =>
      'Hold your phone with both hands or prop it up. Blurry photos cost the most accuracy.';

  @override
  String get lichtStarten => 'Let’s go';

  @override
  String get figurFormularTitel => 'Your measurements';

  @override
  String get figurFormularText =>
      'Height and weight help us judge cuts and fits realistically. Both stay on your device.';

  @override
  String get figurGroesse => 'Height';

  @override
  String get figurGewicht => 'Weight';

  @override
  String get figurGroesseFehler =>
      'Please enter a height between 120 and 230 cm.';

  @override
  String get figurGewichtFehler =>
      'Please enter a weight between 35 and 250 kg.';

  @override
  String get stilFragebogenTitel => 'Your style';

  @override
  String get stilFragebogenText =>
      'Four quick questions so the suggestions fit your everyday life.';

  @override
  String get stilZiel => 'Where should it go?';

  @override
  String get stilZielText => 'Pick as many as you like.';

  @override
  String get stilDresscode => 'What does your day-to-day call for?';

  @override
  String get stilBudget => 'What do you spend per item?';

  @override
  String get stilPflege => 'How much upkeep is fine?';

  @override
  String get analyseTitel => 'Analysis running';

  @override
  String get analyseHinweis =>
      'This takes about 20 seconds. Please do not close the app.';

  @override
  String get ergebnisTitel => 'Your analysis';

  @override
  String get ergebnisGesichtsform => 'Face shape';

  @override
  String get ergebnisPlanErstellen => 'Create plan';

  @override
  String get ergebnisEmpfehlungen => 'Recommendations';

  @override
  String get ergebnisProdukte => 'Products';

  @override
  String get planTitel => 'Your plan';

  @override
  String get planSofort => 'Start today';

  @override
  String get planDreissigTage => 'First 30 days';

  @override
  String get planLangfristig => 'Long term';

  @override
  String get planStreak => 'day streak';

  @override
  String get planFertigZurStartseite => 'Done — back to start';

  @override
  String get checkinTitel => 'Check-in';

  @override
  String get checkinKarteTitel => 'Quick check-in';

  @override
  String get checkinKarteText =>
      'Takes under a minute and makes your plan fit better.';

  @override
  String get checkinKarteFortsetzen => 'Started — keep going';

  @override
  String get checkinStarten => 'Start check-in';

  @override
  String get checkinFortsetzen => 'Keep going';

  @override
  String get checkinSpaeter => 'Later';

  @override
  String get checkinNaechster => 'Next check-in';

  @override
  String get checkinPushTitel => 'Quick check-in';

  @override
  String get checkinPushText => 'Takes under a minute.';

  @override
  String get checkinHabitsTitel => 'How well do the tasks fit?';

  @override
  String get checkinHabitsText =>
      'One tap per task — this is about your daily life, not about results.';

  @override
  String get checkinHabitsErneut =>
      'Only the tasks that gave you trouble last time.';

  @override
  String get checkinGrundTitel => 'What is not working?';

  @override
  String get checkinGrundFreitext => 'Want to say briefly what is going on?';

  @override
  String get checkinWirkungTitelFrueh => 'How does it feel?';

  @override
  String get checkinWirkungTextFrueh =>
      'Just the quick wins — everything else needs a bit more time.';

  @override
  String get checkinWirkungTitelSpaet => 'What has changed?';

  @override
  String get checkinWirkungTextSpaet =>
      'A month is long enough for the first visible differences.';

  @override
  String get checkinWirkungNotiz => 'Note (optional)';

  @override
  String get checkinHinweisTitel => 'A bit of context';

  @override
  String get checkinFotoTitel => 'Progress photo';

  @override
  String get checkinFotoText =>
      'Optional: a photo under the same conditions as your first one — daylight, no filter, same framing.';

  @override
  String get checkinFotoAufnehmen => 'Take photo';

  @override
  String get checkinFotoNeu => 'Retake';

  @override
  String get checkinFotoOhne => 'Continue without a photo';

  @override
  String get checkinVergleichTitel => 'Before / after';

  @override
  String get checkinVergleichVorher => 'Start';

  @override
  String get checkinVergleichNachher => 'Today';

  @override
  String get fotoNichtAufDiesemGeraet => 'Photo not available on this device';

  @override
  String get checkinAuswertungLaeuft => 'Looking through your answers…';

  @override
  String get checkinFazitTitel => 'Where you stand';

  @override
  String get checkinAenderungenTitel => 'What we are changing';

  @override
  String get checkinKeineAenderung =>
      'Your plan stays as it is — this is going well.';

  @override
  String get checkinBestaetigen => 'Apply changes';

  @override
  String get checkinAbschliessen => 'Finish check-in';

  @override
  String get checkinAbbrechenTitel => 'Continue this check-in later?';

  @override
  String get checkinAbbrechenText =>
      'Your answers so far are saved. You can pick up where you left off at any time.';

  @override
  String get checkinVerlassen => 'Continue later';

  @override
  String get checkinDankeTitel => 'Thank you!';

  @override
  String get checkinDankeText =>
      'Your plan is updated. Adjusted tasks are marked in the checklist.';

  @override
  String get verlaufTitel => 'History';

  @override
  String get verlaufLeer => 'No analyses yet.';

  @override
  String get einstellungenTitel => 'Settings';

  @override
  String get einstellungenAngaben => 'Change my details';

  @override
  String get einstellungenErscheinungsbild => 'Appearance';

  @override
  String get einstellungenDatenLoeschen => 'Delete data, keep account';

  @override
  String get einstellungenKontoLoeschen => 'Delete account permanently';

  @override
  String get einstellungenImpressum => 'Legal notice';

  @override
  String get einstellungenRechtliches => 'Legal';

  @override
  String get einstellungenDatenschutz => 'Privacy policy';

  @override
  String get disclaimerMedizin =>
      'TrueGlow is no substitute for medical advice. If you have skin problems, see a dermatologist.';

  @override
  String get disclaimerFotos =>
      'Your photos are sent to the AI service for analysis only and are not stored there. On your device they stay local.';

  @override
  String get disclaimerZustimmung => 'I have read the notes above and agree.';

  @override
  String get pushKanalName => 'Check-in reminders';

  @override
  String get pushKanalBeschreibung =>
      'Reminds you when a quick check-in is due.';

  @override
  String get einstellungenSprache => 'Language';

  @override
  String get spracheFolgtGeraet =>
      'TrueGlow follows your phone’s language setting.';

  @override
  String get spracheFest =>
      'Fixed choice — independent of your system setting.';

  @override
  String get spracheReportHinweis =>
      'Your analysis is written in this language too. Reports you already have stay in the language they were created in.';

  @override
  String get spracheWaehlen => 'Choose language';
}
