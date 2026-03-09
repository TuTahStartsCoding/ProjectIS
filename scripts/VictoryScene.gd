extends Control

func _ready() -> void:
	StyleHelper.style_panel($Panel, Color(0.05, 0.14, 0.10, 1.0))
	StyleHelper.style_btn_cyan($Panel/VBox/BtnMenu)
	$Panel/VBox/LblDebt.text = "Total paid: $%.0f" % GameManager.debt_paid
	$Panel/VBox/LblDay.text  = "Cleared in %d days" % (GameManager.current_day - 1)
	$Panel/VBox/BtnMenu.pressed.connect(func() -> void: StyleHelper.go("res://scenes/MainMenu.tscn"))
