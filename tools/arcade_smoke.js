const http = require("http");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { chromium } = require("playwright-core");

// playwright-core ships no browser, so borrow the chromium that the local
// ms-playwright registry already has (SMOKE_CHROMIUM overrides the pick).
function findChromium() {
  if (process.env.SMOKE_CHROMIUM) return process.env.SMOKE_CHROMIUM;
  const registry = path.join(os.homedir(), "AppData", "Local", "ms-playwright");
  const candidates = fs.readdirSync(registry)
    .filter((name) => /^chromium-\d+$/.test(name))
    .sort((a, b) => Number(b.split("-")[1]) - Number(a.split("-")[1]));
  for (const name of candidates) {
    const exe = path.join(registry, name, "chrome-win64", "chrome.exe");
    if (fs.existsSync(exe)) return exe;
  }
  throw new Error(`no chromium build found under ${registry}`);
}

const root = path.resolve(process.argv[2]);
const out = path.resolve(process.argv[3]);
fs.mkdirSync(out, { recursive: true });
const contentTypes = {
  ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm",
  ".pck": "application/octet-stream", ".png": "image/png", ".json": "application/json",
};
const server = http.createServer((req, res) => {
  const relative = decodeURIComponent(req.url.split("?")[0]);
  const file = path.join(root, relative === "/" ? "index.html" : relative);
  if (!file.startsWith(root) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    res.writeHead(404);
    res.end();
    return;
  }
  res.writeHead(200, {
    "Content-Type": contentTypes[path.extname(file)] || "application/octet-stream",
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Embedder-Policy": "require-corp",
  });
  fs.createReadStream(file).pipe(res);
});

(async () => {
  await new Promise((resolve) => server.listen(8940, resolve));
  const browser = await chromium.launch({
    executablePath: findChromium(),
    args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--mute-audio"],
  });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  const logs = [];
  page.on("pageerror", (error) => errors.push(String(error)));
  page.on("console", (message) => logs.push(message.text()));
  await page.goto("http://127.0.0.1:8940/index.html", { waitUntil: "load", timeout: 120000 });
  for (let i = 0; i < 120; i += 1) {
    if (logs.some((text) => /Godot Engine v\d/.test(text)) && await page.$("canvas")) break;
    await page.waitForTimeout(500);
  }
  await page.waitForTimeout(1000);
  await page.screenshot({ path: path.join(out, "title.png") });

  // Title's second button is ARCADE. It opens the two-column cabinet wall,
  // so these clicks intentionally hit canvas coordinates a player would use.
  await page.mouse.click(640, 418);
  await page.waitForTimeout(2000);
  await page.screenshot({ path: path.join(out, "arcade.png") });

  // The search field filters the wall live: "snake" should leave one cabinet.
  await page.mouse.click(1112, 190);
  await page.keyboard.type("snake");
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(out, "search-snake.png") });
  await page.keyboard.press("Control+A");
  for (let i = 0; i < 6; i += 1) await page.keyboard.press("Backspace");
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(out, "search-cleared.png") });

  // The star pins Arc Snake (row two, right-aligned star box); the FAVORITES
  // chip then shows the shelf that pin creates, and ALL restores the wall.
  await page.mouse.click(582, 420);
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(out, "star-pinned.png") });
  await page.mouse.click(915, 191);
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(out, "favorites-shelf.png") });
  await page.mouse.click(142, 191);
  await page.waitForTimeout(600);

  // Row one, right card is Arc Break. Walk to the first relay, fire the
  // repulsor, and check that the energy puzzle advances through actual input.
  await page.mouse.click(908, 306);
  await page.waitForTimeout(1800);
  await page.screenshot({ path: path.join(out, "arc-break-lab.png") });
  await page.keyboard.down("ArrowRight");
  await page.waitForTimeout(1050);
  await page.keyboard.up("ArrowRight");
  await page.keyboard.down("ArrowUp");
  await page.waitForTimeout(280);
  await page.keyboard.up("ArrowUp");
  await page.keyboard.press("e");
  await page.waitForTimeout(500);
  await page.screenshot({ path: path.join(out, "arc-break-relay-hit.png") });
  await page.keyboard.press("Escape");
  await page.waitForTimeout(1200);

  // Row two, left card is Arc Snake. Confirm relative turning, boosting,
  // and return work in the Web export.
  await page.mouse.click(344, 452);
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(out, "arc-snake.png") });
  await page.keyboard.down("ArrowLeft");
  await page.waitForTimeout(250);
  await page.keyboard.up("ArrowLeft");
  await page.keyboard.down("Space");
  await page.waitForTimeout(350);
  await page.keyboard.up("Space");
  await page.keyboard.press("Escape");
  await page.waitForTimeout(1000);

  // Row two, right card is Brick Reactor. Confirm that the cabinet launches,
  // responds to left/right and launch, and the return route works.
  await page.mouse.click(908, 452);
  await page.waitForTimeout(1200);
  await page.screenshot({ path: path.join(out, "brick-reactor-ready.png") });
  await page.keyboard.down("ArrowLeft");
  await page.waitForTimeout(250);
  await page.keyboard.up("ArrowLeft");
  await page.keyboard.press("Space");
  await page.waitForTimeout(900);
  await page.screenshot({ path: path.join(out, "brick-reactor-playing.png") });
  await page.keyboard.press("Escape");
  await page.waitForTimeout(1200);
  await page.screenshot({ path: path.join(out, "returned.png") });

  // Recent is driven by the persisted profile, not a hardcoded menu list.
  await page.mouse.click(754, 191);
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(out, "recent-filter.png") });

  console.log(`title -> arcade wall -> search -> favorites shelf -> Arc Break relay -> Arc Snake -> Brick Reactor -> recent shelf completed`);
  console.log(`console errors: ${errors.length}`);
  if (errors.length) console.log(errors.join("\n"));
  await browser.close();
  server.close();
  process.exit(errors.length ? 1 : 0);
})().catch((error) => {
  console.error(error);
  server.close();
  process.exit(1);
});
