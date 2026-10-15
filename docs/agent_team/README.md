# Iron-Mario UI/UX team dispatch

This is a **150-role allocation**, not a claim that 150 agents run simultaneously or that 150 tasks are finished. The runtime allows four active agents, including the root coordinator. Agents are dispatched in batches when capacity is available.

The queue derives its 105 game-worker entries from the seven catalog files read by `GameRegistry`. Each worker owns exactly one existing game. The remaining roles are five leads (CEO, CTO, COO, design, QA) and 40 specialists. The dashboard reads `queue.json`; it does not fabricate agent activity.

## Priority and ownership

The first user milestone remains the original four-character superhero-selection experience. No worker may add a minigame or change gameplay, scoring, collision, input, timing, saves, or hit areas. The public roster must use original identities and artwork. Private reference concepts stay outside public exports.

All 105 workers have distinct write ownership: `ui/game_presentations/{game_id}.gd` and `docs/agent_team/worker_reports/{game_id}.md`. The 23 source scripts implement shared game packs and are **read-only to workers**. The CTO owns the shared presentation bridge. This prevents the 25 workers in each pack from editing the same file.

Each presentation extends `RefCounted` and implements `draw_background(canvas: Node2D, context: Dictionary) -> void`. Optional constants: `TITLE`, `SETTING`, `ACCENT`. The context contains `id`, `category`, `elapsed`, `reduced_motion`, `board_rect` (`Rect2(0, 0, 960, 480)`), and `cosmetic`. Draw original genre-specific scenery behind existing play elements; maintain quiet, readable core areas and respect reduced motion.

Each worker reads its actual game implementation and the captured baseline board, then writes its individual presentation and factual report. Workers must not run parallel Godot imports, mutate shared files, run Git, scrape assets, or claim render acceptance without captures. Root/QA perform the consolidated import, rendered capture, visual review, and existing test suites after integration.

## Dedicated-worker execution brief

Find your assigned ID in `queue.json`; read its `source_script`, the game's setup and paint branches, `ui/game_presentation.gd`, and `docs/UI_ACCEPTANCE_STANDARD.md`. **Call `view_image` on the assigned baseline PNG** before drawing. Work on this one game only and do not spawn child agents. Prefix every shell command with `rtk` according to `C:/Users/LalithReddy.b/.codex/RTK.md`.

Create a bespoke environment with multiple meaningful props and a depth layer that reinforces this specific action. A generic skyline or shared palette template is insufficient. Preserve existing dark `INK` outlines on a light, quiet active field. Existing bounds determine safe positions; decorative props must not masquerade as targets, hazards, lanes, or solid platforms. Use deterministic draw calls only: no RNG calls, transforms, gameplay/context mutation, resource imports, or engine processes. Use explicit GDScript types where inferred values could be `Variant`. Parent runs the consolidated engine checks.

Keep the task bounded: inspect the relevant setup/paint sections (roughly 250 source lines, not every unrelated branch), one baseline image, and produce roughly 60–130 lines of carefully typed presenter code. No extended research, speculative systems, or repeated image/engine generation. A static scene is sufficient when it has a distinct environment, meaningful props, restrained depth, and a clear active field.

Write the individual report with inspected source and active bounds, baseline observations, distinct setting and props, reduced-motion behavior, and any integration caveat. If the existing paint later draws an opaque full-board rectangle that could hide the presenter, flag that fact for parent integration instead of editing shared sources. State **implemented, awaiting rendered review**; do not claim a visual acceptance. Return the two owned paths and concise observations.

## Evidence states

- `queued`: role allocated; no active agent assigned.
- `running`: a real agent ID is assigned and has been dispatched.
- `implemented_awaiting_review`: unique presentation and report exist; rendered acceptance is still pending.
- `reviewed`: the specific output has recorded render/test evidence.
- `blocked`: the task has a recorded concrete blocker.

Leader completion is recorded as `completed` with a report or other real deliverable. Worker implementation is never counted as render acceptance. `dispatched_at`, `agent_id`, and `evidence` are populated only from actual dispatch and file/tool results.

Open `index.html` through a local HTTP server rooted at the repository (for example the existing project preview server). Browsers commonly block local-file JSON fetches; the dashboard will say so instead of showing fake counters.
