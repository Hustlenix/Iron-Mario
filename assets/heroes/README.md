# Hero Art

Nine original sprites, one per selectable hero, plus the existing Flappy bonus sprite
outside this folder.

## Provenance

Every file in this folder was hand-authored for Super-Micro Heroes as plain SVG
geometry: rectangles, circles, and polygon paths. No traced, ripped, or
machine-generated third-party art is used here, and no hero is a depiction of an
existing Marvel or DC character.

The nine heroes are original designs distinguished by silhouette and accent color,
so a player can identify the power family from shape alone at 32 px:

| File | Hero | Power | Family | Reads as |
|---|---|---|---|---|
| `dart.svg` | Dart | Lunge | DASH | Swept-back fins, forward-leaning visor |
| `bolt.svg` | Bolt | Overdrive | DASH | Wide wings, speed stripe |
| `echo.svg` | Echo | Sonar | REVEAL | Head-mounted dish and beacon |
| `frost.svg` | Frost | Deep Freeze | REVEAL | Crystal shoulders, diamond core |
| `tether.svg` | Tether | Tether | REACH | Hooked line trailing off the arm |
| `snap.svg` | Snap | Snap | REACH | Twin arm blades |
| `aegis.svg` | Aegis | Aegis | REACH | Large disc shield |
| `pulse.svg` | Pulse | Pulse | BLAST | Gauntlet fists, ringed emitter |
| `lance.svg` | Lance | Lance | BLAST | Single beam emitter, crested helmet |

`assets/flappy_hero.svg` is intentionally left in `assets/` and keeps its original
name; it is the no-power bonus character, not part of the nine-hero roster.

## Editing

All sprites share a 64x64 viewBox and match the chunky outlined style of
`assets/hero.svg`: `stroke="#1a1a1a"`, `stroke-width="1.5"`, flat fills, one glowing
core. Gradient ids are namespaced per file (`dartBody`, `boltBody`, ...) so the SVGs
can be loaded together without id collisions.
