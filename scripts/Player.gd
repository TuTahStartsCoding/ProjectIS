extends CharacterBody2D
## Player — Top-down movement. Uses "player" group for Area2D detection.

const SPEED: float = 130.0
var locked: bool = false

func _ready() -> void:
	add_to_group("player")
	_create_placeholder_sprite()

func _create_placeholder_sprite() -> void:
	var sprite: Sprite2D = null
	for child in get_children():
		if child is Sprite2D:
			sprite = child as Sprite2D
			break
	if sprite == null or sprite.texture != null:
		return
	var img := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	for x in range(4, 28):
		for y in range(16, 48):
			img.set_pixel(x, y, Color(0.2, 0.65, 0.25, 1.0))
	for x in range(8, 24):
		for y in range(0, 16):
			img.set_pixel(x, y, Color(0.95, 0.82, 0.6, 1.0))
	for x in range(6, 26):
		for y in range(0, 6):
			img.set_pixel(x, y, Color(1.0, 0.9, 0.3, 1.0))
	sprite.texture = ImageTexture.create_from_image(img)

func _physics_process(_delta: float) -> void:
	if locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	velocity = dir.normalized() * SPEED if dir.length_squared() > 0.0 else Vector2.ZERO
	move_and_slide()

func set_locked(val: bool) -> void:
	locked = val
	if val:
		velocity = Vector2.ZERO
