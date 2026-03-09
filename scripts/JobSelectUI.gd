extends CanvasLayer

signal job_chosen(job: Dictionary)
signal cancelled

func setup(jobs: Array[Dictionary]) -> void:
	StyleHelper.style_panel($Root/BgPanel, Color(0.07, 0.10, 0.18, 0.97), 16)
	$Root/BgPanel/VBox/HeaderRow/LblDay.text    = GameManager.get_day_string()
	$Root/BgPanel/VBox/HeaderRow/LblEnergy.text = " %.0f%%" % GameManager.get_energy_percent()

	var job_row: HBoxContainer = $Root/BgPanel/VBox/JobRow
	for child in job_row.get_children():
		child.queue_free()

	for j in jobs:
		job_row.add_child(_make_job_card(j))

	StyleHelper.style_btn_cyan($Root/BgPanel/VBox/BtnCancel)
	$Root/BgPanel/VBox/BtnCancel.pressed.connect(func() -> void: cancelled.emit())

func _make_job_card(j: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size   = Vector2(0, 150)

	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.09, 0.13, 0.22, 1.0)
	for corner in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_left","corner_radius_bottom_right"]:
		s.set(corner, 12)
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.border_color = Color(0.26, 0.55, 0.85, 0.5)
	s.content_margin_left   = 12
	s.content_margin_right  = 12
	s.content_margin_top    = 10
	s.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", s)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var lbl_name := Label.new()
	lbl_name.text = j["name"]
	lbl_name.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0, 1.0))
	lbl_name.add_theme_font_size_override("font_size", 17)
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_name)

	var stats := Label.new()
	stats.text = "$%d  ·  %dh  ·  −%d%% " % [j["reward"], j["hours"], j["energy_cost"]]
	stats.add_theme_color_override("font_color", Color(0.9, 0.9, 0.65, 1.0))
	stats.add_theme_font_size_override("font_size", 14)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats)

	var flavor := Label.new()
	flavor.text = j.get("flavor", j["desc"])
	flavor.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70, 1.0))
	flavor.add_theme_font_size_override("font_size", 13)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(flavor)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var btn := Button.new()
	btn.text = "Take This Job"
	btn.custom_minimum_size = Vector2(0, 36)
	btn.add_theme_font_size_override("font_size", 15)
	StyleHelper.style_btn_cyan(btn)
	var captured_j := j
	btn.pressed.connect(func() -> void: job_chosen.emit(captured_j))
	vbox.add_child(btn)

	return panel
