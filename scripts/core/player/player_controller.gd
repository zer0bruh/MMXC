extends CharacterBody2D

const FIXED_STEP := 1.0 / 60.0
const DEFAULT_GRAVITY := 0.25
const TERMINAL_VELOCITY := 6.25
const GROUND_DISTANCE := 3

const WALK_SPEED := 376.0 / 256.0
const DASH_SPEED := 885.0 / 256.0
const JUMP_STRENGTH := 1363.0 / 256.0
const DASH_INTERVAL := 32
const WALL_JUMP_STRENGTH := 5.0
const WALL_STICK_FRAMES := 5
const WALL_LAUNCH_LOCK_FRAMES := 11
const MMXE_DASH_ON_LAND := false
const DASH_JUMP_PRESS_GRACE_FRAMES := 2

const HURT_SPEED := -138.0 / 256.0
const HURT_VERTICAL := -2.0
const LADDER_SPEED := 376.0 / 256.0

const DOUBLE_TAP_WINDOW := 15
const INPUT_BUFFER_LENGTH := 3
const SHOOT_COOLDOWN_FRAMES := 8
const SHOOT_VISUAL_DURATION := 15
const MMXE_MASK_Y_ORIGIN := 16.0
const CHARGE_LEVEL_1_FRAMES := 30
const CHARGE_LEVEL_2_FRAMES := 105
const CHARGE_LEVEL_3_FRAMES := 180
const CHARGE_LEVEL_4_FRAMES := 255
const PALETTE_SWAP_SHADER := preload("res://assets/shaders/palette_swap.gdshader")
const CHARGE_STAGE_0_TEXTURE_PATH := "res://assets/raw/mmxe/player_charge/spr_player_charge_0_strip16.png"
const CHARGE_STAGE_1_TEXTURE_PATH := "res://assets/raw/mmxe/player_charge/spr_player_charge_1_strip22.png"
const CHARGE_STAGE_2_TEXTURE_PATH := "res://assets/raw/mmxe/player_charge/spr_player_charge_2_strip22.png"
const CHARGE_STAGE_3_TEXTURE_PATH := "res://assets/raw/mmxe/player_charge/spr_player_charge_3_strip22.png"
const CHARGE_STAGE_4_TEXTURE_PATH := "res://assets/raw/mmxe/player_charge/spr_player_charge_4_strip22.png"
const CHARGE_FRAME_COUNT := 22
const DEFAULT_X_PALETTE := [
	Color8(32, 48, 128),
	Color8(0, 64, 240),
	Color8(0, 128, 248),
	Color8(24, 88, 176),
	Color8(80, 160, 240),
	Color8(120, 216, 240),
	Color8(24, 24, 24),
	Color8(128, 64, 32),
	Color8(184, 96, 72),
	Color8(248, 176, 128),
	Color8(152, 152, 152),
	Color8(224, 224, 224),
	Color8(240, 240, 240),
	Color8(240, 64, 16),
]
const CHARGE_PALETTE_STAGE_1 := [
	Color8(33, 107, 247),
	Color8(0, 148, 247),
	Color8(0, 189, 255),
	Color8(24, 132, 231),
	Color8(82, 222, 247),
	Color8(165, 247, 247),
	Color8(24, 82, 231),
	Color8(128, 64, 32),
	Color8(184, 96, 72),
	Color8(248, 176, 128),
	Color8(152, 152, 152),
	Color8(224, 224, 224),
	Color8(240, 240, 240),
	Color8(247, 107, 198),
]
const CHARGE_PALETTE_STAGE_2 := [
	Color8(33, 107, 247),
	Color8(0, 148, 247),
	Color8(0, 189, 255),
	Color8(24, 132, 231),
	Color8(82, 222, 247),
	Color8(165, 247, 247),
	Color8(24, 82, 231),
	Color8(128, 64, 32),
	Color8(184, 96, 72),
	Color8(248, 176, 128),
	Color8(152, 152, 152),
	Color8(224, 224, 224),
	Color8(240, 240, 240),
	Color8(247, 107, 198),
]
const CHARGE_PALETTE_UPGRADE_1 := [
	Color8(140, 115, 239),
	Color8(181, 140, 255),
	Color8(181, 173, 255),
	Color8(156, 140, 247),
	Color8(206, 181, 255),
	Color8(231, 231, 255),
	Color8(148, 0, 222),
	Color8(128, 64, 32),
	Color8(184, 96, 72),
	Color8(248, 176, 128),
	Color8(152, 152, 152),
	Color8(224, 224, 224),
	Color8(240, 240, 240),
	Color8(247, 107, 198),
]
const CHARGE_PALETTE_UPGRADE_2 := [
	Color8(231, 74, 33),
	Color8(231, 140, 41),
	Color8(255, 173, 41),
	Color8(231, 140, 41),
	Color8(247, 165, 123),
	Color8(255, 214, 156),
	Color8(140, 0, 0),
	Color8(128, 64, 32),
	Color8(184, 96, 72),
	Color8(248, 176, 128),
	Color8(247, 165, 123),
	Color8(255, 214, 156),
	Color8(240, 240, 240),
	Color8(247, 107, 198),
]

const ANIMATION_DATA_PATH := "res://assets/raw/mmxe/x/animation.json"
const BUSTER_SCENE := preload("res://scenes/core/player/buster_shot.tscn")

const INPUT_ACTIONS := {
	"left": "move_left",
	"right": "move_right",
	"jump": "jump",
	"dash": "dash",
	"shoot": "shoot",
	"move_up": "move_up",
	"move_down": "move_down",
}

const INPUT_BUFFER_ACTIVE := {
	"left": false,
	"right": false,
	"jump": true,
	"dash": true,
	"shoot": false,
}

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var charge_glow_sprite: AnimatedSprite2D = $ChargeGlowSprite
@onready var charge_effect: Sprite2D = $ChargeEffect
@onready var camera: Camera2D = $Camera2D
@onready var armor_overlay: Node2D = $ArmorOverlay
@onready var head_armor: AnimatedSprite2D = $ArmorOverlay/HeadArmor
@onready var body_armor: AnimatedSprite2D = $ArmorOverlay/BodyArmor
@onready var arm_armor: AnimatedSprite2D = $ArmorOverlay/ArmArmor
@onready var leg_armor: AnimatedSprite2D = $ArmorOverlay/LegArmor

var spawn_position := Vector2.ZERO
var fixed_accumulator := 0.0
var frame_counter := 0

var hspd := 0.0
var vspd := 0.0
var gravity_strength := DEFAULT_GRAVITY
var current_hspd := WALK_SPEED

var dir := 1
var hdir := 0
var vdir := 0
var dash_dir := 1
var dash_jump := false
var dash_tapped := false
var timer := 0

var state_name := ""
var previous_state := ""
var input_use_buffer := true

var shoot_cooldown_frames_left := 0
var shot_end_frame := 0
var charge_hold_start_frame := -1
var charge_stage := 0
var charge_effect_stage := 0
var charge_effect_frame := 0
var charge_effect_tick := 0
var charge_palette_limit := 4
var charge_stage_0_texture: Texture2D
var charge_stage_1_texture: Texture2D
var charge_stage_2_texture: Texture2D
var charge_stage_3_texture: Texture2D
var charge_stage_4_texture: Texture2D
var palette_material: ShaderMaterial

var input_state: Dictionary = {}
var input_pressed: Dictionary = {}
var input_released: Dictionary = {}
var input_pressed_buffer: Array[Dictionary] = []

var double_tap_current_key := 0
var double_tap_timer := 0
var double_tap_enabled := false
var double_tap_count := 0
var last_dash_press_frame := -1000

var animation_defs: Dictionary = {}
var animation_name := ""
var animation_key_index := 0.0
var animation_wait_frames := 0
var animation_ended_last_tick := false
var current_animation_frame := 0
var current_shot_offset := Vector2(12.0, -3.0)

enum ArmorPart {
	NONE,
	HEAD,
	BODY,
	ARM,
	LEG,
}

