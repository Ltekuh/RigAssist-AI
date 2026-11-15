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

Updated from `dev` at `dfcd7b3` after PR #5 merged. Reconciled Package.swift
so the calculator and Reference/AI service sources share RigAssistCore, and
both test files remain in RigAssistCoreTests. The README retains both sets of
documentation. Leonel's services, tests, navigation, and resources are retained.

Validation on the updated branch: all 22 combined tests passed (8 calculator
and 14 Reference/AI). The same 22 passed with process network access denied.
The combined iOS Simulator SDK Debug app build passed. Existing actor-isolation
warnings remain in LocalReferenceService at lines 41 and 88. The reference
validator passed with 11 unverified records; no dataset changes were made.
`git diff --check` passed.

Base: dev. Another team member should review the calculation rules and tests
before merging. Final UI integration and simulator/offline QA remain for PR #6;
see docs/calculation-engine.md for the device acceptance checklist. Results
remain academic prototype outputs requiring qualified human verification.
