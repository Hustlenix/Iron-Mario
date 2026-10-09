"""Fail CI on Godot diagnostics as well as process exit status."""
import subprocess
import sys
from pathlib import Path

editor = sys.argv[1] if len(sys.argv) > 1 else 'godot'
root = Path(__file__).resolve().parents[1]
for name in ['services', 'pack_a', 'pack_b', 'input', 'mobile_controls', 'app', 'catalog_audit', 'cabinets', 'classics_a', 'chaos', 'pack_c', 'classics_b', 'performance']:
    result = subprocess.run([editor, '--headless', '--path', str(root), '--script',
                             f'res://tests/{name}_test.gd', '--', '--test'],
                            capture_output=True, text=True, timeout=120)
    output = result.stdout + result.stderr
    print(output, flush=True)
    if result.returncode or 'ERROR:' in output or 'leaked at exit' in output:
        raise SystemExit(f'{name} validation failed')
print('All arcade validation suites passed.')