enum ArmorType {
	NONE,
	LIGHT,
	GIGA,
	MAX,
	FORCE,
	FALCON,
	GAEA,
	BLADE,
	SHADOW,
	GLIDE,
	ICARUS,
	HERMES,
}

var active_armor_parts: Dictionary = {
	ArmorPart.HEAD: ArmorType.NONE,
	ArmorPart.BODY: ArmorType.NONE,
	ArmorPart.ARM: ArmorType.NONE,
	ArmorPart.LEG: ArmorType.NONE,
}

var is_on_ladder := false

func set_armor_part(part: ArmorPart, armor_type: ArmorType) -> void:
	active_armor_parts[part] = armor_type
	_update_armor_overlays()
	_check_set_bonus()

func get_armor_part(part: ArmorPart) -> ArmorType:
	return active_armor_parts.get(part, ArmorType.NONE)

func _ready() -> void:
	spawn_position = global_position
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 512
	camera.limit_bottom = 224
	_reset_input_tracking()
	_load_animation_defs()
	_load_charge_effect_textures()
	_setup_palette_material()
	animated_sprite.stop()
	charge_glow_sprite.stop()

	# Equip Light Armor for testing
	set_armor_part(ArmorPart.HEAD, ArmorType.LIGHT)
	set_armor_part(ArmorPart.BODY, ArmorType.LIGHT)
	set_armor_part(ArmorPart.ARM, ArmorType.LIGHT)
	set_armor_part(ArmorPart.LEG, ArmorType.LIGHT)

	reset_to_spawn()

func _physics_process(delta: float) -> void:
	fixed_accumulator = minf(fixed_accumulator + delta, FIXED_STEP * 4.0)
	while fixed_accumulator >= FIXED_STEP:
		_simulate_tick()
		fixed_accumulator -= FIXED_STEP

	if global_position.y > 300.0:
		reset_to_spawn()

func reset_to_spawn() -> void:
	global_position = spawn_position
	fixed_accumulator = 0.0
	frame_counter = 0
	hspd = 0.0
	vspd = 0.0
	gravity_strength = DEFAULT_GRAVITY
	current_hspd = WALK_SPEED
	dir = 1
	hdir = 0
	vdir = 0
	dash_dir = 1
	dash_jump = false
	dash_tapped = false
	timer = 0
	input_use_buffer = true
	shoot_cooldown_frames_left = 0
	shot_end_frame = 0
	charge_hold_start_frame = -1
	charge_stage = 0
	charge_effect_stage = 0
	charge_effect_frame = 0
	charge_effect_tick = 0
	double_tap_current_key = 0
	double_tap_timer = 0
	double_tap_enabled = false
	double_tap_count = 0
	last_dash_press_frame = -1000
	animation_name = ""
	animation_key_index = 0.0
	animation_wait_frames = 0
	animation_ended_last_tick = false
	current_animation_frame = 0
	current_shot_offset = _to_local_shot_offset(Vector2(12.0, -3.0))
	is_on_ladder = false
	_reset_input_tracking()
	state_name = ""
	previous_state = ""
	_change_state("idle")

func get_debug_summary() -> String:
	return "state: %s | hspd %.3f, vspd %.3f | anim %s:%d | charge %d" % [
		state_name,
		hspd,
		vspd,
		animation_name,
		current_animation_frame,
		charge_stage,
	]

func set_on_ladder(on_ladder: bool) -> void:
	is_on_ladder = on_ladder

func apply_hurt() -> void:
	if state_name != "hurt":
		_change_state("hurt")
		_apply_damage_reduction()

func _apply_damage_reduction() -> void:
	var head_armor := get_armor_part(ArmorPart.HEAD)
	var body_armor := get_armor_part(ArmorPart.BODY)
	var arm_armor := get_armor_part(ArmorPart.ARM)
	var leg_armor := get_armor_part(ArmorPart.LEG)

	# Apply damage reduction based on equipped armor parts
	var total_damage_reduction := 0.0

	# Head armor effects
	if head_armor != ArmorType.NONE:
		match head_armor:
			ArmorType.LIGHT:
				total_damage_reduction += 0.1  # 10% reduction from head
				_apply_headbutt()  # Apply headbutt ability
			ArmorType.GIGA:
				total_damage_reduction += 0.2  # 20% reduction from head
			ArmorType.MAX:
				total_damage_reduction += 0.3  # 30% reduction from head
			ArmorType.FORCE:
				total_damage_reduction += 0.15  # 15% reduction from head
			ArmorType.FALCON:
				total_damage_reduction += 0.1  # 10% reduction from head
			ArmorType.GAEA:
				total_damage_reduction += 0.1  # 10% reduction from head
			ArmorType.BLADE:
				total_damage_reduction += 0.1  # 10% reduction from head
			ArmorType.SHADOW:
				total_damage_reduction += 0.1  # 10% reduction from head
			ArmorType.GLIDE:
				total_damage_reduction += 0.1  # 10% reduction from head
			ArmorType.ICARUS:
				total_damage_reduction += 0.1  # 10% reduction from head
			ArmorType.HERMES:
				total_damage_reduction += 0.1  # 10% reduction from head

	# Body armor effects
	if body_armor != ArmorType.NONE:
		match body_armor:
			ArmorType.LIGHT:
				total_damage_reduction += 0.5  # 50% reduction from chest
			ArmorType.GIGA:
				total_damage_reduction += 0.6  # 60% reduction from chest
			ArmorType.MAX:
				total_damage_reduction += 0.7  # 70% reduction from chest
			ArmorType.FORCE:
				total_damage_reduction += 0.4  # 40% reduction from chest
			ArmorType.FALCON:
				total_damage_reduction += 0.3  # 30% reduction from chest
			ArmorType.GAEA:
				total_damage_reduction += 0.3  # 30% reduction from chest
			ArmorType.BLADE:
				total_damage_reduction += 0.3  # 30% reduction from chest
			ArmorType.SHADOW:
				total_damage_reduction += 0.3  # 30% reduction from chest
			ArmorType.GLIDE:
				total_damage_reduction += 0.3  # 30% reduction from chest
			ArmorType.ICARUS:
				total_damage_reduction += 0.3  # 30% reduction from chest
			ArmorType.HERMES:
				total_damage_reduction += 0.3  # 30% reduction from chest

	# Arm armor effects
	if arm_armor != ArmorType.NONE:
		match arm_armor:
			ArmorType.LIGHT:
				total_damage_reduction += 0.1  # 10% reduction from arms
				_apply_spiral_crush()  # Apply Spiral Crush Buster ability
			ArmorType.GIGA:
				total_damage_reduction += 0.2  # 20% reduction from arms
			ArmorType.MAX:
				total_damage_reduction += 0.3  # 30% reduction from arms
			ArmorType.FORCE:
				total_damage_reduction += 0.15  # 15% reduction from arms
			ArmorType.FALCON:
				total_damage_reduction += 0.1  # 10% reduction from arms
			ArmorType.GAEA:
				total_damage_reduction += 0.1  # 10% reduction from arms
			ArmorType.BLADE:
				total_damage_reduction += 0.1  # 10% reduction from arms
			ArmorType.SHADOW:
				total_damage_reduction += 0.1  # 10% reduction from arms
			ArmorType.GLIDE:
				total_damage_reduction += 0.1  # 10% reduction from arms
			ArmorType.ICARUS:
				total_damage_reduction += 0.1  # 10% reduction from arms
			ArmorType.HERMES:
				total_damage_reduction += 0.1  # 10% reduction from arms

	# Leg armor effects
	if leg_armor != ArmorType.NONE:
		match leg_armor:
			ArmorType.LIGHT:
				total_damage_reduction += 0.1  # 10% reduction from legs
			ArmorType.GIGA:
				total_damage_reduction += 0.2  # 20% reduction from legs
			ArmorType.MAX:
				total_damage_reduction += 0.3  # 30% reduction from legs
			ArmorType.FORCE:
				total_damage_reduction += 0.15  # 15% reduction from legs
			ArmorType.FALCON:
				total_damage_reduction += 0.1  # 10% reduction from legs
			ArmorType.GAEA:
				total_damage_reduction += 0.1  # 10% reduction from legs
			ArmorType.BLADE:
				total_damage_reduction += 0.1  # 10% reduction from legs
			ArmorType.SHADOW:
				total_damage_reduction += 0.1  # 10% reduction from legs
			ArmorType.GLIDE:
				total_damage_reduction += 0.1  # 10% reduction from legs
			ArmorType.ICARUS:
				total_damage_reduction += 0.1  # 10% reduction from legs
			ArmorType.HERMES:
				total_damage_reduction += 0.1  # 10% reduction from legs

	# Apply the total damage reduction
	# This would typically modify a damage variable, which isn't present here.
	# For now, we'll just acknowledge it.
	print("Total damage reduction: ", total_damage_reduction * 100, "%")

