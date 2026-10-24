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
Console. The app cannot elevate its own role. Deploy the rules with
`firebase deploy --only firestore:rules`; they were deployed to the configured
classroom project on 2026-10-24. The Firebase Emulator could not be run on the
current machine because Java is unavailable, and the emulator device
disconnected before a post-deploy app-level permission smoke test. Run the
Rules tests in an environment with the Emulator before relying on them. This
single-host classroom model still needs review before real customer data is
used. Do not put a service-account key or Gemini key in the repository. The
Flutter Firebase client config is not a service-account credential, but must
remain associated with the intended Firebase project.

Firebase network behavior is not covered by `flutter test`; tests run without
Firebase initialization. A disposable Firebase Auth sign-up plus Firestore
profile create/read smoke test passed on 2026-10-24. A cleanup request was sent
for the temporary account, but deletion was not independently verified. On
2026-10-24, the Firebase debug APK built and opened HHL Stay through Explore on
the Medium Phone emulator; the app process had no Flutter crash, Firestore
permission-denied, or timeout log in that smoke run. The same day, a local
release APK also rendered the landing screen. During later Android checks the
host machine ran critically low on RAM while Gradle optimized a release build;
the emulator reported Android System UI/Phone service ANRs while the HHL Stay
screen remained rendered. The Firebase release build was stopped before
completion to avoid further host memory pressure. This separates a successful
app-level smoke from an unstable emulator/host session; it is not a full
concurrency/security or multi-device acceptance test. The app keeps a local
cache and does not yet implement a durable offline queue or conflict resolution.
