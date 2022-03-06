extends RigidDynamicBody3D

signal control_changed(value: Vector3)

var forward := 0.0
var back := 0.0
var right := 0.0
var left := 0.0
var control_vector := Vector3.ZERO


func _integrate_forces(state):
	var control = control_vector.dot(Vector3.FORWARD)
	state.apply_central_force(control * 10.0 * Vector3.FORWARD)


func _input(event):
	var control_changed := false

	if event.is_action_pressed("move_forward"):
		forward = event.get_action_strength("move_forward")
		control_changed = true
	if event.is_action_released("move_forward"):
		forward = 0.0
		control_changed = true

	if event.is_action_pressed("move_back"):
		back = event.get_action_strength("move_back")
		control_changed = true
	if event.is_action_released("move_back"):
		back = 0.0
		control_changed = true

	if event.is_action_pressed("move_right"):
		right = event.get_action_strength("move_right")
		control_changed = true
	if event.is_action_released("move_right"):
		right = 0.0
		control_changed = true

	if event.is_action_pressed("move_left"):
		left = event.get_action_strength("move_left")
		control_changed = true
	if event.is_action_released("move_left"):
		left = 0.0
		control_changed = true

	if control_changed:
		control_vector = forward * Vector3.FORWARD + back * Vector3.BACK + right * Vector3.RIGHT + left * Vector3.LEFT
		emit_signal("control_changed", control_vector)
