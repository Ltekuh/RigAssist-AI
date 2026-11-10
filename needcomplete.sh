#!/usr/bin/env bash
# Leonel's contribution: Run the pre-PR checks and print the remaining review steps.
#
# Usage:
#   bash needcomplete.sh
#   SWIFT_BIN=/path/to/swift bash needcomplete.sh
#
# Exit codes:
#   0 - local checks passed and iOS simulator tests ran.
#   1 - one or more checks failed.
#   2 - local checks passed, but a required platform check could not run here.

set -u

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR" || exit 1

FAILED=0
BLOCKED=0

run_check() {
    local description="$1"
    shift
    printf '\n==> %s\n' "$description"
    if "$@"; then
        printf 'PASS: %s\n' "$description"
    else
        printf 'FAIL: %s\n' "$description"
        FAILED=$((FAILED + 1))
    fi
}

show_review_steps() {
    printf '\n%s\n' "------------------------------------------------------------"
    printf '%s\n' "MANUAL COMPLETION / PULL REQUEST CHECKLIST"
    cat <<'STEPS'
1. Review every changed file:
     git diff origin/dev...HEAD
   Confirm the service changes agree with the shared protocols and do not
   modify the deterministic calculation engine.

2. Finish the dataset with a qualified reviewer:
   - Use authoritative sources: the applicable ASME edition, OSHA regulations,
     and/or the exact sling/equipment manufacturer's instructions.
   - Obtain the exact edition/revision and section/page for each record.
   - Have a qualified person compare each summary and AI context against its
     source. Do not guess citation details or copy proprietary standards into
     the repository.
   - Only after that review, update source.edition, source.section,
     verification.status, verification.reviewedBy, and verification.reviewedOn
     in data/reference_records.json. Keep unreviewed records unverified.
   - Run:
       python3 scripts/validate_reference_data.py data/reference_records.json

3. If on Windows/Linux, run the Swift unit tests locally, then use a Mac with
   Xcode (a teammate's Mac or a trusted cloud Mac) for the iOS app and simulator
   UI tests. This repository's CodeQL workflow builds the app on a GitHub Mac
   for pull requests into dev; it does not run the Xcode UI test suite.

4. Update/check your feature branch and inspect its diff:
     git fetch origin
     git switch feature/leonel-reference-ai
     git merge origin/dev
     git diff --check
     git diff origin/dev...HEAD
   Resolve any conflicts, rerun this script, and commit the resolved changes.

5. Push and open a pull request with base dev:
     git push -u origin feature/leonel-reference-ai
   On GitHub, select base "dev", summarize the changes and test results, and
   request at least one teammate who did not author the changes to review.
   Ask for/request changes when something is incorrect; do not merge your own
   work without the required peer review and passing checks.

6. In the PR, wait for required Actions checks, address comments, and rerun
   relevant tests after changes. Do not merge to main directly.

7. Current integration limits to mention in the PR:
   - The dataset currently has 11 unverified records, so Reference/Ask AI
     intentionally returns no reference content until records are reviewed.
   - The AI provider is not configured; Ask AI uses safe offline fallbacks.
   - The calculator still uses MockCalculationEngine; this is not a production
     rigging calculation and must not be used for lift decisions.
STEPS
    printf '%s\n' "Before opening the PR, run: ./needcomplete.sh"
}

printf '%s\n' "RigAssist pre-PR checks"
printf 'Repository: %s\n' "$ROOT_DIR"
printf 'Branch: %s\n' "$(git branch --show-current 2>/dev/null || printf 'unknown')"
printf '\n'

if git diff --quiet && git diff --cached --quiet \
    && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    printf '%s\n' "PASS: Worktree has no uncommitted or untracked changes."
else
    printf '%s\n' "NOTE: There are uncommitted or untracked changes; include intended work in the feature branch before opening the PR."
    git status --short
fi

if git show-ref --verify --quiet refs/remotes/origin/dev; then
    run_check "Feature branch includes the latest locally fetched origin/dev" \
        git merge-base --is-ancestor origin/dev HEAD
    run_check "No whitespace errors in feature branch changes" \
        git diff --check origin/dev...HEAD
    printf '\n%s\n' "Changed files compared with origin/dev:"
    git diff --stat origin/dev...HEAD
else
    printf '%s\n' "BLOCKED: origin/dev is not available locally. Run 'git fetch origin' and retry."
    BLOCKED=$((BLOCKED + 1))
fi

if command -v python3 >/dev/null 2>&1; then
    run_check "Reference dataset structure and required fields" \
        python3 scripts/validate_reference_data.py data/reference_records.json

    printf '\n%s\n' "Dataset approval status:"
    python3 - <<'PY'
import json

with open("data/reference_records.json", encoding="utf-8") as data_file:
    dataset = json.load(data_file)

pending = [
    record for record in dataset["records"]
    if record["verification"]["status"] != "verified"
]
print(f"{len(pending)} of {len(dataset['records'])} records still need qualified review.")
for record in pending:
    source = record["source"]
    print(
        f"  {record['id']} — {record['topic']}: "
        f"{source['title']} / {source['edition']} / {source['section']}"
    )
PY
else
    printf '%s\n' "FAIL: Python 3 is required to validate the reference dataset."
    FAILED=$((FAILED + 1))
fi

swift_bin="${SWIFT_BIN:-swift}"
if command -v "$swift_bin" >/dev/null 2>&1 \
    && "$swift_bin" --version 2>&1 | grep -q 'Swift version'; then
    run_check "Cross-platform Swift package tests" "$swift_bin" test
else
    printf '\n%s\n' "BLOCKED: A Swift compiler was not found (or 'swift' is not the Swift toolchain)."
    printf '%s\n' "Install Swift and retry, or set SWIFT_BIN to the Swift executable."
    BLOCKED=$((BLOCKED + 1))
fi

if [ "$(uname -s 2>/dev/null || printf unknown)" = "Darwin" ] \
    && command -v xcodebuild >/dev/null 2>&1 \
    && command -v xcrun >/dev/null 2>&1; then
    simulator_id="${IOS_SIMULATOR_ID:-}"
    if [ -z "$simulator_id" ]; then
        simulator_id="$(
            xcrun simctl list devices available -j | python3 -c '
import json
import sys

devices = json.load(sys.stdin)["devices"]
selected = next(
    (
        device["udid"]
        for runtime_devices in devices.values()
        for device in runtime_devices
        if device["isAvailable"] and device["name"].startswith("iPhone")
    ),
    "",
)
print(selected)
'
        )"
    fi

    if [ -n "$simulator_id" ]; then
        run_check "Build app and run Xcode unit/UI tests on iOS Simulator" \
            xcodebuild \
                -project RigAssistAI/RigAssistAI.xcodeproj \
                -scheme RigAssistAI \
                -destination "platform=iOS Simulator,id=$simulator_id" \
                CODE_SIGNING_ALLOWED=NO \
                test
    else
        printf '%s\n' "BLOCKED: No available iPhone simulator. Install one in Xcode or set IOS_SIMULATOR_ID."
        BLOCKED=$((BLOCKED + 1))
    fi
else
    printf '\n%s\n' "BLOCKED: Xcode/iOS Simulator checks require macOS with Xcode installed."
    printf '%s\n' "Run this script on a Mac before merging, or ensure the GitHub macOS build check passes."
    BLOCKED=$((BLOCKED + 1))
fi

show_review_steps

printf '\n%s\n' "------------------------------------------------------------"
printf 'Failed checks: %s\n' "$FAILED"
printf 'Platform/toolchain checks blocked or not run: %s\n' "$BLOCKED"

if [ "$FAILED" -gt 0 ]; then
    printf '%s\n' "RESULT: Not ready. Fix failed checks, then rerun this script."
    exit 1
elif [ "$BLOCKED" -gt 0 ]; then
    printf '%s\n' "RESULT: Local checks passed, but complete blocked checks before merging."
    exit 2
else
    printf '%s\n' "RESULT: Checks passed. Complete the manual review steps before merging."
fi
