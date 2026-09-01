# Coach Popovich

This is the coach a rec team could not hire. It is not a finished product.

One Hermes agent. Three jobs. A linked wiki it reads and writes. Futsal is the game. Soccer is the season. Recovery is pasted, never scraped from an API. Match video never enters git.

Not affiliated with Gregg Popovich, the San Antonio Spurs, or the NBA.

MIT licensed. Fork it, point it at your own team, improve the detectors.

## What it does

| Job | Owns |
|---|---|
| Head coach | Shared picture, match plan, game analysis, team learnings, pro cases |
| Positional coach | Futsal 5+1 as three units only: offense, defense, goalie |
| Personal trainer | One athlete + NOOP + the tape. What to load this week because of how they actually played |

The agent does not spawn other coaches. Workflows in `workflows/` are how this one agent writes to `wiki/`.

`wiki/knowledge/` is how the game is played. Doctrine is what this team does. The agent loads one knowledge page when it needs to name a pattern, then closes it. It does not dump the library into a coaching answer.

After a match the chat reply is the coaching: unit, picture, preventable, cue. Not a detector count.

## What it does not do

- Computer vision as a product. This is ffmpeg, still frames, and a model that reads images. The detectors find scene cuts and loud audio. **They cannot see a turnover** — no filter knows who has the ball, so the model still reads the frames and reports what it thinks it missed.
- A NOOP or WHOOP API. Paste a day's rollup. Do not open the app.
- Medical advice.
- Live pitchside.
- An 11-a-side positional play course.
- A team gym program.
- Match video on GitHub.

Missed turnovers and fuzzy keeper reads are expected. Ship anyway.

## Run it

ffmpeg is required for the laptop path.

```
git clone <this-repo>
cd coach-popovich
brew install ffmpeg          # macOS
./scripts/doctor.sh          # can this checkout run the pipeline?
```

`doctor.sh` checks dependencies, layout, and the wiki link graph, then tells you what to do next. Run it first.

Open the folder as the Hermes workspace so `AGENTS.md` loads, then load `SKILL.md`.

Optional, so the skill triggers from other chats without leaving this wiki behind:

```
mkdir -p ~/.hermes/skills/sports
ln -s "$(pwd)" ~/.hermes/skills/sports/coach-popovich
```

Do not copy anything into `~/.hermes/SOUL.md`. That would hijack every other job on the machine.

Two runtimes, both honest:

- **Laptop.** File in `media/matches/`. `scripts/` run. Frames get reviewed. Default.
- **Chat-only.** Timestamps or already-cut clips. Degraded. The agent must say so.

ffmpeg is required for the laptop path. `brew install ffmpeg` on a Mac.

After a match, AirDrop or Files the tape into `media/matches/`. Name it `YYYY-MM-DD-opponent.mp4`. Then say "review this game."

## Capture

Bird's-eye. High, looking down, both boxes and both touchlines in frame. iPhone, landscape, locked AE/AF, 1080p 30fps, same spot every week. Chest-high sideline tripod is not this. Take-space notes from that angle will be wrong.

## Recovery data

`wiki/noop/logs/` holds pasted daily numbers. NOOP is just the app this fork happens to read from; nothing in the pipeline depends on it. Any source works — a WHOOP or Garmin export, an Oura screenshot, or how you actually feel written in a sentence.

The only thing the trainer needs is recovery, strain, sleep and hours to the next match. The single interpretation table is `wiki/trainer/PROTOCOL.md`, and it converts that into dose, never into a diagnosis.

`workflows/trainer-week.md` refuses if the newest log is over 36 hours old. That is deliberate. A week written on last Saturday's recovery is worse than no week.

## Public vs local

`wiki/team/TEAM.md`, `PLAYERS.md`, `KEEPER.md`, and `wiki/trainer/PROFILE.md` in git are templates. Real names go in the gitignored `*.local.md` files if anyone on the team did not agree to be named.

## Verify it works

```bash
./scripts/doctor.sh          # dependencies, layout, wiki graph
./scripts/smoke-test.sh      # synthetic match, asserts timestamps are correct
```

The smoke test builds a video with scene cuts at known times and checks that a still named `t45s` is genuinely from 0:45. If timestamps drift, every coaching note becomes fiction, so this is the test that matters.

## Help make it better

See [CONTRIBUTING.md](CONTRIBUTING.md). The useful work is better turnover detection, a second-camera keeper cut, more pro cases with public timestamps, and generated backlinks. Personality, wiki shape, and the three-job split are already decided.

## Layout

```
SKILL.md          the agent
AGENTS.md         workspace rules (loads when this folder is the workspace)
workflows/        six jobs
scripts/          ffmpeg + wiki tooling
wiki/             linked memory
media/matches/    local video, gitignored
```

| Script | Job |
|---|---|
| `doctor.sh` | can this checkout run the pipeline |
| `ingest.sh` | probe a file, print the match stub |
| `split-parts.sh` | five equal windows after kickoff, no re-encode |
| `sample-frames.sh` | frames, contact sheets, scene cuts, audio peaks, `candidates.tsv` |
| `cut-moment.sh` | short clip plus stills around one timestamp |
| `wiki.py` | `check`, `backlinks`, `index`, `sync` |

Frames and clips are named by absolute match time, so a coaching note can always cite a real minute.

Backlinks are generated, not hand-written. `python3 scripts/wiki.py sync` derives every `Linked from` block and rebuilds `wiki/INDEX.md` from the real link graph, then `check` exits non-zero on a broken link. Hand-maintained backlinks rot in a week.
