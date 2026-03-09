extends Node2D
## MainGame — Master game controller.
## Updated: real-time clock pause/resume, midnight day-change handling,
##          MoneySpendUI for money decisions after each job.

enum State { EXPLORE, DIALOGUE, JOB_SELECT, JOB_RESULT, HOTEL_PROMPT, SLEEP, TRANSITIONING }
var _state: State = State.EXPLORE

var _near_npc: CharacterBody2D = null
var _near_hotel: bool = false
var _active_ui: Node = null
var _last_result: Dictionary = {}

@onready var _player: CharacterBody2D  = $Player
@onready var _camera: Camera2D         = $Camera2D
@onready var _bar_energy: ProgressBar  = $HUD/HUDControl/LeftPanel/BarEnergy
@onready var _bar_debt: ProgressBar    = $HUD/HUDControl/LeftPanel/BarDebt
@onready var _bar_paid: ProgressBar    = $HUD/HUDControl/LeftPanel/BarPaid
@onready var _lbl_debt_val: Label      = $HUD/HUDControl/LeftPanel/LblDebtVal
@onready var _lbl_paid_val: Label      = $HUD/HUDControl/LeftPanel/LblPaidVal
@onready var _lbl_money: Label         = $HUD/HUDControl/LeftPanel/LblMoney
@onready var _lbl_time: Label          = $HUD/HUDControl/LeftPanel/LblTime
@onready var _lbl_day: Label           = $HUD/HUDControl/LeftPanel/LblDay
@onready var _tooltip: PanelContainer  = $HUD/HUDControl/Tooltip
@onready var _lbl_tooltip: Label       = $HUD/HUDControl/Tooltip/LblTooltip
@onready var _hotel_area: Area2D       = $World/HotelBuilding/HotelArea
@onready var _hotel_hint: Label        = $World/HotelBuilding/HotelHint

func _ready() -> void:
	_style_hud()
	_connect_npc_signals()
	_hotel_area.body_entered.connect(_on_hotel_entered)
	_hotel_area.body_exited.connect(_on_hotel_exited)
	_tooltip.visible    = false
	_hotel_hint.visible = false
	_update_hud()
	## Listen for midnight day-change
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.time_changed.connect(_update_hud)

func _process(_delta: float) -> void:
	_camera.global_position = _player.global_position

## ─── HUD ───────────────────────────────────────────────────────────
func _update_hud() -> void:
	_bar_energy.value  = GameManager.get_energy_percent()
	_bar_debt.value    = GameManager.get_debt_percent()
	_bar_paid.value    = GameManager.get_paid_percent()
	_lbl_debt_val.text = "Debt  $%.0f" % GameManager.debt_remaining
	_lbl_paid_val.text = "Paid  $%.0f" % GameManager.debt_paid
	_lbl_money.text    = "Cash  $%.0f" % GameManager.money
	_lbl_time.text     = GameManager.get_time_string()
	_lbl_day.text      = GameManager.get_day_string()

func _style_hud() -> void:
	var red  := _flat(Color(1.0, 0.22, 0.22, 1.0))
	var yel  := _flat(Color(1.00, 0.75, 0.10, 1.0))
	var blu  := _flat(Color(0.18, 0.70, 1.00, 1.0))
	var bg   := _flat(Color(0.08, 0.08, 0.12, 0.88))
	_bar_energy.add_theme_stylebox_override("fill",       red.duplicate())
	_bar_energy.add_theme_stylebox_override("background", bg.duplicate())
	_bar_debt.add_theme_stylebox_override("fill",         yel.duplicate())
	_bar_debt.add_theme_stylebox_override("background",   bg.duplicate())
	_bar_paid.add_theme_stylebox_override("fill",         blu.duplicate())
	_bar_paid.add_theme_stylebox_override("background",   bg.duplicate())

func _flat(color: Color, r: int = 5) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left     = r
	s.corner_radius_top_right    = r
	s.corner_radius_bottom_left  = r
	s.corner_radius_bottom_right = r
	return s

## ─── Day-changed (from midnight auto-tick) ─────────────────────────
func _on_day_changed() -> void:
	## Only react when no UI is active (i.e. midnight happened mid-explore)
	if _state == State.EXPLORE:
		var cond := GameManager.check_condition()
		if cond == "win":
			_go_win()
		elif cond == "lose_time":
			_go_lose("time")
		elif cond == "lose_energy":
			_go_lose("energy")

