# OnlyEducation GitHub Pages deployment

Repository: https://github.com/Hustlenix/Iron-Mario
Source branch: codex/onlyeducation-history-arcade
Published branch: gh-pages
Primary URL: https://hustlenix.github.io/Iron-Mario/arcade/
Site entry: https://hustlenix.github.io/Iron-Mario/
Legacy Godot arcade: https://hustlenix.github.io/Iron-Mario/legacy.html

## Procedure

1. Commit and push the reviewed source branch.
2. Run tools/package_arcade.py to validate the catalog and package the original assets and arcade.
3. For a 20-game release, record actual human observations in playtests.json and run tools/check_arcade_release.py first. The publisher checks this gate before remote changes. Then run tools/deploy_arcade_pages.py. It reads the existing gh-pages tree into an isolated temporary index, preserves existing legacy assets, adds arcade/ and history-assets/, and publishes one normal non-force commit. It saves the old Godot entry as legacy.html and adds a portal/ compatibility redirect for the existing Legacy arcade navigation link.
4. Verify the matching GitHub Pages build completes and fetch arcade/deployment.json to confirm the exact source revision.
5. Verify the public application, assets, normal keyboard/touch gameplay, switching and mobile layout. Local verification alone is not a public deployment check.

The root entry redirects to the new arcade. The existing service worker receives a version bump and activation update; existing games are not force-navigated. The publisher writes build/pages-release/release-report.json with the deployment commit, previous commit and SHA-256 hashes of the published files.

The source checkout stays on its source branch. A concurrent change to gh-pages rejects the push and needs a fresh publication; the tool does not force-push. It does not modify the main branch or replace the Godot engine binaries. GitHub Pages remains configured to serve gh-pages.

The existing main-branch Godot workflow is a separate release path and can publish its own export on a future main push. Use this OnlyEducation publisher for the independent Canvas platform until those source histories are deliberately integrated.
