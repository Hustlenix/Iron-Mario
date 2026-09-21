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

    checked_files = list(ROOT.rglob("*.gd")) + list(ROOT.rglob("*.tscn")) + [ROOT / "project.godot"]
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
    print("- all res:// file references resolve")
    print("- required InputMap actions are registered")
    print("- shared result signals and five-life state are present")
    return 0


if __name__ == "__main__":
    sys.exit(main())

