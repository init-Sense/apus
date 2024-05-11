extends CharacterBody3D

var speed: float = 0.0
const ACCELERATION: float  = 2.0
const DECELERATION: float  = 5.0
const MAX_SPEED: float     = 6.0
const JUMP_VELOCITY: float = 4.8
const SENSITIVITY: float   = 0.004
const BOB_FREQ: float      = 2.4
const BOB_AMP: float       = 0.08
var t_bob: float           = 0.0
const BASE_FOV: float      = 75.0
const FOV_CHANGE: float    = 1.5
var gravity: float         = 9.8

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var snapshot_viewport: SubViewport = $Viewport/SnapshotViewport
@onready var snapshot_camera: Camera3D = $Viewport/SnapshotViewport/SnapshotCamera3D
@onready var main_camera_display_plane: MeshInstance3D = $Head/MainCameraDisplayPlane
@onready var snapshot_sound: AudioStreamPlayer3D = $SnapshotSound

var snapshot_cooldown: float = 1.0
var last_snapshot_time: float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


func snap_image():
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_snapshot_time >= snapshot_cooldown:
		last_snapshot_time = current_time
		snapshot_camera.global_transform = camera.global_transform
		snapshot_viewport.set_world_3d(get_world_3d())
		var snapshot_image := snapshot_viewport.get_texture().get_image()

		var snapshot_texture := ImageTexture.new()
		snapshot_texture.set_image(snapshot_image)

		var snapshot_display := MeshInstance3D.new()
		var plane_mesh := PlaneMesh.new()
		plane_mesh.size = Vector2(1.0, 0.5625)

		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_texture = snapshot_texture
		material.cull_mode = StandardMaterial3D.CULL_DISABLED
		snapshot_display.material_override = material
		snapshot_display.mesh = plane_mesh


		snapshot_display.global_transform = camera.global_transform * Transform3D.IDENTITY.translated(Vector3(0, 0, -2))
		snapshot_display.rotation_degrees = Vector3(randi_range(50, 170), randi_range(1, 359), randi_range(1, 359),)

		var snapshot_container: Node = get_node("/root/World/SnapshotContainer")
		if snapshot_container:
			snapshot_container.add_child(snapshot_display)
		else:
			print("SnapshotContainer not found.")

		snapshot_sound.pitch_scale = randf_range(0.6, 1.5)
		snapshot_sound.play() 


func _physics_process(delta):
	var is_moving: bool = false

	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir: Vector2 = Input.get_vector("", "", "move_forward", "move_backwards")

	if Input.is_action_pressed("move_forward"):
		speed = min(speed + ACCELERATION * delta, MAX_SPEED)
		is_moving = true
	else:
		speed = max(speed - DECELERATION * delta, 0.0)
		is_moving = speed > 0

	var direction: Vector3 = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor() and is_moving:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = lerp(velocity.x, 0.0, delta * 5.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 5.0)

	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	var velocity_clamped = clamp(velocity.length(), 0.5, MAX_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()


func _headbob(time) -> Vector3:
	var pos: Vector3 = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP * 4  # Increase bob amplitude for a more robotic feel
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


func _process(delta: float):
	if Input.is_action_just_pressed("snap"):
		snap_image()
