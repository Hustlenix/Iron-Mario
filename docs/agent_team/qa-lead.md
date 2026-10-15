# QA lead handoff

The QA lead owns only `tests/ui_visual_test.gd`, `tests/presentation_test.gd`, `tools/presentation_audit.py`, and this document. Application, gameplay, router and worker queue changes belong to their owners.

## Verified locally on 2026-10-09

- `HERO_UI_CHECKS=274 FAILURES=0` with Godot 4.7.1, native headless engine input and layout. The four obsolete HOME 960×540 assertions now validate actual HOME and GAMES viewport bounds, disabled gameplay routing, and destruction of the previous page. The gameplay 960×540 assertion remains in place. The suite creates an isolated test profile and restores the prior profile data/path in memory.
- `PRESENTATION_CHECKS=116 TESTED=7 PENDING=98 FAILURES=0`. Presenters available at this snapshot: `arc_dash`, `arc_snake`, `armor_repair`, `ball_sort`, `balloon_lift`, `balloon_pump`, `boulder_push`. These are executed engine draw callbacks, not source-only checks.
- `PRESENTATION_AUDIT CATALOG=105 IMPLEMENTED=7 PENDING=98 CAPTURED=0 ACCEPTED=0 ERRORS=0`. Individual ownership matches all 105 catalog IDs across the 23 existing gameplay sources; the seven available presenter source hashes are unique.
- A later inventory rerun recorded 9 implemented, 96 pending, 0 captures and 0 errors; this changes the source inventory, not the earlier seven-presenter engine coverage.
- `IMAGE_COMPARISON_SMOKE=4 FAILURES=0`: the audit's pixel comparison was exercised against temporary identical images, one changed pixel (25% of a 2×2 image), different dimensions and a missing capture. Temporary files stayed inside the project's build output and were removed after verification.
- The strict source gate was exercised with `--require-all`: the next snapshot contained 8 presenters and 97 pending IDs, and exited with the expected single missing-batch error. That rejection demonstrates that a partial batch cannot pass the final inventory gate; the eighth presenter was not part of the seven-presenter engine test above.

Godot crashed before startup inside this machine's sandbox. The successful engine runs used approved execution outside the sandbox. An initial QA change eagerly referenced the menu classes and provoked an autoload compilation error; that test-only change was corrected to inspect script resource paths before the successful 274-check rerun.

## Final batch commands

Use RTK for every shell invocation. Substitute the installed Godot executable if its location changes.

```powershell
rtk proxy C:/Users/LalithReddy.b/Godot/Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/ui_visual_test.gd -- --test
rtk proxy C:/Users/LalithReddy.b/Godot/Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/presentation_test.gd -- --test --require-all
rtk proxy C:/Users/LalithReddy.b/Godot/Godot_v4.7.1-stable_win64_console.exe --path . --script res://tests/presentation_test.gd -- --test --require-all --render-compare
rtk proxy python tools/presentation_audit.py --require-all --before build/visual-before/catalog-qa --after build/visual-after/catalog-qa
```

The presentation suite checks unsafe-path rejection, missing-ID fallback, optional metadata and typed constants, immutable draw context, global and seeded gameplay RNG preservation, unchanged gameplay storage and transforms, paused simulation, normal/reduced-motion draw execution, individual integration and node cleanup. Missing sources are pending in ordinary runs and failures with `--require-all`. The optional GPU comparison must run with a rendering display; it compares repeated paused pixels and reduced-motion pixels at elapsed 0 and 4. The headless result above did **not** run that optional GPU branch.

Reports are written under `build/visual-after/`: `hero_ui_test_report.json`, `presentation_test_report.json`, and `presentation_audit.json`. Treat Godot `SCRIPT ERROR`, `ERROR`, process failures and leaks as failures even if a summary is present. The final coordinator should retain the exact output and compare the tested list with the source inventory from the same final snapshot.

## Remaining acceptance work

This is shared integration QA, not catalog-wide visual acceptance. Per `docs/UI_ACCEPTANCE_STANDARD.md`, all 105 games still need comparable baseline/after and action-state captures, hierarchy/geometry/feedback review, lifecycle validation, and a recorded reviewer outcome. The audit marks image presence as **captured**, source presence as **implemented**, and no rows as accepted. Numerical image differences and unique source hashes do not establish a unique or successful artistic composition. Capture files may be stale; compare manifests, seed, difficulty, elapsed state and board dimensions separately before interpreting a difference.

The available-presenter counts are a snapshot while workers continue. The strict final checks must run again when the batch is finished. Native engine, browser, deployed runtime, physical touch and controller results remain separate evidence categories. No browser, publication or physical-device result was established by these QA checks.
