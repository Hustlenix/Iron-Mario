"""Complete the Godot PWA metadata without replacing its generated runtime."""
import json
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
print('PWA metadata and runtime files verified')
