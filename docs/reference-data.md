# RigAssist AI – Reference Data Structure (RA-105)

**Owner:** Leonel  **Status:** Draft for team sign-off (Macauley, Jordy)
**Depends on:** RA-101 (MVP scope)  **Feeds:** RA-106, RA-116, RA-117, RA-119

## Purpose

The reference library is a small, curated, **read-only** dataset bundled with the app. It is the only
source of content the Reference UI shows and the only context the AI assistant may be given. Every
record carries source metadata so any statement can be traced.

## File

- Path in repo: `data/reference_records.json`
- Bundled in the Xcode target as a resource (copy into the app bundle; never written at runtime)
- Swift model: `ReferenceRecord.swift`

## File-level fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `schemaVersion` | string | yes | Bump when the structure changes. Currently `1.0`. |
| `datasetVersion` | string | yes | Bump when records change. |
| `disclaimer` | string | yes | Prototype limitation text shown with reference content. |
| `records` | array | yes | One or more records. |

## Record fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes | Unique, stable, format `REF-###`. |
| `topic` | string | yes | Short title shown in the UI. |
| `category` | string | yes | One of: `load_angle`, `sling_configuration`, `capacity`, `inspection`, `lift_planning`, `app_scope`. |
| `tags` | array of string | yes | Lowercase keywords the Reference Service matches on. At least 2. |
| `summary` | string | yes | Approved plain-language explanation. Shown in the UI. |
| `aiContext` | string | yes | Text supplied to the AI as approved context. May equal `summary`. |
| `relatedCalculation` | string or null | yes | Calculator function this concept links to, or `null`. AI points to the calculator and never computes. |
| `source` | object | yes | See below. |
| `verification` | object | yes | See below. |

### `source` object

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | string | yes | Document title. |
| `publisher` | string | yes | Organization that publishes it. |
| `edition` | string | yes | Edition, year, or revision. `TO VERIFY` is allowed only while status is `unverified`. |
| `section` | string | yes | Section or page. `TO VERIFY` is allowed only while status is `unverified`. |

### `verification` object

| Field | Type | Required | Notes |
|---|---|---|---|
| `status` | string | yes | `unverified` or `verified`. |
| `reviewedBy` | string or null | yes | Reviewer name once verified. |
| `reviewedOn` | string or null | yes | ISO date (`YYYY-MM-DD`) once verified. |

## Rules (enforced by `scripts/validate_reference_data.py`)

1. All required fields present and non-empty.
2. `id` values are unique and match `REF-###`.
3. `category` is from the allowed list.
4. `tags` has at least two entries, all lowercase.
5. `verified` records must have `reviewedBy` and `reviewedOn` set, and no `TO VERIFY` text in `source`.
6. `unverified` records must not have `reviewedBy` or `reviewedOn` set.
7. The app must show the `disclaimer` and each record's source wherever reference content appears.

## Design decisions

- **One source per record.** Keeps the UI and AI response format simple. If a concept needs two
  sources, split it into two records.
- **`aiContext` is separate from `summary`.** Lets the AI context stay precise while the UI text stays
  readable, and they can be identical when that is enough.
- **Retrieval is tag/topic matching** in the Reference Service (RA-116). No embeddings or vector search.
- **Unverified flag is explicit.** Content cannot be mistaken for reviewed material. The AI service
  should only be given `verified` records in the final build.

## Open items for team sign-off

- Confirm the supported concepts and sling configurations from RA-101 match the sample records.
- Macauley: confirm the fields cover the Reference UI and the RA-103 interfaces.
- Jordy: confirm `relatedCalculation` names match calculator function names.