## ─── Tooltip ───────────────────────────────────────────────────────
func _show_tooltip(msg: String) -> void:
	_lbl_tooltip.text = msg
	_tooltip.visible  = true

func _hide_tooltip() -> void:
	_tooltip.visible = false

## ─── Input ─────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	match _state:
		State.EXPLORE:
			if _near_npc != null:
				_start_dialogue(_near_npc)
			elif _near_hotel:
				_open_hotel_prompt()
		State.DIALOGUE:
			_advance_dialogue()

## ─── NPC ───────────────────────────────────────────────────────────
func _connect_npc_signals() -> void:
	for node: Node in get_tree().get_nodes_in_group("npc"):
		if node.has_signal("player_entered"):
			node.player_entered.connect(_on_npc_entered)
		if node.has_signal("player_exited"):
			node.player_exited.connect(_on_npc_exited)

func _on_npc_entered(npc: CharacterBody2D) -> void:
	_near_npc = npc
	_show_tooltip('[ E ]  Talk to ' + npc.get_npc_name())

func _on_npc_exited(npc: CharacterBody2D) -> void:
	if _near_npc == npc:
		_near_npc = null
	if _near_npc == null and not _near_hotel:
		_hide_tooltip()

## ─── Hotel ─────────────────────────────────────────────────────────
func _on_hotel_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_near_hotel = true
		_hotel_hint.visible = true
		_show_tooltip('[ E ]  Rest and end the day')

func _on_hotel_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_near_hotel = false
		_hotel_hint.visible = false
		if _near_npc == null:
			_hide_tooltip()

## ─── DIALOGUE ──────────────────────────────────────────────────────
func _start_dialogue(npc: CharacterBody2D) -> void:
	_set_state(State.DIALOGUE)
	_player.set_locked(true)
	_hide_tooltip()
	GameManager.pause_clock()
	var ui := preload("res://scenes/DialogueUI.tscn").instantiate()
	_open_ui(ui)
	var npc_color: Color = Color(0.7, 0.15, 0.15, 1.0)
	if npc.has_method("get_npc_color"):
		npc_color = npc.get_npc_color()
	ui.setup(npc.get_npc_name(), npc.get_dialogue(), npc_color)

func _advance_dialogue() -> void:
	if _active_ui == null:
		return
	if _active_ui.try_advance():
		_close_active_ui()
		_open_job_select()

## ─── JOB SELECT ────────────────────────────────────────────────────
func _open_job_select() -> void:
	_set_state(State.JOB_SELECT)
	var ui := preload("res://scenes/JobSelectUI.tscn").instantiate()
	_open_ui(ui)
	ui.setup(GameManager.get_today_jobs())
	ui.job_chosen.connect(_on_job_chosen)
	ui.cancelled.connect(_on_cancelled)

func _on_job_chosen(job: Dictionary) -> void:
	_close_active_ui()
	_last_result = GameManager.do_job(job)
	if GameManager.check_condition() == "lose_energy":
		GameManager.resume_clock()
		_go_lose("energy")
		return
	_open_money_spend()

func _on_cancelled() -> void:
	_close_active_ui()
	_player.set_locked(false)
	GameManager.resume_clock()
	_set_state(State.EXPLORE)

## ─── MONEY SPEND (new) ─────────────────────────────────────────────
func _open_money_spend() -> void:
	_set_state(State.JOB_RESULT)
	## Try to load MoneySpendUI scene; fall back to old JobDescriptionUI if missing
	var spend_scene_path := "res://scenes/MoneySpendUI.tscn"
	var ui: Node
	if ResourceLoader.exists(spend_scene_path):
		ui = load(spend_scene_path).instantiate()
		_open_ui(ui)
		ui.setup(_last_result)
		ui.chose_save.connect(_on_chose_save)
		ui.chose_pay_all.connect(_on_chose_pay_all)
		ui.chose_pay_partial.connect(_on_chose_pay_partial)
		ui.chose_buy_food.connect(_on_chose_buy_food)
		ui.chose_more_work.connect(_on_chose_more_work)
	else:
		## Fallback: original JobDescriptionUI
		ui = preload("res://scenes/JobDescriptionUI.tscn").instantiate()
		_open_ui(ui)
		ui.setup(_last_result)
		ui.chose_save.connect(_on_chose_save)
		ui.chose_pay.connect(_on_chose_pay_all)
		ui.chose_more_work.connect(_on_chose_more_work)

