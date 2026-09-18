# B4A setup for TeamPulse

## Prerequisites

- Windows PC with [B4A](https://www.b4x.com/b4a.html) (recent version with B4XPages)
- Android SDK configured via B4A SDK Manager
- Java JDK as required by your B4A version

## Libraries

In the Libraries Manager, enable at least:

- Core, XUI, B4XPages, XUI Views, JavaObject
- FirebaseAuth, FirebaseAnalytics
- OkHttpUtils2 (optional)
- **xCustomListView** (pages call `clv.AsView` — enable the XUI Views / xCustomListView library)

Firebase Android artifacts are resolved through the Google Maven repo when `google-services.json` is present (B4A Firebase setup wizard / additional libs from [B4X Firebase](https://www.b4x.com/android/forum/threads/firebaseauth-authenticate-your-users.72446/)).

## google-services.json

1. Firebase Console → project `gen-lang-client-0447702787`
2. Add an **Android** app with package `com.teampulse.app`
3. Download `google-services.json` into `TeamPulse/Files/` (replace the `.example`)
4. Add your debug/release SHA-1 for Google Sign-In

## Named Firestore database

The web app does **not** use `(default)`. It uses:

`ai-studio-5af61b00-360c-4924-838f-431be734b14d`

`modFirebase.GetFirestoreDb` calls `FirebaseFirestore.getInstance(app, databaseId)`. If your Firebase Android SDK is too old to support named DBs, upgrade the Firebase BOM / Firestore dependency.

## Google Sign-In

`PageLogin` documents the hook: obtain an ID token from Google Sign-In, then call `modAuth.SignInWithGoogleIdToken`. Email/password works once Email/Password is enabled under Authentication → Sign-in method.

## First run checklist

1. Compile and install on a device with Google Play services  
2. Sign up with email  
3. Create a TEAM club → note invite code  
4. Add members → create match → confirm availability → set formation → Go Live  
5. Log goals → End match → open Stats  

## B4i later

Share the `mod*` modules and page logic under a B4i B4XPages project; replace Google Sign-In and `google-services` with the iOS Firebase plist equivalents.