func _apply_headbutt() -> void:
	# Implement headbutt functionality for Light Armor
	# This would typically deal damage to enemies above X
	if state_name == "walk" and vdir < 0:
		# Check for enemies above X
		var space_state := get_world_2d().direct_space_state
		var query := PhysicsRayQueryParameters2D.create(
			global_position + Vector2(0, -16),
			Vector2(0, -16),
			16
		)
		var result := space_state.intersect_ray(query)
		if result.size() > 0:
			# Deal damage to the enemy
			var collider := result[0].get_collider()
			if collider != null and collider.has_method("apply_damage"):
				collider.apply_damage(10)  # Adjust damage value as needed
			# Add visual/sound effects for the headbutt
			# This would typically include a screen shake and sound effect
			# For now, we'll just print a message
			print("Headbutt!")

func _apply_spiral_crush() -> void:
	# Implement Spiral Crush Buster functionality
	# Create a spiral pattern of buster shots
	var spiral_angle := 0.0
	var spiral_radius := 10.0
	var spiral_speed := 0.2
	var spiral_duration := 30  # Frames
	var spiral_shot_count := 12

	for i in range(spiral_shot_count):
		var spiral_shot = BUSTER_SCENE.instantiate()
		spiral_shot.direction = dir
		spiral_shot.shot_level = 1
		spiral_shot.owner_to_ignore = self
		# Calculate spiral position
		var angle := spiral_angle + (i * (2 * PI / spiral_shot_count))
		var offset_x := spiral_radius * cos(angle)
		var offset_y := spiral_radius * sin(angle)
		spiral_shot.global_position = global_position + Vector2(offset_x, offset_y)
		get_tree().current_scene.add_child(spiral_shot)
		# Update spiral angle for next shot
		spiral_angle += spiral_speed

func _get_armor_animation_suffix() -> String:
	# Check if any armor part is equipped
	var has_armor := false
	for part in active_armor_parts:
		if active_armor_parts[part] != ArmorType.NONE:
			has_armor = true
			break
	
	if not has_armor:
		return ""

	# For now, use body armor to determine animation suffix
	# This matches the GML implementation which primarily uses body armor for animation
	var armor_type := get_armor_part(ArmorPart.BODY)
	if armor_type == ArmorType.NONE:
		return ""

	match armor_type:
		ArmorType.LIGHT:
			return "light"
		ArmorType.GIGA:
			return "giga"
		ArmorType.MAX:
			return "max"
		ArmorType.FORCE:
			return "force"
		ArmorType.FALCON:
			return "falcon"
		ArmorType.GAEA:
			return "gaea"
		ArmorType.BLADE:
			return "blade"
		ArmorType.SHADOW:
			return "shadow"
		ArmorType.GLIDE:
			return "glide"
		ArmorType.ICARUS:
			return "icarus"
		ArmorType.HERMES:
			return "hermes"
		_:
			return ""

func _update_armor_overlays() -> void:
	# Update visibility and animation for each armor part
	var head_armor_type := get_armor_part(ArmorPart.HEAD)
	var body_armor_type := get_armor_part(ArmorPart.BODY)
	var arm_armor_type := get_armor_part(ArmorPart.ARM)
	var leg_armor_type := get_armor_part(ArmorPart.LEG)

	# Set visibility based on whether armor is equipped
	head_armor.visible = head_armor_type != ArmorType.NONE
	body_armor.visible = body_armor_type != ArmorType.NONE
	arm_armor.visible = arm_armor_type != ArmorType.NONE
	leg_armor.visible = leg_armor_type != ArmorType.NONE

	# Update animations for each armor part
	if animated_sprite.sprite_frames != null:
		var visual_animation := _get_visual_animation_name()
		
		# Head armor
		if head_armor.visible:
			head_animation_suffix = _get_armor_animation_suffix()
			if head_animation_suffix != "":
				head_armor_animation = "%s_%s" % [visual_animation, head_animation_suffix]
				if animated_sprite.sprite_frames.has_animation(head_armor_animation):
					head_armor.animation = head_armor_animation
			else:
				head_armor.animation = visual_animation
			head_armor.frame = animated_sprite.frame
			head_armor.frame_progress = 0.0
			head_armor.flip_h = animated_sprite.flip_h
		
		# Body armor
		if body_armor.visible:
			body_animation_suffix = _get_armor_animation_suffix()
			if body_animation_suffix != "":
				body_armor_animation = "%s_%s" % [visual_animation, body_animation_suffix]
				if animated_sprite.sprite_frames.has_animation(body_armor_animation):
					body_armor.animation = body_armor_animation
			else:
				body_armor.animation = visual_animation
			body_armor.frame = animated_sprite.frame
			body_armor.frame_progress = 0.0
			body_armor.flip_h = animated_sprite.flip_h
		
		# Arm armor
		if arm_armor.visible:
			arm_animation_suffix = _get_armor_animation_suffix()
			if arm_animation_suffix != "":
				arm_armor_animation = "%s_%s" % [visual_animation, arm_animation_suffix]
				if animated_sprite.sprite_frames.has_animation(arm_armor_animation):
					arm_armor.animation = arm_armor_animation
			else:
				arm_armor.animation = visual_animation
			arm_armor.frame = animated_sprite.frame
			arm_armor.frame_progress = 0.0
			arm_armor.flip_h = animated_sprite.flip_h
		
		# Leg armor
		if leg_armor.visible:
			leg_animation_suffix = _get_armor_animation_suffix()
			if leg_animation_suffix != "":
				leg_armor_animation = "%s_%s" % [visual_animation, leg_animation_suffix]
				if animated_sprite.sprite_frames.has_animation(leg_armor_animation):
					leg_armor.animation = leg_armor_animation
			else:
				leg_armor.animation = visual_animation
			leg_armor.frame = animated_sprite.frame
			leg_armor.frame_progress = 0.0
			leg_armor.flip_h = animated_sprite.flip_h

