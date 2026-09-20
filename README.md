# TeamPulse (B4X)

Native **B4A / B4XPages** client for TeamPulse, based on [johnleeson/teampulse-app](https://github.com/johnleeson/teampulse-app) (React + Capacitor + **Supabase**).

**This repo (`teampulse-b4x`) is the B4X app only.** The web/Capacitor repo is reference material — keep it unchanged; copies live under [`reference/`](reference/).

Layouts and logic are rebuilt in B4X (not an import). Gemini / AI features from the web app are omitted. **Stats are included.**

## What’s in this repo

| Path | Purpose |
|------|---------|
| [`TeamPulse/`](TeamPulse/) | B4XPages project (open `TeamPulse/B4A/TeamPulse.b4a`) |
| [`docs/SCHEMA.md`](docs/SCHEMA.md) | Supabase tables & fields |
| [`docs/B4A_SETUP.md`](docs/B4A_SETUP.md) | IDE + Supabase setup |
| [`reference/`](reference/) | Snapshot of teampulse-app types, services, SQL, components |

## Features (v1)

- Email/password login (Supabase Auth)
- Clubs (TEAM / SOCIAL), invite codes, members/roles (incl. COACH)
- Matches, availability, formation pitch, lineup map
- Substitution planner
- Live feed: score, goals, subs, cards, HT/FT
- Stats: W/D/L, GF/GA, player goals/assists/apps/cards/POTM

## Open in B4A

1. Install [B4A](https://www.b4x.com/b4a.html) with Android SDK and **B4XPages**.
2. Confirm `SUPABASE_URL` / `SUPABASE_ANON_KEY` in `TeamPulse/modConfig.bas`.
3. Open **`TeamPulse/B4A/TeamPulse.b4a`**, enable **JSON** + **JavaObject**, compile.

## Backend

- Supabase project shared with teampulse-app (see `reference/lib/supabase.ts`)
- Data access: PostgREST + Auth HTTP from `modSupabase` / `modDb` / `modAuth`

## Module map

```
Login → Dashboard → Clubs / Matches / Stats
                 ↘ ClubMembers
Matches → MatchPrep (lineup + sub plan) → LiveFeed
```

Shared: `modSupabase`, `modAuth`, `modDb`, `modFormations`, `modSubPlanner`, `modStats`, `modAppState`.

Dashboard / LiveFeed poll Supabase every 10–15s while the page is visible (lightweight realtime stand-in).
