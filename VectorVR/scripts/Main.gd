extends Node3D

var m_interfaceVr : XRInterface
var m_transformVr : Transform3D

# References to scene nodes
var user_node : Node3D
var projectile_node : Node3D
var ball : RigidBody3D

var stored_linear_velocity: Vector3 = Vector3.ZERO
var stored_angular_velocity: Vector3 = Vector3.ZERO
var stored_gravity_scale: float = 1.0
var stored_position: Vector3 = Vector3.ZERO
var is_time_paused: bool = false

# Prevent rapid toggle issues
var is_transitioning: bool = false

func _ready():
	initializeInterfaces()
	initialize_references()
	
func initializeInterfaces():
	m_interfaceVr = XRServer.find_interface("OpenXR")
	if m_interfaceVr and m_interfaceVr.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		m_transformVr = XRServer.get_hmd_transform()
		m_interfaceVr.pose_recentered.connect(processOpenXrPoseRecentered)

func processOpenXrPoseRecentered():
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)

func initialize_references():
	user_node = get_node("user")
	projectile_node = get_node("projectile")
	ball = projectile_node.get_node("Ball")
	
	var xr_origin = user_node.get_node("XROrigin3D")
	xr_origin.connect("time_toggled_signal", Callable(self, "_on_time_control_pressed"))

func _process(_delta: float) -> void:
	# If paused and ball is picked up, update stored position
	if is_time_paused and ball and ball.is_picked_up():
		stored_position = ball.global_position

func _on_time_control_pressed(is_paused: bool):
	# Prevent overlapping pause/unpause operations
	if is_transitioning:
		return
	
	is_transitioning = true
	is_time_paused = is_paused
	
	if projectile_node:
		projectile_node.is_paused = is_paused
	
	if ball:
		if is_paused:
			# Get CURRENT position from ball right now
			var current_pos = ball.global_position
			var current_vel = ball.linear_velocity
			
			# Store everything
			stored_linear_velocity = current_vel
			stored_angular_velocity = ball.angular_velocity
			stored_gravity_scale = ball.gravity_scale
			stored_position = current_pos
			
			# Update projectile frozen velocity
			if projectile_node:
				projectile_node.frozen_velocity = current_vel
			
			# Freeze the ball in place
			ball.freeze = true
			ball.gravity_scale = 0.0
			ball.linear_velocity = Vector3.ZERO
			ball.angular_velocity = Vector3.ZERO
			
			# Force position update
			ball.global_position = current_pos
			
		else:
			# Restore position
			ball.global_position = stored_position
			
			# Unfreeze
			ball.freeze = false
			ball.gravity_scale = stored_gravity_scale
			
			# Set velocities to zero first
			ball.linear_velocity = Vector3.ZERO
			ball.angular_velocity = Vector3.ZERO
			
			# Wait for physics to settle
			await get_tree().physics_frame
			
			# Restore velocities
			ball.linear_velocity = stored_linear_velocity
			ball.angular_velocity = stored_angular_velocity
	
	is_transitioning = false
