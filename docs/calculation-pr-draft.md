# PR title

RA-111 / RA-114 / RA-118: Implement and test the local calculation engine

# PR body

The calculator previously returned hard-coded mock values for every input.
It now validates inputs and computes vertical-hitch and symmetric two-leg
bridle results locally through CalculationEngineProtocol. Angles are measured
from horizontal and rated capacity is per leg. A 5,000 lb load at 60° now
returns approximately 2,886.75 lb tension per leg rather than a fixed demo result.

Adds finite/positive number validation, angle validation, unrounded capacity
comparisons, overload warnings, model-assumption warnings, eight calculator
unit tests, and a macOS test workflow. The input screen uses the real engine,
labels the angle/capacity conventions, and displays typed error messages.

Validation: 8 calculator tests passed; the same 8 passed with process network
access denied. iOS Simulator SDK Debug build passed. A temporary integration
copy of PR #5 passed all 22 combined calculator/reference/AI tests and its
combined iOS Simulator SDK app build. The data
validator passed with 11 unverified records. Device-level offline UI acceptance
is still pending; see docs/calculation-engine.md for the acceptance checklist.

Base: dev. Another team member should review the calculation rules and tests
before merging. If PR #5 merges first, reconcile Package.swift to retain both
contributors' source lists and tests, then rerun the complete suite. The
combined manifest was tested in a temporary copy; this PR does not merge or
modify PR #5. Results remain academic prototype outputs requiring qualified
human verification.
