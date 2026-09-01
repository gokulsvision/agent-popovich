# Part N — MM:SS to MM:SS

```
match: YYYY-MM-DD-opponent
format: 11v11 | futsal
window_s:
detectors: scene, audio, user marks, vision
```

This part is its own job. Only this part's frames and candidates were loaded.

Detectors find scene cuts and loud audio. They cannot see a turnover. Everything below came from looking at the frames.

## Goals

Every goal, no cap. Unreadable still gets listed.

```
- MM:SS  goal_for | goal_against
  what happened:
  unit at fault:
  unit that did the job:
  preventable: yes | no | unreadable
  how:
  picture should have been:
  decision:
  verdict: (score the decision, not the scoreboard)
  cue:
  knowledge | physical:
  frames: frames/t<SS>s-<MM-SS>.jpg
```

_None found in this part._

## Turnovers lost

```
- MM:SS  what happened / did we get back behind the ball
```

_None found._

## Turnovers won

```
- MM:SS  was the free space taken or not
```

_None found._

## Other candidates

Tags: shot_on_goal, 1v1_or_break, through_ball_behind, set_piece, keeper_on_ball.

_None._

## Unreadable

Moments the tape could not resolve. Listed, not guessed.

_None._

## Coverage

Detectors on amateur tape miss turnovers. Say so honestly.

- candidates detected:
- reviewed:
- estimated missed turnovers:
- confidence: high | medium | low

## Part verdict

Three lines maximum. This is what the merge stage reads. It will not reread the frames.

1.
2.
3.

## Links out

- [[<match-slug>]] — the match page this part belongs to
- add the doctrine slug for every moment coached above

## Linked from
