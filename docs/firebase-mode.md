# Firebase mode — HHL Stay

Firebase setup is opt-in so the existing offline classroom demo remains
deterministic. FlutterFire configuration targets the class project
`hhl-stay-home-2026-23010895` for Android and Web.

```powershell
flutter run -d chrome --dart-define=HHL_USE_FIREBASE=true
flutter build web --dart-define=HHL_USE_FIREBASE=true
flutter build apk --debug --dart-define=HHL_USE_FIREBASE=true
```

The opt-in mode initializes Firebase Core, uses Firebase Authentication for
email/password registration and login, stores account profiles in `users`,
loads public homestay, room, and review data, and merges bookings into the local
cache. Guests only query their own bookings; hosts load bookings and management
collections. Domain changes write back to their Firestore collections. Local
SharedPreferences remains the working cache; a full offline queue/conflict
resolver is not implemented.

`firestore.rules` now allows public reads only for the homestay catalog and
reviews, limits guest booking reads/cancellation to the signed-in guest, and
reserves finance, staff, and catalog writes for users whose `users/{uid}`
profile has the `host` role. A new Firebase account can only create a `guest`
profile; a project administrator must grant the `host` role through Firebase
Console. The app cannot elevate its own role. Firestore Rules are covered by
automated Emulator tests for guest and host access, booking creation/cancellation,
review eligibility, and finance/staff restrictions. Run them from the repo root:

```powershell
npm ci --prefix tool/firestore-rules-tests
.\tool\run_firebase_emulator_tests.ps1
```

The Emulator uses port 8180 because port 8080 is occupied by another local
service. Seven rule-test groups passed on 2026-10-25. Firestore Rules were
deployed to the class project on 2026-10-25 after the emulator suite passed.
New booking documents carry `checkInEpochMillis` so the rules enforce the
24-hour cancellation cutoff for confirmed stays. Legacy confirmed bookings
without that field cannot be cancelled by guests through Firebase; hosts can
still process them. Deploy reviewed rules with
`firebase deploy --only firestore:rules`. This single-host classroom model
still needs review before real customer data is used. Do not put a
service-account key or Gemini key in the repository. The Flutter Firebase
client config is not a service-account credential, but must remain associated
with the intended Firebase project.

`flutter test` does not initialize Firebase. A disposable live Firebase Auth
sign-up and Firestore profile smoke test passed on 2026-10-24; cleanup of that
historical account was not independently verified. The 2026-10-24 Medium Phone
startup check covered Firebase initialization and public catalog loading only.
Current Firebase integration evidence is the local emulator suite described
below; a full end-to-end acceptance run against the live project has not been
performed. The Android Firebase debug APK builds successfully but has not been
installed on a device. A separate localhost web smoke test confirmed one live
Gemini response; Android Gemini is not verified. This is not a full
concurrency/security or multi-device acceptance test. The app keeps a local
cache and does not yet implement a durable offline queue or conflict resolution.

### Local Auth + Firestore Emulator workflow

The app can point both Firebase clients at local emulators without changing
the production project configuration. Start the Auth and Firestore emulators
in one terminal, then launch the web build in another:

```powershell
# First terminal: run the complete disposable Auth + Firestore test suite.
.\tool\run_firebase_emulator_tests.ps1

# For manual localhost Web testing, configure JAVA_HOME to the JBR path
# reported by `flutter doctor -v`, then run:
firebase emulators:start --only auth,firestore --project demo-hhl-stay-rules

# Second terminal, for localhost Web testing
flutter run -d chrome `
  --dart-define=HHL_USE_FIREBASE=true `
  --dart-define=HHL_USE_FIREBASE_EMULATORS=true `
  --dart-define=HHL_FIREBASE_EMULATOR_HOST=127.0.0.1
```

For Android Emulator, use `HHL_FIREBASE_EMULATOR_HOST=10.0.2.2` so the app can
reach the host computer. Never enable the emulator flag in a production build.
The test helper locates Java from Flutter/Android Studio when it is missing from
PATH and runs both emulator services. No live project data is created.

On 2026-10-25, all 8 test groups passed, including an Auth emulator sign-up,
guest profile creation, guest booking write/read, host confirmation and finance
write, and rejection of guest role escalation/finance access. The Node test
toolchain uses Firebase 13.1.0 and Rules Unit Testing 6.0.0; `npm audit`
reported 0 vulnerabilities after pinning the compatible gRPC dependency to
1.14.6. These checks prove emulator behavior, not access to the live Firebase
project or Android device acceptance.
