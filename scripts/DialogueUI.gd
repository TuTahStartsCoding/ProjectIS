extends CanvasLayer
## DialogueUI — Portrait-based dialogue with active speaker highlight.

var _lines: Array[String] = []
var _speakers: Array[String] = []  # "npc" or "player"
var _index: int = 0
var _npc_name: String = "NPC"
var _npc_color: Color = Color(0.7, 0.15, 0.15, 1.0)
var _player_name: String = "You"

# Avatar panel references (set in setup)
var _p_panel: Panel
var _n_panel: Panel
var _p_label: Label
var _n_label: Label
var _text_label: Label
var _speaker_label: Label
var _hint_label: Label
var _tween: Tween

func setup(npc_name: String, lines: Array[String], npc_color: Color = Color(0.7, 0.15, 0.15, 1.0)) -> void:
	_npc_name  = npc_name
	_npc_color = npc_color
	_lines     = lines
	_index     = 0

	# Build alternating speaker pattern: NPC starts, player responds
	_speakers.clear()
	for i in range(lines.size()):
		_speakers.append("npc" if i % 2 == 0 else "player")

	_p_panel      = $Root/BgPanel/HBox/P1Avatar
	_n_panel      = $Root/BgPanel/HBox/NPCAvatar
	_p_label      = $Root/BgPanel/HBox/P1Avatar/LblP1
	_n_label      = $Root/BgPanel/HBox/NPCAvatar/LblNPC
	_text_label   = $Root/BgPanel/HBox/TextVBox/LblText
	_speaker_label = $Root/BgPanel/HBox/TextVBox/LblSpeaker
	_hint_label   = $Root/BgPanel/HBox/TextVBox/LblHint

	_n_label.text = npc_name
	_p_label.text = _player_name

	# Style NPC avatar color
	var npc_style := StyleBoxFlat.new()
	npc_style.bg_color = npc_color
	npc_style.corner_radius_top_left    = 44
	npc_style.corner_radius_top_right   = 44
	npc_style.corner_radius_bottom_left = 44
	npc_style.corner_radius_bottom_right = 44
	_n_panel.add_theme_stylebox_override("panel", npc_style)

	# Style player avatar
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.20, 0.62, 0.25, 1.0)
	p_style.corner_radius_top_left    = 44
	p_style.corner_radius_top_right   = 44
	p_style.corner_radius_bottom_left = 44
	p_style.corner_radius_bottom_right = 44
	_p_panel.add_theme_stylebox_override("panel", p_style)

	StyleHelper.style_panel($Root/BgPanel, Color(0.06, 0.08, 0.16, 0.97), 0)
	_show_line()

func _show_line() -> void:
	if _index >= _lines.size():
		return
	var speaker := _speakers[_index]
	_text_label.text = _lines[_index]
	_typewriter_effect(_lines[_index])

	var is_npc := speaker == "npc"
	_speaker_label.text = _npc_name if is_npc else _player_name
	_speaker_label.add_theme_color_override("font_color",
		_npc_color if is_npc else Color(0.35, 0.95, 0.35, 1.0))

	_set_speaker_highlight(is_npc)

func _set_speaker_highlight(npc_speaking: bool) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true)

	# Active speaker: full size + bright; Inactive: smaller + dim overlay
	var active_scale   := Vector2(1.0, 1.0)
	var inactive_scale := Vector2(0.85, 0.85)
	var dim_color      := Color(0.0, 0.0, 0.0, 0.55)
	var clear_color    := Color(0.0, 0.0, 0.0, 0.0)

	if npc_speaking:
		# NPC active
		_tween.tween_property(_n_panel, "scale", active_scale,   0.18)
		_tween.tween_property(_p_panel, "scale", inactive_scale, 0.18)
		$Root/BgPanel/HBox/P1Avatar/DimOverlay.color    = dim_color
		$Root/BgPanel/HBox/NPCAvatar/DimOverlay.color   = clear_color
	else:
		# Player active
		_tween.tween_property(_p_panel, "scale", active_scale,   0.18)
		_tween.tween_property(_n_panel, "scale", inactive_scale, 0.18)
		$Root/BgPanel/HBox/NPCAvatar/DimOverlay.color   = dim_color
		$Root/BgPanel/HBox/P1Avatar/DimOverlay.color    = clear_color

func _typewriter_effect(full_text: String) -> void:
	_text_label.text = ""
	var timer := get_tree().create_timer(0.0)
	var chars_per_tick := 2
	var delay := 0.025
	var pos := 0
	while pos < full_text.length():
		timer.timeout.connect(func() -> void: pass, CONNECT_ONE_SHOT)
		await get_tree().create_timer(delay).timeout
		var end := mini(pos + chars_per_tick, full_text.length())
		_text_label.text = full_text.substr(0, end)
		pos = end

func try_advance() -> bool:
	# Skip typewriter if still running
	if _text_label.text != _lines[_index]:
		_text_label.text = _lines[_index]
		return false
	_index += 1
	if _index >= _lines.size():
		return true
	_show_line()
	return false
