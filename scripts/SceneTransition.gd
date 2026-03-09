extends CanvasLayer
## SceneTransition — Autoload singleton for dip-to-black scene changes.
## Usage: StyleHelper.go("res://scenes/Foo.tscn")

var _overlay: ColorRect
var _tween: Tween
var _pending_scene: String = ""
const FADE_DURATION: float = 0.30

func _ready() -> void:
	layer = 128
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

func go(scene_path: String) -> void:
	if _tween != null and _tween.is_running():
		return
	_pending_scene = scene_path
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_overlay, "color", Color(0.0, 0.0, 0.0, 1.0), FADE_DURATION)
	_tween.tween_callback(_do_change)

func _do_change() -> void:
	get_tree().change_scene_to_file(_pending_scene)
	get_tree().create_timer(0.05).timeout.connect(_fade_in)

func _fade_in() -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), FADE_DURATION)
	_tween.tween_callback(func() -> void: _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE)
