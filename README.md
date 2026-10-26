# RigAssist AI

RigAssist AI is a prototype project exploring how a digital assistant can support
rigging and lift-planning workflows. This repository currently contains the
foundation for its curated reference library: a structured JSON dataset, a Swift
model and loader, and a validator for keeping the dataset consistent.

## Important safety note

This project is for learning and planning support only. It is not a substitute
for applicable standards, manufacturer instructions, equipment capacity tags,
site requirements, or the judgment of a qualified person. Verify information
against its original source and have a qualified person approve every lift.
Never use this prototype as the sole basis for a lifting decision.

The bundled records are currently marked **unverified**. Passing the data
validator checks structure and required fields; it does not verify technical
accuracy or approve content for operational use.

## What is in this repository

| Path | Purpose |
| --- | --- |
| [`data/reference_records.json`](data/reference_records.json) | Bundled, read-only reference dataset. |
| [`ReferenceRecord.swift`](ReferenceRecord.swift) | Codable Swift models and a loader for the dataset. |
| [`docs/reference-data.md`](docs/reference-data.md) | Dataset schema, field requirements, and content rules. |
| [`scripts/validate_reference_data.py`](scripts/validate_reference_data.py) | Checks the JSON dataset against the schema rules. |
| [`validate-reference-data.yml`](validate-reference-data.yml) | GitHub Actions workflow that validates changes to the dataset and validator. |

This repository does not currently include a complete app, an AI service, or
calculator implementations. The reference dataset and Swift loader are intended
to support future app work.

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

## Swift integration

Add `ReferenceRecord.swift` to the Swift target and include
`data/reference_records.json` in the app bundle as a resource. The loader
decodes the bundled `reference_records.json` into a `ReferenceDataset`:

```swift
let dataset = try ReferenceDataLoader.load()
```

The load operation throws if the resource is missing or cannot be decoded;
callers should handle that error explicitly. The loader does not write or
modify the dataset.

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
