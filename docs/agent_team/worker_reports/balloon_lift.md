# Balloon Lift presentation

Status: **implemented, awaiting rendered review**.

Inspected the assigned queue row, presentation contract, UI acceptance standard, `microgames/pack_b.gd` setup (81–83), movement (216–222), input (304–305), paint (489–495), and the supplied `build/visual-before/catalog-qa/balloon_lift_board.png`. The baseline has a cream field, red balloon and suspended hero, a green ROOF goal, an opaque blue destination block, and faint floor dashes; it lacks a particular setting.

The actor starts at (150, 365), advances right, rises while held, and sinks on release. Actor center limits are y35–425; the destination is (810, 130), with success evaluated after x765. Its balloon extends 68 pixels above the actor center. The existing destination block occupies x765–905/y170–430 and the goal x730–890/y95–165. The presentation leaves the instruction band and travel field light and quiet.

Implemented an original rooftop balloon-post setting. A strapped helium cylinder with valve and coiled filling hose sits at x17–97 near the launch edge. A static windsock sits at x20–89. Warm, broad cloud silhouettes add sky depth without closed circular targets. A distant roof and tiny windows sit below y444. A narrow annex and radio antenna beyond x911 situate the existing destination tower. Their pale values keep dark gameplay outlines dominant. There are no decorative labels, new targets, route markings, or active platforms.

All scenery is static and deterministic, so reduced motion and pause require no animated exception. No RNG, transforms, resource imports, input edits, or gameplay/context mutation were added. The shared paint now guards its full-board PAPER rectangle with `presentation == null`; therefore no later full-board fill should cover this presenter. The existing blue block remains opaque and will hide any background behind its own bounds; this composition keeps the annex outside those bounds.

Only the two assigned paths were written. No engine or Git process was run. Parent integration must compile and capture the resting and action states, inspect the top-limit balloon against the instruction band, and perform gameplay/lifecycle and responsive review. Source implementation is not visual acceptance.
