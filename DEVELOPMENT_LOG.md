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


## Home and phone controls update

**What did you make?** A home screen where each of the seven games can be played on its own. Tournament has its own card, and Flappy stays available as a bonus. Single games now end with replay and home options.

**What was challenging?** The original manager assumed every game belonged to a tournament. Single-game results needed their own route without awarding Tournament records. Touch movement also needed to stay held while the other thumb jumps, even when a finger slides outside the pad.

**What changed for testing?** Slide the left pad and tap Jump with the right thumb. In Repair, tap a chip, lift, then tap its matching socket; dragging still works. Test each Home card, replay, return Home, and then start Tournament.

**What am I proud of?** This update makes the games easier to find and lets players practise a favourite without waiting for random selection.

Implementation and automated test work used AI assistance. Actual coding time for this update: **not yet recorded**. Physical phone feedback is still needed.

## Iron Mario: the core experience

**What did you make?** Iron Mario now leads an authored adventure through a workshop, skyline bridges, molten factory and Scrap King boss fight. The homepage offers that journey first. Twenty arcade cabinets, the seven quick games, Tournament and Flappy sit behind optional menu choices. The larger 105-game project remains available through a separate Vault export.

**What was challenging?** The longer games needed independent lives, scores, checkpoints and endings rather than the ten-second timer used by microgames. The boss needed readable attacks and a usable weakness window. The warehouse layouts needed proof that push-only puzzles could be solved. Browser builds also needed to package the preserved project without mixing its Godot version and save system into the adventure.

**What are you proud of?** Iron Mario has a clear role, movement with short hops and jump buffering, different stage hazards and an actual boss. The arcade work still has a place without taking over the first screen.

**What should testers know?** Start Adventure, try a short and long jump, blast turrets after their warning, and use the checkpoints. The boss core opens after its slam; jump the approaching ground pulse. Try each Arcade card, pause, replay and return Home. For Crate Shift, Z undoes. For Soft Landing, all three landing conditions must be safe. Test two fingers together on a real landscape phone. The separate Vault should open and return through IRON MARIO HOME.

AI assisted code, art generation through drawing commands, audio and tests. Automated checks supplement real playtesting. Actual hours for this update: **not recorded yet**; the earlier planned-hours table is not an actual-time claim.

## Finishing the twenty cabinets — 19 October 2026

**What did you make?** Finished the play flow for all twenty cabinets: each has a short controls screen, an explicit PLAY button, pause, results and replay. Touch players can continue between rounds without a keyboard. The original Iron Mario adventure remains the main experience.

**What was challenging?** A car should move at the same speed whether a phone sends ten drag events or a hundred. Ending a tennis rally on both the floor and boundary also needed to award one point, and undoing a solved crate room needed to undo its score as well.

**What are you proud of?** The arcade is playable as a set of separate games with their own goals and controls, rather than twenty menu entries sharing a short timer. Players can read the controls before a snake, lander or enemy starts moving.

**What should testers know?** Choose ARCADE, select a cabinet, then press Space/Enter or tap PLAY. Test a held road finger in Flag Run, tap to continue a cleared wave, and try undoing and re-solving the first crate room. The official Godot 4.4.1 source checks pass 316 assertions and launch every scene. Real phone and speaker testing is still needed. No actual human coding hours have been recorded for this update.


## Controls and landing visibility — 19 October 2026

**What did you make?** Fixed short jumps while holding Blast in the adventure, made swipe steering relative to the finger in Byte Munch and Dot Gobbler, and moved the lunar fuel gauge out of the flight area.

**What was challenging?** Keyboard events and held-action polling used different mappings. Blast could therefore count as a held Jump even after releasing the jump key. Swipes also measured the finger against the character position, which made an upward swipe on the right side turn right.

**What are you proud of?** These are small changes that remove surprising behaviour without changing the games or resetting anyone's progress.

**What should people know to test it?** Hold E, jump, and release Space early: Iron Mario should still make a short hop. In Byte Munch or Dot Gobbler, start an upward swipe anywhere in the playfield, then swipe sideways without lifting. In Soft Landing, check that the ship is visible at the start of every pad. The directional pad still works. Physical phone and audible playback testing remain outstanding.

AI assisted implementation and automated regression testing. Actual human coding time for this update has not been recorded.
