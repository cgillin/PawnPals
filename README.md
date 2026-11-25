# PawnPals ♟️

A chess tutor for iPhone that **grades your moves and explains why** — at a level that fits the player.

There are plenty of places to *play* chess. PawnPals is about *learning*: after each move it tells you whether it was great, good, an inaccuracy, a mistake, or a blunder, and gives a short, kid-friendly reason ("your knight on f3 isn't protected").

> Status: **design stage.** No app code yet. See [docs/DESIGN.md](docs/DESIGN.md).

## Planned features (v1)

1. **Play the computer** at an adjustable level — from total beginner (~300) up to strong club player.
2. **Move grading** with a plain-language reason for each grade.
3. **Predict, then reveal** — in training mode, say what you were trying to do (attack / defend / develop / trade / not sure) and the coach responds to *your plan*, not just the move.
4. **Show the punishment** — step through how the opponent could take advantage of a bad move.
5. **Key moments** — after a game, only the 2–3 turning points.
6. **Mistake tracking** — remembers the kinds of mistakes you make and turns them into practice puzzles from your own games.

## How it works (short version)

| Part | Job |
|---|---|
| **Stockfish** | The judge. Scores positions and finds the best lines. Always the source of truth. |
| **Our fact-finder code** | Finds the *reasons*: hanging pieces, missed captures, forks, threats. |
| **AI language model** | The coach's voice. Only rewords facts the code already checked — never decides chess. |
| **Maia** (later) | The "normal human" meter: how likely a player at your rating is to find a move. |

## Tech stack

- **Swift + SwiftUI** (iOS app, built in Xcode)
- **ChessKit** for chess rules, **ChessKitEngine** for Stockfish (and lc0/Maia later)
- **SwiftData** for saving progress on the device — no accounts
- **Swift Testing** for tests
- **Apple Foundation Models** (on-device) for the coach's voice, with a cloud model as an option

## Build plan

See the step-by-step plan in [docs/DESIGN.md](docs/DESIGN.md#build-plan). Each step is sized for an evening or two, and something visible works from step 1.

## License

GPL-3.0 — required because PawnPals will ship with Stockfish (and later lc0), which are GPL-licensed. See [LICENSE](LICENSE).
