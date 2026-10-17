"""Create a small review bundle of the original browser arcade and art only."""
from pathlib import Path
import subprocess,sys,zipfile,json
ROOT=Path(__file__).resolve().parents[1]
subprocess.run([sys.executable,str(ROOT/'tools/package_arcade.py')],check=True,cwd=ROOT)
out=ROOT/'exports/onlyeducation-arcade-checkpoint.zip'
out.parent.mkdir(parents=True,exist_ok=True)
manifest=json.loads((ROOT/'assets/shared_foundation/history_arcade/manifest.json').read_text())
assert all(a['license']=='project_original' for a in manifest['assets'])
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
    for dirname in ('arcade','history-assets'):
        source=ROOT/'build/web'/dirname
        for p in sorted(source.rglob('*')):
            if p.is_file():
                rel=p.relative_to(ROOT/'build/web')
                assert not any(v in rel.parts for v in ('curators','source_art','node_modules'))
                z.write(p,rel.as_posix())
    z.writestr('START_HERE.txt','OnlyEducation local review checkpoint.\nRun python -m http.server 8785 in this extracted folder, then open http://127.0.0.1:8785/arcade/ .\n13 tested games; 7 planned. Legacy arcade links need the original workspace. No production release is implied.\n')
with zipfile.ZipFile(out) as z:
    assert z.testzip() is None
    assert 'arcade/index.html' in z.namelist() and 'history-assets/assets/manifest.json' in z.namelist()
print('ARCADE_ARCHIVE:',out.stat().st_size,'bytes')
