"""Render scene draw commands to SVG in a disposable copy. Not a GPU screenshot."""
from pathlib import Path
import shutil, subprocess, tempfile, sys
root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='iron-paint-') as tmp:
    copy = Path(tmp)
    for name in ['scripts', 'scenes', 'assets', 'tools']:
        shutil.copytree(root / name, copy / name)
    shutil.copy2(root / 'project.godot', copy / 'project.godot')
    (copy / 'docs').mkdir()
    paint = copy / 'scripts/ui/Paint.gd'
    content = paint.read_text().replace('extends RefCounted', 'extends RefCounted\nconst Capture = preload("res://tools/paint_capture.gd")')
    for old, new in [('canvas.draw_rect(', 'Capture.rect(canvas, '), ('canvas.draw_colored_polygon(', 'Capture.polygon(canvas, '), ('canvas.draw_polyline(', 'Capture.polyline(canvas, ')]:
        content = content.replace(old, new)
    paint.write_text(content)
    hero = copy / 'scripts/ui/IronHero.gd'
    hero.write_text(hero.read_text().replace('draw_set_transform(Vector2(0, -15.3), 0.0, Vector2(0.8, 0.727))', 'pass'))
    engine = sys.argv[1] if len(sys.argv) > 1 else 'godot'
    subprocess.run([engine, '--headless', '--editor', '--path', tmp, '--quit'], check=True, timeout=30, stdout=subprocess.DEVNULL)
    subprocess.run([engine, '--headless', '--path', tmp, 'tools/paint_capture_runner.tscn'], check=True, timeout=30)
    for svg in (copy / 'docs').glob('paint_*.svg'):
        shutil.copy2(svg, root / 'docs' / svg.name)
