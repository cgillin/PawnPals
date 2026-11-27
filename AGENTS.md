# PittChess — Agent Context

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
7. **No API keys in the app.** The AI coach voice uses a cloud model through a small server proxy that holds the key. Apple's on-device Foundation Models aren't an option: they need iOS 26 and Apple Intelligence, and our test phone (iPhone XR) tops out at iOS 18.

## Project layout

```
PittChess/                 ← Xcode app target: SwiftUI views + SwiftData only
PittChessCore/             ← local Swift package: all chess logic, no UI
  Sources/PittChessCore/
    Engine/                ← Stockfish wrapper (an actor)
    Grading/               ← win-% math, classifier, thresholds
    Facts/                 ← fact finders (hanging piece, fork, mate in 1, …)
    Coaching/              ← templates, coaching levels, AI rewording + check
  Tests/PittChessCoreTests/
docs/
```

**Why a separate package:** chess logic in `PittChessCore` has no UI, so its tests run in seconds with `swift test`, without launching a simulator. The app target stays thin: it shows things and saves things.

- `PittChessCore` must not import SwiftUI or SwiftData.
- The app target must not contain grading, fact-finding, or engine logic.

## Swift conventions

**Language & concurrency**
- Swift 6 language mode with strict concurrency checking. Don't turn warnings off to make code compile; fix the cause.
- Keep the app target's default `MainActor` isolation from the Xcode template.
- Use `async`/`await`. Don't use completion handlers, Combine, or `DispatchQueue`.
- The engine wrapper is an `actor` so only one request talks to Stockfish at a time. The opponent and the analyzer **share one engine and take turns** through its queue: ChessKitEngine can only run one Stockfish per app, because it takes over the app's input and output to talk to it. Each request sends its own settings, so one job's settings never leak into the other's.

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
  - **Exception: the board.** Square colors are fixed (a chessboard looks the same in light and dark mode), and piece symbols scale with the square, not with Dynamic Type. Text around the board still follows the rule.
- Give board squares and pieces VoiceOver labels ("white knight on f3").

**SwiftData**
- `@Model` classes live in the app target only. Convert to and from plain `PittChessCore` structs at that boundary.

**Naming and style**
- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/): `UpperCamelCase` types, `lowerCamelCase` everything else, names that read clearly at the call site (`board.move(from: .e2, to: .e4)`).
- Use full words, not abbreviations: `evaluation`, not `eval`. Chess terms (`fen`, `pgn`, `san`, `ply`) are fine.
- Format with the `swift format` tool that ships with Xcode before committing.

## Platform

- **iPhone only, iOS 18.0 minimum.** Our test phone is an iPhone XR, whose last iOS is 18. Don't use APIs newer than iOS 18 unless they're wrapped in `if #available` with a working fallback.
- Swift 6 mode and warnings-as-errors are set for every target (see **Warnings are errors** below).

## Xcode project rules

- **The project file is `PittChess.xcodeproj/project.xcproj`**, Xcode 27's readable text format (it replaced the old `project.pbxproj`). Xcode opens it as text, not as a settings screen.
- **Small build-setting edits in that file are fine.** After any edit, prove Xcode reads it the way you meant: check the value with `xcodebuild -showBuildSettings -project PittChess.xcodeproj -target <target> -sdk iphonesimulator`, then build and run the tests. Don't restructure the file by hand. Let Xcode manage targets, IDs, and package references.
- Source folders are `"kind": "folder"` entries, so new files created on disk under `PittChess/`, `PittChessTests/`, or `PittChessUITests/` are picked up automatically.
- The `PittChess` scheme isn't committed; Xcode and `xcodebuild` generate it automatically, including on a fresh clone in CI.
- Add package dependencies through Xcode (File → Add Package Dependencies; **Add Local…** for `PittChessCore`) for the app, or in `PittChessCore/Package.swift` for the core package.
- **Approved dependencies:** ChessKit (`chesskit-swift`), ChessKitEngine (`chesskit-engine`). Ask before adding any other.

