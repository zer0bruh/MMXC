extends Area2D

const FRAMES_PER_SECOND := 60.0
const LIFETIME := 0.9
const LEMON_TEXTURE_PATH := "res://assets/raw/mmxe/projectiles/spr_weapon_xShot1_strip4.png"
const XSHOT2_TEXTURE_PATH := "res://assets/raw/mmxe/projectiles/spr_weapon_xShot2_strip14.png"
const XSHOT3_TEXTURE_PATH := "res://assets/raw/mmxe/projectiles/spr_weapon_xShot3X1_strip12.png"

const XSHOT2_KEYFRAMES := [
	Vector2(0, 0),
	Vector2(2, 1),
	Vector2(4, 2),
	Vector2(6, 3),
	Vector2(7, 4),
	Vector2(8, 5),
	Vector2(9, 6),
	Vector2(11, 5),
	Vector2(12, 4),
]

const XSHOT3_KEYFRAMES := [
	Vector2(0, 0),
	Vector2(1, 1),
	Vector2(5, 2),
	Vector2(7, 3),
	Vector2(9, 4),
	Vector2(10, 4),
]
const LEMON_HITBOX_SIZE := Vector2(8.0, 8.0)
const XSHOT2_HITBOX_SIZE := Vector2(16.0, 16.0)
const XSHOT3_HITBOX_SIZE := Vector2(24.0, 24.0)
const LEMON_HITBOX_OFFSET := Vector2.ZERO
const XSHOT2_HITBOX_OFFSET := Vector2(16.0, 0.0)
const XSHOT3_HITBOX_OFFSET := Vector2(8.0, 0.0)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var direction := 1
var shot_level := 0
var owner_to_ignore: Node2D
var lifetime_remaining := LIFETIME
var age_frames := 0.0
var impact_age_frames := 0.0
var impacting := false
var active_animation_key := 0.0
var impact_frame_indices := PackedInt32Array()
var impact_frame_length := 2.0


func _ready() -> void:
	_configure_shot()


func _physics_process(delta: float) -> void:
	if impacting:
		_update_impact(delta)
		return

	age_frames += delta * FRAMES_PER_SECOND
	active_animation_key += delta * FRAMES_PER_SECOND
	_sync_active_frame()
	_move_forward(_get_speed_pixels_per_frame() * direction * delta * FRAMES_PER_SECOND)
	if impacting:
		return

	lifetime_remaining -= delta

	if lifetime_remaining <= 0.0:
		queue_free()
		return


func _move_forward(distance: float) -> void:
	global_position.x += distance


func _begin_impact() -> void:
	if impacting:
		return
	if impact_frame_indices.is_empty():
		queue_free()
		return

	impacting = true
	impact_age_frames = 0.0
	monitoring = false
	monitorable = false
	if collision_shape != null:
		collision_shape.disabled = true
	if sprite != null:
		sprite.frame = impact_frame_indices[0]


func _update_impact(delta: float) -> void:
	impact_age_frames += delta * FRAMES_PER_SECOND
	if sprite != null:
		var impact_frame: int = mini(
			impact_frame_indices.size() - 1,
			int(floor(impact_age_frames / impact_frame_length))
		)
		sprite.frame = impact_frame_indices[impact_frame]
	if impact_age_frames >= impact_frame_length * impact_frame_indices.size():
		queue_free()


func _configure_shot() -> void:
	match shot_level:
		1:
			_apply_texture(XSHOT2_TEXTURE_PATH, 14)
			_set_hitbox(XSHOT2_HITBOX_SIZE, XSHOT2_HITBOX_OFFSET)
			impact_frame_indices = PackedInt32Array()
			impact_frame_length = 0.0
		2:
			_apply_texture(XSHOT3_TEXTURE_PATH, 12)
			_set_hitbox(XSHOT3_HITBOX_SIZE, XSHOT3_HITBOX_OFFSET)
			impact_frame_indices = PackedInt32Array()
			impact_frame_length = 0.0
		_:
			_apply_texture(LEMON_TEXTURE_PATH, 4)
			_set_hitbox(LEMON_HITBOX_SIZE, LEMON_HITBOX_OFFSET)
			impact_frame_indices = PackedInt32Array([1, 2, 3])
			impact_frame_length = 2.0


func _apply_texture(texture_path: String, hframes: int) -> void:
	if sprite == null:
		return

	var image := Image.load_from_file(ProjectSettings.globalize_path(texture_path))
	if image != null and not image.is_empty():
		sprite.texture = ImageTexture.create_from_image(image)
		sprite.hframes = hframes
		sprite.frame = 0
	sprite.flip_h = direction < 0


func _set_hitbox(size: Vector2, offset: Vector2) -> void:
	if collision_shape == null:
		return
	collision_shape.position = Vector2(offset.x * direction, offset.y)
	if collision_shape.shape is RectangleShape2D:
		var rectangle_shape: RectangleShape2D = collision_shape.shape
		rectangle_shape.size = size


func _sync_active_frame() -> void:
	if sprite == null:
		return

	match shot_level:
		1:
			sprite.frame = _resolve_keyframed_frame(active_animation_key, XSHOT2_KEYFRAMES, 12.0, 7.0)
		2:
			sprite.frame = _resolve_keyframed_frame(active_animation_key, XSHOT3_KEYFRAMES, 10.0, 5.0)
		_:
			sprite.frame = 0


func _resolve_keyframed_frame(key_time: float, keyframes: Array, max_key: float, loop_begin: float) -> int:
	var resolved_key := key_time
	while resolved_key > max_key:
		resolved_key = loop_begin + (resolved_key - max_key)

	var frame_index := 0
	for keyframe_variant in keyframes:
		var keyframe: Vector2 = keyframe_variant
		if keyframe.x <= resolved_key:
			frame_index = int(keyframe.y)
		else:
			break
	return frame_index


func _get_speed_pixels_per_frame() -> float:
	match shot_level:
		1:
			if age_frames < 5.0:
				return 0.0
			if age_frames < 8.0:
				return 4.0
			if age_frames < 10.0:
				return 5.0
			if age_frames < 12.0:
				return 6.0
			return 6.25
		2:
			if age_frames < 5.0:
				return 0.0
			if age_frames < 6.0:
				return 5.0
			if age_frames < 8.0:
				return 6.0
			if age_frames < 10.0:
				return 6.5
			if age_frames < 12.0:
				return 7.0
			return 7.5
		_:
			if age_frames < 2.0:
				return 4.0
			if age_frames < 5.0:
				return 5.0
			if age_frames < 24.0:
				return 6.0
			return 6.25
