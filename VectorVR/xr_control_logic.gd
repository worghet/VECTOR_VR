extends XROrigin3D

# useful nodes
var left_controller : XRController3D
var right_controller : XRController3D
var camera : XRCamera3D
var player_body : CharacterBody3D

# flag for reset
var reset_toggle : bool = false

# movement settings
var move_speed : float = 2.0
var turn_speed : float = 2.0  # radians per second
var snap_turn : bool = false  # snap turning (true) vs smooth (false)
var snap_angle : float = PI / 4  # 45 degrees
var turn_cooldown : float = 0.0

func _ready() -> void:
	initialize_nodes()

func _process(delta: float) -> void:
	handle_movement(delta)
	handle_turning(delta)
	handle_reset()


# ---- useful stuff -------
func initialize_nodes():
	left_controller = get_node("LeftController")
	right_controller = get_node("RightController")
	camera = get_node("XRCamera3D")
	player_body = get_node("PlayerBody")


# ------ locomotion methods -------

func handle_movement(delta: float) -> void:

	# left thumbstick input (2d cuz 2 axes x and y)
	var left_stick = left_controller.get_vector2("primary")
	
	# account for deadzone cuz maybe stick drift 
	if left_stick.length() > 0.1:  
		
		# reset direction
		var move_dir = Vector3.ZERO
		
		# set movement based on camera orientation
		move_dir -= camera.global_transform.basis.z * left_stick.y  # forward/back
		move_dir += camera.global_transform.basis.x * left_stick.x  # left/right
		move_dir.y = 0  # keep on ground (no moving in y direction)
		move_dir = move_dir.normalized() #normalize it (what is normalization)
		
		# Apply movement with collision using CharacterBody3D (idk what this is)
		if player_body:
			player_body.velocity = move_dir * move_speed
			player_body.move_and_slide()
		else:
			global_position += move_dir * move_speed * delta

func handle_turning(delta: float) -> void:
	
	# get values of the right stick (2d vector cuz 2 axes x, y)
	var right_stick = right_controller.get_vector2("primary")
	
	# cooldown (for snap if needed)
	if turn_cooldown > 0:
		turn_cooldown -= delta
	
	# handle snap
	if snap_turn:
		if abs(right_stick.x) > 0.5 and turn_cooldown <= 0:
			var turn_amount = snap_angle if right_stick.x > 0 else -snap_angle
			rotate_y(turn_amount)
			turn_cooldown = 0.3  # prevent repeated snaps

	# handle smooth turning
	else:
		if abs(right_stick.x) > 0.1:
			rotate_y(-right_stick.x * turn_speed * delta)


# ----- reset stuff ------ (will need to add ball too)

var start_position : Vector3 = Vector3(0, 1, 0)
var start_rotation : Vector3 = Vector3.ZERO

func reset_pressed() -> void:
	reset_toggle = true

func reset_experience() -> void:

	# reset position and rotation
	self.position = start_position
	self.rotation_degrees = start_rotation

# trigger flag and whatnot
func handle_reset() -> void:
	if left_controller.is_button_pressed("ax_button"):
		if not reset_toggle:
			reset_experience()
			reset_toggle = true
	else:
		reset_toggle = false