func _on_chose_save() -> void:
	GameManager.save_money()
	_close_active_ui()
	_player.set_locked(false)
	GameManager.resume_clock()
	_set_state(State.EXPLORE)

func _on_chose_pay_all() -> void:
	GameManager.pay_debt(GameManager.money)
	_close_active_ui()
	var cond := GameManager.check_condition()
	if cond == "win":
		_go_win(); return
	if cond == "lose_energy":
		_go_lose("energy"); return
	_player.set_locked(false)
	GameManager.resume_clock()
	_set_state(State.EXPLORE)

func _on_chose_pay_partial() -> void:
	GameManager.pay_debt_partial(GameManager.money * 0.5)
	_close_active_ui()
	var cond := GameManager.check_condition()
	if cond == "win":
		_go_win(); return
	_player.set_locked(false)
	GameManager.resume_clock()
	_set_state(State.EXPLORE)

func _on_chose_buy_food(item_index: int) -> void:
	GameManager.buy_food(item_index)
	_close_active_ui()
	_player.set_locked(false)
	GameManager.resume_clock()
	_set_state(State.EXPLORE)

func _on_chose_more_work() -> void:
	_close_active_ui()
	if GameManager.energy <= 5.0:
		GameManager.resume_clock()
		_go_lose("energy")
		return
	_open_job_select()   ## clock stays paused while in UI

## ─── HOTEL PROMPT ──────────────────────────────────────────────────
func _open_hotel_prompt() -> void:
	_set_state(State.HOTEL_PROMPT)
	_player.set_locked(true)
	_hide_tooltip()
	GameManager.pause_clock()
	var ui := preload("res://scenes/HotelPromptUI.tscn").instantiate()
	_open_ui(ui)
	ui.chose_rest.connect(_on_chose_rest)
	ui.chose_cancel.connect(_on_hotel_cancel)

func _on_chose_rest() -> void:
	_close_active_ui()
	_do_rest()

func _on_hotel_cancel() -> void:
	_close_active_ui()
	_player.set_locked(false)
	GameManager.resume_clock()
	_set_state(State.EXPLORE)

## ─── SLEEP ─────────────────────────────────────────────────────────
func _do_rest() -> void:
	_set_state(State.SLEEP)
	var data: Dictionary = GameManager.rest()   ## rest() already advances day
	var sleep := preload("res://scenes/SleepScene.tscn").instantiate()
	$HUD.add_child(sleep)
	sleep.setup(data)
	sleep.continue_pressed.connect(_on_sleep_done.bind(sleep))

func _on_sleep_done(sleep_node: Node) -> void:
	sleep_node.queue_free()
	match GameManager.check_condition():
		"win":         _go_win()
		"lose_time":   _go_lose("time")
		"lose_energy": _go_lose("energy")
		_:
			_player.set_locked(false)
			GameManager.resume_clock()
			_set_state(State.EXPLORE)

## ─── Transitions ───────────────────────────────────────────────────
func _go_win() -> void:
	_set_state(State.TRANSITIONING)
	GameManager.pause_clock()
	StyleHelper.go("res://scenes/VictoryScene.tscn")

func _go_lose(reason: String) -> void:
	_set_state(State.TRANSITIONING)
	GameManager.pause_clock()
	if reason == "energy":
		StyleHelper.go("res://scenes/LoseSceneEnergy.tscn")
	else:
		StyleHelper.go("res://scenes/LoseSceneTime.tscn")

## ─── UI helpers ────────────────────────────────────────────────────
func _open_ui(ui: Node) -> void:
	if _active_ui != null:
		_active_ui.queue_free()
	add_child(ui)
	_active_ui = ui

func _close_active_ui() -> void:
	if _active_ui != null:
		_active_ui.queue_free()
		_active_ui = null

func _set_state(s: State) -> void:
	_state = s
