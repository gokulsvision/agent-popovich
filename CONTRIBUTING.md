# Contributing

Fork it. Point it at your team. Improve the detectors. Open a PR.

This is an MVP. Missed turnovers and fuzzy keeper reads are expected. That is the work.

## Wanted

- Better turnover detection on amateur tape (scene filter thresholds, audio peaks, vision tags)
- Second-camera keeper cuts (bird's-eye stays for the team picture)
- Pro cases with a public URL and a start time you can click. Use `wiki/pro/_template.md`. No URL, no page.
- Detector precision on real amateur tape. `candidates.tsv` is a starting point, not a solved problem
- Other sports forks, as long as they keep one agent and three jobs

## Not wanted

- A fourth unit (midfielder, flying goalie as its own hub)
- Match video in git
- A NOOP or WHOOP API as a v1 requirement
- Live pitchside
- New doctrine pages with fewer than two inbound links
- Rewriting TEAM.md with a real roster in a public PR
- Medical advice on NOOP pages
- Personality rewrites that turn this into a pep talk

## How a page is finished

Every wiki page ends with **Links out** and **Linked from**. Canonical slugs live in `wiki/INDEX.md`. If you add a page that duplicates `taking-space` or `rest-defence` or `PROTOCOL`, make it a stub that points at the canonical file.

## Before you open a PR

```bash
./scripts/smoke-test.sh      # builds a synthetic match, asserts timestamps
python3 scripts/wiki.py check
```

The smoke test builds a 60-second video with scene cuts at known times and checks that a frame named `t45s` really is from 0:45. It exists because the first version of this repo shipped a scene detector that discarded every timestamp and a contact sheet that silently covered only the first 100 seconds of an 18-minute part. Both looked fine in the output. Neither was.

If you touch anything in `scripts/`, run it.

## How a detector change lands

Put ffmpeg in `scripts/`. Do not paste a new recipe into a match note. Add a short note to `workflows/game-analysis.md` if the pipeline stages change. Prefer recall over precision at the candidate stage. The review stage cuts.

## License

MIT. You keep your work. The team keeps the wiki.
