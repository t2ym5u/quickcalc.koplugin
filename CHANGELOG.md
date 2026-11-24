# Changelog

All notable changes to this project will be documented in this file.

## [1.0.6] - 2026-11-24

### Changed
- Picks up game-common 1.19.0: with the Dashboard installed, the title bar's
  close icon becomes a house that goes back to it.

## [1.0.5] - 2026-11-24

### Changed
- Picks up game-common 1.18.0: a status line cut off with "…" opens in full
  when tapped, so a long hint can be read.

## [1.0.4] - 2026-11-18

### Changed
- Picks up game-common 1.17.0 (a board redraw fix used by chess, binairo and
  tatami; no change in this game).

## [1.0.3] - 2026-11-12

### Changed
- Picks up game-common 1.16.0: games for two readers (new Two readers
  category) and the shared Start / Join dialog.

## [1.0.2] - 2026-11-04

### Fixed
- The tool no longer crashes when an outdated plugin is installed alongside:
  shared modules left behind by an older plugin are replaced by this
  plugin's own copy instead of being used as they are.

## [1.0.1] - 2026-11-04

### Changed
- Uses less memory: the tool loads when you open it, not when KOReader
  starts, so it no longer takes memory or startup time while unused.

## [1.0.0] - 2026-11-03

### Added
- Calculator with an on-screen keypad: operator precedence, parentheses
  (left open ones are closed by =), %, ±, C / CE / ⌫ (hold ⌫ to clear),
  memory (MC, MR, M+, M−) and a live preview of the result while typing.
- Scientific keys (f(x)): √, ∛, x², x³, xʸ, 1/x, eˣ, 10ˣ, n!, π, e, Ans,
  sin / cos / tan in degrees or radians, log and ln.
- Clear messages for division by zero, overflow and undefined results.
- History of the last 20 results, kept across sessions; tap one to reuse it.
- Percentages: VAT (excl. ↔ incl., 5.5 / 10 / 20 % presets), discount,
  % change, X % of Y.
- Bill split & tip, Loan (monthly payment, total repaid, total interest) and
  Savings (compound interest with an optional monthly deposit).
- Decimal comma and thousands separators follow the UI language.
- The last mode, the form values and the scientific keys are remembered.
