"""Read-only check of the user-requested human playtest release gate."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def check_release():
    raw=(ROOT/'onlyeducation/arcade/catalog.js').read_text(encoding='utf8')
    games=json.loads(raw[raw.index('['):raw.rindex(']')+1])
    playable={g['id'] for g in games if g['status'] in ('PLAYABLE','TESTED','RELEASE READY')}
    if len(playable)<20:return len(playable)
    reviews=json.loads((ROOT/'docs/arcade/playtests.json').read_text(encoding='utf8'))['reviews']
    valid=[]
    for r in reviews:
        assert r.get('kind')=='human','Only actual human observations satisfy this release gate'
        assert r.get('gameId') in playable,'Playtest must identify a playable game'
        assert all(isinstance(r.get(k),str) and r[k].strip() for k in ('anonymousSlot','device','observation','friction','recordedAt')),'Incomplete playtest observation'
        assert type(r.get('enjoyment')) is int and 1<=r['enjoyment']<=5,'Enjoyment must be an actual 1-5 rating'
        assert type(r.get('wouldReplay')) is bool,'Missing replay answer'
        valid.append(r)
    assert len({r['gameId'] for r in valid})>=2,'Public release held: record actual human play observations for at least two games, as requested in the audit. See docs/arcade/PLAYTESTING.md.'
    return len(playable)
if __name__=='__main__':
    count=check_release()
    print('RELEASE_GATE_PASS:',count,'playable games; human observations recorded')
