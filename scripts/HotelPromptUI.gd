extends CanvasLayer

signal chose_rest
signal chose_cancel

func _ready() -> void:
	StyleHelper.style_panel($Root/Panel, Color(0.10, 0.28, 0.36, 0.97))
	StyleHelper.style_btn_cyan($Root/Panel/VBox/BtnRow/BtnRest)
	StyleHelper.style_btn_cyan($Root/Panel/VBox/BtnRow/BtnCancel)
	$Root/Panel/VBox/BtnRow/BtnRest.pressed.connect(func() -> void: chose_rest.emit())
	$Root/Panel/VBox/BtnRow/BtnCancel.pressed.connect(func() -> void: chose_cancel.emit())
