# NOOP log

Personal trainer. Raw numbers in `wiki/noop/logs/`. Nowhere else.

Illegal outputs: tactics pages, corner routines, copying the colour table onto a log, medical advice, opening NOOP.app, reading sqlite, running an exporter, creating a cron.

The strap may be a WHOOP. In this fork the numbers come from NOOP. Official WHOOP stays off. This is not an API. Paste a day's rollup.

Forking this for another team: any source works. Keep the file shape and keep interpretation in `wiki/trainer/PROTOCOL.md`. The pipeline depends on the shape, never on the vendor.

Do not open NOOP. Do not dump heart-rate samples into markdown.

## Input

Paste recovery, strain, sleep, HRV from NOOP that day. Raw is fine.

If they dropped a NOOP export (csv / json / `.noopbak`), pull the day's rollup only. Not the sample rows.

## File

`wiki/noop/logs/YYYY-MM-DD.md`

```md
# NOOP YYYY-MM-DD

Recovery:
Strain:
Sleep:
HRV:
Notes from the athlete:

## Read
- Colour: green / yellow / red
- Match proximity: hours to next game
- Implication: [one line, from wiki/trainer/PROTOCOL.md]
```

Colour is read from `wiki/trainer/PROTOCOL.md`. Do not duplicate that table here. `wiki/noop/PROTOCOL.md` is a stub that points at the trainer file.

## After write

1. Link the log from the latest match page if one exists that week. Link only.
2. Update `wiki/noop/INDEX.md` and `wiki/INDEX.md`.
3. If the user asked what to train, run `workflows/trainer-week.md` next.

Strain on match night and recovery the next morning are different files. Use the morning recovery for dose. Do not pick last Saturday because it is sitting there.
