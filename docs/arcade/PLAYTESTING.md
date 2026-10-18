# Actual player feedback

Current completed human reviews: **0**. Automated QA is recorded separately in TWENTY_GAME_BETA.md and twenty-beta/.

Start with a small voluntary round. Ask each person to play two games for roughly three minutes each without coaching. Record their device, time to understand the controls, enjoyment from 1–5, replay answer, the biggest annoyance and what they actually did. “No issue noticed” is a valid observation; silence is not a positive review.

For the eventual 100-person study, reserve anonymous slots P001–P100 and collect two game observations per person. No names, email addresses or personal identifiers are needed. Do not generate fictional players or prefill ratings.

Store actual observations in the reviews array in playtests.json. Each observation has:

| Field | Value |
| --- | --- |
| kind | human |
| anonymousSlot | P001 through P100, assigned only to a real volunteer |
| gameId | Actual catalog id |
| device | Browser, keyboard/touch and device class reported by the player |
| understoodSeconds | Number of seconds if observed; null if not measured |
| enjoyment | Actual integer rating 1–5 |
| wouldReplay | Actual boolean response |
| observation | What the player did and their own comments |
| friction | Their single biggest annoyance, or “none reported” |
| recordedAt | Actual observation date/time |

Keep a separate observation per game. Retest recurring quit causes and confusing controls after a fix. Compare devices before drawing broad conclusions from a small sample. The release checker requires complete human observations for at least two distinct games; this is an initial release gate, not evidence of broad enjoyment or market demand.

The deployment command checks this file before changing any remote state. An invitation response such as “Yes” does not fill these fields. Publication of the source branch does not publish the beta to GitHub Pages.
