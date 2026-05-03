extends SceneTree

const OUTPUT_PATH := "res://assets/processed/mmxe/x_normal_frames.tres"
const SPRITE_ROOT := "res://assets/raw/mmxe/x/normal/"

const ANIMATION_DEFS := {
	"idle": {"file": "spr_x_idle_strip6.png", "frames": 6, "fps": 10.0},
	"idle_shoot": {"file": "spr_x_idle_shoot_strip2.png", "frames": 2, "fps": 18.0},
	"walk": {"file": "spr_x_walk_strip11.png", "frames": 11, "fps": 20.0},
	"walk_shoot": {"file": "spr_x_walk_shoot_strip11.png", "frames": 11, "fps": 20.0},
	"jump": {"file": "spr_x_jump_strip7.png", "frames": 7, "fps": 16.0},
	"jump_shoot": {"file": "spr_x_jump_shoot_strip7.png", "frames": 7, "fps": 16.0},
	"dash": {"file": "spr_x_dash_strip2.png", "frames": 2, "fps": 12.0},
	"dash_shoot": {"file": "spr_x_dash_shoot_strip2.png", "frames": 2, "fps": 12.0},
	"wall": {"file": "spr_x_wall_strip5.png", "frames": 5, "fps": 10.0},
	"wall_shoot": {"file": "spr_x_wall_shoot_strip5.png", "frames": 5, "fps": 10.0},
}


func _init() -> void:
	var sprite_frames := SpriteFrames.new()

	for animation_name in ANIMATION_DEFS.keys():
		var definition: Dictionary = ANIMATION_DEFS[animation_name]
		var texture: Texture2D = load(SPRITE_ROOT + definition["file"])
		if texture == null:
			push_error("Missing texture: %s" % (SPRITE_ROOT + definition["file"]))
			quit(1)
			return

		var frame_count: int = definition["frames"]
		var frame_width := texture.get_width() / frame_count
		var frame_height := texture.get_height()
		sprite_frames.add_animation(animation_name)
		sprite_frames.set_animation_speed(animation_name, definition["fps"])
		sprite_frames.set_animation_loop(animation_name, true)

		for frame_index in range(frame_count):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(frame_index * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame(animation_name, atlas)

	var result := ResourceSaver.save(sprite_frames, OUTPUT_PATH)
	if result != OK:
		push_error("Failed to save SpriteFrames resource to %s (error %s)" % [OUTPUT_PATH, result])
		quit(1)
		return

	print("Saved SpriteFrames resource to %s" % OUTPUT_PATH)
	quit()
