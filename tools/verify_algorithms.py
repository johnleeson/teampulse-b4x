#!/usr/bin/env python3
"""Verify ported TeamPulse algorithms (stats + sub planner) without B4A."""

from __future__ import annotations


def build_sub_plan(
    confirmed: list[dict],
    tactical: dict[str, str],
    positions: list[dict],
    stars: list[str],
    weaker: list[str],
    duration: int,
    interval: int,
    max_subs: int,
):
    pitch_ids = [v for v in tactical.values() if v]
    if not pitch_ids:
        return {"error": "Please assign players to the pitch first."}
    confirmed_ids = [p["id"] for p in confirmed]
    names = {p["id"]: p["name"] for p in confirmed}
    bench_ids = [i for i in confirmed_ids if i not in pitch_ids]
    gk = next((p["id"] for p in positions if p["label"] == "GK"), None)
    gk_player = tactical.get(gk or "", "")
    fixed = set()
    if gk_player:
        fixed.add(gk_player)
    for i in pitch_ids:
        if i in stars:
            fixed.add(i)
    rot_pitch = [i for i in pitch_ids if i not in fixed]
    rot_bench = [i for i in bench_ids if i not in fixed]
    if not rot_pitch and not rot_bench:
        return {"error": "No outfield players available for rotation"}
    steps = duration // interval
    if steps <= 1:
        return {"error": "Need at least 2 sub windows"}
    play = {i: 0 for i in confirmed_ids}
    for f in fixed:
        play[f] = duration
    cur_p, cur_b = list(rot_pitch), list(rot_bench)
    events = []
    for step in range(1, steps + 1):
        for i in cur_p:
            play[i] = play.get(i, 0) + interval
        if step == steps:
            break
        if cur_b and cur_p:
            sb = sorted(
                cur_b,
                key=lambda a: (play.get(a, 0), 0 if a in weaker else 1, a),
            )
            sp = sorted(
                cur_p,
                key=lambda a: (-play.get(a, 0), 0 if a not in stars else 1, a),
            )
            swap = min(len(sb), len(sp), max_subs)
            next_p, next_b = list(cur_p), list(cur_b)
            subs = []
            for i in range(swap):
                out, inn = sp[i], sb[i]
                subs.append(
                    {
                        "playerOut": out,
                        "playerIn": inn,
                        "outName": names[out],
                        "inName": names[inn],
                    }
                )
                next_p[next_p.index(out)] = inn
                next_b[next_b.index(inn)] = out
            cur_p, cur_b = next_p, next_b
            events.append({"minute": step * interval, "subs": subs})
    return {"events": events, "playTimes": play, "fixed": list(fixed)}


def compute_stats(club, matches, events, selected="all"):
    cid = club["id"]
    is_team = club.get("type", "TEAM") == "TEAM"
    club_matches = [
        m
        for m in matches
        if m["clubId"] == cid
        and m["status"] == "COMPLETED"
        and (selected in ("all", "") or m["id"] == selected)
    ]
    wins = draws = losses = gf = ga = 0
    players = {
        m["id"]: {
            "id": m["id"],
            "name": m["name"],
            "goals": 0,
            "assists": 0,
            "apps": 0,
            "potmWins": 0,
            "yellowCards": 0,
            "redCards": 0,
        }
        for m in club["members"]
    }
    for m in club_matches:
        sa, sb = m.get("scoreA", 0), m.get("scoreB", 0)
        if is_team:
            club_score, opp = (sa, sb) if m.get("isHome", True) else (sb, sa)
            gf += club_score
            ga += opp
            if club_score > opp:
                wins += 1
            elif club_score == opp:
                draws += 1
            else:
                losses += 1
        else:
            gf += sa + sb
        for uid, av in m.get("availability", {}).items():
            if av == "CONFIRMED" and uid in players:
                players[uid]["apps"] += 1
        votes = m.get("potmVotes", {})
        if votes:
            counts = {}
            for v in votes.values():
                counts[v] = counts.get(v, 0) + 1
            winner = max(counts, key=counts.get)
            if winner in players:
                players[winner]["potmWins"] += 1
    mids = {m["id"] for m in club_matches}
    for e in events:
        if e["matchId"] not in mids:
            continue
        d = e.get("details", {})
        if e["type"] == "GOAL":
            if d.get("scorer") in players:
                players[d["scorer"]]["goals"] += 1
            if d.get("assist") in players:
                players[d["assist"]]["assists"] += 1
        if e["type"] == "YELLOW_CARD" and d.get("player") in players:
            players[d["player"]]["yellowCards"] += 1
        if e["type"] == "RED_CARD" and d.get("player") in players:
            players[d["player"]]["redCards"] += 1
    return {
        "wins": wins,
        "draws": draws,
        "losses": losses,
        "goalsFor": gf,
        "goalsAgainst": ga,
        "players": sorted(players.values(), key=lambda p: -p["goals"]),
    }


def main():
    positions = [
        {"id": "gk", "label": "GK"},
        {"id": "cb", "label": "CB"},
        {"id": "st", "label": "ST"},
    ]
    squad = [{"id": f"p{i}", "name": f"P{i}"} for i in range(1, 6)]
    tactical = {"gk": "p1", "cb": "p2", "st": "p3"}
    plan = build_sub_plan(squad, tactical, positions, ["p1"], [], 60, 15, 2)
    assert "error" not in plan, plan
    assert len(plan["events"]) >= 1
    assert plan["playTimes"]["p1"] == 60  # GK fixed via star+gk

    club = {
        "id": "c1",
        "type": "TEAM",
        "members": [{"id": "p1", "name": "Ada"}, {"id": "p2", "name": "Bea"}],
    }
    matches = [
        {
            "id": "m1",
            "clubId": "c1",
            "status": "COMPLETED",
            "scoreA": 2,
            "scoreB": 1,
            "isHome": True,
            "availability": {"p1": "CONFIRMED", "p2": "CONFIRMED"},
            "potmVotes": {"x": "p1"},
        }
    ]
    events = [
        {
            "matchId": "m1",
            "type": "GOAL",
            "details": {"scorer": "p1", "assist": "p2"},
        }
    ]
    stats = compute_stats(club, matches, events)
    assert stats["wins"] == 1 and stats["goalsFor"] == 2 and stats["goalsAgainst"] == 1
    assert stats["players"][0]["id"] == "p1" and stats["players"][0]["goals"] == 1
    assert stats["players"][0]["potmWins"] == 1
    assert next(p for p in stats["players"] if p["id"] == "p2")["assists"] == 1
    print("OK: sub planner and stats algorithms verified")


if __name__ == "__main__":
    main()
