"""Publish only small, actual rendered game covers; leave QA/source atlases out."""
from pathlib import Path
import shutil
root = Path(__file__).resolve().parents[1]
destination = root / 'web' / 'previews'
destination.mkdir(parents=True, exist_ok=True)
count = 0
for path in (root / 'build' / 'catalog-qa').glob('*_thumbnail.png'):
    shutil.copyfile(path, destination / path.name.replace('_thumbnail', ''))
    count += 1
print(f'{count} rendered covers prepared for lazy Web loading')
