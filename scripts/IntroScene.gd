extends Control
## IntroScene — Story intro + tutorial.

var _ready_to_proceed: bool = false

func _ready() -> void:
	get_tree().create_timer(1.0).timeout.connect(func() -> void: _ready_to_proceed = true)

func _unhandled_input(event: InputEvent) -> void:
	if not _ready_to_proceed:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_proceed()
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		_proceed()

func _proceed() -> void:
	_ready_to_proceed = false
	StyleHelper.go("res://scenes/MainGame.tscn")