func _check_set_bonus() -> void:
	# Check if all 4 parts of the same armor type are equipped
	var head_armor := get_armor_part(ArmorPart.HEAD)
	var body_armor := get_armor_part(ArmorPart.BODY)
	var arm_armor := get_armor_part(ArmorPart.ARM)
	var leg_armor := get_armor_part(ArmorPart.LEG)

	# Check for Light Armor set bonus
	if head_armor == ArmorType.LIGHT and body_armor == ArmorType.LIGHT and arm_armor == ArmorType.LIGHT and leg_armor == ArmorType.LIGHT:
		_apply_light_armor_set_bonus()
		print("Light Armor Set Bonus Applied!")
	
	# Check for Giga Armor set bonus
	elif head_armor == ArmorType.GIGA and body_armor == ArmorType.GIGA and arm_armor == ArmorType.GIGA and leg_armor == ArmorType.GIGA:
		_apply_giga_armor_set_bonus()
		print("Giga Armor Set Bonus Applied!")
	
	# Check for Max Armor set bonus
	elif head_armor == ArmorType.MAX and body_armor == ArmorType.MAX and arm_armor == ArmorType.MAX and leg_armor == ArmorType.MAX:
		_apply_max_armor_set_bonus()
		print("Max Armor Set Bonus Applied!")
	
	# Check for Force Armor set bonus
	elif head_armor == ArmorType.FORCE and body_armor == ArmorType.FORCE and arm_armor == ArmorType.FORCE and leg_armor == ArmorType.FORCE:
		_apply_force_armor_set_bonus()
		print("Force Armor Set Bonus Applied!")
	
	# Check for Falcon Armor set bonus
	elif head_armor == ArmorType.FALCON and body_armor == ArmorType.FALCON and arm_armor == ArmorType.FALCON and leg_armor == ArmorType.FALCON:
		_apply_falcon_armor_set_bonus()
		print("Falcon Armor Set Bonus Applied!")
	
	# Check for Gaea Armor set bonus
	elif head_armor == ArmorType.GAEA and body_armor == ArmorType.GAEA and arm_armor == ArmorType.GAEA and leg_armor == ArmorType.GAEA:
		_apply_gaea_armor_set_bonus()
		print("Gaea Armor Set Bonus Applied!")
	
	# Check for Blade Armor set bonus
	elif head_armor == ArmorType.BLADE and body_armor == ArmorType.BLADE and arm_armor == ArmorType.BLADE and leg_armor == ArmorType.BLADE:
		_apply_blade_armor_set_bonus()
		print("Blade Armor Set Bonus Applied!")
	
	# Check for Shadow Armor set bonus
	elif head_armor == ArmorType.SHADOW and body_armor == ArmorType.SHADOW and arm_armor == ArmorType.SHADOW and leg_armor == ArmorType.SHADOW:
		_apply_shadow_armor_set_bonus()
		print("Shadow Armor Set Bonus Applied!")
	
	# Check for Glide Armor set bonus
	elif head_armor == ArmorType.GLIDE and body_armor == ArmorType.GLIDE and arm_armor == ArmorType.GLIDE and leg_armor == ArmorType.GLIDE:
		_apply_glide_armor_set_bonus()
		print("Glide Armor Set Bonus Applied!")
	
	# Check for Icarus Armor set bonus
	elif head_armor == ArmorType.ICARUS and body_armor == ArmorType.ICARUS and arm_armor == ArmorType.ICARUS and leg_armor == ArmorType.ICARUS:
		_apply_icarus_armor_set_bonus()
		print("Icarus Armor Set Bonus Applied!")
	
	# Check for Hermes Armor set bonus
	elif head_armor == ArmorType.HERMES and body_armor == ArmorType.HERMES and arm_armor == ArmorType.HERMES and leg_armor == ArmorType.HERMES:
		_apply_hermes_armor_set_bonus()
		print("Hermes Armor Set Bonus Applied!")

func _apply_light_armor_set_bonus() -> void:
	# Light Armor set bonus: Enhanced charge speed and damage
	# In the original GML, this would increase charge speed and damage
	# For now, we'll just print a message
	print("Light Armor Set Bonus: Enhanced charge speed and damage")
	# TODO: Implement actual charge speed and damage bonuses

func _apply_giga_armor_set_bonus() -> void:
	# Giga Armor set bonus: Super armor and increased damage resistance
	# In the original GML, this would make X immune to flinch and reduce damage further
	# For now, we'll just print a message
	print("Giga Armor Set Bonus: Super armor and increased damage resistance")
	# TODO: Implement actual super armor and damage resistance bonuses

func _apply_max_armor_set_bonus() -> void:
	# Max Armor set bonus: Maximum charge and special abilities
	# In the original GML, this would allow for maximum charge and special abilities
	# For now, we'll just print a message
	print("Max Armor Set Bonus: Maximum charge and special abilities")
	# TODO: Implement actual maximum charge and special abilities

func _apply_force_armor_set_bonus() -> void:
	# Force Armor set bonus: Enhanced dash and melee abilities
	# In the original GML, this would enhance dash speed and melee damage
	# For now, we'll just print a message
	print("Force Armor Set Bonus: Enhanced dash and melee abilities")
	# TODO: Implement actual dash and melee enhancements

func _apply_falcon_armor_set_bonus() -> void:
	# Falcon Armor set bonus: Flight abilities
	# In the original GML, this would allow for flight
	# For now, we'll just print a message
	print("Falcon Armor Set Bonus: Flight abilities")
	# TODO: Implement actual flight abilities

func _apply_gaea_armor_set_bonus() -> void:
	# Gaea Armor set bonus: Earthquake abilities
	# In the original GML, this would allow for earthquake attacks
	# For now, we'll just print a message
	print("Gaea Armor Set Bonus: Earthquake abilities")
	# TODO: Implement actual earthquake abilities

func _apply_blade_armor_set_bonus() -> void:
	# Blade Armor set bonus: Enhanced blade attacks
	# In the original GML, this would enhance blade attacks
	# For now, we'll just print a message
	print("Blade Armor Set Bonus: Enhanced blade attacks")
	# TODO: Implement actual blade enhancements

func _apply_shadow_armor_set_bonus() -> void:
	# Shadow Armor set bonus: Shadow dash and stealth
	# In the original GML, this would allow for shadow dash and stealth
	# For now, we'll just print a message
	print("Shadow Armor Set Bonus: Shadow dash and stealth")
	# TODO: Implement actual shadow dash and stealth abilities

func _apply_glide_armor_set_bonus() -> void:
	# Glide Armor set bonus: Gliding abilities
	# In the original GML, this would allow for gliding
	# For now, we'll just print a message
	print("Glide Armor Set Bonus: Gliding abilities")
	# TODO: Implement actual gliding abilities

func _apply_icarus_armor_set_bonus() -> void:
	# Icarus Armor set bonus: Enhanced jump and air abilities
	# In the original GML, this would enhance jump height and air control
	# For now, we'll just print a message
	print("Icarus Armor Set Bonus: Enhanced jump and air abilities")
	# TODO: Implement actual jump and air enhancements

func _apply_hermes_armor_set_bonus() -> void:
	# Hermes Armor set bonus: Enhanced speed and dash abilities
	# In the original GML, this would enhance speed and dash abilities
	# For now, we'll just print a message
	print("Hermes Armor Set Bonus: Enhanced speed and dash abilities")
	# TODO: Implement actual speed and dash enhancements

func _simulate_tick() -> void:
	frame_counter += 1

	var animation_end_event := animation_ended_last_tick
	animation_ended_last_tick = false

	_step_input()
	if _get_input_pressed_raw("dash"):
		last_dash_press_frame = frame_counter
	_tick_counters()
	_update_axes()
	_step_double_tap()
	_update_charge_state()

	if _get_input_pressed_raw("shoot"):
		_try_shoot()

	if hdir != 0:
		_trigger_move_h()
	if _get_input_pressed("jump"):
		_trigger_jump()
	if _get_input_pressed_raw("dash") and not _get_input_pressed("jump"):
		dash_tapped = false
		_trigger_dash()
	if animation_end_event:
		_trigger_animation_end()
	if not _is_on_floor():
		_trigger_dash_end()
	if _check_wall(dash_dir):
		_trigger_dash_end()

	_trigger_transition()
	_sync_shoot_presentation()
	_step_state()
	_step_physics()
	_advance_animation()
	_apply_animation_pose()
	_update_charge_visuals()

func _tick_counters() -> void:
	if shoot_cooldown_frames_left > 0:
		shoot_cooldown_frames_left -= 1

func _update_axes() -> void:
	hdir = int(_get_input("right")) - int(_get_input("left"))
	vdir = int(_get_input("move_down")) - int(_get_input("move_up"))

func _reset_input_tracking() -> void:
	input_state.clear()
	input_pressed.clear()
	input_released.clear()
	for verb in INPUT_ACTIONS.keys():
		input_state[verb] = false
		input_pressed[verb] = false
		input_released[verb] = false

	input_pressed_buffer.clear()
	for _i in range(INPUT_BUFFER_LENGTH):
		var entry := {}
		for verb in INPUT_ACTIONS.keys():
			entry[verb] = false
		input_pressed_buffer.append(entry)

