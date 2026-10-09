extends SceneTree
## Renders the shared asset foundation at native 960x480 and mobile-safe widths.
const OUT := "res://build/shared-foundation"
const KITS := ["sky_foundry", "neon_workshop", "reactor_core", "fungus_underworks", "battle_lab", "chaos_carnival", "ui_kit", "effects_kit"]
var viewport: SubViewport
var index := 0
var sizes := [Vector2i(960,480), Vector2i(390,844)]

func _initialize() -> void: call_deferred("render")

func render() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for size in sizes:
		viewport = SubViewport.new(); viewport.size=size; viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		for kit in KITS:
			var node := TextureRect.new(); node.texture=load("res://assets/shared_foundation/zone_kits/"+kit+".svg") if kit not in ["ui_kit","effects_kit"] else load("res://assets/shared_foundation/"+kit+".svg")
			node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); viewport.add_child(node)
			await frames(2)
			var safe: String = kit+"_"+str(size.x)+"x"+str(size.y)+".png"
			viewport.get_texture().get_image().save_png(OUT+"/"+safe)
			node.queue_free(); await process_frame
		viewport.queue_free(); await process_frame
	print("SHARED_ASSET_PREVIEWS=", KITS.size()*sizes.size())
	quit(0)

func frames(count: int) -> void:
	for i in count: await process_frame
	await RenderingServer.frame_post_draw
