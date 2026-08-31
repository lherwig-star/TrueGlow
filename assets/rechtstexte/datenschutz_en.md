# Privacy Policy

> **DRAFT — not yet reviewed by a lawyer.**
> This text describes the data flows of the app as they can be traced in the
> source code. It is meant as a working basis for legal review and is **not
> yet binding**. Before release in the stores it must be reviewed and the
> text version raised to one without "-entwurf".

**As of:** 31 August 2026 · **Text version:** 1-entwurf

---

## 1 · Who is responsible

The controller for the processing of your data under the General Data
Protection Regulation (GDPR) is:

> **[NAME OF THE CONTROLLER]**
> [STREET AND NUMBER]
> [POSTCODE AND CITY]
> [COUNTRY]
> Email: [CONTACT EMAIL]

For any question about data protection, write to the address above.

No data protection officer has been appointed; the conditions requiring one
are not met.

---

## 2 · What this app does

TrueGlow takes photos you have taken yourself and produces an assessment of
grooming and style, plus a plan of daily tasks. A Google AI service is used
to analyse the photos.

The app is for **people aged 18 and over**.

TrueGlow gives no medical information, makes no diagnoses and awards no
scores.

---

## 3 · Your photos — the most important point

Because they are the most sensitive data, they come first.

**Where your photos live.** Only on your device, in a directory only this app
can reach. They are **not** uploaded to a cloud and **not** stored
permanently on our servers.

**They are excluded from backups too.** The app is configured so that Android
does not include them in the automatic Google backup or in a device
transfer.

**What happens during an analysis.** When you start an analysis, the photos
needed for it are sent to our own server (Google Cloud Functions, Frankfurt)
and passed straight on to the AI service **Google Gemini**. On our server
they only pass through memory: they are not stored, not written to any log,
and discarded after the call.

**Processing at Google also takes place outside the European Union** (third
country transfer). The legal basis is your explicit consent under Art. 49(1)
(a) GDPR, which you give before the first photo and can withdraw at any
time.

**Progress photos** from the check-ins also stay on your device. They leave
it only when a results check explicitly asks for a before/after comparison —
and then the same applies as above.

**What that means for you:** If you uninstall the app or clear its data on
the device, your photos are gone for good. We cannot restore them, because we
never had them.

---

## 4 · What else we process

### 4.1 Account

You need an account to start an analysis. You can choose:

- **Sign in with Google**
- **Sign in with Apple**
- an **anonymous account** — no name, no email address

This involves an identifier issued by Firebase, the time of sign-in and —
depending on the method — your email address and display name. **There are no
passwords**; the app offers no email-and-password sign-in.

*Legal basis: performance of a contract (Art. 6(1)(b) GDPR).*

### 4.2 Your answers and results

Stored in your account:

| What | Example |
|---|---|
| Answers from the intro | age range, budget, time per day, focus areas, gender information |
| Your direction | chosen style directions and your free-text message to the coach |
| Module selection and extra details | height, weight, style questionnaire |
| Your analyses | the finished reports as text |
| Your check-ins | your answers and the plan changes derived from them |
| Your progress | which tasks you ticked on which day, streak, jokers |
| Record of consent | when and for which text version you agreed |
| Usage counters | how many analyses you started on a day and in a month |

**Where:** in Google Firestore, region **europe-west3 (Frankfurt)**.
Image data is technically excluded there — a document containing an image
field is rejected by the access rules.

**Who may access it:** only your own account. The access rules are set so
that another account can neither read nor write; this is tested
automatically with every change.

*Legal basis: performance of a contract (Art. 6(1)(b) GDPR).*

### 4.3 Crash reports and usage statistics — only with your consent

If you agree, we use:

- **Firebase Crashlytics** for crash reports (technical details about the
  device and the point in the program where it failed),
- **Firebase Analytics** for a small number of events.