func _step_input() -> void:
	for verb in INPUT_ACTIONS.keys():
		var current_value := Input.is_action_pressed(INPUT_ACTIONS[verb])
		var previous_value: bool = input_state.get(verb, false)
		var just_pressed := (not previous_value) and current_value
		var just_released := previous_value and (not current_value)

		input_state[verb] = current_value
		input_pressed[verb] = just_pressed
		input_released[verb] = just_released

		if INPUT_BUFFER_ACTIVE.get(verb, false):
			for index in range(input_pressed_buffer.size() - 1, -1, -1):
				if index == 0:
					input_pressed_buffer[index][verb] = just_pressed
				else:
					input_pressed_buffer[index][verb] = input_pressed_buffer[index - 1][verb]
		else:
			for entry in input_pressed_buffer:
				entry[verb] = false

func _get_input(verb: String) -> bool:
	return input_state.get(verb, false)

func _get_input_pressed_raw(verb: String) -> bool:
	return input_pressed.get(verb, false)

func _get_input_released_raw(verb: String) -> bool:
	return input_released.get(verb, false)

func _get_input_pressed(verb: String) -> bool:
	var result: bool = input_pressed.get(verb, false)
	if not input_use_buffer:
		return result

	for entry in input_pressed_buffer:
		if entry.get(verb, false):
			return true
	return result

func _step_double_tap() -> void:
	if _get_input_pressed_raw("right"):
		_double_tap_pressed(1)
	if _get_input_pressed_raw("left"):
		_double_tap_pressed(-1)

	if not double_tap_enabled:
		return

	double_tap_timer += 1
	if double_tap_timer >= DOUBLE_TAP_WINDOW:
		_reset_double_tap()

func _double_tap_pressed(key: int) -> void:
	if double_tap_current_key != 0 and double_tap_current_key != key:
		_reset_double_tap()
		double_tap_current_key = key

	double_tap_enabled = true
	double_tap_count += 1
	double_tap_timer = 0

	if double_tap_count <= 1 or dir != key:
		double_tap_current_key = key
		return

	_reset_double_tap()
	dash_dir = key
	dash_tapped = true
	_trigger_dash()

func _reset_double_tap() -> void:
	double_tap_timer = 0
	double_tap_enabled = false
	double_tap_current_key = 0
	double_tap_count = 0

func _has_recent_dash_jump_press() -> bool:
	return frame_counter - last_dash_press_frame <= DASH_JUMP_PRESS_GRACE_FRAMES

func _update_charge_state() -> void:
	if _get_input_pressed_raw("shoot"):
		charge_hold_start_frame = frame_counter
		charge_stage = 0

	if charge_hold_start_frame >= 0 and _get_input("shoot"):
		charge_stage = _get_charge_stage_for_elapsed(frame_counter - charge_hold_start_frame)

	if _get_input_released_raw("shoot"):
		var released_charge_stage := 0
		if charge_hold_start_frame >= 0:
			released_charge_stage = _get_charge_stage_for_elapsed(frame_counter - charge_hold_start_frame)
		charge_hold_start_frame = -1
		charge_stage = 0
		if released_charge_stage > 0:
			_try_shoot(released_charge_stage)

func _get_charge_stage_for_elapsed(elapsed_frames: int) -> int:
	if elapsed_frames >= CHARGE_LEVEL_4_FRAMES:
		return 4
	if elapsed_frames >= CHARGE_LEVEL_3_FRAMES:
		return 3
	if elapsed_frames >= CHARGE_LEVEL_2_FRAMES:
		return 2
	if elapsed_frames >= CHARGE_LEVEL_1_FRAMES:
		return 1
	return 0

func _get_charge_visual_level_for_elapsed(elapsed_frames: int) -> int:
	if elapsed_frames >= CHARGE_LEVEL_4_FRAMES:
		return 4
	if elapsed_frames >= CHARGE_LEVEL_3_FRAMES:
		return 3
	if elapsed_frames >= CHARGE_LEVEL_2_FRAMES:
		return 2
	if elapsed_frames >= CHARGE_LEVEL_1_FRAMES:
		return 1
	return 0

func _trigger_move_h() -> void:
	match state_name:
		"idle":
			if not _check_wall(hdir):
				_change_state("walk")
		"land":
			if not _check_wall(hdir) and not _get_input("dash"):
				_change_state("walk")
			elif MMXE_DASH_ON_LAND and _get_input("dash"):
				_change_state("dash")
	if get_armor_part(ArmorPart.HEAD) == ArmorType.LIGHT:
		_apply_headbutt()

func _trigger_jump() -> void:
	if _can_jump_check():
		match state_name:
			"idle", "walk", "dash", "land", "dash_end":
				_change_state("jump")
				return

	var wall_jump_dir := _get_wall_jump_dir()
	if wall_jump_dir != 0:
		match state_name:
			"fall", "wall_slide", "wall_jump":
				_change_state("wall_jump")

func _trigger_dash() -> void:
	var candidate_dir := dir if dir != 0 else hdir
	if candidate_dir == 0:
		return
	if _check_wall(candidate_dir):
		return
	if not _is_on_floor(GROUND_DISTANCE):
		return

	dash_dir = candidate_dir
	_change_state("dash")

func _trigger_dash_end() -> void:
	if state_name != "dash":
		return

	if not _is_on_floor(GROUND_DISTANCE):
		_change_state("fall")
	else:
		_change_state("dash_end")

func _trigger_animation_end() -> void:
	match state_name:
		"land", "dash_end":
			_change_state("idle")
		"hurt":
			if _is_on_floor():
				_change_state("idle")
			else:
				_change_state("fall")

func _trigger_transition() -> void:
	match state_name:
		"idle":
			if not _is_on_floor(GROUND_DISTANCE):
				_change_state("fall")
			elif vdir != 0 and is_on_ladder:
				_change_state("ladder_idle")
		"walk":
			if not _is_on_floor(GROUND_DISTANCE):
				_change_state("fall")
			elif hdir == 0 or _check_wall(hdir):
				_change_state("idle")
			elif vdir != 0 and is_on_ladder:
				_change_state("ladder_idle")
		"jump":
			if not _get_input("jump") or _is_on_ceil() or vspd >= 0.0:
				_change_state("fall")
			elif vdir != 0 and is_on_ladder:
				_change_state("ladder_idle")
		"fall":
			if _is_on_floor():
				_change_state("land")
			elif _wall_slide_possible():
				_change_state("wall_slide")
			elif vdir != 0 and is_on_ladder:
				_change_state("ladder_idle")
		"dash":
			if (hdir != dash_dir and (hdir != 0 or dash_tapped)) or timer <= frame_counter or (not dash_tapped and not _get_input("dash")):
				_change_state("dash_end")
			elif vdir != 0 and is_on_ladder:
				_change_state("ladder_idle")
		"wall_slide":
			if _is_on_floor():
				_change_state("land")
			elif hdir != dir or not _wall_slide_possible():
				_change_state("fall")
		"wall_jump":
			if _is_on_floor():
				_change_state("land")
			elif (((not _get_input("jump")) or _is_on_ceil()) and frame_counter - timer > 10) or vspd > 0.0:
				_change_state("fall")
			elif vdir != 0 and is_on_ladder:
				_change_state("ladder_idle")
		"ladder_idle":
			if vdir != 0:
				_change_state("ladder_move")
			elif not is_on_ladder or _is_on_floor():
				_change_state("fall" if not _is_on_floor() else "idle")
		"ladder_move":
			if vdir == 0:
				_change_state("ladder_idle")
			elif not is_on_ladder:
				_change_state("fall")
			elif _is_on_floor() and vdir > 0:
				_change_state("idle")

func _change_state(new_state: String) -> void:
	if new_state == state_name:
		return

	if state_name != "":
		_leave_state(state_name)

	previous_state = state_name
	state_name = new_state
	_enter_state(state_name)

