# Phase 1 — Rename to Super-Mario Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Change every player-visible name from Iron-Mario to Super-Mario, without touching the repository folder or rewriting historical documents.

**Architecture:** Five files change, each a single value or a single string. No logic moves, no scenes are restructured, and no file paths are renamed, so the build and deploy pipeline are unaffected.

**Tech Stack:** Godot 4.7.1, `project.godot`, `export_presets.cfg`, GDScript-free (config and scene-text only), PowerShell for verification.

## Global Constraints

- Godot 4.7.1, engine binary at `C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe`.
- Always run Godot with `--headless --path C:\Users\LalithReddy.b\Iron-Mario`.
- The player-visible name is `Super-Mario`. The repository folder stays `Iron-Mario`.
- The absolute path `C:\Users\LalithReddy.b\Iron-Mario` appearing inside README instructions is correct and must not be changed.
- Historical documents under `docs/superpowers/` and `.superpowers/sdd/` are not rewritten.
- The game must stay playable on desktop keyboard and mouse.

## File Structure

| File | Change | Responsibility after |
|---|---|---|
| `project.godot` | `config/name` | Window and taskbar title |
| `scenes/title_screen.tscn` | `TitleLabel` text | The big logo on the title screen |
| `export_presets.cfg` | 4 values | Web app name, Windows binary name and metadata |
| `README.md` | heading + note | Repo documentation |
| `tools/gen_audio.ps1` | header comment | Tool documentation |

---

### Task 1: Verify the baseline is green

Nothing changes until the current build is confirmed working, so any later failure
is attributable to this phase.

**Files:** none modified.

**Interfaces:**
- Consumes: nothing
- Produces: a known-good baseline to compare against

- [ ] **Step 1: Run the headless boot check**

```powershell
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --quit-after 30 2>&1 | Tee-Object -Variable boot
```

Expected: process exits, and `$boot` contains no `SCRIPT ERROR` and no `ERROR:` lines. A clean baseline prints engine banner lines only.

- [ ] **Step 2: Record the working tree state**

```powershell
rtk git status --short
```

Expected: empty output. Any output here means pre-existing uncommitted work that must be dealt with before editing.

- [ ] **Step 3: Commit nothing yet**

No files are touched in this task, so there is nothing to commit. This task exists to establish the baseline.

---

### Task 2: Write the failing rename check

The check defines what "renamed" means, and it must fail before the edits and pass
after. Without it there is no proof the rename is complete.

**Files:** none modified. The check is run inline.

**Interfaces:**
- Consumes: the five target files listed in File Structure
- Produces: a repeatable pass/fail assertion used by Task 4

- [ ] **Step 1: Run the check and confirm it fails**

```powershell
$fail = @()
Select-String -Path "project.godot","export_presets.cfg","tools\gen_audio.ps1" -Pattern 'Iron-Mario' |
  ForEach-Object { $fail += "$($_.Filename):$($_.LineNumber)  $($_.Line.Trim())" }
Select-String -Path "scenes\title_screen.tscn" -Pattern 'IRON\[/color\]' |
  ForEach-Object { $fail += "title_screen.tscn:$($_.LineNumber)  $($_.Line.Trim())" }
Select-String -Path "README.md" -Pattern '^# IRON-MARIO' |
  ForEach-Object { $fail += "README.md:$($_.LineNumber)  $($_.Line.Trim())" }
if ($fail.Count) { $fail; "`nFAIL: player-visible Iron-Mario remains" } else { "PASS" }
```

Expected: FAIL, listing eight hits — one in `project.godot`, four in
`export_presets.cfg`, one in `tools/gen_audio.ps1`, one in `title_screen.tscn`,
and one in `README.md`.

- [ ] **Step 2: Confirm the README false positive is excluded**

```powershell
Select-String -Path "README.md" -Pattern 'Iron-Mario'
```

Expected: exactly one hit, and it is the `--path "C:\Users\LalithReddy.b\Iron-Mario"` instruction line. This line is correct and must survive the rename. If the check above ever flags this line, the pattern has drifted and must be narrowed to `^# IRON-MARIO`.

---

### Task 3: Apply the rename

Seven string changes across four files, plus two documentation edits.