The event list is exhaustive and carries **no parameters** — only the fact
*that* a step was reached is recorded:

`onboarding_abgeschlossen`, `anmeldung_abgeschlossen`, `analyse_gestartet`,
`analyse_fertig`, `plan_geoeffnet`, `checkin_gestartet`,
`checkin_abgeschlossen`.

No content of your analysis, no free text, no profile details and no photos
are transmitted. The device's **advertising ID is explicitly not used**; it
is switched off in the app.

If you do not agree, nothing is collected in the first place — not
"collected but not sent".

*Legal basis: consent (Art. 6(1)(a) GDPR), withdrawable at any time in the
settings.*

### 4.4 Technical logs

Our servers write logs so that faults can be found. They contain the time,
the type of call, error messages and the number of computing steps used.
**Photos, email addresses, names and your free texts are not in them.** In
individual lines the identifier of your account may appear.

Logs are deleted automatically after **30 days**.

*Legal basis: legitimate interest in secure operation (Art. 6(1)(f) GDPR).*

---

## 5 · Who we use

| Service | For what | Where |
|---|---|---|
| **Google Firebase** (Auth, Firestore, Cloud Functions, App Check) | account, storage, server functions | Frankfurt (europe-west3) |
| **Google Gemini** | analysis of the photos | Google servers, also outside the EU |
| **Firebase Crashlytics / Analytics** | crash reports, statistics | only with consent |

The provider in each case is Google Ireland Limited or Google LLC. For
processing outside the EU we rely on your consent and on the standard
contractual clauses used by Google.

**There are no advertising networks, no cross-app tracking and no sale of
data.**

---

## 6 · How long we keep things

- **Photos:** until you delete them — they only exist on your device.
- **Account data, analyses, check-ins, progress:** until you delete them or
  close your account.
- **Record of consent:** as long as the account exists.
- **Usage counters:** rolling; they reset monthly and deliberately survive a
  data deletion (see section 8).
- **Server logs:** 30 days.

---

## 7 · Your rights

You have the right to:

- **Access** (Art. 15 GDPR) — in the app under *Settings → Download my data*.
  You get a readable file containing everything stored for your account.
- **Data portability** (Art. 20 GDPR) — the same file is machine-readable
  JSON.
- **Rectification** (Art. 16 GDPR) — your answers can be changed in the app.
- **Erasure** (Art. 17 GDPR) — in the app under *Settings*, either just the
  contents or the whole account.
- **Restriction and objection** (Art. 18, 21 GDPR).
- **Withdrawal of any consent** (Art. 7(3) GDPR) — in the settings. The
  withdrawal takes effect immediately; processing that was lawful before it
  is unaffected.
- **Complaint to a supervisory authority** (Art. 77 GDPR).

---

## 8 · What happens when you delete

**"Delete all data"** removes your entire data area on the server: profile,
direction, modules, analyses, check-ins, progress. The account itself
remains.

**"Delete account"** additionally removes the account. After that, signing in
with the same credentials creates a **new** account. Because this step cannot
be undone, it requires a fresh sign-in.

**Photos** are on your device and are deleted there — through the app or by
removing the app.

**One exception, and we name it explicitly:** the counter of how many
analyses you started this month is kept. It contains nothing about you beyond
two numbers and a date — no content, no answers, no result. It stays because
otherwise repeated deletion would reset it, and the limit that protects us
from unbounded cost would be worthless.

*Legal basis for this exception: legitimate interest in preventing abuse
(Art. 6(1)(f) GDPR).*

---

## 9 · Security

- Access to your data is limited to your account; the rules for this are
  tested automatically.
- Every server call is secured twice: by your account **and** by a check that
  the call comes from a genuine installation of the app.
- The key for the AI service exists only on the server and is not contained
  in the app.
- All connections are encrypted.

---

## 10 · Changes to this policy

If something material changes, we raise the text version. The app then asks
for your agreement again before you continue.