func _enter_state(new_state: String) -> void:
	match new_state:
		"idle":
			_play_animation("idle", false, 0.0)
			hspd = 0.0
			vspd = 0.0
		"walk":
			_play_animation("walk")
			current_hspd = WALK_SPEED
		"jump":
			input_use_buffer = false
			_play_animation("jump")
			current_hspd = WALK_SPEED
			vspd = -JUMP_STRENGTH
			if previous_state == "dash" or _has_recent_dash_jump_press():
				current_hspd = DASH_SPEED
		"fall":
			_play_animation("fall")
			if previous_state == "jump" or vspd < 0.0:
				vspd = 0.0
		"land":
			_play_animation("land")
			input_use_buffer = true
			current_hspd = WALK_SPEED
			if hdir != 0 and not _check_wall(hdir):
				hspd = WALK_SPEED * float(hdir)
			else:
				hspd = 0.0
		"dash":
			timer = frame_counter + DASH_INTERVAL
			_play_animation("dash")
		"dash_end":
			timer = 0
			if not dash_jump:
				current_hspd = WALK_SPEED
			dash_dir = dir
			dash_tapped = false
			_play_animation("dash_end")
		"wall_slide":
			input_use_buffer = true
			timer = 0
			dash_jump = false
			current_hspd = WALK_SPEED
			gravity_strength = 0.0
			hspd = 0.0
			vspd = 0.0
			_play_animation("wall_slide")
		"wall_jump":
			input_use_buffer = false
			timer = frame_counter
			dir = _get_wall_jump_dir()
			gravity_strength = 0.0
			hspd = 0.0
			vspd = 0.0
			_play_animation("wall_jump")
		"hurt":
			_play_animation("hurt")
			hspd = dir * HURT_SPEED
			vspd = HURT_VERTICAL
			gravity_strength = DEFAULT_GRAVITY
		"ladder_idle":
			hspd = 0.0
			vspd = 0.0
			gravity_strength = 0.0
			_play_animation("ladder_idle")
		"ladder_move":
			gravity_strength = 0.0
			_play_animation("ladder_move")

	_apply_animation_pose()

func _leave_state(old_state: String) -> void:
	match old_state:
		"dash":
			dash_jump = _get_input_pressed("jump")
			if not dash_jump and _is_on_floor():
				current_hspd = WALK_SPEED
		"land":
			dash_jump = false
		"wall_slide":
			gravity_strength = DEFAULT_GRAVITY
			vspd = 0.0
		"wall_jump":
			gravity_strength = DEFAULT_GRAVITY
		"ladder_idle", "ladder_move":
			gravity_strength = DEFAULT_GRAVITY

func _step_state() -> void:
	match state_name:
		"walk", "jump", "fall", "dash_end":
			_set_hor_movement()
		"dash":
			_set_hor_movement(dash_dir)
			if frame_counter >= timer - DASH_INTERVAL + 2:
				current_hspd = DASH_SPEED
		"wall_slide":
			timer += 1
			if timer == 6:
				vspd = 2.0
			_set_hor_movement()
		"wall_jump":
			if timer + WALL_LAUNCH_LOCK_FRAMES < frame_counter:
				input_use_buffer = true
				_play_animation("jump", false, 10.0)
				_set_hor_movement()
			if timer + WALL_STICK_FRAMES == frame_counter:
				gravity_strength = DEFAULT_GRAVITY
				if _get_input("dash"):
					current_hspd = DASH_SPEED
					if not _is_on_ceil() or dir != hdir:
						hspd = DASH_SPEED * dir * -1.0
					dash_jump = true
				else:
					if not _is_on_ceil() or dir != hdir:
						hspd = WALK_SPEED * dir * -1.0
				vspd = -WALL_JUMP_STRENGTH
		"ladder_idle":
			if _get_input_pressed("jump"):
				_change_state("jump")
		"ladder_move":
			hspd = 0.0
			vspd = vdir * LADDER_SPEED
			if _get_input_pressed("jump"):
				_change_state("jump")

func _set_hor_movement(direction_override: int = hdir) -> void:
	if direction_override != 0:
		dir = direction_override
	hspd = current_hspd * float(direction_override)

func _step_physics() -> void:
	_move_step(Vector2(hspd, vspd))
	vspd += gravity_strength
	if vspd > TERMINAL_VELOCITY:
		vspd = TERMINAL_VELOCITY
	if _is_on_floor(2):
		vspd = 0.0

func _is_motion_blocked(motion: Vector2) -> bool:
	return test_move(global_transform, motion)

func _probe_collision(offset: Vector2, motion: Vector2) -> bool:
	var probe_transform := global_transform
	probe_transform.origin += offset
	return test_move(probe_transform, motion)

func _has_body_wall_contact(direction: int, distance: float = 9.0) -> bool:
	if direction == 0:
		return false

	var motion := Vector2(float(direction) * distance, 0.0)
	var hit_count := 0
	for offset_y in [-10.0, -5.0, 0.0]:
		if _probe_collision(Vector2(0.0, offset_y), motion):
			hit_count += 1
	return hit_count >= 2

func _move_step(delta: Vector2) -> void:
	var original_x := global_position.x
	if delta.x > 0.0:
		var collided_right := _move_right(delta.x)
		if collided_right:
			global_position.x = original_x
			global_position.y -= 1.0
			collided_right = _move_right(delta.x)
			if collided_right:
				global_position.x = original_x
				global_position.y += 2.0
				_move_right(delta.x)
				global_position.y -= 1.0
	elif delta.x < 0.0:
		var collided_left := _move_left(-delta.x)
		if collided_left:
			global_position.x = original_x
			global_position.y -= 1.0
			collided_left = _move_left(-delta.x)
			if collided_left:
				global_position.x = original_x
				global_position.y += 2.0
				_move_left(-delta.x)
				global_position.y -= 1.0

	var original_y := global_position.y
	var floor_probe_hit := _move_down(2.0)
	if not floor_probe_hit or delta.y < 0.0:
		global_position.y = original_y

	if delta.y >= 0.0:
		_move_down(delta.y)
	else:
		_move_up(-delta.y)

func _move_right(distance: float) -> bool:
	return _move_axis(distance, Vector2.RIGHT)

func _move_left(distance: float) -> bool:
	return _move_axis(distance, Vector2.LEFT)

func _move_down(distance: float) -> bool:
	return _move_axis(distance, Vector2.DOWN)

func _move_up(distance: float) -> bool:
	return _move_axis(distance, Vector2.UP)

func _move_axis(distance: float, unit: Vector2) -> bool:
	if distance <= 0.0:
		return false

	var whole_steps := int(floor(distance))
	for _step in range(whole_steps):
		if _is_motion_blocked(unit):
			return true
		global_position += unit

	var fractional_step := distance - float(whole_steps)
	if fractional_step > 0.0:
		var motion := unit * fractional_step
		if _is_motion_blocked(motion):
			return true
		global_position += motion

	return false

func _is_on_floor(dist: int = 1) -> bool:
	return _probe_collision(Vector2.ZERO, Vector2(0.0, float(dist)))

func _is_on_ceil(dist: int = 3) -> bool:
	return _probe_collision(Vector2.ZERO, Vector2(0.0, -float(dist)))

func _check_wall(dist: int) -> bool:
	if dist == 0:
		return false

	return _probe_collision(Vector2.ZERO, Vector2(float(dist), 0.0))

func _wall_slide_possible() -> bool:
	return hdir != 0 and not _is_on_floor() and _check_wall(hdir)

func _get_wall_jump_dir() -> int:
	if _is_on_floor():
		return 0
	var has_right := _has_body_wall_contact(1, 1.0)
	var has_left := _has_body_wall_contact(-1, 1.0)
	if has_right and has_left:
		return hdir if hdir != 0 else 1
	if has_right:
		return 1
	if has_left:
		return -1
	return 0

func _can_jump_check() -> bool:
	return _is_on_floor(GROUND_DISTANCE) and not _is_on_ceil(6)



