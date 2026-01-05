extends XROrigin3D

# signal

signal time_toggled_signal(is_paused: bool)
signal reset_ball(right_hand_position: Vector3)


# useful nodes
var left_controller : XRController3D
var right_controller : XRController3D
var camera : XRCamera3D
var player_body : CharacterBody3D

# flag for reset
var reset_flag : bool = false

# flag for time toggle
var time_toggle_flag : bool = false
var time_paused : bool = false

var slow_label : Node3D 
var pause_label : Node3D

# movement settings
const DEFAULT_MOVE_SPEED = 2.0
const DEFAULT_TURN_SPEED = 2.0 # radians per sec
var move_speed : float = DEFAULT_MOVE_SPEED
var turn_speed : float = DEFAULT_TURN_SPEED
var snap_turn : bool = false  # snap turning (true) vs smooth (false)
var snap_angle : float = PI / 4  # 45 degrees
var turn_cooldown : float = 0.0

var time_slow_flag : bool = false
var time_slow : bool = false
@export var slow_time_scale : float = 0.2

func _ready() -> void:
	initialize_nodes()

func _process(delta: float) -> void:
	handle_movement(delta)
	handle_turning(delta)
	handle_reset()
	handle_time_toggle()
	handle_time_slow()


# ---- useful stuff -------
func initialize_nodes():
	left_controller = get_node("LeftController")
	right_controller = get_node("RightController")
	camera = get_node("XRCamera3D")
	player_body = get_node("PlayerBody")
	slow_label = get_node("XRCamera3D/Slowed_Label")
	pause_label = get_node("XRCamera3D/Paused_Label")


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

func reset_pressed() -> void:
	reset_flag = true

func reset_experience() -> void:
	emit_signal("reset_ball", right_controller.global_position)


# trigger flag and whatnot
func handle_reset() -> void:
	if right_controller.is_button_pressed("ax_button") or Input.is_action_pressed("ball_reset_key"):
		if not reset_flag:
			reset_experience()
			reset_flag = true
	else:
		reset_flag = false
		

func handle_time_toggle() -> void:
	# Using B/Y button for time control
	if right_controller.is_button_pressed("by_button") or Input.is_action_pressed("time_toggle_key"):
		if not time_toggle_flag:
			time_paused = !time_paused  # Toggle pause state
			emit_signal("time_toggled_signal", time_paused)
			time_toggle_flag = true
			
			
	else:
		time_toggle_flag = false
	
	pause_label.visible = time_paused



func handle_time_slow() -> void:
	#Engine.time_scale = 0.5
	
	# Using B/Y button for time control
	if right_controller.is_button_pressed("trigger_click") or Input.is_action_pressed("time_slow_key"):
		
		print("thing pressed")
		if not time_slow_flag:
			time_slow = !time_slow
			toggle_slow_time()
			time_slow_flag= true
	else:
		time_slow_flag = false


func toggle_slow_time():
	if time_slow:
		Engine.time_scale = slow_time_scale
		move_speed = DEFAULT_MOVE_SPEED / slow_time_scale
		turn_speed = DEFAULT_TURN_SPEED / slow_time_scale
		slow_label.visible = true
		
	else:
		Engine.time_scale = 1
		move_speed = DEFAULT_MOVE_SPEED
		turn_speed = DEFAULT_TURN_SPEED
		slow_label.visible = false
