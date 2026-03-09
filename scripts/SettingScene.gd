extends Control

func _ready() -> void:
	StyleHelper.style_panel($Panel, Color(0.07, 0.10, 0.18, 1.0))
	StyleHelper.style_btn_cyan($Panel/VBox/BtnBack)
	$Panel/VBox/SliderSound.value      = GameManager.sound_effect_volume
	$Panel/VBox/SliderMusic.value      = GameManager.music_volume
	$Panel/VBox/SliderBrightness.value = GameManager.brightness
	$Panel/VBox/SliderSound.value_changed.connect(
		func(v: float) -> void: GameManager.sound_effect_volume = v)
	$Panel/VBox/SliderMusic.value_changed.connect(
		func(v: float) -> void: GameManager.music_volume = v)
	$Panel/VBox/SliderBrightness.value_changed.connect(
		func(v: float) -> void: GameManager.brightness = v)
	$Panel/VBox/BtnBack.pressed.connect(func() -> void: StyleHelper.go("res://scenes/MainMenu.tscn"))
