# RigAssist AI

RigAssist AI is a prototype exploring how a digital assistant can support
rigging and lift-planning workflows. It includes a SwiftUI calculator interface,
a read-only local reference library, and a constrained Ask AI interface. The
deterministic calculation engine is still a mock.

## Important safety note

This project is for learning and planning support only. It is not a substitute
for applicable standards, manufacturer instructions, equipment capacity tags,
site requirements, or the judgment of a qualified person. Verify information
against its original source and have a qualified person approve every lift.
Never use this prototype as the sole basis for a lifting decision.

All records in the bundled dataset are currently marked **unverified**, so the
Reference and Ask AI screens deliberately return no record content. Passing
the data validator checks structure and required fields; it does not verify
technical accuracy or approve content for operational use.

## What is in this repository

| Path | Purpose |
| --- | --- |
| [`data/reference_records.json`](data/reference_records.json) | Bundled, read-only reference dataset. |
| [`RigAssistAI/RigAssistAI/ReferenceRecord.swift`](RigAssistAI/RigAssistAI/ReferenceRecord.swift) | Codable Swift models and a loader for the dataset. |
| [`RigAssistAI/RigAssistAI/Services/LocalReferenceService.swift`](RigAssistAI/RigAssistAI/Services/LocalReferenceService.swift) | Offline topic/tag search that returns only verified records. |
| [`RigAssistAI/RigAssistAI/Services/ConstrainedAIService.swift`](RigAssistAI/RigAssistAI/Services/ConstrainedAIService.swift) | Reference-grounded AI orchestration and controlled offline fallbacks. |
| [`docs/reference-data.md`](docs/reference-data.md) | Dataset schema, field requirements, and content rules. |
| [`scripts/validate_reference_data.py`](scripts/validate_reference_data.py) | Checks the JSON dataset against the schema rules. |
| [`validate-reference-data.yml`](validate-reference-data.yml) | GitHub Actions workflow that validates changes to the dataset and validator. |

The AI provider interface is injectable, but no external provider or API
credentials are configured. Until one is supplied, Ask AI can only show
verified local reference text as a fallback; it never calculates rigging
loads.

## Reference dataset

The JSON file has dataset-level metadata (`schemaVersion`, `datasetVersion`,
and `disclaimer`) and a list of reference records. Each record includes a
stable ID, topic, category, search tags, user-facing summary, AI context,
optional related calculation, source details, and verification status.

The dataset is designed to be read-only at runtime. Records should be
traceable to their source, and the app should display both the disclaimer and
source wherever reference content appears. See
[`docs/reference-data.md`](docs/reference-data.md) for the full schema and
requirements for changing or adding records.

## Validate the data

Python 3 is required. From the repository root, run:

```bash
python3 scripts/validate_reference_data.py data/reference_records.json
```

The script exits with a non-zero status and reports validation errors if the
file cannot be parsed or does not meet the required structure and content
rules. You can also pass a different JSON file as the first argument:

```bash
python3 scripts/validate_reference_data.py path/to/reference_records.json
```

[`validate-reference-data.yml`](validate-reference-data.yml) contains a
workflow definition for this validation. GitHub Actions automatically discovers
workflow files only when they are placed under `.github/workflows/`.

## Build and test

Run the platform-independent Reference/AI service tests from the repository
root with `swift test`. Building or running the SwiftUI app and its UI tests
requires Xcode on macOS and an iOS Simulator. The Xcode project bundles
`data/reference_records.json` read-only; a missing or malformed resource is
reported in the app rather than silently ignored.

## Development workflow

`main` is the stable branch and `dev` is the integration branch. Work on
`feature/<name>-<topic>` branches, then open a pull request into `dev`; do not
develop directly on `main` or `dev`. Require at least one review from someone
other than the author, and request changes when integration or safety
requirements are not met. Merge `dev` into `main` only after the combined app
has been built and the UI, calculation, reference, and AI components have been
integration-tested.

AI assistance may be used for test generation and code improvement. Review
AI-assisted changes manually, build and test them, and have them peer-reviewed
through the same pull request process. Rigging calculations remain
deterministic and must be checked against approved calculation rules; AI
answers are not calculation results.

## Contributing

When adding or changing reference content:

1. Follow the schema and content rules in
   [`docs/reference-data.md`](docs/reference-data.md).
2. Keep record IDs stable and unique; use the `REF-###` format for new IDs.
3. Update the dataset version when records change. Update the schema version
   when the data structure changes.
4. Keep each record's source and verification details accurate. Do not mark a
   record verified until it has been reviewed against its original source.
5. Run the validator and include relevant documentation updates with schema
   changes.
