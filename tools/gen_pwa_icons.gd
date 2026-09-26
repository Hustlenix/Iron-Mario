extends SceneTree

## Rasterizes assets/web_orb.svg into the three square PNG sizes that the Web
## export preset requires for a Progressive Web App manifest:
## 144x144, 180x180 and 512x512.
##
## Each icon is composited onto an opaque #0b132b canvas rather than left
## transparent, so launchers that mask the icon (Android adaptive icons) or
## render it on a light background don't show a white/black halo.
##
## The orb SVG is the project's own mark -- no third-party art is involved.
##
## Run from the project root:
##   godot --headless --path . --script res://tools/gen_pwa_icons.gd

const SOURCE := "res://assets/web_orb.svg"
const OUTPUT_DIR := "res://assets/icons"
const SIZES := [144, 180, 512]
const BACKGROUND := Color("#0b132b")
## Rasterize oversized then downscale: sampling down from a larger raster keeps
## the thin 0.8px spokes from disappearing.
const RASTER_SIZE := 1024


func _initialize() -> void:
	var bytes := FileAccess.get_file_as_bytes(SOURCE)
	if bytes.is_empty():
		push_error("Could not read %s" % SOURCE)
		quit(1)
		return

	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(OUTPUT_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	# Image.load_svg_from_buffer rasterizes on the CPU via ThorVG, so this works
	# under the headless dummy renderer with no GPU involved.
	var big := Image.new()
	var err := big.load_svg_from_buffer(bytes, float(RASTER_SIZE) / 40.0)
	if err != OK:
		push_error("SVG rasterization failed: %d" % err)
		quit(1)
		return

	for size in SIZES:
		var icon := Image.create(size, size, false, Image.FORMAT_RGBA8)
		icon.fill(BACKGROUND)

		var mark := big.duplicate() as Image
		mark.resize(size, size, Image.INTERPOLATE_LANCZOS)

		# Centre the mark and let any glow alpha blend into the opaque backdrop.
		icon.blend_rect(mark, Rect2i(Vector2i.ZERO, mark.get_size()), Vector2i.ZERO)

		var path := "%s/icon_%dx%d.png" % [OUTPUT_DIR, size, size]
		var save_err := icon.save_png(path)
		if save_err != OK:
			push_error("Failed to write %s: %d" % [path, save_err])
			quit(1)
			return
		print("wrote %s (%dx%d)" % [path, size, size])

	print("PWA icons generated")
	quit(0)
