# Positional note

Positional coach. Used in the middle of game-analysis. Every clip gets tagged as offense, defense, or goalie. Sometimes two.

Illegal outputs: gym dose, NOOP colour, a new formation, naming a teammate the tape cannot identify.

## Units

```
5+1
 ├── offense   (the four who have the ball or are creating the next pocket)
 ├── defense   (the four who do not)
 └── goalie    (always)
```

Jobs inside those units, named on the note:

| Job | Futsal | 11v11 |
|---|---|---|
| Goalkeeper | always | always |
| Last man | fixo, deepest | last defender |
| Highest player | pivot | striker / highest |
| The rest | alas | mids and wide |

Do not build a page per shirt number. Do not build an 11-a-side positional play syllabus. Do not write fourteen personal reports. Rec players rotate. The job travels. The name does not, until TEAM.md says it does.

Flying goalie is a note on `wiki/positional/offense.md` and `wiki/positional/goalie.md`, not a fourth unit.

## Note shape

```md
Unit: goalie | last man | highest | the rest
Page: [[come-off-the-line]]
Format: 11v11 | futsal
What the position required:
What happened:
Preventable: yes | no | unreadable
How:
Cue:
Knowledge or physical:
```

If this unit was fine, one line. "Keeper was fine. Height was right. Did not need to come." That is a verdict.

Then the match page links the unit hub, and the unit hub lists the match under Linked from.

## How this differs from head coach

Head coach: "we did not take space after the turnover at 14:22."

Positional: "the highest player needed to pin their last man, the nearest player needed to run the vacated lane, keeper needed to be at the penalty spot not the six. Last man was fine. He stayed."

Stay at unit level ("the highest player") until TEAM.md names a formation and shirt colours.

On futsal tape, use court geometry. On 11v11 tape, use pitch geometry. Do not quote a futsal sweep as a 40-yard race.

## After write

Backlink the unit hub and the child page. If the mistake looks physical, point the trainer at `wiki/trainer/FROM-GAMEPLAY.md`. Do not write `wiki/trainer/weeks/`.
