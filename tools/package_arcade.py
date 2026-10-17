"""Build the independent browser arcade without changing the legacy Godot export."""
from pathlib import Path
import shutil,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'onlyeducation/arcade';target=ROOT/'build/web/arcade'
subprocess.run([sys.executable,str(ROOT/'tools/package_history_assets.py')],check=True,cwd=ROOT)
target.mkdir(parents=True,exist_ok=True)
for p in source.rglob('*'):
    if p.is_file() and p.suffix in ('.html','.css','.js'):
        out=target/p.relative_to(source);out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,out)
shutil.copy2(ROOT/'assets/icons/onlyeducation_mark_32.png',target/'oe-mark.png')
docs=ROOT/'docs/arcade'
if docs.exists():shutil.copytree(docs,target/'docs',dirs_exist_ok=True)
print('ARCADE_PACKAGE:',sum(p.stat().st_size for p in target.rglob('*') if p.is_file()),'bytes in independent /arcade/')
