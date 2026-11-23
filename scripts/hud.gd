extends CanvasLayer
class_name GameHUD

signal movement_changed(value: Vector2)
signal aim_changed(value: Vector2)
signal reload_pressed
signal weapon_pressed
signal upgrade_selected(upgrade_name: String)

var health_bar: ProgressBar
var health_label: Label
var ammo_label: Label
var wave_label: Label
var score_label: Label
var message_label: Label
var move_stick: VirtualStick
var aim_stick: VirtualStick
var upgrade_panel: PanelContainer
var game_over_panel: PanelContainer
var upgrade_buttons: Array[Button] = []

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top := HBoxContainer.new()
	top.position = Vector2(22, 18)
	top.size = Vector2(676, 86)
	root.add_child(top)

	var stats := VBoxContainer.new()
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(stats)
	health_label = _label("HEALTH 100 / 100", 20)
	stats.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(280, 18)
	health_bar.max_value = 100
	health_bar.value = 100
	stats.add_child(health_bar)
	wave_label = _label("WAVE 1", 22)
	top.add_child(wave_label)
	score_label = _label("SCORE 0", 18)
	score_label.position = Vector2(520, 110)
	root.add_child(score_label)
	ammo_label = _label("PISTOL 18 / 120", 20)
	ammo_label.position = Vector2(22, 155)
	root.add_child(ammo_label)

	message_label = _label("", 26)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	message_label.position.y = 210
	message_label.size = Vector2(720, 48)
	root.add_child(message_label)

	move_stick = VirtualStick.new()
	move_stick.position = Vector2(28, 1000)
	move_stick.size = Vector2(180, 180)
	root.add_child(move_stick)
	move_stick.value_changed.connect(func(value: Vector2) -> void: movement_changed.emit(value))

	aim_stick = VirtualStick.new()
	aim_stick.position = Vector2(512, 1000)
	aim_stick.size = Vector2(180, 180)
	root.add_child(aim_stick)
	aim_stick.value_changed.connect(func(value: Vector2) -> void: aim_changed.emit(value))

	var reload_button := Button.new()
	reload_button.text = "RELOAD"
	reload_button.position = Vector2(545, 900)
	reload_button.size = Vector2(130, 52)
	root.add_child(reload_button)
	reload_button.pressed.connect(func() -> void: reload_pressed.emit())

	var weapon_button := Button.new()
	weapon_button.text = "NEXT"
	weapon_button.position = Vector2(38, 900)
	weapon_button.size = Vector2(115, 52)
	root.add_child(weapon_button)
	weapon_button.pressed.connect(func() -> void: weapon_pressed.emit())

	upgrade_panel = PanelContainer.new()
	upgrade_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	upgrade_panel.position = Vector2(-220, -190)
	upgrade_panel.size = Vector2(440, 380)
	upgrade_panel.visible = false
	root.add_child(upgrade_panel)
	var upgrade_box := VBoxContainer.new()
	upgrade_panel.add_child(upgrade_box)
	var upgrade_title := _label("WAVE CLEARED", 28)
	upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_box.add_child(upgrade_title)
	for upgrade_name in ["Speed", "Health", "Damage", "Fire Rate"]:
		var button := Button.new()
		button.text = "Upgrade: " + upgrade_name
		button.custom_minimum_size.y = 58
		upgrade_box.add_child(button)
		button.pressed.connect(func() -> void:
			upgrade_selected.emit(upgrade_name)
			upgrade_panel.visible = false
		)

	game_over_panel = PanelContainer.new()
	game_over_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	game_over_panel.position = Vector2(-190, -110)
	game_over_panel.size = Vector2(380, 220)
	game_over_panel.visible = false
	root.add_child(game_over_panel)
	var over_box := VBoxContainer.new()
	game_over_panel.add_child(over_box)
	var over_title := _label("YOU WERE OVERRUN", 27)
	over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_box.add_child(over_title)
	var retry := Button.new()
	retry.text = "PLAY AGAIN"
	retry.custom_minimum_size.y = 64
	over_box.add_child(retry)
	retry.pressed.connect(func() -> void: get_tree().reload_current_scene())

func _label(text_value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.94))
	return label

func set_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "HEALTH %d / %d" % [roundi(current), roundi(maximum)]

func set_ammo(current: int, reserve: int, weapon_name: String) -> void:
	ammo_label.text = "%s  %d / %d" % [weapon_name.to_upper(), current, reserve]

func set_wave(value: int) -> void:
	wave_label.text = "WAVE %d" % value

func set_score(value: int) -> void:
	score_label.text = "SCORE %d" % value

func show_message(value: String) -> void:
	message_label.text = value

func show_upgrades() -> void:
	upgrade_panel.visible = true

func show_game_over() -> void:
	game_over_panel.visible = true
