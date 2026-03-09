extends Control

func _ready() -> void:
	StyleHelper.style_btn_cyan($VBox/BtnReturn)
	$VBox/BtnReturn.pressed.connect(func() -> void: StyleHelper.go("res://scenes/MainMenu.tscn"))