**Files:**
- Modify: `project.godot:13`
- Modify: `scenes/title_screen.tscn:167`
- Modify: `export_presets.cfg:42`
- Modify: `export_presets.cfg:60`
- Modify: `export_presets.cfg:80`
- Modify: `export_presets.cfg:81`
- Modify: `README.md:1`
- Modify: `tools/gen_audio.ps1:2`

**Interfaces:**
- Consumes: nothing
- Produces: the renamed state that Task 4 verifies

- [ ] **Step 1: Rename the project**

In `project.godot`, change line 13:

```gdscript
config/name="Super-Mario"
```

Replaces `config/name="Iron-Mario"`. Nothing else in this file changes.

- [ ] **Step 2: Rename the title screen logo**

In `scenes/title_screen.tscn`, change the `TitleLabel` `text` property on line 167:

```
text = "[center][color=#ffd34d]SUPER[/color][color=#e8403f]-[/color][color=#ffd34d]MARIO[/color][/center]"
```

Only the word `IRON` becomes `SUPER`. The three colour tags, the dash in red, and
the `MARIO` segment are unchanged, so the logo keeps its two-tone gold-and-red look.

- [ ] **Step 3: Rename the web app name**

In `export_presets.cfg`, change line 42:

```
progressive_web_app/app_name="SUPER-MARIO"
```

Replaces `progressive_web_app/app_name="IRON-MARIO"`. This is the name a phone shows under the installed icon. It is set now even though Phase 2 enables the PWA, so the two phases do not fight over the same line.

- [ ] **Step 4: Rename the Windows export path**

In `export_presets.cfg`, change line 60:

```
export_path="build/windows/Super-Mario.exe"
```

Replaces `export_path="build/windows/Iron-Mario.exe"`. Godot derives the `.pck` name from this, so both artifacts rename together.

- [ ] **Step 5: Rename the Windows product name**

In `export_presets.cfg`, change line 80:

```
application/product_name="SUPER-MARIO"
```

Replaces `application/product_name="IRON-MARIO"`. This is what Windows shows in its file properties and task manager.

- [ ] **Step 6: Rename the Windows file description**

In `export_presets.cfg`, change line 81:

```
application/file_description="SUPER-MARIO game"
```

Replaces `application/file_description="IRON-MARIO game"`.

- [ ] **Step 7: Rename the README heading and add the fan-project note**

In `README.md`, change line 1:

```markdown
# SUPER-MARIO
```

Replaces `# IRON-MARIO`. Then insert directly beneath it, before the existing next line:

```markdown
> **Fan project.** Super-Mario is an unofficial, non-commercial project and is not
> affiliated with or endorsed by Nintendo, Marvel, DC, or any film or comic
> publisher. All characters and audio in this project are original creations
> inspired by superhero conventions. The title resembles a trademarked property —
> check before publishing commercially.
```

- [ ] **Step 8: Update the audio tool comment**

In `tools/gen_audio.ps1`, change line 2:

```powershell
# Generates Super-Mario's sound assets as 16-bit PCM mono 22050 Hz WAV files.
```

Replaces `# Generates Iron-Mario's sound assets as 16-bit PCM mono 22050 Hz WAV files.` Comment only; no behaviour changes.

---

### Task 4: Verify the rename

- [ ] **Step 1: Re-run the rename check and confirm it passes**

