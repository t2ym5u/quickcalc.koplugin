# Changelog

All notable changes to this project will be documented in this file.

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
