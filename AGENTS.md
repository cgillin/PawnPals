# PawnPals — Agent Context

An iPhone chess tutor that **grades moves and explains why**, at the player's level.
Full design: [docs/DESIGN.md](docs/DESIGN.md). Read it before making architectural changes.

## Who's building this

A parent (experienced programmer, new to Swift) and a kid (new to coding). So:

- **Explain choices in plain language.** When you introduce a Swift feature for the first time (optionals, `guard`, `@Observable`, `async/await`, actors…), add a one- or two-sentence explanation in chat. Comparisons to other languages are welcome for the parent.
- **Follow the build plan in docs/DESIGN.md, one step at a time.** Don't build ahead of the current step or add features that weren't asked for. If something from a later step is needed, say so and ask.
- **Keep changes small** enough to read in one sitting. Prefer several small files to one big one.
- **Tell us how to see the result** at the end of each change (which simulator, what to tap, which test to run).

## The rules that matter most

These come from the design and are not negotiable:

1. **ChessKit decides what's legal.** Never write custom move-legality code.
2. **Stockfish decides what's good.** Grades, best moves, and best lines come only from engine output.
3. **The AI model never does chess.** It only rewords a list of facts that code has already verified. Its output is checked: every piece and square it mentions must appear in the facts, or we fall back to the template sentence. Never ask a language model for a move, an evaluation, or a reason.
4. **No invented reasons.** If no fact finder fires, the coach says the computer sees a deeper idea and offers to step through the line.
5. **Scores are stored from White's point of view, always.** Stockfish reports from the side to move; convert at the engine boundary, in exactly one place. Grading converts to the mover's point of view when it needs to.
6. **Grade with win %, not raw centipawns.** Mate scores map to ~100% / ~0%. All grading thresholds live in one file (`GradingThresholds`).
7. **No API keys in the app.** Use Apple's on-device Foundation Models, or a server proxy for cloud models.

## Project layout

```
PawnPals/                  ← Xcode app target: SwiftUI views + SwiftData only
PawnPalsCore/              ← local Swift package: all chess logic, no UI
  Sources/PawnPalsCore/
    Engine/                ← Stockfish wrapper (an actor)
    Grading/               ← win-% math, classifier, thresholds
    Facts/                 ← fact finders (hanging piece, fork, mate in 1, …)
    Coaching/              ← templates, coaching levels, AI rewording + check
  Tests/PawnPalsCoreTests/
docs/
```

**Why a separate package:** chess logic in `PawnPalsCore` has no UI, so its tests run in seconds with `swift test`, without launching a simulator. The app target stays thin: it shows things and saves things.

- `PawnPalsCore` must not import SwiftUI or SwiftData.
- The app target must not contain grading, fact-finding, or engine logic.

## Swift conventions

**Language & concurrency**
- Swift 6 language mode with strict concurrency checking. Don't turn warnings off to make code compile; fix the cause.
- Keep the app target's default `MainActor` isolation from the Xcode template.
- Use `async`/`await`. Don't use completion handlers, Combine, or `DispatchQueue`.
- The engine wrapper is an `actor` so only one request talks to Stockfish at a time. The opponent and the analyzer use **separate engine instances**.

**Types**
- Model chess concepts with `struct` and `enum` (value types). Use `class` only when SwiftUI or SwiftData requires it.
- Use enums with associated values for closed sets, e.g. `enum Fact { case hangingPiece(piece:square:attackedBy:) … }`, `enum Grade { case great, good, inaccuracy, mistake, blunder }`.
- Grading and fact finders are **pure functions**: input in, result out, no hidden state. That's what makes them easy to test.
- Mark types `Sendable` when they cross actor boundaries (most value types already are).

**Optionals and errors**
- No force unwrapping (`!`) or `try!` in app or core code. Use `guard let`, `if let`, or `??`. (Tests may use `#require`.)
- Throw errors for things that can actually fail (engine didn't start, invalid FEN). Don't return magic values like `-1`.

**SwiftUI**
- State: `@Observable` classes for shared models, `@State` for view-local values, `@Environment` to pass shared models down. Don't use the older `ObservableObject` / `@Published` / `@StateObject`.
- Keep views small. If a `body` scrolls off the screen, extract a subview.
- Every view gets a `#Preview` with realistic sample data, so it can be checked without running the app.
- Use SF Symbols for icons and system fonts and colors, so Dynamic Type and dark mode work for free.
- Give board squares and pieces VoiceOver labels ("white knight on f3").

**SwiftData**
- `@Model` classes live in the app target only. Convert to and from plain `PawnPalsCore` structs at that boundary.

**Naming and style**
- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/): `UpperCamelCase` types, `lowerCamelCase` everything else, names that read clearly at the call site (`board.move(from: .e2, to: .e4)`).
- Use full words, not abbreviations: `evaluation`, not `eval`. Chess terms (`fen`, `pgn`, `san`, `ply`) are fine.
- Format with the `swift format` tool that ships with Xcode before committing.

## Xcode project rules

- **Never hand-edit `PawnPals.xcodeproj/project.pbxproj`.** The project uses folder-synchronized groups, so new files created on disk under `PawnPals/` show up in Xcode automatically.
- Add package dependencies through Xcode (File → Add Package Dependencies) for the app, or in `PawnPalsCore/Package.swift` for the core package.
- **Approved dependencies:** ChessKit (`chesskit-swift`), ChessKitEngine (`chesskit-engine`). Ask before adding any other.

## Testing

- Use **Swift Testing** (`import Testing`, `@Test`, `#expect`, `#require`), not XCTest, for unit tests.
- Every grading function and fact finder gets tests, written first when practical. Use real FEN positions as test inputs, and name each test after the chess idea (`@Test func knightLeftUndefendedIsHanging()`).
- Must-have tests: the score sign flip, mate scores, and the boundary value of each grading threshold.
- Tests that start Stockfish are slower. Tag them `.tags(.engine)` so they can be skipped during quick runs.

## Commands

> Fill in the scheme and simulator names after step 0 creates the Xcode project.

```bash
# Core logic tests (fast, no simulator)
swift test --package-path PawnPalsCore

# Build the app for the simulator
xcodebuild -project PawnPals.xcodeproj -scheme PawnPals -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run app tests
xcodebuild -project PawnPals.xcodeproj -scheme PawnPals -destination 'platform=iOS Simulator,name=iPhone 17' test

# Format
swift format --in-place --recursive PawnPals PawnPalsCore
```

## Git

- One branch per build-plan step (`step-01-board`, `step-02-move-list`, …), merged to `main` when the step works.
- Small commits with messages that say what changed and why.
- Never commit secrets, `xcuserdata/`, or `DerivedData/` (already in `.gitignore`).
- The repo is public and GPL-3.0 because we ship Stockfish. Don't add code with an incompatible license.
