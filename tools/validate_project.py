#!/usr/bin/env python3
"""Static project checks for environments where the Godot binary is unavailable."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = [
    "project.godot",
    "scenes/title_screen.tscn",
    "scenes/intermission.tscn",
    "scenes/winner_scene.tscn",
    "scenes/death_scene.tscn",
    "scripts/Global.gd",
    "scripts/GameManager.gd",
    "scripts/MiniGameBase.gd",
    "scenes/adventure/iron_adventure.tscn",
    "scenes/arcade_library.tscn",
    "scripts/adventure/AdventureMotor.gd",
    "scripts/arcade/ArcadeGameBase.gd",
    "scripts/arcade/ArcadeCatalog.gd",
]
REQUIRED_ACTIONS = ["move_left", "move_right", "jump", "action", "restart", "click"]
RESOURCE_PATTERN = re.compile(
    r"res://[A-Za-z0-9_./-]+(?:\.gd|\.tscn|\.tres|\.res|\.svg|\.png|\.wav|\.ogg)"
)


def main() -> int:
    errors: list[str] = []
    for relative in REQUIRED_FILES:
        if not (ROOT / relative).is_file():
            errors.append(f"missing required file: {relative}")

    minigame_scenes = sorted((ROOT / "scenes/minigames").glob("*.tscn"))
    minigame_scripts = sorted((ROOT / "scripts/minigames").glob("*.gd"))
    if len(minigame_scenes) != 7:
        errors.append(f"expected 7 minigame scenes, found {len(minigame_scenes)}")
    if len(minigame_scripts) != 7:
        errors.append(f"expected 7 minigame scripts, found {len(minigame_scripts)}")

    cabinet_scenes = sorted((ROOT / "scenes/arcade").glob("*.tscn"))
    catalog = (ROOT / "scripts/arcade/ArcadeCatalog.gd").read_text(encoding="utf-8")
    cabinet_ids = re.findall(r'^\s*\["([a-z_]+)",', catalog, re.MULTILINE)
    if len(cabinet_ids) != 20 or len(set(cabinet_ids)) != 20:
        errors.append("arcade catalog must contain 20 unique cabinets")
    if {scene.stem for scene in cabinet_scenes} != set(cabinet_ids):
        errors.append("arcade scenes and catalog IDs do not match")
    guide_ids = re.findall(r'^\s*"([a-z_]+)":\["[^"]+","[^"]+"\]', catalog, re.MULTILINE)
    if set(guide_ids) != set(cabinet_ids):
        errors.append("every cabinet needs keyboard and touch controls")
    for scene in cabinet_scenes:
        if f'game_id = "{scene.stem}"' not in scene.read_text(encoding="utf-8"):
            errors.append(f"{scene.relative_to(ROOT)} has the wrong cabinet ID")

    # Other checkouts can sit beside this project in a shared workspace.
    # Their res:// paths belong to their own project, not this one.
    checked_files = [ROOT / "project.godot"]
    for directory in ["scripts", "scenes", "tools"]:
        checked_files.extend((ROOT / directory).rglob("*.gd"))
        checked_files.extend((ROOT / directory).rglob("*.tscn"))
    combined = ""
    for source in checked_files:
        if not source.is_file():
            continue
        text = source.read_text(encoding="utf-8")
        combined += text
        for resource in RESOURCE_PATTERN.findall(text):
            target = ROOT / resource.removeprefix("res://")
            if not target.is_file():
                errors.append(f"{source.relative_to(ROOT)} references missing {resource}")

    for action in REQUIRED_ACTIONS:
        if f'"{action}"' not in combined:
            errors.append(f"input action not registered: {action}")

    if "DEFAULT_LIVES := 5" not in combined:
        errors.append("existing five reactor lives must be preserved")
    if combined.count("minigame_won") < 2 or combined.count("minigame_lost") < 2:
        errors.append("shared minigame result signals are not fully connected")
    if "pass #" in combined or "PLACEHOLDER_LOGIC" in combined:
        errors.append("unfinished logic marker found")

    if errors:
        print("STATIC VALIDATION FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    print("STATIC VALIDATION PASSED")
    print(f"- {len(minigame_scenes)} minigame scenes")
    print(f"- {len(minigame_scripts)} minigame scripts")
    print(f"- {len(cabinet_scenes)} arcade scenes match the catalog")
    print("- every arcade scene has its matching ID and keyboard/touch guide")
    print("- adventure, movement, and arcade shared systems exist")
    print("- all res:// file references resolve")
    print("- required InputMap actions are registered")
    print("- shared result signals and five-life state are present")
    return 0


if __name__ == "__main__":
    sys.exit(main())
