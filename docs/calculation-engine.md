# Calculation engine: RA-111, RA-114, RA-118

## Architecture and scope

`CalculatorView` collects inputs, builds `LiftInput`, and calls
`CalculationEngineProtocol`. `CalculationEngine` validates every input again
and returns either `CalculationResult` or a typed `CalculationError`. The view
only displays the returned values. The development mock remains available but
is no longer used by the calculator screen. AI and reference services are not
dependencies of the engine.

Supported inputs use pounds and **per-leg** rated capacity. A vertical hitch
carries the whole load with multiplier 1. A symmetric two-leg bridle assigns
half the load to each leg and uses `1 / sin(angle from horizontal)` for the
angle multiplier. Tension is load share times multiplier; utilization is
tension divided by capacity. Capacity status compares unrounded tension to
capacity; equality is within the supplied rating. Overloads return results
with a warning so they can be displayed explicitly.

The bridle model assumes a static load, equal leg angles, equal load sharing,
and a center of gravity midway between pick points. It does not model shock,
eccentric loads, hitch reductions, or equipment-specific derating. A capacity
status is not approval of a lift. The existing academic-prototype notice is
retained and engine warnings describe the assumptions.

The formula and equal-share assumption are consistent with The Crosby Group's
[2019 Rigging Information, Sling Angles table](https://www.thecrosbygroup.com/wp-content/uploads/catalog/2016/en-US/473.pdf).
Its tabulated factors at 90, 60, 45, and 30 degrees are 1, approximately 1.155,
approximately 1.414, and 2. The engine uses unrounded trigonometry internally
and exact factors at 30 and 90 degrees. The 30–90 degree input restriction
comes from the project's existing shared input/error contract. This source
check does not mark any reference dataset record verified or replace the
team's review of approved calculation rules.

## Automated checks

Run `swift test` from the repository root. No external package dependencies
or credentials are required. The package compiles the same engine and shared
models used by the Xcode app. The eight XCTest methods cover vertical and
bridle values, four analytical angle fixtures, capacity boundaries on either
side of equality, invalid/missing/unexpected angles, non-finite/zero/negative
inputs, numeric overflow/underflow, fractional inputs, and repeatability.

The calculation workflow runs the suite on macOS for pull requests into dev
or main. Build the iOS application separately with Xcode; passing package tests
does not validate SwiftUI navigation or device behavior.

## RA-118 device acceptance check

After installing the app on a device or simulator, disconnect its network and
cold launch it. Test these inputs and confirm results/navigation work:

| Configuration | Load lb | Capacity per leg lb | Angle from horizontal | Expected tension per leg lb | Status |
| --- | ---: | ---: | ---: | ---: | --- |
| Vertical | 5000 | 6000 | None | 5000 | Within rating |
| Two-leg | 5000 | 4000 | 60° | About 2886.75 | Within rating |
| Two-leg | 5000 | 5000 | 30° | 5000 | Within rating, exactly 100% |
| Two-leg | 5000 | 4000 | 30° | 5000 | Exceeds rating with warning |

Also reject zero weight and an angle below 30°. Switch back to vertical and
confirm the previous angle is cleared. Repeat after terminating/reopening the
app while disconnected. Record device/OS, date, tester, and outcome before
closing device-level RA-118. Reference-library offline acceptance remains
Leonel's task and combined navigation testing is RA-120.

## Branch and PR workflow

This work starts from `origin/dev` on `feature/jordy-calculation-engine`.
Review the diff, commit only these files, push that feature branch, and open a
PR with **base dev**. Have another team member review before merging. Do not
push directly to dev/main or merge teammates' PRs as part of this work.

PR #5 also introduces `Package.swift` for reference/AI tests. If it merges
first, resolve the add/add manifest conflict by keeping **both** sets of core
sources and tests under its `RigAssistCore` / `RigAssistCoreTests` targets;
remove the calculator files from its excludes. Keep its reference/AI sources,
and continue excluding the SwiftUI views and mock. Run all calculator and
reference/AI tests after reconciliation, then build the combined app. Do not
replace the manifest with only one contributor's target list.

## Validation performed on November 12, 2026

- Calculator suite: 8 tests passed with zero failures on macOS / Swift 6.4.
- The same compiled XCTest bundle: 8 tests passed while the process was run
  with `(deny network*)` using macOS sandbox-exec.
- iOS Simulator SDK Debug build: succeeded with code signing disabled,
  Xcode 27.1. This was a build, not an app launch.
- Temporary combined-source copy of PR #5 head
  `27d39858e9bd0a7d844ae33d0aa90d88083280ce`: reconciled the package manifest
  as described above; 22 tests passed (8 calculator + 14 reference/AI).
  The combined iOS Simulator SDK Debug app build also succeeded, with
  actor-isolation warnings in PR #5's LocalReferenceService.normalize calls
  (lines 41 and 88). Those warnings are outside the calculator change and
  should be reviewed before adopting Swift 6 language mode.
  Neither remote branch was merged or modified by this check.
- Reference validator: 11 structurally valid records, all still unverified.
- Device-level offline UI acceptance: pending; no simulator was booted.

The restricted local environment needed `swift test --disable-sandbox` and
module caches under `/tmp` to compile the test package. This only disables
SwiftPM's nested build sandbox. Network denial was applied separately to the
compiled test process for the offline check.
