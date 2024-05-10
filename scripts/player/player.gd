extends CharacterBody3D

# Movement properties
var speed: float           = 5.0
const WALK_SPEED: float    = 5.0
const SPRINT_SPEED: float  = 8.0
const JUMP_VELOCITY: float = 4.5
const GRAVITY: float       = 7.0
const SENSITIVITY: float   = 0.03
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var snapshot_viewport: SubViewport = $Viewport/SnapshotViewport
@onready var snapshot_camera: Camera3D = $Viewport/SnapshotViewport/SnapshotCamera3D
@onready var main_camera_display_plane: MeshInstance3D = $Head/MainCameraDisplayPlane
@onready var player_mesh: MeshInstance3D = $MeshInstance3D
const PLAYER_LAYER: int                  = 2  # Example layer number for the player's mesh
const SNAPSHOT_CAMERA_MASK: int          = ~(1 << PLAYER_LAYER)  # Mask excluding player's layer


func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

    main_camera_display_plane.visible = false


func snap_image():
    player_mesh.visible = false
    main_camera_display_plane.visible = false

    snapshot_camera.global_transform = camera.global_transform

    var snapshot_image := snapshot_viewport.get_texture().get_image()

    var snapshot_texture := ImageTexture.new()
    snapshot_texture.set_image(snapshot_image)

    var material := StandardMaterial3D.new()
    material.albedo_texture = snapshot_texture
    main_camera_display_plane.material_override = material

    main_camera_display_plane.visible = true

    player_mesh.visible = true


# Function to handle player movement
func _physics_process(delta: float):
    if not is_on_floor():
        velocity.y -= GRAVITY * delta

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED

    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
    var direction    := (head.transform.basis * Vector3(input_vector.x, 0, 0)).normalized()

    if is_on_floor():
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
        velocity.z = lerp(velocity.x, direction.z * speed, delta * 3.0)

    move_and_slide()


# Function to handle camera rotation using mouse movement
func _unhandled_input(event: InputEvent):
    if event is InputEventMouseMotion:
        head.rotate_y(-event.relative.x * SENSITIVITY)
        camera.rotate_x(-event.relative.y * SENSITIVITY)

        camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -40, 60)


# Function to handle snapping events
func _process(delta: float):
    if Input.is_action_just_pressed("snap"):
        snap_image()
