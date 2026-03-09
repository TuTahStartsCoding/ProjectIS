extends Control

func _ready() -> void:
	StyleHelper.style_panel($Panel, Color(0.06, 0.08, 0.14, 1.0))
	for btn_name: String in ["BtnStart", "BtnSetting", "BtnExit"]:
		StyleHelper.style_btn_cyan($Panel/VBox.get_node(btn_name) as Button)

	$Panel/DiffRow/BtnEasy.pressed.connect(func() -> void: _set_diff("easy"))
	$Panel/DiffRow/BtnNormal.pressed.connect(func() -> void: _set_diff("normal"))
	$Panel/DiffRow/BtnHard.pressed.connect(func() -> void: _set_diff("hard"))
	$Panel/VBox/BtnStart.pressed.connect(_on_start)
	$Panel/VBox/BtnSetting.pressed.connect(_on_setting)
	$Panel/VBox/BtnExit.pressed.connect(_on_exit)
	_refresh_diff_buttons()

func _set_diff(d: String) -> void:
	GameManager.game_difficulty = d
	_refresh_diff_buttons()

func _refresh_diff_buttons() -> void:
	var diff := GameManager.game_difficulty

	# Update debt/days/energy preview label
	var info := ""
	match diff:
		"easy":
			info = "Debt: $3,000  ·  9 days  ·  120% energy  ·  2% interest/day"
		"normal":
			info = "Debt: $6,000  ·  7 days  ·  100% energy  ·  5% interest/day"
		"hard":
			info = "Debt: $10,000  ·  5 days  ·  80% energy  ·  9% interest/day"
	$Panel/LblDiffInfo.text = info

	var active   := Color(0.259, 0.749, 0.918, 1.0)
	var inactive := Color(0.14, 0.20, 0.30, 1.0)
	_tint_btn($Panel/DiffRow/BtnEasy,   active if diff == "easy"   else inactive)
	_tint_btn($Panel/DiffRow/BtnNormal, active if diff == "normal" else inactive)
	_tint_btn($Panel/DiffRow/BtnHard,   active if diff == "hard"   else inactive)

func _tint_btn(btn: Button, c: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.corner_radius_top_left     = 10
	s.corner_radius_top_right    = 10
	s.corner_radius_bottom_left  = 10
	s.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   s)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))

func _on_start() -> void:
	GameManager.reset_game()
	StyleHelper.go("res://scenes/IntroScene.tscn")

func _on_setting() -> void:
	StyleHelper.go("res://scenes/SettingScene.tscn")

func _on_exit() -> void:
	get_tree().quit()
