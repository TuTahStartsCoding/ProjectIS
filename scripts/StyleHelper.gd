extends Node
## StyleHelper — Autoload singleton for UI styling + scene transitions.

#  Scene Transition (dip to black) 
var _overlay: ColorRect = null
var _tween: Tween = null
var _pending: String = ""
const _FADE: float = 0.30

func go(scene_path: String) -> void:
	if _tween != null and _tween.is_running():
		return
	_ensure_overlay()
	_pending = scene_path
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_overlay, "color", Color(0.0, 0.0, 0.0, 1.0), _FADE)
	_tween.tween_callback(_do_change)

func _ensure_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		return
	var cv := CanvasLayer.new()
	cv.layer = 128
	add_child(cv)
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cv.add_child(_overlay)

func _do_change() -> void:
	get_tree().change_scene_to_file(_pending)
	get_tree().create_timer(0.05).timeout.connect(_fade_in)

func _fade_in() -> void:
	_ensure_overlay()
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), _FADE)
	_tween.tween_callback(func() -> void: _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE)

#  Styling Helpers 
func flat(color: Color, radius: int = 24) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	return s

func style_panel(p: Panel, color: Color = Color(0.114, 0.318, 0.396, 1.0), radius: int = 20) -> void:
	p.add_theme_stylebox_override("panel", flat(color, radius))

func style_btn_cyan(btn: Button) -> void:
	var normal  := flat(Color(0.259, 0.749, 0.918, 1.0))
	var hover   := flat(Color(0.18,  0.60,  0.78,  1.0))
	var pressed := flat(Color(0.14,  0.50,  0.68,  1.0))
	var focus   := flat(Color(0.259, 0.749, 0.918, 1.0))
	btn.add_theme_stylebox_override("normal",  normal)
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus",   focus)
	btn.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1.0))
