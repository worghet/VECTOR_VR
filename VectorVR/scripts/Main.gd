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
var stored_collision_layer: int = 0
var stored_collision_mask: int = 0
var is_time_paused: bool = false

# Prevent rapid toggle issues
var is_transitioning: bool = false
var pause_count: int = 0

# Debug labels for VR
var debug_label: Label3D
var camera: XRCamera3D

func _ready():
	initializeInterfaces()
	initialize_references()
	create_debug_hud()
	
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
	camera = get_node("user/XROrigin3D/XRCamera3D")
	
	var xr_origin = user_node.get_node("XROrigin3D")
	xr_origin.connect("time_toggled_signal", Callable(self, "_on_time_control_pressed"))

func create_debug_hud():
	debug_label = Label3D.new()
	debug_label.font_size = 28
	debug_label.outline_size = 4
	debug_label.modulate = Color(0, 1, 0, 1)  # Green
	debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	debug_label.position = Vector3(0, -0.2, -1.0)  # Below center view
	
	if camera:
		camera.add_child(debug_label)
	else:
		add_child(debug_label)

func _process(_delta: float) -> void:
	if debug_label and ball:
		var pos = ball.global_position
		var vel = ball.linear_velocity
		debug_label.text = "Ball: (%.2f, %.2f, %.2f)\n" % [pos.x, pos.y, pos.z]
		debug_label.text += "Vel: (%.2f, %.2f, %.2f)\n" % [vel.x, vel.y, vel.z]
		debug_label.text += "Paused: %s | Freeze: %s\n" % [is_time_paused, ball.freeze]
		debug_label.text += "Stored: (%.2f, %.2f, %.2f)\n" % [stored_position.x, stored_position.y, stored_position.z]
		debug_label.text += "Pause #%d | Trans: %s" % [pause_count, is_transitioning]
		
		# If paused and ball is picked up, update stored position
		if is_time_paused and ball.is_picked_up():
			stored_position = ball.global_position

func _on_time_control_pressed(is_paused: bool):
	# Prevent overlapping pause/unpause operations
	if is_transitioning:
		print("⚠️ Already transitioning, ignoring input")
		return
	
	is_transitioning = true
	is_time_paused = is_paused
	
	if projectile_node:
		projectile_node.is_paused = is_paused
	
	if ball:
		if is_paused:
			pause_count += 1
			
			# Get CURRENT position from ball right now
			var current_pos = ball.global_position
			var current_vel = ball.linear_velocity
			
			# Store everything
			stored_linear_velocity = current_vel
			stored_angular_velocity = ball.angular_velocity
			stored_gravity_scale = ball.gravity_scale
			stored_position = current_pos
			stored_collision_layer = ball.collision_layer
			stored_collision_mask = ball.collision_mask
			
			# Update projectile frozen velocity
			if projectile_node:
				projectile_node.frozen_velocity = current_vel
			
			# DON'T disable collisions - let it stay grabbable
			# Just freeze it in place
			ball.freeze = true
			ball.gravity_scale = 0.0
			ball.linear_velocity = Vector3.ZERO
			ball.angular_velocity = Vector3.ZERO
			
			# Force position update
			ball.global_position = current_pos
			
			print("⏸️ PAUSE #%d - Stored pos: %s | vel: %s" % [pause_count, current_pos, current_vel])
			
		else:
			print("▶️ UNPAUSE #%d - Restoring to: %s" % [pause_count, stored_position])
			
			# Restore position IMMEDIATELY
			ball.global_position = stored_position
			
			# Unfreeze
			ball.freeze = false
			ball.gravity_scale = stored_gravity_scale
			
			# Set velocities to zero first
			ball.linear_velocity = Vector3.ZERO
			ball.angular_velocity = Vector3.ZERO
			
			# Wait for physics to settle
			await get_tree().physics_frame
			
			# NOW restore velocities
			ball.linear_velocity = stored_linear_velocity
			ball.angular_velocity = stored_angular_velocity
			
			print("▶️ RESUMED at actual pos: %s | vel: %s" % [ball.global_position, ball.linear_velocity])
	
	is_transitioning = false
