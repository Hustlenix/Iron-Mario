"""Render scene draw commands to SVG in a disposable copy. Not a GPU screenshot."""
from pathlib import Path
import shutil, subprocess, tempfile, sys, os
root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='iron-paint-') as tmp:
    copy = Path(tmp)
    capture_env = dict(os.environ, XDG_DATA_HOME=str(copy / "userdata"), APPDATA=str(copy / "userdata"))
    for name in ['scripts', 'scenes', 'assets', 'tools']:
        shutil.copytree(root / name, copy / name)
    shutil.copy2(root / 'project.godot', copy / 'project.godot')
    (copy / 'docs').mkdir()
    # The character gallery does not need continuous background music.
    music = copy / 'scripts/Music.gd'
    music.write_text('extends Node\nfunc play_theme(_id: String, _mood: String = "menu") -> void:\n\tpass\nfunc stop_music() -> void:\n\tpass\n')
    # Geometry-only capture: avoid starting audio players and freeing them in the same tick.
    for relative in ['scripts/TitleScreen.gd', 'scenes/flappy_bird.gd']:
        audio_script = copy / relative
        audio_script.write_text(audio_script.read_text().replace('music.play()', 'music.stop()').replace('bgm.play()', 'bgm.stop()'))
    paint = copy / 'scripts/ui/Paint.gd'
    content = paint.read_text().replace('extends RefCounted', 'extends RefCounted\nconst Capture = preload("res://tools/paint_capture.gd")')
    for old, new in [('canvas.draw_rect(', 'Capture.rect(canvas, '), ('canvas.draw_colored_polygon(', 'Capture.polygon(canvas, '), ('canvas.draw_polyline(', 'Capture.polyline(canvas, ')]:
        content = content.replace(old, new)
    paint.write_text(content)
    engine = sys.argv[1] if len(sys.argv) > 1 else 'godot'
    subprocess.run([engine, '--headless', '--editor', '--path', tmp, '--quit'], env=capture_env, check=True, timeout=30, stdout=subprocess.DEVNULL)
    subprocess.run([engine, '--headless', '--path', tmp, 'tools/paint_capture_runner.tscn'], env=capture_env, check=True, timeout=30)
    for svg in (copy / 'docs').glob('paint_*.svg'):
        shutil.copy2(svg, root / 'docs' / svg.name)
