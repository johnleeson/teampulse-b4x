# Firestore schema (TeamPulse)

Named database id: `ai-studio-5af61b00-360c-4924-838f-431be734b14d`

## Collections

### `profiles/{userId}`

| Field | Type |
|-------|------|
| name | string |
| avatar | string |
| roles | string[] (`ADMIN`, `PLAYER`, `SPECTATOR`) |
| age, gender, favPosition, kitSize | string (optional) |

### `clubs/{clubId}`

| Field | Type |
|-------|------|
| name, logo, description | string |
| type | `TEAM` \| `SOCIAL` |
| ownerId | string |
| inviteCode | string |
| ageGroup, gender, teamPhoto | optional |

### `club_members/{clubId_userId}`

| Field | Type |
|-------|------|
| clubId, userId | string |
| roles | string[] |
| abilityRating | number (optional) |

### `matches/{matchId}`

| Field | Type |
|-------|------|
| clubId, title, date, meetTime, kickOffTime, location | string |
| status | `UPCOMING` \| `LIVE` \| `COMPLETED` \| `CANCELLED` |
| scoreA, scoreB | number |
| teamA, teamB, signedUpPlayerIds, startingLineupIds, benchIds, starPlayerIds, weakerPlayerIds | string[] |
| availability | map userId → `CONFIRMED` \| `UNAVAILABLE` |
| opponentName, isHome | string / bool |
| potmVotes | map voterId → playerId |
| managerSummary | string (plain text; no AI) |
| formation | string e.g. `4-4-2` |
| tacticalLineup | map positionId → playerId |
| playerStats | map userId → {goals, assists, yellowCards, redCards, …} |

### `feed_events/{eventId}`

| Field | Type |
|-------|------|
| matchId, userId, userName | string |
| type | `GOAL`, `SUB`, `COMMENT`, `START`, `HALF_TIME`, `SECOND_HALF`, `END`, `YELLOW_CARD`, `RED_CARD`, … |
| timestamp | Firestore Timestamp |
| content | string |
| details | map (scorer, assist, playerIn, playerOut, team, …) |
| mediaUrl | optional |

## Security

Rules from the web export are in [`reference/firestore.rules`](../reference/firestore.rules). Deploy the same rules for this database; do not open writes without Auth + club membership checks.
