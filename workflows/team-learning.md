# Team learning

Head coach. The agent posts team abilities and builds the next plan from them.

Illegal outputs: gym dose, NOOP numbers copied onto STRENGTHS / GAPS, a new system that fights a listed strength.

## When it runs

- After game-analysis
- When you say "we are actually good at X"
- When a pattern shows up twice

## Where it writes

### `wiki/team/STRENGTHS.md`

Claims only. Each claim has evidence links.

```md
## High work rate when chasing
Evidence: [[2026-09-07-united]] 60+, [[2026-08-20-city]]
Do not coach this. Protect it.
```

### `wiki/team/GAPS.md`

Same shape. Current known gaps to seed:

- Keeper starting height when the ball is in the middle third
- Come / stay on a fast break
- When and how the team takes space
- Corners, attacking and defending

A gap that did not show for five matches gets demoted, not deleted. Note the date.

### `wiki/team/LEARNINGS.md`

Append-only. Dated. One bullet, one link. Archive. Do not load the whole file into a coaching pass.

```md
- 2026-09-07 — Back line drops as a block on turnover. Space in front dies. See [[2026-09-07-united]] [[taking-space]]
```

### `wiki/team/KEEPER.md`

The named keeper only. Tendencies, not a biography. Public repo uses the template. Real name lives in `KEEPER.local.md` if needed.

### `wiki/team/THIS-WEEK.md`

Overwrite each week. This is the page a human takes to the pitch.

Last week's cue stays this week's cue until the tape shows it landed.

## So what

The workflow ends with a block the agent must fill:

```md
## Build from this
Train this week: [the gap that showed up most]
Use this strength to hide that gap: [e.g. work rate covers a slow step-up]
Do not install a new system that fights a listed strength
Last week's theme: confirmed / killed / still open
```

Then write `wiki/team/THIS-WEEK.md`:

- One theme
- Two team sessions and one GK session around the match
- Cue in one sentence
- What we are not installing this week

If NOOP for this week is missing or older than 36 hours, write the theme anyway and leave dose to trainer-week. Do not guess recovery.

## Monthly compact

After five new matches, rewrite STRENGTHS and GAPS from those five plus the current claims. Do not rebuild them from the whole LEARNINGS log.
