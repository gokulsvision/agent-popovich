# Game analysis

Head coach. Footage in, coaching out. The match page is the last step, not the first.

Seven stages. If a stage fails, stop and name the stage. Never invent a timestamp to keep going.

**Illegal outputs:** anything under `wiki/trainer/weeks/`, a new formation, gym dose, a scored call when audio is unusable, a coached moment with no timestamp.

Set `$COACH` to the repo root first. Every path here is relative to it.

## Stage 0 — last week's rock

Read the previous match page's `## One thing to train this week` and `wiki/team/THIS-WEEK.md`.

If that theme appears on this tape, it is the first selected clip. Confirm or kill it after the merge. Do not open a new theme while last week's is unresolved.

Also read `wiki/team/GAPS.md` now. A turnover that repeats a listed gap is automatically selectable later.

## Stage 1 — ingest

Accept, in this order:

1. A file already in `media/matches/`
2. A file the user dropped into the session
3. A public URL the environment can fetch
4. Timestamps plus a description, if there is no file at all (degraded)

```bash
scripts/ingest.sh <path-or-url> YYYY-MM-DD-opponent
```

Write the stub to `wiki/analysis/matches/YYYY-MM-DD-opponent.md` from `wiki/analysis/_template.md`. Fill `source`, `duration`, `fps`, `audio`, `orientation`, `format`, `angle`, `we`, `they`, `status: analysis in progress`.

Ask for `angle` and `format`. Do not assume. Never commit the video.

## Stage 2 — index

The ingest script prints the fields. Two of them change how you coach:

- `angle: sideline` — say plainly that take-space and shape notes will be weak. A chest-high sideline shot hides depth. Do not pretend it is bird's-eye.
- `audio: no` — every call is `call: unknown`. Never score communication from a silent tape.

If the file is a 12-second clip, skip detection and treat the whole thing as one moment.

## Stage 3 — split into five parts

Do not scan 90 minutes as one blob.

```bash
scripts/split-parts.sh media/matches/YYYY-MM-DD-opponent.mp4 [kickoff-s]
```

Pass `kickoff-s` if there is warm-up on the tape. The script prints five windows and the exact `sample-frames.sh` command for each. It does not re-encode.

Create `wiki/analysis/moments/YYYY-MM-DD-opponent/` and copy `wiki/analysis/_part-template.md` to `part-1.md` through `part-5.md`.

Split on duration, never on "when things happened." Finding the moments is your job after the cut.

## Stage 4 — detectors, one part at a time

```bash
scripts/sample-frames.sh <video> wiki/analysis/moments/<slug>/part-N <start-s> <end-s>
```

Per part it writes `frames/` named by absolute match time, `sheets/` with a `MAP.tsv`, `scene.tsv`, `audio.tsv`, and the merged `candidates.tsv`.

Read `candidates.tsv`. Columns: `start_s end_s mmss source`.

What the detectors are: scene cuts fire on stoppages, restarts and camera pans. Audio peaks fire on whistles and shouts. Both are hints.

**Detectors cannot see a turnover.** No filter knows who has the ball. Scene and audio narrow where to look. You still read the contact sheets to find turnovers, and you say so in the part file's coverage block.

User marks always make the list. If they said "the fourth goal" or "around 14 minutes," that window is reviewed.

Required tags, never dropped: `goal_for`, `goal_against`, `turnover_lost`, `turnover_won`.
Other tags: `shot_on_goal`, `1v1_or_break`, `through_ball_behind`, `set_piece`, `keeper_on_ball`.

Tag and timestamp only in this stage. Do not coach yet. Prefer recall. The next stage cuts.

Load only this part's frames. Do not carry part 1 frames into part 4.

## Stage 5 — review inside the part

Windows:

| Moment | Before | After |
|---|---|---|
| Goal | 5s | 8s |
| Turnover | 3s | 6s |
| Everything else | 3s | 5s |

```bash
scripts/cut-moment.sh <video> <out-dir> <timestamp-s> <before> <after>
```

Come-or-stay is a motion judgement. Watch the clip. Never score it from one still.

Every goal and every turnover in this part gets a note on `part-N.md`, whether or not it reaches the match page.

If the tape cannot resolve it, write `unreadable`. A goal that is unreadable still gets listed with that flag. Missing a turnover is allowed. Pretending is not.

Fill the coverage block honestly, including an estimate of what you think you missed.

Keep teammate notes at unit level ("the highest player") until TEAM.md names a formation and shirt colours.

## Stage 6 — merge

Only after `part-5.md` exists.

Read the five part verdicts. Do not reread every frame.

Build: score and goal list, the turnover map, errors repeating across parts, and whether last week's theme showed up.

Write `SELECTED.md` from `wiki/analysis/_selected-template.md`.

- every goal, no cap
- turnovers that created or killed a chance, or repeat a GAP
- then the quota, skipping duplicates: 2 goalie, 2 outfield, 1 set piece

Cap the human-facing page at every goal plus five coached clips. Rec players will not use a 20-clip dossier.

## Stage 7 — coach and write

Score the decision separately from the goal.

Each selected moment:

- timestamp
- unit (O / D / GK) via `workflows/positional-note.md`
- what happened
- what the picture should have been
- cue
- knowledge or physical (if physical, point at `wiki/trainer/FROM-GAMEPLAY.md` and stop; do not write the week)

Keeper rubric, every clip: starting height against ball location, come or stay, set before the shot, call made (`call: unknown` if audio is dead).

Team rubric, every clip: did we take space that was free, did we take space that was not, did each body arrive at its corner job, how many were behind the ball when we lost it.

Attach one pro case as the picture. If none exists for that mistake, queue `workflows/pro-case.md` rather than inventing a lecture.

Then:

1. Write the match page from `wiki/analysis/_template.md`
2. Add it to `wiki/analysis/INDEX.md`
3. Add `Links out` to every doctrine and team page you cited
4. Append `wiki/team/LEARNINGS.md` if something durable was learned
5. Run `workflows/team-learning.md` on anything that showed up twice
6. Link the recovery log for that week. Link only, never copy the numbers
7. Note the `frames/` path so a human can reopen stills without rerunning ffmpeg
8. Run `python3 scripts/wiki.py sync`

## Degraded modes

| What you have | What happens |
|---|---|
| Bird's-eye full match | All seven stages. Shape notes valid. Keeper notes need clips, not stills |
| Handheld full match | All stages, but scene cuts are noisy |
| Sideline tripod | All stages. Say take-space and shape notes are weak |
| Already-cut highlights | Skip splitting. Each clip is one candidate |
| Timestamps only | Jump to stage 5 on those stamps. Say coverage is partial |
| No video | Ask for a file or stamps. Do not pretend |

## Do not

- Dump a 90-minute transcript and call it analysis
- Collapse the five parts into one prompt
- Coach from a single thumbnail
- Store match video in git
- Output 20 clips because the detector was noisy
- Cap goals on the match page
- Print 60 turnovers on the match page
- Claim live computer vision. This is ffmpeg, stills, and a model that reads images
- Paste an ffmpeg recipe into a match note. Call `scripts/`
