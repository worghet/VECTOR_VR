extends Node3D

var velocity_vectors : Node3D
var vector_velocity_x : Node3D
var vector_velocity_y : Node3D
var vector_velocity_z : Node3D
var vector_velocity_resultant : Node3D

var vector_gravity: Node3D
var vector_normal: Node3D  # NEW: Normal force vector

var ball : XRToolsPickable

@export var vector_scale : int = 1.5

var is_paused: bool = false
var pause_label: Label3D
var frozen_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	initialize_nodes()
	set_velocity_colours()
	create_pause_hud()
	


func create_pause_hud() -> void:
	pause_label = Label3D.new()
	pause_label.text = "[TIME PAUSED]"
	pause_label.font_size = 48
	pause_label.outline_size = 8
	pause_label.modulate = Color(1, 0, 0, 1)
	pause_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pause_label.visible = false
	pause_label.position = Vector3(0, 0.3, -1.5)
	
	var camera = get_node("/root/Main/user/XROrigin3D/XRCamera3D")
	if camera:
		camera.add_child(pause_label)
	else:
		add_child(pause_label)

func _process(delta: float) -> void:
	if not is_paused:
		process_vectors(delta)
		pause_label.visible = false
	else:
		display_frozen_vectors()
		pause_label.visible = true

func display_frozen_vectors() -> void:
	velocity_vectors.visible = true
	vector_gravity.visible = true
	vector_normal.visible = true  # NEW
	velocity_vectors.global_position = ball.global_position
	vector_gravity.global_position = ball.global_position
	vector_normal.global_position = ball.global_position  # NEW

func initialize_nodes() -> void:
	vector_velocity_x = get_node("velocities/velocity_X")
	vector_velocity_y = get_node("velocities/velocity_Y")
	vector_velocity_z = get_node("velocities/velocity_Z")
	vector_velocity_resultant = get_node("velocities/velocity_RESULTANT")
	velocity_vectors = get_node("velocities")
	vector_gravity = get_node("forces/force_GRAVITY")
	vector_normal = get_node("forces/force_NORMAL")  # NEW
	ball = get_node("Ball")

func set_velocity_colours() -> void:
	# X-axis (Red)
	var red : StandardMaterial3D = StandardMaterial3D.new()
	red.albedo_color = Color.RED
	var rodX = vector_velocity_x.get_node("Rod") as MeshInstance3D
	rodX.set_surface_override_material(0, red)
	var coneX = vector_velocity_x.get_node("Cone") as MeshInstance3D
	coneX.set_surface_override_material(0, red)
	
	# Y-axis (Green)
	var green : StandardMaterial3D = StandardMaterial3D.new()
	green.albedo_color = Color.GREEN
	var rodY = vector_velocity_y.get_node("Rod") as MeshInstance3D
	rodY.set_surface_override_material(0, green)
	var coneY = vector_velocity_y.get_node("Cone") as MeshInstance3D
	coneY.set_surface_override_material(0, green)
	
	# Z-axis (Blue)
	var blue : StandardMaterial3D = StandardMaterial3D.new()
	blue.albedo_color = Color.BLUE
	var rodZ = vector_velocity_z.get_node("Rod") as MeshInstance3D
	rodZ.set_surface_override_material(0, blue)
	var coneZ = vector_velocity_z.get_node("Cone") as MeshInstance3D
	coneZ.set_surface_override_material(0, blue)

	# resultant (orange)
	var orange : StandardMaterial3D = StandardMaterial3D.new()
	orange.albedo_color = Color.ORANGE
	var rodRes = vector_velocity_resultant.get_node("Rod") as MeshInstance3D
	rodRes.set_surface_override_material(0, orange)
	var coneRes = vector_velocity_resultant.get_node("Cone") as MeshInstance3D
	coneRes.set_surface_override_material(0, orange)
	
	# FORCES (Purple gravity, Cyan normal)
	var purple : StandardMaterial3D = StandardMaterial3D.new()
	purple.albedo_color = Color.PURPLE
	var rodGrav = vector_gravity.get_node("Rod") as MeshInstance3D
	rodGrav.set_surface_override_material(0, purple)
	var coneGrav = vector_gravity.get_node("Cone") as MeshInstance3D
	coneGrav.set_surface_override_material(0, purple)
	
	# NEW: Normal force (Cyan)
	var cyan : StandardMaterial3D = StandardMaterial3D.new()
	cyan.albedo_color = Color.CYAN
	var rodNorm = vector_normal.get_node("Rod") as MeshInstance3D
	rodNorm.set_surface_override_material(0, cyan)
	var coneNorm = vector_normal.get_node("Cone") as MeshInstance3D
	coneNorm.set_surface_override_material(0, cyan)

