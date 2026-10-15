"""Inventory individual presenters and comparable capture evidence; never accept art.

Run while workers are active, or add --require-all for the final batch gate.
Image comparison is numerical evidence only, not an aesthetic review outcome.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from collections import defaultdict
from pathlib import Path

CATALOGS = (
    "microgames/pack_a.json", "microgames/pack_b.json", "microgames/pack_c.json",
    "games/classics_a.json", "games/classics_b.json", "games/cabinets.json", "games/chaos.json",
)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def image_evidence(before: Path, after: Path) -> dict:
    result = {"before_exists": before.is_file(), "after_exists": after.is_file()}
    if not after.is_file():
        return result
    result["after_sha256"] = digest(after.read_bytes())
    if not before.is_file():
        result["comparison"] = "missing_baseline"
        return result
    result["before_sha256"] = digest(before.read_bytes())
    try:
        from PIL import Image, ImageChops, ImageStat
        with Image.open(before) as first, Image.open(after) as second:
            result["before_dimensions"] = list(first.size)
            result["after_dimensions"] = list(second.size)
            if first.size != second.size:
                result["comparison"] = "dimensions_differ"
                return result
            difference = ImageChops.difference(first.convert("RGB"), second.convert("RGB"))
            result["mean_absolute_rgb_difference"] = sum(ImageStat.Stat(difference).mean) / 3
            pixels = difference.convert("RGB").getdata()
            result["changed_pixel_fraction"] = sum(any(pixel) for pixel in pixels) / (first.width * first.height)
            result["comparison"] = "pixels_identical" if difference.getbbox() is None else "pixels_changed"
    except ImportError:
        result["comparison"] = "pixel_comparison_unavailable_Pillow_missing"
    except (OSError, ValueError) as error:
        result["comparison"] = "invalid_image"
        result["image_error"] = str(error)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--before", type=Path, default=Path("build/visual-before/catalog-qa"))
    parser.add_argument("--after", type=Path, default=Path("build/visual-after/catalog-qa"))
    parser.add_argument("--output", type=Path, default=Path("build/visual-after/presentation_audit.json"))
    parser.add_argument("--require-all", action="store_true")
    args = parser.parse_args()
    root = args.root.resolve()

    def resolve(path: Path) -> Path:
        return path if path.is_absolute() else root / path

    errors: list[str] = []
    catalog = [entry for path in CATALOGS for entry in json.loads((root / path).read_text(encoding="utf-8-sig"))]
    ids = [entry["id"] for entry in catalog]
    if len(ids) != 105 or len(set(ids)) != 105:
        errors.append("Expected 105 unique existing catalog IDs")
    queue = json.loads((root / "docs/agent_team/queue.json").read_text(encoding="utf-8-sig"))
    workers = [role for role in queue["roles"] if role["kind"] == "worker"]
    if len(workers) != 105 or {role["game_id"] for role in workers} != set(ids):
        errors.append("Worker allocation must map exactly to the 105 catalog IDs")
    owners: dict[str, list[str]] = defaultdict(list)
    for role in workers:
        for path in role.get("owned_paths", []):
            owners[path].append(role["role_id"])
        expected = f"ui/game_presentations/{role['game_id']}.gd"
        if expected not in role.get("owned_paths", []):
            errors.append(f"{role['role_id']} lacks its individual presentation ownership")
    duplicate_ownership = {path: assigned for path, assigned in owners.items() if len(assigned) > 1}
    if duplicate_ownership:
        errors.append("Worker paths have overlapping ownership")
    rows = []
    source_hashes: dict[str, list[str]] = defaultdict(list)
    geometry_hashes: dict[str, list[str]] = defaultdict(list)
    pending = []
    for entry in catalog:
        game_id = entry["id"]
        if not re.fullmatch(r"[a-z0-9_]+", game_id):
            errors.append(f"Unsafe catalog identifier: {game_id}")
            continue
        path = root / "ui/game_presentations" / f"{game_id}.gd"
        row = {"id": game_id, "source": path.relative_to(root).as_posix(), "source_exists": path.is_file()}
        if path.is_file():
            source = path.read_text(encoding="utf-8-sig")
            row["source_sha256"] = digest(source.encode())
            row["source_lines"] = len(source.splitlines())
            source_hashes[row["source_sha256"]].append(game_id)
            code = re.sub(r"#.*", "", source)
            # Geometry duplicate candidates ignore metadata, colour and whitespace.
            # A match requests human inspection; it does not establish equivalence.
            geometry = re.sub(r"(?m)^\s*const\s+(?:TITLE|SETTING|ACCENT).*?$", "", code)
            geometry = re.sub(r"Color\([^)]*\)", "Color", geometry)
            geometry = re.sub(r"\s+", "", geometry)
            row["geometry_candidate_sha256"] = digest(geometry.encode())
            geometry_hashes[row["geometry_candidate_sha256"]].append(game_id)
            if not re.search(r"(?m)^extends\s+RefCounted\s*$", code):
                errors.append(f"{game_id}: source is not a direct RefCounted presenter")
            if not re.search(r"func\s+draw_background\s*\(", code):
                errors.append(f"{game_id}: draw_background method absent")
            risky = re.findall(r"\b(?:randf|randi|randf_range|randi_range|randomize|seed|draw_set_transform|draw_set_transform_matrix|add_child|queue_free|set_process)\s*\(", code)
            row["forbidden_call_candidates"] = risky
            if risky:
                errors.append(f"{game_id}: forbidden state/RNG/transform call needs repair: {', '.join(risky)}")
        else:
            pending.append(game_id)
        evidence = image_evidence(resolve(args.before) / f"{game_id}_board.png", resolve(args.after) / f"{game_id}_board.png")
        row["capture_evidence"] = evidence
        row["evidence_stage"] = "captured" if evidence["after_exists"] else ("implemented" if path.is_file() else "queued")
        row["review_outcome"] = "not_reviewed_by_this_audit"
        rows.append(row)
    duplicates = {key: values for key, values in source_hashes.items() if len(values) > 1}
    if duplicates:
        errors.append("Exact duplicate presenter sources found")
    if args.require_all and pending:
        errors.append(f"{len(pending)} individual presenters remain missing")
    report = {
        "catalog_count": len(ids), "worker_count": len(workers),
        "implemented_count": len(ids) - len(pending), "pending_count": len(pending),
        "captured_count": sum(row["capture_evidence"]["after_exists"] for row in rows),
        "baseline_capture_count": sum(row["capture_evidence"]["before_exists"] for row in rows),
        "changed_capture_count": sum(row["capture_evidence"].get("comparison") == "pixels_changed" for row in rows),
        "identical_capture_count": sum(row["capture_evidence"].get("comparison") == "pixels_identical" for row in rows),
        "dimension_mismatch_count": sum(row["capture_evidence"].get("comparison") == "dimensions_differ" for row in rows),
        "accepted_by_this_audit": 0, "require_all": args.require_all,
        "source_script_count": len({entry["script"] for entry in catalog}),
        "unique_source_hash_count": len(source_hashes), "duplicate_ownership": duplicate_ownership,
        "exact_duplicate_sources": duplicates,
        "geometry_duplicate_candidates_for_review": {key: values for key, values in geometry_hashes.items() if len(values) > 1},
        "pending": pending, "errors": errors, "rows": rows,
        "limitation": "Source allocation, hashes and numerical before/after captures only. Capture files may be stale; verify their manifests, seed, difficulty and elapsed state separately. Shared passes and changed pixels do not establish gameplay, visual acceptance or physical-device results.",
    }
    output = resolve(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"PRESENTATION_AUDIT CATALOG={len(ids)} IMPLEMENTED={report['implemented_count']} PENDING={len(pending)} CAPTURED={report['captured_count']} ACCEPTED=0 ERRORS={len(errors)}")
    for error in errors:
        print(error)
    print(f"Report: {output}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