## Testing

- Use **Swift Testing** (`import Testing`, `@Test`, `#expect`, `#require`), not XCTest, for unit tests. UI tests in `PittChessUITests/` are the exception: they still use XCTest, because driving the app UI requires it.
- Keep UI tests few and fast. They launch the app in a simulator and are the slowest part of CI.
- Every grading function and fact finder gets tests, written first when practical. Use real FEN positions as test inputs, and name each test after the chess idea (`@Test func knightLeftUndefendedIsHanging()`).
- Must-have tests: the score sign flip, mate scores, and the boundary value of each grading threshold.
- Tests that start Stockfish are slower. Tag them `.tags(.engine)` so they can be skipped during quick runs.

## Commands

```bash
# Download Stockfish's neural networks (once per clone; they're not in git)
scripts/fetch-stockfish-networks.sh

# Core logic tests (fast, no simulator)
swift test --package-path PittChessCore

# Core logic tests without the ones that start Stockfish
swift test --package-path PittChessCore --skip StockfishEngineTests

# Build the app for the simulator
xcodebuild -project PittChess.xcodeproj -scheme PittChess -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run app tests (unit + UI)
xcodebuild -project PittChess.xcodeproj -scheme PittChess -destination 'platform=iOS Simulator,name=iPhone 17' test

# Run only the fast unit tests
xcodebuild -project PittChess.xcodeproj -scheme PittChess -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:PittChessTests

# Format (fixes files in place; only files git tracks, so build output is skipped)
git ls-files '*.swift' | xargs swift format --in-place --configuration .swift-format

# Lint (what CI runs; fails on any problem)
git ls-files '*.swift' | xargs swift format lint --strict --configuration .swift-format

# Turn on the pre-commit format check (once per clone)
git config core.hooksPath .githooks
```

CI doesn't use `iPhone 17`; it picks the first available iPhone simulator on the runner, because runner images change which simulators they ship.

**Warnings are errors.** The app project sets `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` project-wide, and every `PittChessCore` target has `swiftSettings: [.treatAllWarnings(as: .error)]`. New targets must keep this. Don't silence a warning to get a build through; fix it.

## Lint rules

`.swift-format` is the style config: swift-format defaults, 4-space indentation, plus `NeverForceUnwrap`, `NeverUseForceTry`, and `NeverUseImplicitlyUnwrappedOptionals` turned on to enforce the optionals rule above. Change it only on purpose, in its own PR.

## Git and pull requests

- **`main` is protected. Never push to it directly.** Every change goes through a pull request, and the CI checks (Lint, Build & test, Tests required) must pass before merging.
- CI's Build & test job runs on the `xcode-27` runner label (GitHub names Mac images by Xcode version). Our project format needs Xcode 27, so bump the label when we move to a new Xcode.
- CI's lint job uses a pinned Swift container (`swift:6.4.2-noble` in `.github/workflows/ci.yml`). When we update Xcode, bump that tag to match `swift --version`, so formatting rules agree between CI and our machines.
- One branch per build-plan step (`step-01-board`, `step-02-move-list`, …), or per smaller change. Open a PR when the step works.
- **PRs that change Swift code must change tests too.** CI fails otherwise. For a real exception (a rename, a UI-only tweak), add the `no-tests-needed` label and say why in the PR description.
- PR descriptions say what changed, why, and how to see it working (simulator steps, or which tests to run).
- **Code review happens locally, before the PR.** Run `/code-review` **without `--fix`**, then present the findings: what's wrong, where, and how it would break, explained plainly. Wait for us to choose which to fix, skip, or fix differently. Don't apply review fixes without our approval, even when the fix looks obvious. List any skipped findings and the reason in the PR description.
- Small commits with messages that say what changed and why.
- Never commit secrets, `xcuserdata/`, or `DerivedData/` (already in `.gitignore`).
- The repo is public and GPL-3.0 because we ship Stockfish. Don't add code with an incompatible license.
