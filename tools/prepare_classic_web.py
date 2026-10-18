"""Give the restored game fresh runtime URLs and retire the newer game's PWA worker."""
from pathlib import Path
import hashlib
import re

root = Path(__file__).resolve().parents[1] / 'build' / 'web'
runtime = sorted(p for p in root.glob('index.*') if p.suffix in ('.js', '.wasm', '.pck') and p.name != 'index.service.worker.js')
assert (root / 'index.html').is_file()
assert any(p.suffix == '.pck' for p in runtime)
prefix = 'classic-seven-' + hashlib.sha256(b''.join(p.read_bytes() for p in runtime)).hexdigest()[:16]
renames = {p.name: p.name.replace('index', prefix, 1) for p in runtime}
for path in [root / 'index.html'] + [p for p in runtime if p.suffix == '.js']:
    content = path.read_text(encoding='utf-8')
    for before, after in renames.items():
        content = content.replace(before, after)
    content = re.sub(r'("executable"\s*:\s*)"index"', lambda m: m[1] + '"' + prefix + '"', content)
    path.write_text(content, encoding='utf-8')
for before, after in renames.items():
    (root / before).rename(root / after)
# This URL was registered by the newer PWA. Installing a worker without a fetch
# handler removes its cached-page interception, without touching player saves.
(root / 'index.service.worker.js').write_text('''self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil((async () => {
  await self.clients.claim();
  await self.registration.unregister();
  const windows = await self.clients.matchAll({type: 'window'});
  for (const client of windows) {
    if (client.url.startsWith(self.registration.scope)) await client.navigate(client.url);
  }
})()));
''', encoding='utf-8')
print('Classic seven-game Web package prepared:', prefix)