```powershell
$fail = @()
Select-String -Path "project.godot","export_presets.cfg","tools\gen_audio.ps1" -Pattern 'Iron-Mario' |
  ForEach-Object { $fail += "$($_.Filename):$($_.LineNumber)  $($_.Line.Trim())" }
Select-String -Path "scenes\title_screen.tscn" -Pattern 'IRON\[/color\]' |
  ForEach-Object { $fail += "title_screen.tscn:$($_.LineNumber)  $($_.Line.Trim())" }
Select-String -Path "README.md" -Pattern '^# IRON-MARIO' |
  ForEach-Object { $fail += "README.md:$($_.LineNumber)  $($_.Line.Trim())" }
if ($fail.Count) { $fail; "`nFAIL: player-visible Iron-Mario remains" } else { "PASS" }
```

Expected: `PASS`, with no hits listed.

- [ ] **Step 2: Re-import so Godot registers the new project name**

```powershell
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --import 2>&1 | Tee-Object -Variable imp
```

Expected: import completes with no `SCRIPT ERROR`. Some `Editor` or `Godot Engine` banner lines are normal.

- [ ] **Step 3: Re-run the headless boot check**

```powershell
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --quit-after 30 2>&1 | Tee-Object -Variable boot2
```

Expected: no `SCRIPT ERROR` and no `ERROR:` lines. Output matches the Task 1 baseline, confirming the rename broke nothing.

- [ ] **Step 4: Confirm the new values are actually present**

```powershell
Select-String -Path "project.godot" -Pattern 'config/name'
Select-String -Path "export_presets.cfg" -Pattern 'Super-Mario|SUPER-MARIO'
Select-String -Path "scenes\title_screen.tscn" -Pattern 'SUPER\[/color\]'
```

Expected: `config/name="Super-Mario"`; four `export_presets.cfg` hits covering the PWA name, export path, product name, and file description; and one `title_screen.tscn` hit showing the `SUPER` segment.

- [ ] **Step 5: Confirm nothing outside the intended surface changed**

```powershell
rtk git status --short
rtk git diff --stat
```

Expected: exactly five modified files — `project.godot`, `scenes/title_screen.tscn`, `export_presets.cfg`, `README.md`, `tools/gen_audio.ps1` — plus the two new documentation files from this phase's planning. No file renames, no deletions, no stray `.uid` or `.import` churn staged for commit.

---

### Task 5: Export and commit

- [ ] **Step 1: Export the web build to prove the preset is valid**

```powershell
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --export-release "Web" build/web/index.html 2>&1 | Tee-Object -Variable web
```

Expected: export completes, no `ERROR:` lines, and `build/web/index.wasm` exists.

- [ ] **Step 2: Confirm the export artifacts exist**

```powershell
Get-Item build\web\index.html, build\web\index.wasm | Select-Object Name, Length, LastWriteTime
```

Expected: both files with a non-zero length and a timestamp from this run.

- [ ] **Step 3: Review the diff before staging**

```powershell
rtk git diff
```

Expected: only the seven string changes from Task 3 and the README note. Read every hunk. If anything unexpected appears, stop and investigate rather than staging it.

- [ ] **Step 4: Stage only the intended files**

```powershell
rtk git add project.godot scenes/title_screen.tscn export_presets.cfg README.md tools/gen_audio.ps1
rtk git status --short
```

Expected: those five files staged as modifications. The planning documents are staged separately in the following commit so this one stays reviewable on its own.

- [ ] **Step 5: Commit the rename**

```powershell
rtk git commit -m "chore(rename): ship as Super-Mario"
```

- [ ] **Step 6: Commit the design and plan documents**

```powershell
rtk git add docs/superpowers/specs/2026-09-26-super-mario-upgrades-design.md docs/superpowers/plans/2026-09-26-super-mario-upgrades.md docs/superpowers/plans/2026-09-26-phase-1-rename.md
rtk git commit -m "docs: design and plan for the Super-Mario upgrade set"
```

- [ ] **Step 7: Confirm the tree is clean**

```powershell
rtk git status --short
```

Expected: empty output.

---

## Self-review

**Spec coverage:** every player-visible name in the design's Phase 1 list is covered —
project name, title logo, web app name, Windows product name, file description,
export path, README heading, audio tool comment. The design's fan-project note is
covered by Task 3 Step 7.

**Placeholder scan:** no TBD, no "similar to Task N", no unspecified code. Every
config step shows the literal replacement string, and every verification step shows
the literal command and its expected output.

**Type and name consistency:** the value `Super-Mario` in `project.godot`,
`SUPER-MARIO` in the four uppercase export fields, and `Super-Mario.exe` in the
export path are intentionally different casings because they populate different
platform fields. The README heading uses `SUPER-MARIO` to match the on-screen logo.
These are deliberate, not drift.

**Known non-goal:** the deploy workflow artifact is named `web-build` and contains
no game name, so `.github/workflows/deploy.yml` is intentionally untouched. The
GitHub Pages URL still reads `/Iron-Mario` because it derives from the repository
name, which is not changing.
