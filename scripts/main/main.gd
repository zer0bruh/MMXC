extends Node2D

const MOVEMENT_TEST_SCENE := preload("res://scenes/test/movement_test.tscn")

const ACTIONS := {
	"move_left": {
		"keys": [KEY_A, KEY_LEFT],
	},
	"move_right": {
		"keys": [KEY_D, KEY_RIGHT],
	},
	"jump": {
		"keys": [KEY_SPACE, KEY_Z],
	},
	"dash": {
		"keys": [KEY_SHIFT, KEY_X],
		"mouse_buttons": [MOUSE_BUTTON_XBUTTON1, MOUSE_BUTTON_XBUTTON2],
	},
	"shoot": {
		"keys": [KEY_C, KEY_J],
		"mouse_buttons": [MOUSE_BUTTON_LEFT],
	},
	"reset_room": {
		"keys": [KEY_R],
	},
}

@onready var world: Node = $World
var movement_test: Node
var player: Node


func _ready() -> void:
	_ensure_input_actions()
	movement_test = $World/MovementTest
	player = movement_test.get_node_or_null("Player")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_room"):
		_spawn_movement_test()
		get_viewport().set_input_as_handled()


func _spawn_movement_test() -> void:
	if is_instance_valid(movement_test):
		movement_test.queue_free()

	movement_test = MOVEMENT_TEST_SCENE.instantiate()
	world.add_child(movement_test)
	player = movement_test.get_node_or_null("Player")

func _ensure_input_actions() -> void:
	for action_name in ACTIONS.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		var config: Dictionary = ACTIONS[action_name]
		for keycode in config.get("keys", []):
			if _action_has_key(action_name, keycode):
				continue
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action_name, event)
		for button_index in config.get("mouse_buttons", []):
			if _action_has_mouse_button(action_name, button_index):
				continue
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = button_index
			InputMap.action_add_event(action_name, mouse_event)


func _action_has_key(action_name: String, keycode: int) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false


func _action_has_mouse_button(action_name: String, button_index: MouseButton) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventMouseButton and event.button_index == button_index:
			return true
	return false
