# TeamPulse (B4X)

Native **B4A / B4XPages** rewrite of the TeamPulse web app (Google AI Studio export). Same Firebase project and Firestore document shapes so the web and Android clients can share data.

**Not an import** — layouts and logic are rebuilt in B4X. AI / Gemini features from the web app are intentionally omitted. **Stats are included.**

## What’s in this repo

| Path | Purpose |
|------|---------|
| [`TeamPulse/`](TeamPulse/) | B4A project (open `TeamPulse.b4a` in B4A) |
| [`docs/SCHEMA.md`](docs/SCHEMA.md) | Firestore collections & fields |
| [`docs/B4A_SETUP.md`](docs/B4A_SETUP.md) | IDE, Firebase, named database notes |
| [`reference/`](reference/) | Original web types, `dbService`, blueprint, zip |

## Features (v1)

- Email/password login (+ Google Sign-In hook)
- Clubs (TEAM / SOCIAL), invite codes, members/roles
- Matches, availability, formation pitch, tactical lineup
- Substitution planner (ported from web)
- Live feed: score, goals, subs, cards, HT/FT
- Stats: W/D/L, GF/GA, player goals/assists/apps/cards/POTM

## Open in B4A

1. Install [B4A](https://www.b4x.com/b4a.html) with Android SDK and **B4XPages**.
2. Enable Firebase libraries (FirebaseAuth, FirebaseAnalytics) and place `google-services.json` in `TeamPulse/Files/` (see setup doc).
3. Open `TeamPulse/TeamPulse.b4a`, resolve libraries, compile to device/emulator.

This cloud environment **cannot compile B4X**; develop and run on Windows with B4A.

## Firebase

- Project: `gen-lang-client-0447702787`
- **Named Firestore DB** (required): `ai-studio-5af61b00-360c-4924-838f-431be734b14d`
- Auth: Email/Password + Google (enable both in console; add Android SHA-1 for Google)

Config constants live in [`TeamPulse/modConfig.bas`](TeamPulse/modConfig.bas).

## Module map

```
Login → Dashboard → Clubs / Matches / Stats
                 ↘ ClubMembers
Matches → MatchPrep (lineup + sub plan) → LiveFeed
```

Shared: `modFirebase`, `modAuth`, `modDb`, `modFormations`, `modSubPlanner`, `modStats`, `modAppState`.
