"""Complete the Godot PWA metadata without replacing its generated runtime."""
import json
import hashlib
from pathlib import Path

root = Path(__file__).resolve().parents[1] / 'build' / 'web'
manifest_path = root / 'index.manifest.json'
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
manifest.update(short_name='Micro Heroes', id='./', scope='./', theme_color='#fff4d7',
                description='Fifty tiny adventures. One hand-drawn arcade universe.')
for icon in manifest['icons']:
    icon['purpose'] = 'any maskable'
manifest_path.write_text(json.dumps(manifest, separators=(',', ':')), encoding='utf-8')
assert (root / 'index.wasm').stat().st_size > 1_000_000
assert (root / 'index.pck').stat().st_size > 100_000
# Content-address runtime assets so an old service worker or CDN cannot mix
# JavaScript, WebAssembly, and game data from different Godot versions.
runtime = [p for p in root.glob('index.*') if p.suffix in ('.js', '.wasm', '.pck')
           and p.name != 'index.service.worker.js']
digest = hashlib.sha256()
for path in sorted(runtime):
    digest.update(path.read_bytes())
prefix = 'smh-' + digest.hexdigest()[:16]
renames = {p.name: p.name.replace('index', prefix, 1) for p in runtime}
for name in ('index.html', 'index.service.worker.js'):
    path = root / name
    content = path.read_text(encoding='utf-8')
    for before, after in renames.items():
        content = content.replace(before, after)
    content = content.replace('"executable":"index"', '"executable":"' + prefix + '"')
    path.write_text(content, encoding='utf-8')
for before, after in renames.items():
    (root / before).rename(root / after)
print('PWA metadata and runtime files verified')
