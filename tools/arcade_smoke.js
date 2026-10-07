const http = require("http");
const fs = require("fs");
const path = require("path");
const { chromium } = require("playwright");

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

  // Title's second button is ARCADE. It opens the new library without a DOM
  // button, so this intentionally uses the canvas coordinates a player uses.
  await page.mouse.click(640, 418);
  await page.waitForTimeout(1800);
  await page.screenshot({ path: path.join(out, "arcade.png") });

  // The second catalogue row is Arc Snake. Confirm that relative turning,
  // boosting, and the return route work in the Web export.
  await page.mouse.click(420, 355);
  await page.waitForTimeout(1800);
  await page.screenshot({ path: path.join(out, "arc-snake.png") });
  await page.keyboard.down("ArrowLeft");
  await page.waitForTimeout(250);
  await page.keyboard.up("ArrowLeft");
  await page.keyboard.down("Space");
  await page.waitForTimeout(400);
  await page.keyboard.up("Space");
  await page.keyboard.press("Escape");
  await page.waitForTimeout(1200);

  // The third catalogue row is Brick Reactor. Confirm that the cabinet launches,
  // responds to left/right and launch, and the return route works.
  await page.mouse.click(420, 435);
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

  // The fourth catalogue row is Tower Bounce. Exercise its launch and return.
  await page.mouse.click(420, 515);
  await page.waitForTimeout(1200);
  await page.screenshot({ path: path.join(out, "tower-bounce.png") });
  await page.keyboard.press("Escape");
  await page.waitForTimeout(1200);

  // Recent is driven by the persisted profile, not a hardcoded menu list.
  await page.mouse.click(785, 193);
  await page.waitForTimeout(500);
  await page.screenshot({ path: path.join(out, "recent-filter.png") });

  console.log(`title -> arcade -> Arc Snake -> Brick Reactor -> Tower Bounce -> returns completed`);
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
