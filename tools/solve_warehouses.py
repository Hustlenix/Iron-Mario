"""Independent breadth-first solvability check of the authored crate rooms."""
import json
from collections import deque
from pathlib import Path
root = Path(__file__).resolve().parents[1]
source = (root / 'scripts/arcade/BoardGames.gd').read_text()
rooms = json.loads(source.split('const ROOMS =',1)[1].split('const SHAPES',1)[0].strip())
solutions=[]
for number,rows in enumerate(rooms):
    width=len(rows[0]); walls=set(); goals=set(); crates=set(); player=None
    for y,row in enumerate(rows):
        for x,ch in enumerate(row):
            p=x+y*width
            if ch=='#': walls.add(p)
            if ch=='.': goals.add(p)
            if ch=='$': crates.add(p)
            if ch=='@': player=p
    initial=(player,tuple(sorted(crates)))
    queue=deque([initial]); parents={initial:None}; found=None
    for state in iter(queue.popleft,None):
        pos,boxes=state; occupied=set(boxes)
        if occupied==goals: found=state;break
        for action,delta in [('left',-1),('right',1),('up',-width),('down',width)]:
            target=pos+delta
            if target in walls:continue
            moved=occupied.copy()
            if target in moved:
                if target+delta in walls or target+delta in moved:continue
                moved.remove(target);moved.add(target+delta)
            next_state=(target,tuple(sorted(moved)))
            if next_state not in parents:
                parents[next_state]=(state,action);queue.append(next_state)
        if not queue:break
    if found is None:raise SystemExit(f'UNSOLVABLE ROOM {number+1}')
    actions=[]
    while parents[found] is not None:
        found,action=parents[found];actions.append(action)
    actions.reverse();solutions.append(actions)
    print(f'PASS room {number+1}: {len(actions)} legal moves, {len(parents)} searched states')
(root/'tools/warehouse_solutions.json').write_text(json.dumps(solutions))
