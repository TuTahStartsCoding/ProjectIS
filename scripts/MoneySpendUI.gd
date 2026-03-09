extends CanvasLayer
## MoneySpendUI — Popup after job: choose what to do with earned money.
## Signals let MainGame.gd react without this UI knowing about game flow.

signal chose_save          ## Keep money, tiny energy bonus
signal chose_pay_all       ## Pay all money toward debt
signal chose_pay_partial   ## Pay a custom amount
signal chose_buy_food(item_index: int)  ## Buy food item
signal chose_more_work     ## Keep working without spending

const FADE_IN: float = 0.25

var _result: Dictionary = {}

func setup(result: Dictionary) -> void:
	_result = result
	_populate()
	_run_reveal()

func _populate() -> void:
	var job: Dictionary = _result["job"]

	## Header info
	$Root/VBox/LblJobName.text   = job["name"]
	$Root/VBox/LblEarned.text    = "+$%.0f  |  -%d%% energy  |  %dh" % [
		_result["money_earned"], _result["energy_used"], job["hours"]
	]
	if _result.get("had_event", false):
		$Root/VBox/LblEvent.text    = _result.get("event_desc", "")
		$Root/VBox/LblEvent.visible = true
		_color_event_label(_result.get("event_color", "white"))
	else:
		$Root/VBox/LblEvent.visible = false

	## Status strip
	$Root/VBox/StatusRow/LblEnergy.text = "Energy  %.0f%%" % GameManager.get_energy_percent()
	$Root/VBox/StatusRow/LblCash.text   = "Cash  $%.0f"    % GameManager.money
	$Root/VBox/StatusRow/LblDebt.text   = "Debt  $%.0f"    % GameManager.debt_remaining

	## ── Choice buttons ──
	## 1. Save it
	_wire_btn($Root/VBox/Choices/BtnSave,
		"Save it  (+5%% energy)",
		func() -> void: chose_save.emit())

	## 2. Pay ALL debt
	var can_pay := GameManager.money > 0.0
	_wire_btn($Root/VBox/Choices/BtnPayAll,
		"Pay ALL debt  ($%.0f → debt)" % GameManager.money,
		func() -> void: chose_pay_all.emit())
	$Root/VBox/Choices/BtnPayAll.disabled = not can_pay

	## 3. Pay partial (half)
	var half := GameManager.money * 0.5
	_wire_btn($Root/VBox/Choices/BtnPayHalf,
		"Pay HALF  ($%.0f → debt)" % half,
		func() -> void: chose_pay_partial.emit())
	$Root/VBox/Choices/BtnPayHalf.disabled = not can_pay

	## 4. Food items
	for i in range(GameManager.food_items.size()):
		var item: Dictionary = GameManager.food_items[i]
		var btn_name := "BtnFood%d" % (i + 1)
		if $Root/VBox/Choices.has_node(btn_name):
			var btn: Button = $Root/VBox/Choices.get_node(btn_name)
			var affordable: bool = GameManager.money >= float(item["cost"])
			_wire_btn(btn,
				"%s  ($%d  +%.0f%% energy)" % [item["name"], item["cost"], item["energy"]],
				func() -> void: chose_buy_food.emit(i))
			btn.disabled = not affordable

	## 5. Keep working
	var can_work := GameManager.energy > 8.0
	_wire_btn($Root/VBox/BtnMore,
		"Keep Working" if can_work else "Too Exhausted",
		func() -> void: chose_more_work.emit())
	$Root/VBox/BtnMore.disabled = not can_work

func _wire_btn(btn: Button, lbl: String, cb: Callable) -> void:
	btn.text = lbl
	StyleHelper.style_btn_cyan(btn)
	if not btn.pressed.is_connected(cb):
		btn.pressed.connect(cb)

func _color_event_label(color_key: String) -> void:
	match color_key:
		"green": $Root/VBox/LblEvent.add_theme_color_override("font_color", Color(0.32, 1.0, 0.52))
		"red":   $Root/VBox/LblEvent.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		_:       $Root/VBox/LblEvent.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))

func _run_reveal() -> void:
	$Root/BG.modulate = Color(1, 1, 1, 0)
	var t := create_tween()
	t.tween_property($Root/BG, "modulate", Color(1, 1, 1, 1), FADE_IN)
