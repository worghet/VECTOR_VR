extends Node3D

var debug_label: Label3D
var pickable: XRToolsPickable
var collision_shape: CollisionShape3D

func _ready():
	# Create debug label above tablet
	debug_label = Label3D.new()
	debug_label.pixel_size = 0.0008
	debug_label.font_size = 40
	debug_label.modulate = Color.YELLOW
	debug_label.outline_size = 10
	debug_label.outline_modulate = Color.BLACK
	add_child(debug_label)
	debug_label.position = Vector3(0.15, 0.25, 0)
	
	# Get references
	pickable = $PickableObject
	collision_shape = $PickableObject/CollisionShape3D2
	
	if pickable:
		pickable.collision_layer = 1048576  # This is layer 21 (2^20)
		pickable.collision_mask = 1  # Ground collision

func _process(_delta):
	# Get controller positions
	var left_controller = get_node_or_null("../user/XROrigin3D/LeftController")
	var right_controller = get_node_or_null("../user/XROrigin3D/RightController")
	
	var info = ""
	info += "=== TABLET DEBUG ===\n\n"
	
	# Pickup status
	if pickable:
		info += "Is Picked Up: " + str(pickable.is_picked_up()) + "\n"
		info += "Enabled: " + str(!pickable.is_queued_for_deletion()) + "\n\n"
	
	# Collision shape info
	if collision_shape and collision_shape.shape:
		info += "Collision Size: " + str(collision_shape.shape.size) + "\n"
		info += "Collision Pos: " + str(collision_shape.position) + "\n\n"
	
	# Check PickupFunction nodes
	var left_pickup = get_node_or_null("../user/XROrigin3D/LeftController/LeftHand/PickupFunction")
	var right_pickup = get_node_or_null("../user/XROrigin3D/RightController/RightHand/PickupFunction")
	
	# Distance to controllers
	if left_controller:
		var dist_left = global_position.distance_to(left_controller.global_position)
		info += "Left Hand Dist: " + str(snappedf(dist_left, 0.01)) + "m\n"
		
		# Check if grip pressed
		if left_controller.is_button_pressed("grip_click"):
			info += "LEFT GRIP PRESSED!\n"
		
		# Check pickup function
		if left_pickup:
			info += "L-Pickup Enabled: " + str(left_pickup.enabled) + "\n"
			if left_pickup.has_method("get_picked_up_object"):
				var obj = left_pickup.get_picked_up_object()
				info += "L-Holding: " + str(obj != null) + "\n"
		info += "\n"
	
	if right_controller:
		var dist_right = global_position.distance_to(right_controller.global_position)
		info += "Right Hand Dist: " + str(snappedf(dist_right, 0.01)) + "m\n"
		
		# Check if grip pressed
		if right_controller.is_button_pressed("grip_click"):
			info += "RIGHT GRIP PRESSED!\n"
		
		# Check pickup function
		if right_pickup:
			info += "R-Pickup Enabled: " + str(right_pickup.enabled) + "\n"
			if right_pickup.has_method("get_picked_up_object"):
				var obj = right_pickup.get_picked_up_object()
				info += "R-Holding: " + str(obj != null) + "\n"
	
	# Collision layers
	if pickable:
		info += "\nTablet Layer: " + str(pickable.collision_layer) + "\n"
		info += "Tablet Mask: " + str(pickable.collision_mask) + "\n"
	
	debug_label.text = info
	
	# Make label face camera
	var camera = get_node_or_null("../user/XROrigin3D/XRCamera3D")
	if camera:
		debug_label.look_at(camera.global_position, Vector3.UP)
		debug_label.rotate_object_local(Vector3.UP, PI)
