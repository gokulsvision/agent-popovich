# Plan

Architecture for the repo as built. Personality is filled last, in `SKILL.md` and `AGENTS.md`.

This is an MVP. Public repo. Other people should be able to fork it, point it at their own team, and improve the detectors.

## Amendments from the original architecture note

- `media/` and `scripts/` sit at repo root, not under `wiki/`. Wiki is markdown nodes only.
- One canonical page per slug. Stubs at the other paths. Map is in `wiki/INDEX.md`.
- `wiki/team/THIS-WEEK.md` is the pitch card. Team-learning writes the theme. Trainer-week writes the dose.
- TEAM / KEEPER / PLAYERS / PROFILE in git are templates. Real names go in gitignored `*.local.md`.
- Trainer-week refuses if the newest NOOP log is older than 36 hours.
- Game analysis stage 0 reads last week's theme. First selected clip is that theme if it appears.
- Every match page has `format: 11v11` or `format: futsal`.
- Each workflow lists illegal outputs so the three jobs do not bleed.
- `scripts/wiki.py` generates `wiki/INDEX.md` and every `Linked from` block from the real link graph. Break point 4 said hand-maintained backlinks rot in a week, so they are derived, not remembered.
- `scripts/split-parts.sh` computes the five windows without re-encoding video.
- `scripts/doctor.sh` tells a fresh clone whether it can run the pipeline.
- Frames and clips are named by absolute match time, so a note can always cite a real minute.
- Hermes loads `AGENTS.md` from the workspace root. Do not write `HERMES.md` (it would hide `AGENTS.md`). Do not copy identity into `~/.hermes/SOUL.md`.
- Personality is not a skippable `VOICE.md`. It is the identity section of `SKILL.md` and `AGENTS.md`, written last.

## The model

```
                         SKILL.md
                      Coach Popovich
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
   HEAD COACH          POSITIONAL             TRAINER
   match picture       offense                NOOP log
   game analysis       defense                gameplay load
   team learnings      goalie                 week dose
   pro cases
        │                    ▼                    │
        └────────────────────┼────────────────────┘
                             ▼
                     wiki/  (double-linked)
```

## v1 file set

Steps 1–7 of the original build order, plus THIS-WEEK, canonical stubs, templates, and two seed pro cases that have public URLs.

Left for the community: better detectors, second camera, a live NOOP export, generated bidirectional links as a promise, live pitchside, the rest of the pro seed set, personality polish after the first real match.

## What this is not

- Not seven separate coach agents
- Not a computer-vision product
- Not a NOOP API. Not official WHOOP. Paste the rollup.
- Not a medical file
- Not a new page for every thought
- Not a highlight-reel dump
- Not an 11-a-side positional play course
- Not a team gym program
