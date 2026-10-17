# B4A setup for TeamPulse

## Prerequisites

- Windows PC with [B4A](https://www.b4x.com/b4a.html) (recent version with B4XPages)
- Android SDK configured via B4A SDK Manager
- Java JDK as required by your B4A version
- Network access to your Supabase project

## Folder layout

```
TeamPulse/
  B4A/
    TeamPulse.b4a          ← open this in B4A (Windows)
    Files/
  B4i/
    TeamPulse.b4i          ← open this in B4i (Mac or hosted builder)
    Files/
  B4XMainPage.bas
  Page*.bas / mod*.bas     ← shared by both projects
  Shared Files/
```

## Libraries

Enable in Libraries Manager:

- Core, XUI, **B4XPages**, **B4XCollections**, XUI Views
- **JavaObject**, **JSON**
- OkHttpUtils2 (optional; current client uses HttpURLConnection)
- **xCustomListView**

Firebase libraries are **not** required (auth is Supabase). Do not enable FirebaseAnalytics/FirebaseAuth or their manifest macros unless you add a real `B4A/google-services.json` from the Firebase console.

## Supabase config

Defaults in [`TeamPulse/modConfig.bas`](../TeamPulse/modConfig.bas) match `teampulse-app` (`lib/supabase.ts`):

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Change those constants if you point at another project. Auth uses email/password against Supabase Auth; session tokens are stored in the app folder (`File.DirInternal` on Android, `File.DirDocuments` on iOS).

## Reference source

Behaviour and schema are based on a **read-only** copy of [johnleeson/teampulse-app](https://github.com/johnleeson/teampulse-app) under [`reference/`](../reference/). Do not modify the separate `teampulse-app` working tree when developing this B4X app.

## First run checklist

1. Open `TeamPulse/B4A/TeamPulse.b4a` — Modules tab must include **B4XMainPage** and **modSupabase**
2. Libraries: B4XPages, B4XCollections, JSON, JavaObject, xCustomListView
3. Tools → Clean Project, compile, install
4. Sign up with email (ensure Email provider is enabled in Supabase Auth)
5. Create a TEAM club → note invite code
6. Add members → create match → confirm availability → set formation → Go Live
7. Log goals → End match → open Stats

## iOS (B4i)

B4i does not compile on Windows. Open `TeamPulse/B4i/TeamPulse.b4i` on a Mac, or use the hosted builder.

Libraries: iPhone, iHttp, iHUD, iMedia, JSON, XUI, XUI Views, B4XPages, B4XCollections, xCustomListView.

Signing is not stored in the project. Set the certificate and provision profile in the B4i IDE before you compile.

The project already includes `NSPhotoLibraryUsageDescription` (“Attach a photo to a match event.”) so event photos can use the photo library. App Transport Security stays on; Supabase is HTTPS, so no ATS exception is required. No `google-services` file is used.
