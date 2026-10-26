#!/usr/bin/env python3
"""Validate data/reference_records.json against docs/reference-data.md (RA-106)."""
import json
import re
import sys

PATH = sys.argv[1] if len(sys.argv) > 1 else "data/reference_records.json"
CATEGORIES = {"load_angle", "sling_configuration", "capacity", "inspection", "lift_planning", "app_scope"}
FILE_FIELDS = ["schemaVersion", "datasetVersion", "disclaimer", "records"]
RECORD_FIELDS = ["id", "topic", "category", "tags", "summary", "aiContext", "relatedCalculation", "source", "verification"]
SOURCE_FIELDS = ["title", "publisher", "edition", "section"]
VERIF_FIELDS = ["status", "reviewedBy", "reviewedOn"]

errors = []


def err(msg):
    errors.append(msg)


def blank(v):
    return not isinstance(v, str) or not v.strip()


try:
    with open(PATH, encoding="utf-8") as f:
        data = json.load(f)
except Exception as e:
    print(f"FAIL: cannot parse {PATH}: {e}")
    sys.exit(1)

for k in FILE_FIELDS:
    if k not in data:
        err(f"file: missing '{k}'")
for k in ("schemaVersion", "datasetVersion", "disclaimer"):
    if k in data and blank(data[k]):
        err(f"file: '{k}' is empty")

records = data.get("records", [])
if not isinstance(records, list) or not records:
    err("file: 'records' must be a non-empty array")
    records = []

seen = set()
for i, r in enumerate(records):
    rid = r.get("id", f"#{i}")
    for k in RECORD_FIELDS:
        if k not in r:
            err(f"{rid}: missing '{k}'")
    if not re.fullmatch(r"REF-\d{3}", str(r.get("id", ""))):
        err(f"{rid}: id must match REF-###")
    if rid in seen:
        err(f"{rid}: duplicate id")
    seen.add(rid)
    for k in ("topic", "summary", "aiContext"):
        if blank(r.get(k)):
            err(f"{rid}: '{k}' is empty")
    if r.get("category") not in CATEGORIES:
        err(f"{rid}: invalid category '{r.get('category')}'")
    tags = r.get("tags", [])
    if not isinstance(tags, list) or len(tags) < 2:
        err(f"{rid}: needs at least 2 tags")
    else:
        for t in tags:
            if blank(t) or t != t.lower():
                err(f"{rid}: tag '{t}' must be non-empty lowercase")
    rc = r.get("relatedCalculation")
    if rc is not None and blank(rc):
        err(f"{rid}: relatedCalculation must be null or non-empty")

    src = r.get("source", {})
    for k in SOURCE_FIELDS:
        if blank(src.get(k)):
            err(f"{rid}: source.{k} is empty")

    v = r.get("verification", {})
    for k in VERIF_FIELDS:
        if k not in v:
            err(f"{rid}: verification.{k} missing")
    status = v.get("status")
    placeholder = any("TO VERIFY" in str(src.get(k, "")) for k in SOURCE_FIELDS)
    if status == "verified":
        if blank(v.get("reviewedBy")) or blank(v.get("reviewedOn")):
            err(f"{rid}: verified record needs reviewedBy and reviewedOn")
        elif not re.fullmatch(r"\d{4}-\d{2}-\d{2}", v["reviewedOn"]):
            err(f"{rid}: reviewedOn must be YYYY-MM-DD")
        if placeholder:
            err(f"{rid}: verified record still has TO VERIFY in source")
    elif status == "unverified":
        if v.get("reviewedBy") or v.get("reviewedOn"):
            err(f"{rid}: unverified record must not have reviewer fields")
    else:
        err(f"{rid}: verification.status must be 'verified' or 'unverified'")

if errors:
    print(f"FAIL: {len(errors)} problem(s) in {PATH}")
    for e in errors:
        print(" -", e)
    sys.exit(1)

unver = sum(1 for r in records if r["verification"]["status"] == "unverified")
print(f"OK: {len(records)} records valid ({unver} unverified, {len(records) - unver} verified)")
