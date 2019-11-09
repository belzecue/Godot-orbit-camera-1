extends Spatial

# Control variables
export var maxPitch : float = 45
export var minPitch : float = -45
export var maxZoom : float = 20
export var minZoom : float = 4
export var zoomStep : float = 2
export var zoomYStep : float = 0.25
export var verticalSensitivity : float = 0.002
export var horizontalSensitivity : float = 0.002
export var camLerpSpeed : float = 16
export var camYOffset : float = 4
export var camZOffset : float = 1.5
export var camGroundOffset : float = 1.0
export(NodePath) var target

# Private variables
var camTarget : Spatial = null
var cam : Camera
var curZoom : float = 0.0

func _ready() -> void:
	# Setup node references
	camTarget = get_node(target)
	cam = get_node("Camera")
	# Setup camera position in rig
	cam.translate(Vector3(0,camYOffset,maxZoom))
	curZoom = cam.transform.origin.distance_to(camTarget.global_transform.origin)

func _input(event) -> void:
	if event is InputEventMouseMotion:
		# Rotate the rig around the target
		rotate_y(-event.relative.x * horizontalSensitivity)
		rotation.x = clamp(rotation.x - event.relative.y * verticalSensitivity, deg2rad(minPitch), deg2rad(maxPitch))
		orthonormalize()
		
	if event is InputEventMouseButton:
		# Change zoom level on mouse wheel rotation
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP and curZoom > minZoom:
				curZoom -= zoomStep
				camYOffset -= zoomYStep
			if event.button_index == BUTTON_WHEEL_DOWN and curZoom < maxZoom:
				curZoom += zoomStep
				camYOffset += zoomYStep

func _physics_process(delta) -> void:
	# Find the closest point that is blocking the camera
	var rayOrigin = camTarget.global_transform.origin + Vector3(0,camYOffset-camGroundOffset,0)
	var rayTarget = to_global(cam.transform.origin + Vector3(0,-camGroundOffset,camZOffset))
	var obstacle = get_world().direct_space_state.intersect_ray(rayOrigin, rayTarget,[camTarget])
	# If a collison shape is blocking the camera, reposition the camera
	if not obstacle.empty():
		# Get distance to blocking point
		var offset = rayOrigin.distance_to(obstacle.position)
		# Offset the camera in the rig
		if offset < curZoom:
			cam.set_translation(cam.translation.linear_interpolate(Vector3(0,camYOffset,offset),delta * camLerpSpeed))
		else:
			cam.set_translation(cam.translation.linear_interpolate(Vector3(0,camYOffset,curZoom),delta * camLerpSpeed))
	else:
		cam.set_translation(cam.translation.linear_interpolate(Vector3(0,camYOffset,curZoom),delta * camLerpSpeed))
		
	# Translate the rig to the target
	set_translation(camTarget.global_transform.origin)
