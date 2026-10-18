"""Publish OnlyEducation into existing GitHub Pages, preserving the legacy Godot export.
Run after package_arcade.py; an isolated temporary Git index keeps the source checkout unchanged.
"""
from pathlib import Path
import datetime, hashlib, json, os, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build/pages-release'
OUT.mkdir(parents=True,exist_ok=True)
def git(*args,input=None,env=None):
    r=subprocess.run(['git',*args],cwd=ROOT,input=input,stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=env)
    if r.returncode: raise RuntimeError(r.stderr.decode('utf8','replace'))
    return r.stdout
remote=git('remote','get-url','origin').decode().strip()
assert remote=='https://github.com/Hustlenix/Iron-Mario.git', 'Unexpected deployment repository'
branch=git('branch','--show-current').decode().strip()
assert branch=='codex/onlyeducation-history-arcade','Deploy from the reviewed source branch'
assert not git('status','--porcelain','--untracked-files=no').strip(),'Commit tracked source changes before deployment'
source=git('rev-parse','HEAD').decode().strip()
git('fetch','--no-tags','origin','gh-pages')
base=git('rev-parse','origin/gh-pages').decode().strip()
redirect='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#11151f"><meta name="description" content="OnlyEducation by Hustlenix. Original pixel games, free in your browser."><title>OnlyEducation — Your pixel playground</title><link rel="icon" href="arcade/oe-mark.png"><meta http-equiv="refresh" content="0;url=./arcade/"><style>body{background:#11151f;color:#f5f4ed;font:18px system-ui;padding:40px}a{color:#ffd16f}</style></head><body><p><a href="./arcade/">Open OnlyEducation</a></p><script>location.replace(new URL('./arcade/'+location.search+location.hash,location.href));</script></body></html>'''
(OUT/'index.html').write_text(redirect,encoding='utf8')
legacy=git('show',base+':index.html')
legacy_path=git('ls-tree',base,'legacy.html').decode().strip()
files={}
if not legacy_path:
    assert b'GODOT_CONFIG' in legacy,'Unexpected existing entry point; preserve its identity before replacing'
    (OUT/'legacy.html').write_bytes(legacy);files['legacy.html']=OUT/'legacy.html'
(OUT/'portal.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Legacy arcade</title><meta http-equiv="refresh" content="0;url=../legacy.html"></head><body><a href="../legacy.html">Open the legacy arcade</a></body></html>',encoding='utf8')
files.update({'index.html':OUT/'index.html','portal/index.html':OUT/'portal.html'})
worker=git('show',base+':index.service.worker.js').decode('utf8')
import re
worker=re.sub(r"const CACHE_VERSION = '[^']*';","const CACHE_VERSION = 'onlyeducation-"+source[:12]+"';",worker,count=1)
# Existing visitors receive the new root entry after worker activation; do not force-navigate active games.
worker=worker.replace("event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES)));","event.waitUntil(Promise.all([caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES)), self.skipWaiting()]));")
worker=worker.replace("return ('navigationPreload' in self.registration) ? self.registration.navigationPreload.enable() : Promise.resolve();","return Promise.all([self.clients.claim(), ('navigationPreload' in self.registration) ? self.registration.navigationPreload.enable() : Promise.resolve()]);")
(OUT/'index.service.worker.js').write_text(worker,encoding='utf8');files['index.service.worker.js']=OUT/'index.service.worker.js'
for family in ('arcade','history-assets'):
    folder=ROOT/'build/web'/family
    assert (folder/'index.html').is_file(),family+' is not packaged'
    for file in sorted(folder.rglob('*')):
        if file.is_file():
            assert not any(p in file.parts for p in ('node_modules','source_art','curators'))
            assert file.stat().st_size<50_000_000
            files[family+'/'+file.relative_to(folder).as_posix()]=file
metadata={'sourceCommit':source,'sourceBranch':branch,'publishedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'entry':'/Iron-Mario/arcade/','legacy':'/Iron-Mario/legacy.html','games':14}
(OUT/'deployment.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf8');files['arcade/deployment.json']=OUT/'deployment.json'
index=OUT/('publish-'+source[:12]+'.index')
assert not index.exists(),'An existing publication index requires review'
env=os.environ.copy();env['GIT_INDEX_FILE']=str(index)
git('read-tree',base,env=env)
paths=list(files)
blobs=git('hash-object','-w','--stdin-paths',input=('\n'.join(files[p].as_posix() for p in paths)+'\n').encode()).decode().splitlines()
assert len(blobs)==len(paths)
rows=''.join('100644 '+blob+'\t'+p+'\n' for p,blob in zip(paths,blobs))
git('update-index','--index-info',input=rows.encode(),env=env)
tree=git('write-tree',env=env).decode().strip()
commit=git('commit-tree',tree,'-p',base,'-m','Deploy OnlyEducation playground from '+source[:12]).decode().strip()
# A normal non-force push rejects a concurrent gh-pages update rather than overwriting it.
git('push','origin',commit+':refs/heads/gh-pages')
report={**metadata,'deploymentCommit':commit,'previousPagesCommit':base,'publishedFiles':len(files),'files':{p:hashlib.sha256(files[p].read_bytes()).hexdigest() for p in paths}}
(OUT/'release-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps({k:v for k,v in report.items() if k!='files'},indent=2))