func _try_shoot(shot_level: int = 0) -> void:
	if shot_level == 0 and shoot_cooldown_frames_left > 0:
		return

	var shot_direction := _get_shot_direction()
	var shot_offset := _get_fire_shot_offset()
	var shot = BUSTER_SCENE.instantiate()
	shot.direction = shot_direction
	shot.shot_level = shot_level
	shot.owner_to_ignore = self
	shot.global_position = global_position + Vector2(shot_offset.x * shot_direction, shot_offset.y)
	get_tree().current_scene.add_child(shot)

	shoot_cooldown_frames_left = SHOOT_COOLDOWN_FRAMES
	shot_end_frame = frame_counter + SHOOT_VISUAL_DURATION
	if state_name == "idle":
		_play_animation("shoot", animation_name == "shoot")

	if get_armor_part(ArmorPart.ARM) == ArmorType.LIGHT:
		# Implement Spiral Crush Buster functionality
		# Create a spiral pattern of buster shots
		var spiral_angle := 0.0
		var spiral_radius := 10.0
		var spiral_speed := 0.2
		var spiral_duration := 30  # Frames
		var spiral_shot_count := 12

		for i in range(spiral_shot_count):
			var spiral_shot = BUSTER_SCENE.instantiate()
			spiral_shot.direction = dir
			spiral_shot.shot_level = 1
			spiral_shot.owner_to_ignore = self
			# Calculate spiral position
			var angle := spiral_angle + (i * (2 * PI / spiral_shot_count))
			var offset_x := spiral_radius * cos(angle)
			var offset_y := spiral_radius * sin(angle)
			spiral_shot.global_position = global_position + Vector2(offset_x, offset_y)
			get_tree().current_scene.add_child(spiral_shot)
			# Update spiral angle for next shot
			spiral_angle += spiral_speed

func _get_shot_direction() -> int:
	if animation_name == "wall_slide":
		return -dir
	return dir

func _get_fire_shot_offset() -> Vector2:
	# Check if we're in a state where we should use animation-specific shot offset
	if state_name == "idle" and animation_name != "shoot" and animation_defs.has("shoot"):
		var shoot_pose := _resolve_animation_pose("shoot", 0.0)
		var base_offset := _to_local_shot_offset(shoot_pose.get("shot_offset", Vector2(12.0, -3.0)))
		
		# Apply armor-specific shot offset based on arm armor type
		var arm_armor := get_armor_part(ArmorPart.ARM)
		match arm_armor:
			ArmorType.LIGHT:
				# Light Armor - no special offset
				pass
			ArmorType.GIGA:
				# Giga Armor - slightly higher shot position
				base_offset.y -= 2.0
			ArmorType.MAX:
				# Max Armor - higher shot position
				base_offset.y -= 4.0
			ArmorType.FORCE:
				# Force Armor - slightly lower shot position
				base_offset.y += 2.0
			ArmorType.FALCON:
				# Falcon Armor - forward shot position
				base_offset.x += 2.0
			ArmorType.GAEA:
				# Gaea Armor - slightly forward shot position
				base_offset.x += 1.0
			ArmorType.BLADE:
				# Blade Armor - forward shot position
				base_offset.x += 3.0
			ArmorType.SHADOW:
				# Shadow Armor - slightly forward shot position
				base_offset.x += 1.0
			ArmorType.GLIDE:
				# Glide Armor - no special offset
				pass
			ArmorType.ICARUS:
				# Icarus Armor - no special offset
				pass
			ArmorType.HERMES:
				# Hermes Armor - no special offset
				pass
			_:
				# No armor or unknown armor type
				pass
		
		return base_offset
	
	return current_shot_offset

func _sync_shoot_presentation() -> void:
	var shot_active := shot_end_frame > frame_counter
	if shot_active:
		if state_name == "idle":
			if animation_name == "idle":
				_play_animation("shoot")
		elif animation_name == "shoot":
			_play_animation("idle")
	elif animation_name == "shoot":
		_play_animation("idle")

func _load_animation_defs() -> void:
	animation_defs.clear()
	if not FileAccess.file_exists(ANIMATION_DATA_PATH):
		return

	var raw_text := FileAccess.get_file_as_string(ANIMATION_DATA_PATH)
	var parsed: Variant = JSON.parse_string(_strip_json_comments(raw_text))
	if not (parsed is Dictionary):
		return

	var data: Dictionary = parsed.get("data", {})
	var animations: Dictionary = data.get("animations", {})
	var animation_list: Array = animations.get("list", [])

	for entry_variant in animation_list:
		if not (entry_variant is Dictionary):
			continue

		var entry: Dictionary = entry_variant
		var name: String = entry.get("name", "")
		if name.is_empty():
			continue

		var properties: Dictionary = entry.get("properties", {})
		var keyframes: Array = []
		var max_key := 0.0
		for keyframe_variant in properties.get("keyframes", []):
			if keyframe_variant is Dictionary:
				var keyframe: Dictionary = keyframe_variant
				keyframes.append(keyframe)
				max_key = maxf(max_key, float(keyframe.get("key", 0.0)))

		animation_defs[name] = {
			"action": properties.get("action", name),
			"keyframes": keyframes,
			"loop_begin": float(properties.get("loop_begin", 0.0)),
			"max_key": max_key,
			"speed": float(properties.get("speed", 1.0)),
		}

func _strip_json_comments(source: String) -> String:
	var cleaned_lines: PackedStringArray = []
	for line in source.split("\n"):
		var builder := ""
		var in_string := false
		var escaped := false
		var index := 0
		while index < line.length():
			var current_char := line.substr(index, 1)
			var next_char := ""
			if index + 1 < line.length():
				next_char = line.substr(index + 1, 1)

			if not in_string and current_char == "/" and next_char == "//":
				break

			builder += current_char

			if current_char == "\"" and not escaped:
				in_string = not in_string
			if current_char == "\\" and not escaped:
				escaped = true
			else:
				escaped = false

			index += 1
		cleaned_lines.append(builder)
	return "\n".join(cleaned_lines)

func _play_animation(name: String, reset: bool = true, key_index: float = 0.0) -> void:
	if not animation_defs.has(name):
		return
	if animation_name == name and not reset:
		return

	animation_name = name
	animation_key_index = key_index
	animation_wait_frames = 1
	var pose := _resolve_animation_pose(name, key_index)
	current_animation_frame = pose.get("frame", 0)
	current_shot_offset = _to_local_shot_offset(pose.get("shot_offset", Vector2(12.0, -3.0)))

func _advance_animation() -> void:
	if animation_name.is_empty():
		return
	if not animation_defs.has(animation_name):
		return

	var definition: Dictionary = animation_defs[animation_name]
	var keyframes: Array = definition.get("keyframes", [])
	if keyframes.is_empty():
		return

	var loop_begin: float = definition.get("loop_begin", 0.0)
	var max_key: float = definition.get("max_key", 0.0)
	var speed: float = definition.get("speed", 1.0)
	var key_progress := animation_key_index + speed

	if animation_wait_frames > 0:
		animation_wait_frames -= 1
		key_progress = animation_key_index
	elif key_progress > max_key:
		animation_ended_last_tick = true
		key_progress = loop_begin + (key_progress - max_key)
		if key_progress >= max_key:
			key_progress = max_key

	animation_key_index = key_progress
	var pose := _resolve_animation_pose(animation_name, animation_key_index)
	current_animation_frame = pose.get("frame", 0)
	current_shot_offset = _to_local_shot_offset(pose.get("shot_offset", Vector2(12.0, -3.0)))

func _resolve_animation_pose(name: String, key_index: float) -> Dictionary:
	if not animation_defs.has(name):
		return {
			"frame": 0,
			"shot_offset": Vector2(12.0, -3.0),
		}

	var keyframes: Array = animation_defs[name].get("keyframes", [])
	var chosen_frame := 0
	var shot_offset := Vector2(12.0, -3.0)

	for keyframe_variant in keyframes:
		var keyframe: Dictionary = keyframe_variant
		if float(keyframe.get("key", 0.0)) <= key_index:
			chosen_frame = int(keyframe.get("frame", chosen_frame))
			shot_offset = Vector2(
				float(keyframe.get("shot_offset_x", shot_offset.x)),
				float(keyframe.get("shot_offset_y", shot_offset.y))
			)
		else:
			break

	return {
		"frame": chosen_frame,
		"shot_offset": shot_offset,
	}

