extends Camera3D

const BallProbe = preload("res://player_camera/test_ball.tscn")

@export var start_paused := false

@export var rotation_speed := 1.0
@export var yaw_factor := 0.005
@export var pitch_factor := 0.005
@export var pitch_inverted := false

@export var move_speed := 1.5
@export var move_factor := Vector3(1, 1, 1)

var _move_forward = false
var _move_back = false
var _move_left = false
var _move_right = false
var _move_up = false
var _move_down = false
var _single_step = false
var _single_physics_step = false


func _ready():
	# Don't pause camera flying
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = start_paused


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			var delta_yaw = -event.relative[0] * yaw_factor * rotation_speed
			var delta_pitch = -event.relative[1] * pitch_factor * rotation_speed
			if pitch_inverted:
				delta_pitch = -delta_pitch
			
			var current_angle = transform.basis.get_euler()
			current_angle.x = clamp(current_angle.x + delta_pitch, -.5 * PI, .5 * PI)
			current_angle.y = fmod(current_angle.y + delta_yaw, 2 * PI)
			transform.basis = Basis.from_euler(current_angle)
	
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				var ball = BallProbe.instantiate()
				ball.transform = transform
				ball.linear_velocity = -transform.basis.z * 10.0
				get_tree().root.add_child(ball)

	if event is InputEventKey:
		if event.physical_keycode == KEY_W:
			_move_forward = event.pressed
		if event.physical_keycode == KEY_S:
			_move_back = event.pressed
		if event.physical_keycode == KEY_A:
			_move_left = event.pressed
		if event.physical_keycode == KEY_D:
			_move_right = event.pressed
		if event.physical_keycode == KEY_E:
			_move_up = event.pressed
		if event.physical_keycode == KEY_Q:
			_move_down = event.pressed


func _process(delta):
	if Input.is_action_just_pressed("debug_pause"):
		get_tree().paused = !get_tree().paused
		_single_step = false
		_single_physics_step = false

	if Input.is_action_just_pressed("debug_step"):
		_single_step = true
		get_tree().paused = false
	elif _single_step:
		_single_step = false
		get_tree().paused = true

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var movement = Vector3(0, 0, 0)
		if _move_forward:
			movement.z -= 1.0
		if _move_back:
			movement.z += 1.0
		if _move_left:
			movement.x -= 1.0
		if _move_right:
			movement.x += 1.0
		if _move_up:
			movement.y += 1.0
		if _move_down:
			movement.y -= 1.0

		movement = transform.basis * (movement * move_factor)
		transform.origin += movement * delta

func _physics_process(delta):
	if Input.is_action_just_pressed("debug_physics_step"):
		_single_physics_step = true
		get_tree().paused = false
	elif _single_physics_step:
		_single_physics_step = false
		get_tree().paused = true
