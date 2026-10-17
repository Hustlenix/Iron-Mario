# Sidecourt, Hopway and Flag Run

These are independent original modules in onlyeducation/arcade/games, with plain Canvas geometry and synthesized sound. No original commercial source code, characters or level layouts were imported.

## Sidecourt
Side-view gravity tennis. The ball may bounce once on each side before another bounce loses the point. Move left/right under the incoming trajectory; choose a lob with Up or a drive with Down; hold Action for swings and serves. Pointer dragging also moves the player. A capped-speed computer opponent tracks reachable returns. First to five wins, with scored returns and match points.

Historical context: Brookhaven National Laboratory describes William Higinbotham's 1958 Tennis for Two as an interactive analog-computer tennis display for its visitors. Sidecourt uses an independently authored player-movement and opponent system.
[Brookhaven — Tennis for Two](https://www.bnl.gov/about/history/firstvideo.php).

## Hopway
Hop from the bottom verge through moving traffic and across logs. Logs carry the player; water without a supporting log and traffic contact cost lives. Four distinct home bays make a round; three rounds speed up the lanes. Four lives and a per-crossing timer bound the run. Dpad/arrows hop; Action hops forward; tapping toward a direction also works. Authored lane parameters and generated phases are original.

Historical context: The Strong's collection record identifies Frogger's 1981 U.S. release and its road/river crossing structure. Hopway has its own artwork, hazards, timings and progression.
[The Strong collection record](https://artsandculture.google.com/asset/arcade-game-frogger/VwFdTWvOkRkBdg?hl=en).

## Flag Run
An original overhead road grid with six flags, two fuel cans, pursuing cars, limited fuel and smoke. Collect every flag and return to E through three different districts. BFS pathfinding guides pursuers; smoke can stun them but costs twelve fuel. Dpad/arrows steer; dragging selects a direction; Action releases smoke. Picked flags survive a crash, so a mistake does not erase all progress.

Historical context: Namco's official New Rally-X page describes flag collection, smoke and fuel in the related 1981 game. The catalog's 1980 inspiration date refers to the preceding Rally-X; this linked page is specifically its sequel, not evidence of the first game's date.
[Namco — New Rally-X](https://www.bandainamcoent.co.jp/cs/list/nm_psp/newrally-x.php).
The new module's maps and route choices were authored for this project.

## Verification
26 Node tests cover deterministic play, bounds, serve/swing timing, gravity, opponent returns, point/match outcomes, road/log/home/timeout rules, flag/fuel/smoke and pursuit interactions, progression, and terminal freeze.

The real-browser suite tools/court_hop_flag_browser.cjs separately exercises Sidecourt serving/returns and a point, Hopway scoring and an actual traffic collision, and Flag Run movement/flag/fuel/smoke. All three pass touch, pause, restart and exit checks. It does not establish complete human-played campaigns or physical mobile-device quality. Evidence: build/arcade/wave-b/court-hop-flag/report.json and adjacent real screenshots.

References checked 2026-10-17.
