# Iron-Mario Development Log

Use this document to record real work sessions. The estimates below describe the planned coding scope only; they are not completed-hour claims.

## Super-Micro Heroes update — September 2026

The game now has nine original character choices. Picking a card previews the
character, their environment, and their music before saving. The shared renderer
keeps the choice consistent across the game, including Flappy and both endings.

Mobile input needed more than buttons on the screen. Movement and jump must work
together, releasing one finger must not release the other, and a tap must not
count twice when the engine creates a mouse event. Those cases now have
regression checks. Repair dragging tracks the finger that picked up the chip,
and the memory game accepts taps on its arrow tiles.

The rename preserves existing desktop saves in the original Iron-Mario folder.
Old profiles start with Ember Rig and retain their records and audio settings.

The art and soundtrack are original programmatic work with AI assistance.
The public title is Super-Micro Heroes; no Marvel recordings were added.
Test evidence belongs in docs/TEST_REPORT.md. Actual human development time
still belongs in the session table below.

| Work area | Planned | Actual time | Date / evidence / notes |
|---|---:|---:|---|
| Project setup and input | 1 hour |  |  |
| GameManager and transitions | 2 hours |  |  |
| HUD and state | 1.5 hours |  |  |
| Minigames 1–2 | 2 hours |  |  |
| Minigames 3–4 | 2 hours |  |  |
| Minigames 5–7 | 3 hours |  |  |
| Winner/Death Scenes | 1.5 hours |  |  |
| Balancing and bug fixing | 1.5 hours |  |  |
| Testing/export/README | 1.5 hours |  |  |
| **Total planned coding scope** | **16.5 hours (approximately 16)** |  |  |

## Session record

Add one row after each real development session.

| Date | Start | End | Duration | Work completed | Test evidence |
|---|---|---|---:|---|---|
|  |  |  |  |  |  |

## Submission check

- Replace the README visual preview with a real in-engine screenshot or GIF.
- Confirm the actual-time total from the session record.
- Record the Godot version used for the final export.
- Record the exported build name and the platform tested.
