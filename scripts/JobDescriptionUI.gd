extends CanvasLayer
## JobDescriptionUI — Full-screen job result, cinematic line-by-line reveal.

signal chose_save
signal chose_pay
signal chose_more_work

const FADE_IN:    float = 0.35
const LINE_DELAY: float = 0.50

func setup(result: Dictionary) -> void:
	var job: Dictionary = result["job"]

	# Fill content
	$Root/MainVBox/LblJobName.text = job["name"]
	$Root/MainVBox/LblAmount.text  = "+$%.0f earned" % result["money_earned"]
	$Root/MainVBox/LblFlavor.text  = job.get("flavor", job["desc"])

	if result.get("had_event", false):
		var ev_lbl: Label = $Root/MainVBox/LblEvent
		ev_lbl.text = result.get("event_desc", "")
		match result.get("event_color", "white"):
			"green": ev_lbl.add_theme_color_override("font_color", Color(0.32, 1.0, 0.52, 1.0))
			"red":   ev_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
			_:       ev_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
		ev_lbl.visible = true
	else:
		$Root/MainVBox/LblEvent.visible = false

	$Root/MainVBox/LblStats.text = (
		"%dh worked   |   -%.0f%% energy   |   +$%.0f" % [
			job["hours"], result["energy_used"], result["money_earned"]
		]
	)

	$Root/MainVBox/StatusRow/LblEnergy.text = "Energy  %.0f%%" % GameManager.get_energy_percent()
	$Root/MainVBox/StatusRow/LblMoney.text  = "Cash  $%.0f"    % GameManager.money
	$Root/MainVBox/StatusRow/LblDebt.text   = "Debt  $%.0f"    % GameManager.debt_remaining

	StyleHelper.style_btn_cyan($Root/MainVBox/BtnRow/BtnSave)
	StyleHelper.style_btn_cyan($Root/MainVBox/BtnRow/BtnPay)
	StyleHelper.style_btn_cyan($Root/MainVBox/BtnMore)

	$Root/MainVBox/BtnRow/BtnSave.pressed.connect(func() -> void: chose_save.emit())
	$Root/MainVBox/BtnRow/BtnPay.pressed.connect(func() -> void: chose_pay.emit())
	$Root/MainVBox/BtnMore.pressed.connect(func() -> void: chose_more_work.emit())

	$Root/MainVBox/BtnRow/BtnPay.disabled = GameManager.money <= 0.0
	var can_work := GameManager.energy > 8.0
	$Root/MainVBox/BtnMore.disabled = not can_work
	$Root/MainVBox/BtnMore.text = "Keep Working" if can_work else "Too Exhausted to Continue"

	_run_reveal()

func _run_reveal() -> void:
	# Dip to black: BG starts transparent, fades to visible
	$Root/BG.modulate       = Color(1.0, 1.0, 1.0, 0.0)
	$Root/AccentLeft.modulate = Color(1.0, 1.0, 1.0, 0.0)

	var t0 := create_tween().set_parallel(true)
	t0.tween_property($Root/BG,         "modulate", Color(1,1,1,1), 0.4)
	t0.tween_property($Root/AccentLeft, "modulate", Color(1,1,1,1), 0.4)
	await get_tree().create_timer(0.45).timeout

	# Lines appear one by one
	await _fadein($Root/MainVBox/LblJobName)
	await get_tree().create_timer(LINE_DELAY * 0.6).timeout
	await _fadein($Root/MainVBox/LblAmount)
	await get_tree().create_timer(LINE_DELAY * 0.5).timeout
	await _fadein($Root/MainVBox/Divider)
	await get_tree().create_timer(LINE_DELAY * 0.4).timeout

	await _fadein($Root/MainVBox/LblFlavor)
	await get_tree().create_timer(LINE_DELAY + 0.1).timeout

	if $Root/MainVBox/LblEvent.visible:
		await _fadein($Root/MainVBox/LblEvent)
		await get_tree().create_timer(LINE_DELAY).timeout

	await _fadein($Root/MainVBox/LblStats)
	await get_tree().create_timer(LINE_DELAY).timeout

	# Status + buttons fade in together
	var tf := create_tween().set_parallel(true)
	tf.tween_property($Root/MainVBox/StatusRow, "modulate", Color(1,1,1,1), FADE_IN)
	tf.tween_property($Root/MainVBox/BtnRow,    "modulate", Color(1,1,1,1), FADE_IN)
	tf.tween_property($Root/MainVBox/BtnMore,   "modulate", Color(1,1,1,1), FADE_IN)

func _fadein(node: Node) -> Signal:
	var tw := create_tween()
	tw.tween_property(node, "modulate", Color(1,1,1,1), FADE_IN)
	return tw.finished
