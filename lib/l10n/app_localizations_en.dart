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
  String get koerperNiemandFrei => 'Step into the frame – or shoot manually';

  @override
  String get koerperNichtGanz => 'All of you — at least down to your thighs';

  @override
  String get koerperZuWeitWeg => 'A few steps closer';

  @override
  String get koerperZuNah => 'A few steps back';

  @override
  String get koerperBereit => 'That’s it — hold still';

  @override
  String get koerperTippAbstand =>
      'Step back a little — head down to your thighs has to be visible';

  @override
  String get koerperAutoHinweis =>
      'Prop your phone up and step back until you are in frame from your head down to at least your thighs. Where you stand does not matter, and feet are optional. The app then counts down and takes the photo itself — manual still works at any time.';

  @override
  String get outfitAutoHinweis =>
      'Prop your phone up and step back until you are in frame from your head down to at least your thighs. The app then counts down and takes the photo itself. If the outfit is laid out instead, nothing starts: just shoot manually as usual.';

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
  String moduleAusOnboarding(String module) {
    return 'Already ticked from your onboarding focus: $module. You can change this freely here.';
  }

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
      'Ten analyses a month — you have used them all. Your allowance goes back to ten on the first of next month. Your plan, your checklist and the check-ins the app invites you to keep working — those do not count towards it.';

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
  String get modusTitel => 'New analysis';

  @override
  String get modusEyebrow => 'First step';

  @override
  String get modusUeberschrift => 'What should this analysis do for you?';

  @override
  String get modusEinleitung =>
      'Both are full analyses using the same photos. What differs is the question we answer for you.';

  @override
  String get modusVerfeinernTitel => 'Refine my look';

  @override
  String get modusVerfeinernText =>
      'Happy with your style? We bring out the best of it — cut, grooming and the details that suit what you already have.';

  @override
  String get modusVerfeinernEtikett => 'Refined';

  @override
  String get modusEntdeckenTitel => 'Discover a new look';

  @override
  String get modusEntdeckenText =>
      'Ready for a change? We propose a new direction that suits your face, your hair and your everyday life.';

  @override
  String get modusEntdeckenEtikett => 'New look';

  @override
  String get modusWeiter => 'Continue to the modules';

  @override
  String get modusHinweis =>
      'Both modes cost exactly one analysis run, and you take the same photos either way. You choose again for every analysis.';

  @override
  String get gesamtbildTitel => 'The bigger picture';

  @override
  String get neuerLookTitel => 'Your new look';

  @override
  String get richtungszielClean => 'Clean & groomed';

  @override
  String get richtungszielCleanUnter =>
      'Sharp outlines, calm colours, nothing extra';

  @override
  String get richtungszielMarkant => 'Striking & masculine';

  @override
  String get richtungszielMarkantUnter =>
      'Hard edges: jaw, short hair, contour';

  @override
  String get richtungszielNatuerlich => 'Natural & relaxed';

  @override
  String get richtungszielNatuerlichUnter => 'Low effort, unmistakably you';

  @override
  String get richtungszielWeich => 'Soft & elegant';

  @override
  String get richtungszielWeichUnter =>
      'Soft lines, fine fabric, quiet presence';

  @override
  String get richtungszielStreetwear => 'Streetwear & casual';

  @override
  String get richtungszielStreetwearUnter =>
      'Easy campus look, loose hair, sneakers';

  @override
  String get richtungszielSmart => 'Smart & refined';

  @override
  String get richtungszielSmartUnter => 'Polished from haircut to shoes';

  @override
  String get richtungszielSportlich => 'Sporty & functional';

  @override
  String get richtungszielSportlichUnter => 'Short, practical, ready to move';

  @override
  String get richtungszielKreativ => 'Creative & bold';

  @override
  String get richtungszielKreativUnter =>
      'Bold colour, statement pieces, clearly yours';

  @override
  String get tabHeute => 'Today';

  @override
  String get tabPlan => 'Plan';

  @override
  String get tabAnalyse => 'Analysis';

  @override
  String get tabFortschritt => 'Progress';

  @override
  String get abschnittMorgens => 'Morning';

  @override
  String get abschnittTagsueber => 'During the day';

  @override
  String get abschnittAbends => 'Evening';

  @override
  String get abschnittBeiBedarf => 'When it comes up';

  @override
  String abschnittThema(String thema) {
    return 'Area: $thema';
  }

  @override
  String get heuteKeineAufgabenTitel => 'Nothing to tick today';

  @override
  String get heuteKeineAufgabenText =>
      'Your report did not come with daily tasks. We will adjust the plan at the next check-in.';

  @override
  String get planReportOeffnen => 'Open the full report';

  @override
  String get analyseTabTitel => 'Your analyses';

  @override
  String get analyseTabEinleitung =>
      'Start a new analysis or open an earlier one.';

  @override
  String kontingentMonatUebrig(int anzahl) {
    return '$anzahl of 10 left this month';
  }

  @override
  String get fortschrittTabHinweis =>
      'Progress photos stay on your device. They never go to a cloud.';

  @override
  String get fortschrittSerieTitel => 'Your streak';

  @override
  String get fortschrittSerieAktuell => 'Days in a row';

  @override
  String get fortschrittSerieRekord => 'Longest streak';

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
  String get richtungWeiter => 'Continue';

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
  String get ausprobierenTitel => 'Things to try';

  @override
  String get ausprobierenEyebrow => 'Optional';

  @override
  String get ausprobierenUeberschrift =>
      'Fancy adding something new to your routine?';

  @override
  String get ausprobierenEinleitung =>
      'Pick what you have always meant to try — we will work it into your plan where it fits. You can skip this step too.';

  @override
  String get ausprobierenChipsText => 'Pick as many as you like.';

  @override
  String get ausprobierenWeiter => 'On to the photos';

  @override
  String ausprobierenGewaehlt(int anzahl) {
    return '$anzahl selected';
  }

  @override
  String get ausprobierenNichts =>
      'There is nothing to offer here for your selection.';

  @override
  String get ergebnisNeuFuerDich => 'New for you';

  @override
  String get technikKopfhautmassage => 'Scalp massage';

  @override
  String get technikKopfhautmassageUnter =>
      'Two minutes with your fingertips, for circulation.';

  @override
  String get technikRosmarinoel => 'Rosemary oil for the scalp';

  @override
  String get technikRosmarinoelUnter => 'Diluted, massaged in, over weeks.';

  @override
  String get technikFoehnRundbuerste => 'Blow-drying with a round brush';

  @override
  String get technikFoehnRundbuersteUnter =>
      'Volume and shape that hold all day.';

  @override
  String get technikHaaroelkur => 'Overnight hair oil treatment';

  @override
  String get technikHaaroelkurUnter =>
      'Oil into the lengths, washed out in the morning.';

  @override
  String get technikSeidenkissen => 'Silk pillowcase';

  @override
  String get technikSeidenkissenUnter =>
      'Less friction, less breakage and fewer kinks.';

  @override
  String get technikBartoelRoutine => 'Beard oil & balm';

  @override
  String get technikBartoelRoutineUnter =>
      'Oil for the skin underneath, balm for the shape.';

  @override
  String get technikBartbuerste => 'Beard brush';

  @override
  String get technikBartbuersteUnter => 'Trains the hairs and spreads the oil.';

  @override
  String get technikGuaSha => 'Gua sha';

  @override
  String get technikGuaShaUnter => 'A stone along the face, always outwards.';

  @override
  String get technikGesichtsyoga => 'Face yoga';

  @override
  String get technikGesichtsyogaUnter =>
      'Targeted exercises for cheeks, jaw and forehead.';

  @override
  String get technikIceRolling => 'Ice rolling in the morning';

  @override
  String get technikIceRollingUnter =>
      'Cold against puffy eyes and morning tiredness.';

  @override
  String get technikLymphmassage => 'Facial lymphatic massage';

  @override
  String get technikLymphmassageUnter =>
      'Gentle strokes, from the centre down to the neck.';

  @override
  String get technikSanftesPeeling => 'Gentle chemical exfoliant';

  @override
  String get technikSanftesPeelingUnter => 'A mild acid, eased in slowly.';

  @override
  String get technikSheetMaske => 'Sheet mask ritual';

  @override
  String get technikSheetMaskeUnter =>
      'Twenty minutes, one fixed evening a week.';

  @override
  String get technikLippenpeeling => 'Lip scrub';

  @override
  String get technikLippenpeelingUnter => 'Buff gently, then look after them.';

  @override
  String get technikNagelpflege => 'Nail care routine';

  @override
  String get technikNagelpflegeUnter => 'File, cuticles, oil — once a week.';

  @override
  String get technikAugenbrauenWimpern => 'Brow & lash care';

  @override
  String get technikAugenbrauenWimpernUnter =>
      'Brush, oil, keep the shape instead of drawing it on.';

  @override
  String get technikPinselhygiene => 'Keep your brushes clean';

  @override
  String get technikPinselhygieneUnter =>
      'Wash them every two weeks — your skin will thank you.';

  @override
  String get technikLidschattenbasis => 'Eyeshadow primer';

  @override
  String get technikLidschattenbasisUnter =>
      'Holds the colour and stops it creasing.';

  @override
  String get technikRougePlatzierung => 'Place blush deliberately';

  @override
  String get technikRougePlatzierungUnter => 'By face shape, not by habit.';

  @override
  String get technikOelziehen => 'Oil pulling';

  @override
  String get technikOelziehenUnter =>
      'Swish oil in the morning, then spit it out.';

  @override
  String get technikZungenschaber => 'Tongue scraper';

  @override
  String get technikZungenschaberUnter =>
      'One pass over the tongue before brushing.';

  @override
  String get technikLaechelntraining => 'Practise smiling in the mirror';

  @override
  String get technikLaechelntrainingUnter =>
      'So it doesn\'t come out forced in photos.';

  @override
  String get technikAufhellung => 'Teeth whitening';

  @override
  String get technikAufhellungUnter => 'Only after talking to your dentist.';

  @override
  String get technikChinTuck => 'Chin tucks for the neck';

  @override
  String get technikChinTuckUnter => 'Chin back, against tech neck.';

  @override
  String get technikMobilityMinuten => 'Daily mobility minutes';

  @override
  String get technikMobilityMinutenUnter =>
      'Five minutes of mobility, not a whole programme.';

  @override
  String get technikWandstand => 'Wall stand for posture';

  @override
  String get technikWandstandUnter => 'Back to the wall, two minutes.';

  @override
  String get technikKaltDuschen => 'Finish your shower cold';

  @override
  String get technikKaltDuschenUnter => 'The last thirty seconds cold.';

  @override
  String get technikSchlafhygiene => 'Sleep hygiene routine';

  @override
  String get technikSchlafhygieneUnter => 'Fixed times, dark room, no screens.';

  @override
  String get technikKleiderschrankAudit => 'Wardrobe audit';

  @override
  String get technikKleiderschrankAuditUnter =>
      'Go through everything once and sort it honestly.';

  @override
  String get technikCapsuleWardrobe => 'Capsule wardrobe';

  @override
  String get technikCapsuleWardrobeUnter =>
      'Few pieces that all work together.';

  @override
  String get technikSchuhpflege => 'Shoe care ritual';

  @override
  String get technikSchuhpflegeUnter =>
      'Brush, condition, get them back in shape.';

  @override
  String get technikAccessoireEinstieg => 'Your first accessory';

  @override
  String get technikAccessoireEinstiegUnter =>
      'One ring or chain, started quietly.';

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
  String get stilZielText =>
      'Pick as many as you like. Same directions as under \"Your direction\" — here it is only about clothes.';

  @override
  String get stilZweck => 'What should your style work for, above all?';

  @override
  String get stilZweckText =>
      'Pick as many as you like. You can also skip this one.';

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
  String get wissenTitel => 'Knowledge';

  @override
  String get wissenText =>
      'Short explanations of the techniques that appear in your report and your plan.';

  @override
  String get wissenSuche => 'Search';

  @override
  String get wissenLeer => 'There is no entry for that.';

  @override
  String get wissenLaedt => 'Loading …';

  @override
  String get wissenWasIstDas => 'WHAT IT IS';

  @override
  String get wissenSoGehts => 'HOW TO DO IT';

  @override
  String get wissenWieOft => 'HOW OFTEN';

  @override
  String get wissenWomit => 'WHAT YOU NEED';

  @override
  String get wissenWoraufAchten => 'WHAT TO WATCH FOR';

  @override
  String wissenWasIst(String name) {
    return 'What is $name?';
  }

  @override
  String get einstellungenWissen => 'Knowledge';

  @override
  String get ergebnisTitel => 'Your analysis';

  @override
  String get ergebnisAuswahl => 'Your choices';

  @override
  String ergebnisKachelEmpfehlungen(int anzahl) {
    String _temp0 = intl.Intl.pluralLogic(
      anzahl,
      locale: localeName,
      other: '$anzahl recommendations',
      one: '1 recommendation',
    );
    return '$_temp0';
  }

  @override
  String get ergebnisDeinWunsch => 'In your words';

  @override
  String ergebnisKopf(
    String datum,
    String modus,
    int kapitel,
    int empfehlungen,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      kapitel,
      locale: localeName,
      other: '$kapitel chapters',
      one: '1 chapter',
    );
    String _temp1 = intl.Intl.pluralLogic(
      empfehlungen,
      locale: localeName,
      other: '$empfehlungen recommendations',
      one: '1 recommendation',
    );
    return '$datum · $modus · $_temp0 · $_temp1';
  }

  @override
  String get ergebnisGesichtsform => 'Face shape';

  @override
  String get ergebnisPlanErstellen => 'Create plan';

  @override
  String get ergebnisZumPlan => 'To your plan';

  @override
  String get ergebnisAlleBereiche => 'Every area has been analysed.';

  @override
  String ergebnisErweiternZeile(int anzahl, String bereiche) {
    String _temp0 = intl.Intl.pluralLogic(
      anzahl,
      locale: localeName,
      other: '$anzahl areas not analysed yet',
      one: '1 area not analysed yet',
    );
    return '$_temp0: $bereiche';
  }

  @override
  String get ergebnisEmpfehlungen => 'Recommendations';

  @override
  String get ergebnisProdukte => 'Products';

  @override
  String get produktReinigung => 'Cleansing';

  @override
  String get produktPflege => 'Care';

  @override
  String get produktStyling => 'Styling';

  @override
  String get produktWerkzeug => 'Tools';

  @override
  String get produktMakeup => 'Make-up';

  @override
  String get produktKleidung => 'Clothing';

  @override
  String get produktSonstiges => 'Other';

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
  String checkinNaechsterIn(int tage) {
    String _temp0 = intl.Intl.pluralLogic(
      tage,
      locale: localeName,
      other: 'Next check-in in $tage days',
      one: 'Next check-in tomorrow',
    );
    return '$_temp0';
  }

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
  String get einstellungenDatenExport => 'Download my data';

  @override
  String get einstellungenDatenExportLaeuft => 'Preparing your file …';

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
  String get erinnerungPushTitel => 'Your daily goal';

  @override
  String get erinnerungPushText =>
      'Nothing ticked off today — one tick secures the day.';

  @override
  String get erinnerungKanalName => 'Daily reminder';

  @override
  String get erinnerungKanalBeschreibung =>
      'Reminds you in the evening if you have not ticked anything off yet.';

  @override
  String get einstellungenErinnerung => 'Daily reminder';

  @override
  String get erinnerungAn => 'Remind me';

  @override
  String get erinnerungZeit => 'Time';

  @override
  String get erinnerungHinweis =>
      'Only arrives if you have a plan and nothing is ticked off that day.';

  @override
  String get erinnerungOhneBerechtigung =>
      'Your phone is currently not allowing notifications for TrueGlow. You can change that in the system settings.';

  @override
  String get erinnerungZeitWaehlen => 'Pick a time';

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

  @override
  String get alter18bis24 => '18–24';

  @override
  String get alter25bis34 => '25–34';

  @override
  String get alter35bis44 => '35–44';

  @override
  String get alterAb45 => '45+';

  @override
  String get budgetNiedrig => 'Low';

  @override
  String get budgetNiedrigText => 'Drugstore, under €30 a month';

  @override
  String get budgetMittel => 'Medium';

  @override
  String get budgetMittelText => '€30–80 a month';

  @override
  String get budgetHoch => 'High';

  @override
  String get budgetHochText => 'over €80 a month';

  @override
  String get zeitKurz => '5 minutes';

  @override
  String get zeitKurzText => 'Just the essentials';

  @override
  String get zeitMittel => '15 minutes';

  @override
  String get zeitMittelText => 'A solid routine';

  @override
  String get zeitLang => '30+ minutes';

  @override
  String get zeitLangText => 'The full works';

  @override
  String get fokusHaut => 'Skin';

  @override
  String get fokusHaare => 'Hair';

  @override
  String get fokusBart => 'Beard';

  @override
  String get fokusStyle => 'Style';

  @override
  String get fokusFitness => 'Fitness habits';

  @override
  String get modulBasisTitel => 'Face, hair & beard';

  @override
  String get modulBasisText => 'Face shape, haircut and beard recommendations.';

  @override
  String get modulBasisCheckliste => 'Hair & beard';

  @override
  String get modulHautTitel => 'Skin & colour type';

  @override
  String get modulHautText =>
      'Skin condition, undertone, a colour palette for your clothes.';

  @override
  String get modulHautCheckliste => 'Skin';

  @override
  String get modulZaehneTitel => 'Teeth & smile';

  @override
  String get modulZaehneText =>
      'Tooth colour, alignment, how your smile reads.';

  @override
  String get modulZaehneCheckliste => 'Teeth';

  @override
  String get modulFigurTitel => 'Figure & fit';

  @override
  String get modulFigurText => 'Silhouette, proportions, which cuts suit you.';

  @override
  String get modulFigurCheckliste => 'Posture & figure';

  @override
  String get modulStilTitel => 'Style & wardrobe';

  @override
  String get modulStilText =>
      'Your current outfits, where you want to take them, specific looks to try.';

  @override
  String get modulStilCheckliste => 'Style';

  @override
  String get modulZieleTitel => 'Personal goals';

  @override
  String get modulZieleText =>
      'What you set out to do in your own words under “Your direction”.';

  @override
  String get modulZieleCheckliste => 'Your goals';

  @override
  String get modulBenoetigtZiele => 'What you wrote under “Your direction”';

  @override
  String get zweckUniSchule => 'Uni / school / training';

  @override
  String get zweckAusgehenDates => 'Going out & dates';

  @override
  String get zweckArbeitNebenjob => 'Work / part-time job';

  @override
  String get zweckGymSport => 'Gym & sport';

  @override
  String get kleidungsbudgetKlein => 'Up to €50 per item';

  @override
  String get kleidungsbudgetMittel => '€50–150 per item';

  @override
  String get kleidungsbudgetGross => 'Over €150 per item';

  @override
  String get pflegeaufwandMinimal => 'As little as possible';

  @override
  String get pflegeaufwandMittel => 'A bit of effort is fine';

  @override
  String get pflegeaufwandHoch => 'I\'m happy to put time in';

  @override
  String get fotoproblemKeinGesichtTitel => 'No face detected';

  @override
  String get fotoproblemKeinGesichtTipp =>
      'Hold the camera so your whole face is in frame — no sunglasses, hat or mask.';

  @override
  String get fotoproblemMehrereTitel => 'More than one face';

  @override
  String get fotoproblemMehrereTipp =>
      'Only your face should be in the photo. Find a quiet background with nobody else in it.';

  @override
  String get fotoproblemZuKleinTitel => 'Face too small';

  @override
  String get fotoproblemZuKleinTipp =>
      'Move closer to the camera, or hold your phone nearer, until your head fills most of the frame.';

  @override
  String get fotoproblemZuDunkelTitel => 'Photo too dark';

  @override
  String get fotoproblemZuDunkelTipp =>
      'Stand by a window or turn more lights on. Even light from the front works best.';

  @override
  String get fotoproblemUngueltigTitel => 'Image could not be read';

  @override
  String get fotoproblemUngueltigTipp =>
      'Try a different photo, or take a new one.';

  @override
  String get fotoproblemFehlerTitel => 'Something went wrong';

  @override
  String get fotoproblemFehlerTipp => 'Please try again.';

  @override
  String get authAbgebrochenTitel => 'Sign-in cancelled';

  @override
  String get authAbgebrochenTipp =>
      'No problem — you can try again whenever you like.';

  @override
  String get authKeinInternetTitel => 'No connection';

  @override
  String get authKeinInternetTipp =>
      'Check your internet connection and try again.';

  @override
  String get authKontoVergebenTitel => 'Account already in use';

  @override
  String get authKontoVergebenTipp =>
      'This Google account already belongs to a TrueGlow login. We\'ve signed you in with it.';

  @override
  String get authNichtVerfuegbarTitel => 'Sign-in unavailable';

  @override
  String get authNichtVerfuegbarTipp =>
      'This way of signing in isn\'t available on your device.';

  @override
  String get authUnbekanntTitel => 'Sign-in failed';

  @override
  String get authUnbekanntTipp => 'Something went wrong. Please try again.';

  @override
  String get anbieterGoogle => 'Google';

  @override
  String get anbieterApple => 'Apple';

  @override
  String get anbieterAnonym => 'No account';

  @override
  String get nutzerOhneKonto => 'Signed in without an account';

  @override
  String get nutzerAngemeldet => 'Signed in';

  @override
  String get kontoNeuAnmeldenTitel => 'Please sign in again';

  @override
  String get kontoNeuAnmeldenTipp =>
      'Deleting an account can\'t be undone. That\'s why we ask you to sign in once more first.';

  @override
  String get kontoKeinInternetTitel => 'No connection';

  @override
  String get kontoKeinInternetTipp =>
      'Deleting needs a moment of internet — otherwise your account would stay in the cloud. Try again once you\'re online.';

  @override
  String get kontoFehlgeschlagenTitel => 'Couldn\'t delete';

  @override
  String get kontoFehlgeschlagenTipp =>
      'Something went wrong. Your data is unchanged — please try again later.';

  @override
  String get analyseKeinInternetTitel => 'No connection';

  @override
  String get analyseKeinInternetTipp =>
      'Check your internet connection and try again.';

  @override
  String get analyseZeitTitel => 'Timed out';

  @override
  String get analyseZeitTipp => 'The analysis took too long. Please try again.';

  @override
  String get analyseZugangTitel => 'This installation is not authorised';

  @override
  String get analyseZugangTipp =>
      'The server did not reject your account — it rejected this installation of the app. Waiting will not help. Close the app and start it again; if it persists, the installation needs to be authorised (SETUP.md, section 4.3).';

  @override
  String get analyseApiTitel => 'Analysis unavailable';

  @override
  String get analyseApiTipp =>
      'The analysis service isn\'t responding right now. Please try again later.';

  @override
  String get analyseKontingentTitel => 'Allowance used up';

  @override
  String get analyseKontingentTipp =>
      'The analysis service has hit its limit. Please try again later.';

  @override
  String get analyseAntwortTitel => 'Response unreadable';

  @override
  String get analyseAntwortTipp =>
      'The analysis came back incomplete. Trying again usually helps.';

  @override
  String get analyseKeinSchluesselTitel => 'Analysis service not set up';

  @override
  String get analyseKeinSchluesselTipp =>
      'The service isn\'t ready right now. We\'re on it — please try again later.';

  @override
  String get analyseFotosFehlenTitel => 'Photos missing';

  @override
  String get analyseFotosFehlenTipp =>
      'Some photos for this selection are still missing. Go back and take them.';

  @override
  String get analyseEinwilligungTitel => 'Consent missing';

  @override
  String get analyseEinwilligungTipp =>
      'To run an analysis we need your consent to send your photos to the AI service. You can give it in your settings.';

  @override
  String get einwilligungNutzung => 'Terms of use and privacy';

  @override
  String get einwilligungMindestalter => 'I am at least 18 years old';

  @override
  String get einwilligungFotoKi => 'Analysis of my photos by the AI service';

  @override
  String get einwilligungDiagnose => 'Crash reports and usage statistics';

  @override
  String get dokumentDatenschutzTitel => 'Privacy policy';

  @override
  String get dokumentDatenschutzText =>
      'What data we process, why, and for how long.';

  @override
  String get dokumentAgbTitel => 'Terms of use';

  @override
  String get dokumentAgbText => 'The rules for using TrueGlow.';

  @override
  String get dokumentImpressumTitel => 'Legal notice';

  @override
  String get dokumentImpressumText =>
      'Who is behind the app and how to reach us.';

  @override
  String get abzeichenSektionTitel => 'Your badges';

  @override
  String get abzeichenErsteAnalyseTitel => 'First analysis done';

  @override
  String get abzeichenErsteAnalyseText => 'You completed your first analysis.';

  @override
  String get abzeichenDreiTitel => 'Getting started';

  @override
  String get abzeichenDreiText =>
      'Three days in a row with something ticked off.';

  @override
  String get abzeichenSiebenTitel => 'First week done';

  @override
  String get abzeichenSiebenText =>
      'Seven days in a row — that\'s the first week.';

  @override
  String get abzeichenVierzehnTitel => 'Two solid weeks';

  @override
  String get abzeichenVierzehnText =>
      'Fourteen days in a row. That\'s a routine now.';

  @override
  String get abzeichenDreissigTitel => 'A month in';

  @override
  String get abzeichenDreissigText => 'Thirty days in a row. Impressive.';

  @override
  String get abzeichenSechzigTitel => 'Two months strong';

  @override
  String get abzeichenSechzigText =>
      'Sixty days in a row — few people get this far.';

  @override
  String get abzeichenNeunzigTitel => 'A quarter of a year';

  @override
  String get abzeichenNeunzigText =>
      'Ninety days in a row. This is just your life now.';

  @override
  String get abzeichenAlleModuleTitel => 'Everything unlocked';

  @override
  String get abzeichenAlleModuleText => 'Your analysis covers every module.';

  @override
  String abzeichenJubelTage(int tage) {
    return '$tage days straight!';
  }

  @override
  String get erscheinungHell => 'Light';

  @override
  String get erscheinungDunkel => 'Dark';

  @override
  String get erscheinungSystem => 'System';

  @override
  String get aufnahmeBasisFrontalLabel => 'Front photo';

  @override
  String get aufnahmeBasisFrontalHinweis =>
      'Look straight into the camera. Neutral expression, good light, nothing on your head.';

  @override
  String get aufnahmeProfilLinksLabel => 'Left profile';

  @override
  String get aufnahmeProfilLinksHinweis =>
      'Turn your head to the right so the left side of your face points at the camera. Your ear and jawline should be visible.';

  @override
  String get aufnahmeProfilRechtsLabel => 'Right profile';

  @override
  String get aufnahmeProfilRechtsHinweis =>
      'Turn your head to the left so the right side of your face points at the camera. Your ear and jawline should be visible.';

  @override
  String get aufnahmeWinkelLabel => '45° angle';

  @override
  String get aufnahmeWinkelHinweis =>
      'Turn your head halfway to the right — about 45 degrees. Both eyes stay visible.';

  @override
  String get aufnahmeLaechelnLabel => 'Smile';

  @override
  String get aufnahmeLaechelnHinweis =>
      'Smile straight at the camera so your teeth are clearly visible.';

  @override
  String get aufnahmeGanzkoerperFrontalLabel => 'Full body, front';

  @override
  String get aufnahmeGanzkoerperFrontalHinweis =>
      'In frame from your head down to at least your thighs, standing straight, arms relaxed at your sides. Feet are optional. Close-fitting clothes show your silhouette best.';

  @override
  String get aufnahmeGanzkoerperSeitlichLabel => 'Full body, side';

  @override
  String get aufnahmeGanzkoerperSeitlichHinweis =>
      'The same pose turned 90 degrees — that shows your posture and proportions from the side.';

  @override
  String get aufnahmeOutfitEinsLabel => 'Outfit 1';

  @override
  String get aufnahmeOutfitEinsHinweis =>
      'An outfit you wear often — on you or laid out flat.';

  @override
  String get aufnahmeOutfitZweiLabel => 'Outfit 2';

  @override
  String get aufnahmeOutfitZweiHinweis =>
      'A second outfit, ideally for a different occasion.';

  @override
  String get aufnahmeOutfitDreiLabel => 'Outfit 3';

  @override
  String get aufnahmeOutfitDreiHinweis =>
      'Optional: a third outfit. You can skip this step.';

  @override
  String get aufnahmeHautLichtZusatz =>
      'This photo also feeds the skin analysis, so the daylight from the checklist counts double here.';

  @override
  String get modulBenoetigtBasis =>
      'Front, both side profiles and a 45° angle.';

  @override
  String get modulBenoetigtHaut =>
      'No photo of its own — it uses your front photo. Take that one in indirect daylight.';

  @override
  String get modulBenoetigtZaehne => '1 photo, smiling.';

  @override
  String get modulBenoetigtFigur =>
      '2 full-body photos (front and side) plus your height and weight.';

  @override
  String get modulBenoetigtStil =>
      '2–3 outfit photos and a few quick questions.';

  @override
  String get checkinTypAlltagTitel => 'Everyday check';

  @override
  String get checkinTypAlltagIntro =>
      'One week in! We only want to know one thing: how well do the tasks fit into your day?';

  @override
  String get checkinTypZwischenTitel => 'Halfway check';

  @override
  String get checkinTypZwischenIntro =>
      'Two weeks in. We\'ll take a quick look at the tasks that gave you trouble — and how the first days have felt.';

  @override
  String get checkinTypWirkungTitel => 'Results check';

  @override
  String get checkinTypWirkungIntro =>
      'A month is up. Now it\'s worth looking at what has changed — and what we should sharpen up.';

  @override
  String get bewertungLaeuftGut => 'Going well';

  @override
  String get bewertungGehtSo => 'So-so';

  @override
  String get bewertungPasstNicht => 'Not working';

  @override
  String get grundZeit => 'Takes too long';

  @override
  String get grundVergessen => 'I forget';

  @override
  String get grundUnangenehm => 'Unpleasant / don\'t like it';

  @override
  String get grundTeuer => 'Too expensive';

  @override
  String get grundAnderer => 'Another reason';

  @override
  String get frageRoutine => 'How well is your morning routine going?';

  @override
  String get frageHautGefuehl => 'How does your skin feel?';

  @override
  String get frageZaehneGefuehl => 'How clean do your teeth feel?';

  @override
  String get frageHaltungGefuehl => 'How aware are you of your posture?';

  @override
  String get frageAnziehen => 'How easy is getting dressed in the morning?';

  @override
  String get frageBasisErgebnis => 'How have your hair and beard come along?';

  @override
  String get frageHautErgebnis => 'How has your skin come along?';

  @override
  String get frageZaehneErgebnis => 'How have your teeth and smile come along?';

  @override
  String get frageHaltungErgebnis => 'How has your posture come along?';

  @override
  String get frageStilErgebnis => 'How well are your outfits working now?';

  @override
  String get einordnungHaut =>
      'Visible changes in skin usually show from week 4–6 — you\'re on track.';

  @override
  String get einordnungZaehne =>
      'Discolouration fades slowly: the difference usually shows from week 4 — you\'re on track.';

  @override
  String get einordnungHaltung =>
      'Posture changes over weeks, not days — from week 4 to 6 other people start noticing. You\'re on track.';

  @override
  String get einordnungStil =>
      'A wardrobe changes piece by piece — after four to six weeks the new combinations come naturally.';

  @override
  String get einordnungBasis =>
      'Hair grows about a centimetre a month — the new shape shows from week 4. You\'re on track.';

  @override
  String get dokumentFolgt => 'Not available yet';

  @override
  String dokumentTitelFolgt(String titel) {
    return '$titel (coming soon)';
  }

  @override
  String loginMitAnbieter(String anbieter) {
    return 'Sign in with $anbieter';
  }

  @override
  String get offlineBand =>
      'Offline — your plan and checklist keep working, changes will sync later.';

  @override
  String routeNichtGefunden(String pfad) {
    return 'Page not found: $pfad';
  }

  @override
  String get ladeGesichtsform => 'Analysing face shape...';

  @override
  String get ladeHautbild => 'Checking your skin...';

  @override
  String get ladeFrisur => 'Comparing haircut options...';

  @override
  String get ladeEmpfehlungen => 'Putting recommendations together...';

  @override
  String get ladePlan => 'Building your plan...';

  @override
  String get unterbrochenTitel => 'Analysis interrupted';

  @override
  String get unterbrochenText =>
      'Your last analysis didn\'t finish — the app was closed in between. Nothing was saved. Your photos are still there, so you can start again right away.';

  @override
  String get loginWarumKonto =>
      'So your plan, streak and history survive a change of phone, everything belongs to an account.';

  @override
  String get loginGast => 'Just have a look first';

  @override
  String get loginGastErklaerung =>
      'If you just look around, we create an account with no name and no email. Sign in with Google later and we bring your data along.';

  @override
  String get loginFotosBleiben => 'Your photos stay on your device.';

  @override
  String get fotoWirdGeprueft => 'Checking photo...';

  @override
  String get flowNichtsAufzunehmen =>
      'There\'s nothing to photograph for this selection.';

  @override
  String flowSchritt(int nummer, int gesamt) {
    return 'Step $nummer of $gesamt';
  }

  @override
  String get figurBleibtLokalTitel => 'Stays on your device';

  @override
  String get figurBleibtLokalText =>
      'Your height and weight are only sent along for the fit recommendation and are not stored by the analysis service.';

  @override
  String get fotoOptional => 'Optional — you can skip this step.';

  @override
  String get fotoSoKlapptEs => 'How to get this shot';

  @override
  String get fotoAutoTitel => 'The app takes it for you';

  @override
  String get fotoGeprueft => 'Checked';

  @override
  String get hinweisSchliessen => 'Dismiss notice';

  @override
  String get modulHautKeinFotoTitel => 'No separate photo needed';

  @override
  String get modulHautKeinFotoText =>
      'We read your undertone and colour palette from your front photo. No extra close-up needed.';

  @override
  String get modulHautLichtTitel => 'Light counts double here';

  @override
  String get modulHautLichtText =>
      'If your front photo was too dark or had a colour cast, go back a step and retake it in indirect daylight — warm artificial light distorts your undertone.';

  @override
  String get aufnahmeTitel => 'Photos';

  @override
  String get richtungBleibtLokal => 'Stays on your device';

  @override
  String get checkinKeiner => 'No check-in is due right now.';

  @override
  String checkinSchrittZaehler(int aktuell, int gesamt) {
    return '$aktuell of $gesamt';
  }

  @override
  String get checkinUnterEinerMinute => 'Under a minute';

  @override
  String get checkinAbbrechbar =>
      'You can stop at any time — what you\'ve entered stays saved.';

  @override
  String get checkinAufKurs => 'You\'re on track';

  @override
  String get checkinPlanUnveraendert => 'Leave plan as it is';

  @override
  String get checkinOhneAnpassung => 'Finish without changes';

  @override
  String get vergleichHinweis =>
      'Same framing, same light — that\'s what makes a real comparison possible.';

  @override
  String get vergleichNurFuerDichTitel => 'Just for you';

  @override
  String get vergleichNurFuerDichText =>
      'Your progress photo also stays on your device and only goes to the analysis service for the evaluation.';

  @override
  String get vergleichOhneDatum => 'no date';

  @override
  String get altersTitel => 'Adults only';

  @override
  String get altersWeiter => 'Continue to the analysis';

  @override
  String get altersZurueck => 'Back to the dashboard';

  @override
  String get altersWarumTitel => 'Why we ask';

  @override
  String get altersWarumText =>
      'To run an analysis, TrueGlow processes images of your face. That kind of data is specially protected, and only adults can give valid consent for it. That\'s why the app is 18+.';

  @override
  String get altersOhneText =>
      'Without confirmation, only the analysis section stays closed. Your plan, daily checklist, streak and check-ins keep working — and the reports you already have stay put.';

  @override
  String get einwilligungKurzTitel => 'One quick confirmation';

  @override
  String get einwilligungNachgeschaerftTitel => 'We\'ve tightened this up';

  @override
  String get einwilligungNeueFassungTitel => 'New version of our terms';

  @override
  String get einwilligungNachgeschaerftText =>
      'There used to be a single tick box for everything. Because your photos are a different matter from using the app, we now ask about both separately — once, and never again.';

  @override
  String get einwilligungNeueFassungText =>
      'Our legal texts have changed. So that your agreement covers what actually applies, we\'re asking you to confirm once.';

  @override
  String get einwilligungBleibtErhalten =>
      'Your existing analyses, your plan and your streak stay exactly as they are.';

  @override
  String get erklaerungMindestalter =>
      'TrueGlow processes images of your face and is therefore for adults only. By ticking this box you confirm that you are of legal age.';

  @override
  String get erklaerungNutzung =>
      'I have read the terms of use and the privacy policy and agree to them.';

  @override
  String get erklaerungDiagnose =>
      'I consent to anonymous crash reports and minimal usage statistics being collected. Only THAT a step was reached is recorded — no photos, no analysis content, no free text, no profile details.';

  @override
  String get erklaerungFotoKi =>
      'I consent to my photos — including images of my face — being sent to the AI service Google Gemini for evaluation. Processing takes place on Google servers, including outside the EU (third-country transfer). The images are neither stored nor logged there.';

  @override
  String get freiwilligFotoKi =>
      'Optional and revocable at any time in your settings. Without it there are no new analyses — everything else keeps working and existing reports stay.';

  @override
  String get freiwilligMindestalter =>
      'Without confirmation the analysis section stays closed. You can still use your plan, checklists and check-ins.';

  @override
  String get freiwilligDiagnose =>
      'Optional, off by default and revocable at any time. It helps us find crashes before they end up in a review.';

  @override
  String get datumHeute => 'today';

  @override
  String get datumGestern => 'yesterday';

  @override
  String get verlaufLoeschenTitel => 'Delete analysis?';

  @override
  String verlaufLoeschenText(String datum) {
    return 'The analysis from $datum will be removed from this device.';
  }

  @override
  String get loeschen => 'Delete';

  @override
  String get verlaufLoeschenTooltip => 'Delete analysis';

  @override
  String get homeDeinPlan => 'Your plan';

  @override
  String get homeAnalyseKurz => 'Analysis';

  @override
  String homeErstelltAm(String datum) {
    return 'created $datum';
  }

  @override
  String get legalFotosText =>
      'Your photos only leave the device for the duration of an analysis, and are not stored anywhere in the process.';

  @override
  String legalNichtOeffenbar(String titel) {
    return '$titel can\'t be opened right now.';
  }

  @override
  String get legalStehenAusTitel => 'Texts still to come';

  @override
  String get dokumentKeinTextTitel => 'Not available yet';

  @override
  String get dokumentKeinTextText =>
      'No text has been added for this document yet.';

  @override
  String get dokumentNichtLesbarTitel => 'Text can\'t be read';

  @override
  String get dokumentNichtLesbarText =>
      'The stored text can\'t be loaded. Please open it on the website instead.';

  @override
  String get migrationTitel => 'Bring your existing data along?';

  @override
  String get migrationText =>
      'This device holds analyses, a plan, a streak and check-ins from before you had an account. Should they belong to your account?\n\nEither way, your photos stay on the device only.';

  @override
  String get migrationUebernehmen => 'Bring them along';

  @override
  String get migrationNichts => 'There was nothing to bring.';

  @override
  String migrationErfolg(int anzahl) {
    return 'Brought along: $anzahl entries.';
  }

  @override
  String get migrationFehler =>
      'Couldn\'t bring your data along. It\'s still on the device — we\'ll ask again next time you start the app.';

  @override
  String get onbPunktFotos => 'Take two photos';

  @override
  String get onbPunktAnalyse => 'AI analysis of your features';

  @override
  String get onbPunktPlan => 'A concrete plan with a checklist';

  @override
  String get onbDatenschutzText =>
      'Please read the notes below before we start.';

  @override
  String get onbKeineMedizin => 'Not medical advice';

  @override
  String get onbUmgangFotos => 'How we handle your photos';

  @override
  String get planLeer => 'No plan yet. Run an analysis first.';

  @override
  String get ergebnisNichtVorhanden => 'This analysis no longer exists.';

  @override
  String get settingsKontoLoeschenFrage => 'Delete account permanently?';

  @override
  String get settingsDatenLoeschenFrage => 'Delete all data?';

  @override
  String get settingsKontoLoeschenText =>
      'Your account and everything in it will be deleted for good — on this device and in the cloud. Your photos on the device go too.\n\nAfterwards you won\'t be able to sign in with this account.';

  @override
  String get settingsDatenLoeschenText =>
      'Analyses, your plan, your progress and your details will be removed for good — on this device and in your account. Your photos on the device go too.\n\nYour account itself stays.';

  @override
  String get settingsKontoLoeschenKnopf => 'Delete account';

  @override
  String get settingsFotoJa =>
      'Analyses are possible. Your photos go to the AI service only for the duration of the evaluation.';

  @override
  String get settingsFotoNein =>
      'Without photo consent there are no new analyses. Your existing reports, your plan and your streak stay.';

  @override
  String settingsNochNichtGefragt(String titel) {
    return '$titel: not asked yet';
  }

  @override
  String get settingsNachtraeglich => 'later';

  @override
  String get settingsAnmeldungUnklar =>
      'We can\'t check your sign-in status right now. Your data on the device isn\'t affected.';

  @override
  String get settingsKontoAnonym =>
      'Your data is tied to this device. Sign in with Google so it survives a change of phone — everything you have so far comes with you.';

  @override
  String get settingsKontoEcht =>
      'Your plan, streak and history belong to this account. Photos stay on the device.';

  @override
  String get settingsVerknuepfen => 'Link with Google';

  @override
  String get settingsVerknuepft => 'Account linked.';

  @override
  String get settingsAbmeldenAnonym =>
      'You\'re signed in without an account. Once you sign out, you can\'t get back to this state. The data on this device stays.';

  @override
  String get settingsAbmeldenEcht =>
      'Your data stays in your account. It\'ll be there again after your next sign-in.';

  @override
  String get settingsKonto => 'Account';

  @override
  String get settingsAnalyseModus => 'Analysis mode';

  @override
  String get settingsModusDemo =>
      'No photos are sent. The app shows a stored sample analysis. Switch at build time with --dart-define=TRUEGLOW_MOCK.';

  @override
  String settingsModusLive(String modell) {
    return 'Analyses run through the TrueGlow service ($modell). Your photos are transmitted for the evaluation and are neither stored nor logged there.';
  }

  @override
  String settingsFehlerMeldung(String titel, String tipp) {
    return '$titel: $tipp';
  }

  @override
  String get streakTage => 'days in a row';

  @override
  String get streakAllesErledigt => 'All done for today. Nice.';

  @override
  String get streakKeineAufgaben => 'No daily tasks yet.';

  @override
  String get streakNichtsAbgehakt =>
      'Nothing ticked off today — one tick secures the day.';

  @override
  String streakHeuteErledigt(int erledigt, int gesamt) {
    return '$erledigt of $gesamt done today';
  }

  @override
  String streakRekord(int tage) {
    String _temp0 = intl.Intl.pluralLogic(
      tage,
      locale: localeName,
      other: 'Longest streak: $tage days',
      one: 'Longest streak: 1 day',
    );
    return '$_temp0';
  }

  @override
  String get streakNeustart =>
      'Fresh start — your longest streak stays with you.';

  @override
  String get fotosTitel => 'Your progress photos';

  @override
  String get fotosLeerTitel => 'No photo yet';

  @override
  String get fotosLeerText =>
      'You can take one at your next check-in — entirely optional, and you can skip it.';

  @override
  String get fotosEinsTitel => 'The starting point';

  @override
  String get fotosEinsText =>
      'From your second photo on, you will see the comparison here.';

  @override
  String get fotosNurHierTitel => 'These photos stay on this device';

  @override
  String get fotosNurHierText =>
      'They live in the app\'s protected storage: not in your gallery, not in Google\'s backup, not on our server. They are never used for the analysis. If you change phones or reinstall, they are gone.';

  @override
  String get fotosVerstanden => 'Got it';

  @override
  String get fotosVorher => 'Before';

  @override
  String get fotosNachher => 'After';

  @override
  String get fotosReglerHinweis => 'Drag the slider to compare.';

  @override
  String fotosZeitleiste(int anzahl) {
    String _temp0 = intl.Intl.pluralLogic(
      anzahl,
      locale: localeName,
      other: '$anzahl photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get fotosStart => 'Start';

  @override
  String get fotosLoeschen => 'Delete this photo';

  @override
  String get fotosLoeschenFrage => 'Delete photo?';

  @override
  String get fotosLoeschenText =>
      'The image is removed from your device and cannot be restored. Your check-in answers stay.';

  @override
  String get fotosStartNichtLoeschbar =>
      'The starting photo belongs to your analysis.';

  @override
  String get fotosOeffnen => 'View progress photos';

  @override
  String get fotosAlleAnsehen => 'See all photos';

  @override
  String get challengeTitel => 'This week\'s challenge';

  @override
  String challengeAktiveTage(int ziel) {
    return 'Be active on $ziel days — one tick is enough.';
  }

  @override
  String challengeSerie(int ziel) {
    return 'Tick off at least one item on $ziel days in a row.';
  }

  @override
  String challengeVolleTage(int ziel) {
    return 'Clear your whole checklist on $ziel days.';
  }

  @override
  String challengeAufgaben(int ziel) {
    return 'Tick off $ziel tasks this week.';
  }

  @override
  String get challengeFrueheWoche =>
      'Strong start: one tick on Monday, Tuesday and Wednesday.';

  @override
  String get challengeWochenende =>
      'Weekends too: one tick on Saturday and Sunday.';

  @override
  String challengeStand(int stand, int ziel) {
    return '$stand of $ziel';
  }

  @override
  String get challengeGeschafft => 'Done!';

  @override
  String get abzeichenChallengesTitel => 'Four weeks, four goals';

  @override
  String get abzeichenChallengesText => 'Four weekly challenges completed.';

  @override
  String abzeichenNochChallenges(int anzahl) {
    String _temp0 = intl.Intl.pluralLogic(
      anzahl,
      locale: localeName,
      other: '$anzahl challenges to go',
      one: '1 challenge to go',
    );
    return '$_temp0';
  }

  @override
  String get rueckblickTitel => 'Your week';

  @override
  String rueckblickZeitraum(String von, String bis) {
    return '$von to $bis';
  }

  @override
  String rueckblickAktiveTage(int tage) {
    String _temp0 = intl.Intl.pluralLogic(
      tage,
      locale: localeName,
      other: 'active on $tage of 7 days',
      one: 'active on 1 of 7 days',
    );
    return '$_temp0';
  }

  @override
  String rueckblickAufgaben(int anzahl) {
    String _temp0 = intl.Intl.pluralLogic(
      anzahl,
      locale: localeName,
      other: '$anzahl tasks ticked off',
      one: '1 task ticked off',
    );
    return '$_temp0';
  }

  @override
  String rueckblickStaerkster(String bereich) {
    return 'Your strongest area: $bereich';
  }

  @override
  String get rueckblickTonStark =>
      'Strong week. That is how intention turns into routine.';

  @override
  String get rueckblickTonSolide => 'Solid week. The groundwork is there.';

  @override
  String get rueckblickTonKlein =>
      'Two days are two more than none. That counts.';

  @override
  String get rueckblickTonLeer =>
      'New week, fresh chance — one tick is enough to start.';

  @override
  String get rueckblickSchliessen => 'Close the review';

  @override
  String get streakTagGesichert => 'Day secured!';

  @override
  String streakTagGesichertText(int tage) {
    String _temp0 = intl.Intl.pluralLogic(
      tage,
      locale: localeName,
      other: 'That makes $tage days in a row.',
      one: 'That\'s day 1 on the board.',
    );
    return '$_temp0';
  }

  @override
  String streakJokerUebrig(int anzahl) {
    String _temp0 = intl.Intl.pluralLogic(
      anzahl,
      locale: localeName,
      other: '$anzahl jokers left this month',
      one: '1 joker left this month',
      zero: 'No jokers left this month',
    );
    return '$_temp0';
  }

  @override
  String streakJokerGerettet(int anzahl) {
    String _temp0 = intl.Intl.pluralLogic(
      anzahl,
      locale: localeName,
      other: '$anzahl jokers saved your streak.',
      one: 'A joker saved your streak.',
    );
    return '$_temp0';
  }

  @override
  String streakJokerErklaerung(int gesamt) {
    return 'Jokers: $gesamt a month. Miss a day and one steps in automatically.';
  }

  @override
  String streakNochModule(int anzahl) {
    return '$anzahl to go';
  }

  @override
  String streakNochTage(int anzahl) {
    return '$anzahl to go';
  }

  @override
  String verlaufZeile(int bereiche, int empfehlungen) {
    return '$bereiche areas · $empfehlungen recommendations';
  }

  @override
  String homePlanZeile(String datum, int empfehlungen) {
    return 'created $datum · $empfehlungen recommendations';
  }

  @override
  String legalEntwurfHinweis(String bericht) {
    return 'The final versions haven\'t been added yet. Until then the affected entries stay locked.\n\n$bericht';
  }

  @override
  String get migrationAblehnen => 'No, start fresh';

  @override
  String get settingsEinwilligungen => 'Consents';

  @override
  String get settingsWirdGeladen => 'Loading …';

  @override
  String get settingsNichtAngemeldet => 'Not signed in.';

  @override
  String get settingsAbmelden => 'Sign out';

  @override
  String get settingsAbmeldenFrage => 'Sign out?';

  @override
  String get settingsErteilt => 'given';

  @override
  String get settingsNichtErteilt => 'not given';

  @override
  String settingsNachweis(
    String titel,
    String stand,
    String datum,
    String version,
    String kanal,
  ) {
    return '$titel: $stand on $datum (text version $version, $kanal)';
  }

  @override
  String get settingsVersionUnbekannt => 'unknown';

  @override
  String get settingsKanalOnboarding => 'during onboarding';

  @override
  String get settingsKanalEinstellungen => 'in settings';

  @override
  String get settingsKanalNachtrag => 'later';

  @override
  String get settingsModusMock => 'Mock';

  @override
  String get settingsModusLiveKurz => 'Live';

  @override
  String get abzeichenErsteAnalyseOffen => 'Run your first analysis';

  @override
  String abzeichenNochModule(int anzahl) {
    String _temp0 = intl.Intl.pluralLogic(
      anzahl,
      locale: localeName,
      other: '$anzahl modules to go',
      one: '1 module to go',
    );
    return '$_temp0';
  }

  @override
  String abzeichenNochTage(int anzahl) {
    String _temp0 = intl.Intl.pluralLogic(
      anzahl,
      locale: localeName,
      other: '$anzahl days to go',
      one: '1 day to go',
    );
    return '$_temp0';
  }

  @override
  String get erscheinungFolgtSystem =>
      'TrueGlow follows your phone’s system setting.';

  @override
  String get erscheinungFest =>
      'Fixed choice — independent of your system setting.';

  @override
  String get mockGrundOhne => 'This doesn\'t fit your day as it stands.';

  @override
  String mockGrundMit(String grund) {
    return '$grund — we\'ll make it easier.';
  }

  @override
  String get mockKeineAenderung =>
      'Your plan stays as it is — this is going well.';

  @override
  String mockAenderungen(int anzahl) {
    String _temp0 = intl.Intl.pluralLogic(
      anzahl,
      locale: localeName,
      other: 'We\'re adjusting $anzahl tasks that didn\'t fit your day.',
      one: 'We\'re adjusting 1 task that didn\'t fit your day.',
    );
    return '$_temp0';
  }

  @override
  String get mockFazit =>
      'Compared with your first photo, your routine looks more consistent overall. Stick with the tasks that come easily — the two adjusted ones will save you time.';

  @override
  String mockVarianteZeit(String habit) {
    return '$habit — just 30 seconds';
  }

  @override
  String mockVarianteVergessen(String habit) {
    return '$habit — right after brushing your teeth';
  }

  @override
  String mockVarianteUnangenehm(String habit) {
    return '$habit — the gentle version';
  }

  @override
  String mockVarianteTeuer(String habit) {
    return '$habit — with a cheaper alternative';
  }

  @override
  String mockVarianteAnderer(String habit) {
    return '$habit — every other day';
  }

  @override
  String get loginWillkommen =>
      'Your personal plan for skin, hair, beard and style. Sign in — or just have a look around first.';

  @override
  String get loginRechtliches => 'Before you start:';

  @override
  String get geschlechtMaennlich => 'Male';

  @override
  String get geschlechtWeiblich => 'Female';

  @override
  String get geschlechtDivers => 'Non-binary';

  @override
  String get geschlechtKeineAngabe => 'Prefer not to say';

  @override
  String get onbGeschlechtTitel => 'Who are we building this plan for?';

  @override
  String get onbGeschlechtText =>
      'This decides which modules, framing guides and recommendations you get. You can change it in your settings at any time.';

  @override
  String get einstellungenGeschlecht => 'Personalisation';

  @override
  String get geschlechtHinweisWeiblich =>
      'Make-up & presence is included, beard advice is dropped.';

  @override
  String get geschlechtHinweisMaennlich =>
      'Beard and contours are part of the core module, make-up stays out.';

  @override
  String get geschlechtHinweisNeutral =>
      'Every module is available — beard as well as make-up.';

  @override
  String get geschlechtHinweisOffen =>
      'Nothing chosen yet. Until then, everything stays as it was.';

  @override
  String get modulMakeupTitel => 'Make-up & presence';

  @override
  String get modulMakeupText =>
      'Colours that suit you, what to emphasise, and an everyday look that fits your features.';

  @override
  String get modulMakeupCheckliste => 'Make-up';

  @override
  String get modulBenoetigtMakeup =>
      'No photo of its own — it uses your front photo. Take it either without make-up or with your everyday look.';

  @override
  String get modulMakeupKeinFotoTitel => 'No separate photo needed';

  @override
  String get modulMakeupKeinFotoText =>
      'We read your features and how colours work on you from your front photo. Whether you wear make-up in it is up to you — bare shows the starting point, made-up shows your current look.';

  @override
  String get modulBasisTitelOhneBart => 'Face & hair';

  @override
  String get modulBasisTextOhneBart =>
      'Face shape and haircut recommendations.';

  @override
  String get modulBasisCheckisteOhneBart => 'Hair';

  @override
  String get modulBenoetigtBasisOhneBart =>
      'Front, both side profiles and a 45° angle.';

  @override
  String get frageMakeupGefuehl => 'How confident do you feel with your look?';

  @override
  String get frageMakeupErgebnis =>
      'How well is your everyday look working now?';

  @override
  String get einordnungMakeup =>
      'A new look takes a few tries — after two or three weeks it becomes second nature.';

  @override
  String get moduleEinleitungOhneBart =>
      'Face and hair are always included. Everything else is up to you — and you can add more later.';
}