func _to_local_shot_offset(mmxe_offset: Vector2) -> Vector2:
	return Vector2(mmxe_offset.x, mmxe_offset.y - MMXE_MASK_Y_ORIGIN)

func _load_charge_effect_textures() -> void:
	charge_stage_0_texture = _load_texture_from_png(CHARGE_STAGE_0_TEXTURE_PATH)
	charge_stage_1_texture = _load_texture_from_png(CHARGE_STAGE_1_TEXTURE_PATH)
	charge_stage_2_texture = _load_texture_from_png(CHARGE_STAGE_2_TEXTURE_PATH)
	charge_stage_3_texture = _load_texture_from_png(CHARGE_STAGE_3_TEXTURE_PATH)
	charge_stage_4_texture = _load_texture_from_png(CHARGE_STAGE_4_TEXTURE_PATH)

func _load_texture_from_png(resource_path: String) -> Texture2D:
	var image := Image.load_from_file(ProjectSettings.globalize_path(resource_path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _setup_palette_material() -> void:
	if charge_glow_sprite == null:
		return

	animated_sprite.material = null
	animated_sprite.modulate = Color.WHITE
	palette_material = ShaderMaterial.new()
	palette_material.shader = PALETTE_SWAP_SHADER
	palette_material.set_shader_parameter("source_palette", DEFAULT_X_PALETTE)
	palette_material.set_shader_parameter("target_palette", DEFAULT_X_PALETTE)
	palette_material.set_shader_parameter("palette_swap_enabled", false)
	charge_glow_sprite.material = palette_material
	charge_glow_sprite.modulate = Color.WHITE
	charge_glow_sprite.visible = false
	# TODO: Set charge_glow_sprite.visible = true and modulate to correct color when charging

func _set_charge_palette(enabled: bool, palette: Array = DEFAULT_X_PALETTE) -> void:
	if palette_material == null or charge_glow_sprite == null:
		return

	if not enabled:
		palette_material.set_shader_parameter("target_palette", DEFAULT_X_PALETTE)
		palette_material.set_shader_parameter("palette_swap_enabled", false)
		charge_glow_sprite.visible = false
		return

	palette_material.set_shader_parameter("source_palette", DEFAULT_X_PALETTE)
	palette_material.set_shader_parameter("target_palette", palette)
	palette_material.set_shader_parameter("palette_swap_enabled", true)
	charge_glow_sprite.visible = true

# Set glow color based on palette (charge stage)
	if palette == CHARGE_PALETTE_STAGE_1:
		charge_glow_sprite.modulate = Color(0.6, 0.9, 1.0, 0.7) # Brighter blue with some transparency
	elif palette == CHARGE_PALETTE_STAGE_2:
		charge_glow_sprite.modulate = Color(1.0, 1.0, 0.6, 0.7) # Brighter yellow with some transparency
	elif palette == CHARGE_PALETTE_UPGRADE_1:
		charge_glow_sprite.modulate = Color(0.9, 0.7, 1.0, 0.7) # Brighter purple with some transparency
	elif palette == CHARGE_PALETTE_UPGRADE_2:
		charge_glow_sprite.modulate = Color(1.0, 0.7, 0.4, 0.7) # Brighter orange with some transparency
	else:
		charge_glow_sprite.modulate = Color(1.0, 1.0, 1.0, 0.7) # White with some transparency

func _get_charge_palette_for_visual_level(visual_level: int) -> Array:
	var palette_index := clampi(visual_level - 1, 0, charge_palette_limit - 1)
	match palette_index:
		3:
			return CHARGE_PALETTE_UPGRADE_2
		2:
			return CHARGE_PALETTE_UPGRADE_1
		1:
			return CHARGE_PALETTE_STAGE_2
		_:
			return CHARGE_PALETTE_STAGE_1

func _get_charge_texture_for_visual_level(visual_level: int) -> Texture2D:
	var clamped_level := clampi(visual_level, 0, charge_palette_limit)
	match clamped_level:
		4:
			return charge_stage_4_texture
		3:
			return charge_stage_3_texture
		2:
			return charge_stage_2_texture
		1:
			return charge_stage_1_texture
		_:
			return charge_stage_0_texture

func _update_charge_visuals() -> void:
	if charge_effect == null or animated_sprite == null:
		return

	if charge_hold_start_frame < 0:
		charge_effect.visible = false
		charge_effect_stage = 0
		charge_effect_frame = 0
		charge_effect_tick = 0
		animated_sprite.modulate = Color.WHITE
		charge_effect.modulate = Color.WHITE
		_set_charge_palette(false)
		return

	var elapsed_frames := frame_counter - charge_hold_start_frame
	var visual_level := _get_charge_visual_level_for_elapsed(elapsed_frames)
	if visual_level <= 0:
		charge_effect.visible = false
		charge_effect_stage = 0
		charge_effect_frame = 0
		charge_effect_tick = 0
		animated_sprite.modulate = Color.WHITE
		charge_effect.modulate = Color.WHITE
		_set_charge_palette(false)
		return

	var stage_texture := _get_charge_texture_for_visual_level(visual_level)
	var charge_palette := _get_charge_palette_for_visual_level(visual_level)

	if stage_texture == null:
		animated_sprite.modulate = Color.WHITE
		_set_charge_palette(elapsed_frames % 2 == 0, charge_palette)
		return

	if charge_effect_stage != visual_level or charge_effect.texture != stage_texture:
		charge_effect_stage = visual_level
		charge_effect_frame = 0
		charge_effect_tick = 0
		charge_effect.texture = stage_texture
		charge_effect.hframes = 16 if visual_level == 0 else CHARGE_FRAME_COUNT
		charge_effect.frame = 0

	charge_effect.visible = true
	charge_effect.flip_h = dir < 0
	charge_effect.position = animated_sprite.position
	charge_effect.modulate = Color.WHITE
	animated_sprite.modulate = Color.WHITE
	if charge_glow_sprite != null:
		charge_glow_sprite.position = animated_sprite.position
	charge_effect_tick += 1
	if charge_effect_tick >= 1:
		charge_effect_tick = 0
		charge_effect_frame = (charge_effect_frame + 1) % charge_effect.hframes
	charge_effect.frame = charge_effect_frame
	_set_charge_palette(elapsed_frames % 2 == 0, charge_palette)

func _apply_animation_pose() -> void:
	if animated_sprite.sprite_frames == null:
		return

	var visual_animation := _get_visual_animation_name()
	if not animated_sprite.sprite_frames.has_animation(visual_animation):
		return

	# Apply armor-specific animations
	var armor_animation := _get_armor_animation_suffix()
	if armor_animation != "":
		var armor_visual_animation := "%s_%s" % [visual_animation, armor_animation]
		if animated_sprite.sprite_frames.has_animation(armor_visual_animation):
			visual_animation = armor_visual_animation

	animated_sprite.flip_h = dir < 0
	if animated_sprite.animation != visual_animation:
		animated_sprite.animation = visual_animation
	var frame_count := animated_sprite.sprite_frames.get_frame_count(visual_animation)
	if frame_count <= 0:
		return

	animated_sprite.frame = clampi(current_animation_frame, 0, frame_count - 1)
	animated_sprite.frame_progress = 0.0
	if charge_glow_sprite != null:
		charge_glow_sprite.flip_h = animated_sprite.flip_h
		if charge_glow_sprite.animation != visual_animation:
			charge_glow_sprite.animation = visual_animation
		charge_glow_sprite.frame = animated_sprite.frame
		charge_glow_sprite.frame_progress = 0.0

func _get_visual_animation_name() -> StringName:
	if animation_name.is_empty() or not animation_defs.has(animation_name):
		return &"idle"

	var action_name := String(animation_defs[animation_name].get("action", animation_name))
	if shot_end_frame > frame_counter:
		var shoot_name := "%s_shoot" % action_name
		if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(shoot_name):
			return StringName(shoot_name)

	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(action_name):
		return StringName(action_name)
	return &"idle"