func process_vectors(delta: float) -> void:
	velocity_vectors.visible = true
	vector_gravity.visible = true
	vector_normal.visible = true  # NEW
	
	velocity_vectors.global_position = ball.global_position
	vector_gravity.global_position = ball.global_position
	vector_normal.global_position = ball.global_position  # NEW
	
	var ball_velocity : Vector3 = ball.linear_velocity 
	var lerp_speed : float = 10.0
	var rotation_lerp_speed : float = 7.5

	# ===== COMPONENT VECTORS (X, Y, Z) =====
	var target_x : float = ball_velocity.x * vector_scale
	vector_velocity_x.scale.y = lerp(vector_velocity_x.scale.y, target_x, lerp_speed * delta)

	var target_y : float = ball_velocity.y * vector_scale
	vector_velocity_y.scale.y = lerp(vector_velocity_y.scale.y, target_y, lerp_speed * delta)

	var target_z : float = ball_velocity.z * vector_scale
	vector_velocity_z.scale.y = lerp(vector_velocity_z.scale.y, target_z, lerp_speed * delta)

	# ===== RESULTANT VECTOR (total velocity) =====
	
	if ball_velocity.length() > 0.01:
		var magnitude = ball_velocity.length()
		var target_scale_y = magnitude * vector_scale
		
		var current_scale = vector_velocity_resultant.scale.y
		var new_scale = lerp(current_scale, target_scale_y, lerp_speed * delta)
		
		var velocity_normalized = ball_velocity.normalized()
		
		var target_basis = Basis()
		target_basis.y = velocity_normalized
		
		if abs(velocity_normalized.y) < 0.99:
			target_basis.x = velocity_normalized.cross(Vector3.UP).normalized()
			target_basis.z = target_basis.x.cross(velocity_normalized).normalized()
		else:
			target_basis.z = velocity_normalized.cross(Vector3.RIGHT).normalized()
			target_basis.x = velocity_normalized.cross(target_basis.z).normalized()
		
		target_basis = target_basis.orthonormalized()
		
		var current_basis = vector_velocity_resultant.basis.orthonormalized()
		var interpolated_basis = current_basis.slerp(target_basis, rotation_lerp_speed * delta)
		
		vector_velocity_resultant.basis = interpolated_basis
		vector_velocity_resultant.scale = Vector3(1.0, new_scale, 1.0)
		
	else:
		vector_velocity_resultant.scale.y = lerp(vector_velocity_resultant.scale.y, 0.0, lerp_speed * delta)
		vector_velocity_resultant.scale.x = 1.0
		vector_velocity_resultant.scale.z = 1.0
	
	# ===== FORCES =====
	# Gravity (downward)
	var target_grav : float = ball.mass * ball.gravity_scale * vector_scale
	vector_gravity.scale.y = lerp(vector_gravity.scale.y, target_grav, lerp_speed * delta)
	
	# NEW: Normal force calculation
	calculate_normal_force(delta, lerp_speed)

# NEW: Calculate normal force based on surface contact
func calculate_normal_force(delta: float, lerp_speed: float) -> void:
	# Check if ball is on a surface using raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		ball.global_position,
		ball.global_position + Vector3.DOWN * 0.15  # Slightly longer than ball radius
	)
	query.exclude = [ball]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# Ball is on a surface - calculate normal force
		var surface_normal = result.normal
		
		# Normal force magnitude equals weight when on flat surface
		# (For simplicity, assuming no acceleration perpendicular to surface)
		var gravity_magnitude = ball.mass * ball.gravity_scale * 9.8
		var normal_magnitude = gravity_magnitude * surface_normal.dot(Vector3.UP)
		
		# Only show if there's significant contact
		if normal_magnitude > 0.1:
			var target_scale = normal_magnitude * vector_scale * 0.1  # Scale down for visibility
			vector_normal.scale.y = lerp(vector_normal.scale.y, target_scale, lerp_speed * delta)
			
			# Orient normal force in direction of surface normal
			var target_basis = Basis()
			target_basis.y = surface_normal
			
			if abs(surface_normal.y) < 0.99:
				target_basis.x = surface_normal.cross(Vector3.UP).normalized()
				target_basis.z = target_basis.x.cross(surface_normal).normalized()
			else:
				target_basis.z = surface_normal.cross(Vector3.RIGHT).normalized()
				target_basis.x = surface_normal.cross(target_basis.z).normalized()
			
			target_basis = target_basis.orthonormalized()
			var current_basis = vector_normal.basis.orthonormalized()
			vector_normal.basis = current_basis.slerp(target_basis, lerp_speed * delta)
		else:
			# Shrink to invisible
			vector_normal.scale.y = lerp(vector_normal.scale.y, 0.0, lerp_speed * delta)
	else:
		# Ball is in air - no normal force
		vector_normal.scale.y = lerp(vector_normal.scale.y, 0.0, lerp_speed * delta)
