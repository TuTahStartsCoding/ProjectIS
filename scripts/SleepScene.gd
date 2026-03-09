extends Control
## SleepScene — Full-screen day summary, lines appear one by one.

signal continue_pressed

const FADE_BG:    float = 0.40
const LINE_DELAY: float = 0.42
const LINE_FADE:  float = 0.30

# Color palette (no emoji)
const C_HEADER: Color = Color(0.28, 0.82, 1.0,  1.0)
const C_GREEN:  Color = Color(0.32, 1.0,  0.52, 1.0)
const C_RED:    Color = Color(1.0,  0.38, 0.38, 1.0)
const C_YELLOW: Color = Color(0.92, 0.92, 0.40, 1.0)
const C_DIM:    Color = Color(0.52, 0.52, 0.52, 1.0)
const C_NORMAL: Color = Color(0.82, 0.82, 0.82, 1.0)

var _can_continue: bool = false

func setup(data: Dictionary) -> void:
	var lines: Array[Dictionary] = data.get("summary_lines", [])
	_run_reveal(lines)

func _run_reveal(lines: Array[Dictionary]) -> void:
	# Dip to black: fade in background
	var t0 := create_tween().set_parallel(true)
	t0.tween_property($BG,        "modulate", Color(1,1,1,1), FADE_BG)
	t0.tween_property($AccentTop, "modulate", Color(1,1,1,1), FADE_BG)
	await get_tree().create_timer(FADE_BG + 0.05).timeout

	# Reveal each line
	for entry in lines:
		var txt: String   = entry.get("text", "")
		var col_key: String = entry.get("color", "normal")

		if col_key == "spacer":
			# Invisible spacer label for spacing
			var spacer := Label.new()
			spacer.text = " "
			spacer.add_theme_font_size_override("font_size", 10)
			$LinesContainer.add_child(spacer)
			await get_tree().create_timer(LINE_DELAY * 0.3).timeout
			continue

		var lbl := Label.new()
		lbl.text = txt
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.modulate = Color(1,1,1,0)

		match col_key:
			"header":
				lbl.add_theme_color_override("font_color", C_HEADER)
				lbl.add_theme_font_size_override("font_size", 34)
			"green":
				lbl.add_theme_color_override("font_color", C_GREEN)
				lbl.add_theme_font_size_override("font_size", 20)
			"red":
				lbl.add_theme_color_override("font_color", C_RED)
				lbl.add_theme_font_size_override("font_size", 20)
			"yellow":
				lbl.add_theme_color_override("font_color", C_YELLOW)
				lbl.add_theme_font_size_override("font_size", 20)
			"dim":
				lbl.add_theme_color_override("font_color", C_DIM)
				lbl.add_theme_font_size_override("font_size", 17)
			_:
				lbl.add_theme_color_override("font_color", C_NORMAL)
				lbl.add_theme_font_size_override("font_size", 20)

		$LinesContainer.add_child(lbl)

		var tw := create_tween()
		tw.tween_property(lbl, "modulate", Color(1,1,1,1), LINE_FADE)
		await tw.finished
		await get_tree().create_timer(LINE_DELAY).timeout

	# Show "continue" hint
	var tf := create_tween()
	tf.tween_property($LblContinue, "theme_override_colors/font_color",
		Color(0.5, 0.5, 0.5, 0.75), 0.5)
	await tf.finished

	# Brief pause before accepting input
	await get_tree().create_timer(0.4).timeout
	_can_continue = true

func _unhandled_input(event: InputEvent) -> void:
	if not _can_continue:
		return
	var ok := false
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		ok = true
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		ok = true
	if ok:
		_can_continue = false
		continue_pressed.emit()
