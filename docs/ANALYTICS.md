# Analytics and telemetry

Super-Micro Heroes uses one privacy-first telemetry layer for the GitHub Pages build.

## What is tracked

The game emits gameplay events for:

- page load, PLAY, successful game load, fullscreen, and page exit
- home views and game selection
- tournament start, completion, failure, and run duration
- single-game starts/results/replays
- mission start, win/loss, restart, abandonment, elapsed time, time left, average FPS, minimum FPS, and aggregated control counts
- first use of each keyboard/mouse/touch control per mission
- portrait-orientation prompts and focus/orientation pause/resume duration
- hero changes by stable hero ID only
- Flappy starts, milestones, game-over score, retries, and exits
- scene-change and browser/runtime errors

The telemetry intentionally does **not** send the pilot callsign, typed text, email addresses, or raw pointer coordinates.

## Providers

The Web export can connect to all three providers:

1. **Google Analytics 4** — traffic, acquisition, devices, funnels, custom game events, retention.
2. **Microsoft Clarity** — shell/UI behavior, heatmaps and recordings where the browser can observe DOM interactions. The Godot game itself is rendered in a canvas, so do not expect Clarity to reconstruct gameplay inside the canvas; use the custom gameplay events for that.
3. **Sentry** — JavaScript/runtime errors plus game-event breadcrumbs for debugging context.

All providers are optional. The game still works when none are configured.

## Connect the production providers

Open the repository on GitHub and go to:

**Settings → Secrets and variables → Actions → Variables**

Create these repository variables:

| Variable | Value |
| --- | --- |
| `GA4_MEASUREMENT_ID` | Your GA4 Web stream measurement ID, for example `G-XXXXXXXXXX` |
| `CLARITY_PROJECT_ID` | The project ID from Microsoft Clarity |
| `SENTRY_LOADER_URL` | The Browser JavaScript Loader URL from Sentry, normally `https://js.sentry-cdn.com/<public-key>.min.js` |

These are client-side identifiers/URLs that end up in the public Web build. Do not put private API tokens in them.

For Sentry, configure the loader for error monitoring and keep Sentry Session Replay disabled unless you have deliberately reviewed its privacy implications.

After setting the variables, run **Build, test, and publish** from GitHub Actions or push a commit to `main`. The workflow injects the values into the exported `index.html` before browser tests and deployment.

## Consent behavior

Analytics is off by default on a device.

The launch screen has an **ALLOW ANALYTICS** control. The choice is saved as:

`localStorage["smh_analytics_consent_v1"]`

Providers are not loaded until the player enables analytics. Turning analytics off reloads the page so previously loaded third-party scripts are removed from that browser session.

Google Analytics is initialized with Google Signals and ad-personalization signals disabled.

## Debug without any provider account

The Web shell keeps the latest 100 sanitized telemetry events locally in memory:

```js
window.__SMH_ANALYTICS_DEBUG__
```

Open DevTools → Console and inspect that array while playing. This lets you validate event names and parameters even before GA4, Clarity, or Sentry is connected.

## Important GA4 events

| Event | Purpose |
| --- | --- |
| `page_loaded` | Browser game page opened |
| `play_clicked` | Player pressed PLAY |
| `game_loaded` | Godot finished starting; includes load time |
| `game_session_start` / `game_session_end` | Run-level funnel and duration |
| `game_selected` | Single minigame selected |
| `tournament_started` | Tournament entered |
| `tournament_completed` | Seven-mission tournament cleared |
| `tournament_failed` | Tournament ended with no lives |
| `mission_started` | Mission became playable |
| `mission_completed` | Mission won |
| `mission_failed` | Mission lost |
| `mission_restarted` | Player restarted |
| `mission_abandoned` | Mission exited/replaced |
| `control_used` | First use of a control/input type in a mission |
| `orientation_warning` / `orientation_fixed` | Portrait interruption |
| `game_paused` / `game_resumed` | Focus/orientation interruptions |
| `flappy_started` / `flappy_game_over` | Bonus-game funnel |
| `client_error` / `game_error` | Browser/Godot integration failures |

Mission-completion events also include aggregated `controls_*` counts and FPS metrics, which are more useful than sending one network event for every button press.

## Suggested GA4 explorations

Build funnels for:

`page_loaded → play_clicked → game_loaded → game_session_start → mission_completed`

and:

`tournament_started → mission_completed → tournament_completed`

Useful breakdowns are `mission_id`, `mode`, `input_type`, `device_class`, and `orientation`.

For standard GA4 reports, register the event parameters you care about as custom dimensions/metrics in the GA4 property.

## Adding future monetization

Do not fabricate monetization events before the game has monetization. When ads, a shop, or purchases are actually added, send them through the same central API:

```gdscript
Analytics.track("shop_opened", {"source": "home"})
Analytics.track("purchase_started", {"item_id": "example_item"})
```

Use GA4's recommended ecommerce/ad event names where they apply to the real implementation.
