"""Export a preset and preserve diagnostics without noisy progress output."""
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
editor, preset, destination = sys.argv[1:]
(root / destination).parent.mkdir(parents=True, exist_ok=True)
result = subprocess.run([editor, '--headless', '--path', str(root),
                         '--export-release', preset, destination],
                        capture_output=True, text=True, timeout=240)
output = result.stdout + result.stderr
log = root / 'build' / ('export-' + preset.replace(' ', '-') + '.log')
log.write_text(output, encoding='utf-8')
diagnostics = [line for line in output.splitlines() if 'ERROR:' in line or 'WARNING:' in line]
print('\n'.join(diagnostics) or f'{preset} export complete.')
print(f'Exit code: {result.returncode}; log: {log}')
if result.returncode or any('ERROR:' in line for line in diagnostics):
    raise SystemExit(1)
