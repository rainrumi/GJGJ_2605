extends Node2D

signal battle_finished(won: bool)

const START_HOUR := 23
const END_HOUR := 30
const STEP_MINUTES := 30
const REST_MINUTES := 60
const MAX_HP := 100
const REST_HP := 50
const MAX_FULLNESS := 6

@onready var ui: CanvasLayer = $UI
@onready var time_text: Label = $UI/TimeBar/TimeText
@onready var hp_text: Label = $UI/HPBar/HPText
@onready var fullness_text: Label = get_node_or_null("UI/StatusPanel/FullnessText") as Label
@onready var message_text: Label = get_node_or_null("UI/StatusPanel/MessageText") as Label
@onready var nightmare_text: Label = get_node_or_null("UI/NightmarePanel/NightmareText") as Label
@onready var enemy_nodes: Array[Node2D] = [
	$EnemyLeft as Node2D,
	$EnemyCenter as Node2D,
	$EnemyRight as Node2D,
]
@onready var time_graph: TextureRect = get_node_or_null("UI/TimeBar/Graph") as TextureRect
@onready var eat_button: Button = get_node_or_null("UI/EatButton") as Button
@onready var skill_button: Button = get_node_or_null("UI/SkillButton") as Button
@onready var turn_end_button: Button = get_node_or_null("UI/TarnEndButton") as Button

var minutes: int = START_HOUR * 60
var hp: int = MAX_HP
var digest_speed: int = 1
var skill_active_turns: int = 0
var nightmares: Array[Dictionary] = []
var digesting: Array[Dictionary] = []


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	if eat_button != null:
		eat_button.pressed.connect(_on_eat_button_pressed)
	if skill_button != null:
		skill_button.pressed.connect(_on_skill_button_pressed)
	if turn_end_button != null:
		turn_end_button.pressed.connect(_on_turn_end_button_pressed)
	_sync_ui_visibility()
	start_battle()


func start_battle() -> void:
	minutes = START_HOUR * 60
	hp = MAX_HP
	digest_speed = 1
	skill_active_turns = 0
	digesting.clear()
	nightmares = [
		_create_nightmare("大人に追われる悪夢", 3, 2, 2),
		_create_nightmare("落下する悪夢", 2, 1, 1),
		_create_nightmare("仕事が終わらない悪夢", 4, 3, 2),
	]
	for enemy_node in enemy_nodes:
		enemy_node.visible = true
	_set_action_buttons_enabled(true)
	_update_ui("６時までにすべての悪夢を消化しましょう")


func _on_visibility_changed() -> void:
	_sync_ui_visibility()


func _sync_ui_visibility() -> void:
	if ui == null:
		return
	ui.visible = visible


func _create_nightmare(name: String, cost: int, size: int, attack: int) -> Dictionary:
	return {
		"name": name,
		"cost": cost,
		"remaining": cost,
		"size": size,
		"attack": attack,
		"digesting": false,
		"digested": false,
	}


func _on_eat_button_pressed() -> void:
	var nightmare_index := _find_eatable_nightmare_index()
	if nightmare_index == -1:
		_update_ui("これ以上食べられる悪夢がありません。")
		return
	var nightmare: Dictionary = nightmares[nightmare_index]
	nightmare["digesting"] = true
	nightmares[nightmare_index] = nightmare
	digesting.append(nightmare)
	_update_ui("%s を食べました。" % nightmare["name"])


func _on_skill_button_pressed() -> void:
	if skill_active_turns > 0:
		_update_ui("スキルはすでに発動中です。")
		return
	digest_speed = 2
	skill_active_turns = 2
	_update_ui("スキル発動。2ターンの間、消化速度が上がります。")


func _on_turn_end_button_pressed() -> void:
	_digest_nightmares()
	_apply_enemy_attack()
	_advance_time(STEP_MINUTES)
	if hp <= 0:
		hp = REST_HP
		_advance_time(REST_MINUTES)
		_update_ui("体力が尽きたため休憩しました。")
	else:
		_update_ui("30分が経過しました。")
	_update_skill()
	_update_enemy_visibility()
	_check_battle_end()


func _find_eatable_nightmare_index() -> int:
	var current_fullness := _current_fullness()
	for i in range(nightmares.size()):
		var nightmare: Dictionary = nightmares[i]
		if bool(nightmare["digesting"]) or bool(nightmare["digested"]):
			continue
		if current_fullness + int(nightmare["size"]) <= MAX_FULLNESS:
			return i
	return -1


func _current_fullness() -> int:
	var total := 0
	for raw_nightmare in digesting:
		var nightmare: Dictionary = raw_nightmare
		if not bool(nightmare["digested"]):
			total += int(nightmare["size"])
	return total


func _digest_nightmares() -> void:
	for i in range(digesting.size()):
		var nightmare: Dictionary = digesting[i]
		if bool(nightmare["digested"]):
			continue
		nightmare["remaining"] = maxi(0, int(nightmare["remaining"]) - digest_speed)
		if int(nightmare["remaining"]) == 0:
			nightmare["digested"] = true
			_mark_nightmare_digested(String(nightmare["name"]))
		digesting[i] = nightmare


func _mark_nightmare_digested(nightmare_name: String) -> void:
	for i in range(nightmares.size()):
		if String(nightmares[i]["name"]) != nightmare_name:
			continue
		var nightmare: Dictionary = nightmares[i]
		nightmare["digested"] = true
		nightmare["digesting"] = false
		nightmare["remaining"] = 0
		nightmares[i] = nightmare
		return


func _apply_enemy_attack() -> void:
	var damage := 0
	for raw_nightmare in nightmares:
		var nightmare: Dictionary = raw_nightmare
		if bool(nightmare["digesting"]) or bool(nightmare["digested"]):
			continue
		damage += int(nightmare["attack"])
	hp -= damage


func _advance_time(amount_minutes: int) -> void:
	minutes += amount_minutes


func _update_skill() -> void:
	if skill_active_turns <= 0:
		return
	skill_active_turns -= 1
	if skill_active_turns == 0:
		digest_speed = 1


func _update_enemy_visibility() -> void:
	for i in range(enemy_nodes.size()):
		if i >= nightmares.size():
			enemy_nodes[i].visible = false
			continue
		enemy_nodes[i].visible = not bool(nightmares[i]["digested"])


func _check_battle_end() -> void:
	if _all_nightmares_digested():
		_update_ui("勝利。朝までに悪夢をすべて消化しました。")
		_set_action_buttons_enabled(false)
		battle_finished.emit(true)
		return
	if minutes >= END_HOUR * 60:
		_update_ui("敗北。悪夢を消化しきれないまま朝を迎えました。")
		_set_action_buttons_enabled(false)
		battle_finished.emit(false)
		return
	var current_message := ""
	if message_text != null:
		current_message = message_text.text
	_update_ui(current_message)


func _all_nightmares_digested() -> bool:
	for raw_nightmare in nightmares:
		var nightmare: Dictionary = raw_nightmare
		if not bool(nightmare["digested"]):
			return false
	return true


func _set_action_buttons_enabled(enabled: bool) -> void:
	if eat_button != null:
		eat_button.disabled = not enabled
	if skill_button != null:
		skill_button.disabled = not enabled
	if turn_end_button != null:
		turn_end_button.disabled = not enabled


func _update_ui(message: String) -> void:
	if time_text != null:
		time_text.text = _format_time()
	if hp_text != null:
		hp_text.text = "%d/%d" % [maxi(0, hp), MAX_HP]
	if fullness_text != null:
		fullness_text.text = "%d/%d" % [_current_fullness(), MAX_FULLNESS]
	if message_text != null:
		message_text.text = message
	if nightmare_text != null:
		nightmare_text.text = _format_nightmare_list()
	_update_time_graph()


func _format_time() -> String:
	var hour := int(minutes / 60) % 24
	var minute := minutes % 60
	return "%02d:%02d" % [hour, minute]


func _format_nightmare_list() -> String:
	var lines := PackedStringArray()
	for raw_nightmare in nightmares:
		var nightmare: Dictionary = raw_nightmare
		var state: String = "未食"
		if bool(nightmare["digested"]):
			state = "消化完了"
		elif bool(nightmare["digesting"]):
			state = "消化中"
		lines.append("%s  %s  残り%s" % [
			nightmare["name"],
			state,
			_format_digest_time(int(nightmare["remaining"])),
		])
	return "\n".join(lines)


func _format_digest_time(cost: int) -> String:
	var speed: int = maxi(1, digest_speed)
	var seconds: int = int(ceil(float(cost) / float(speed) * 30.0 * 60.0))
	var hours: int = int(seconds / 3600)
	var minutes_part: int = int((seconds % 3600) / 60)
	var seconds_part: int = seconds % 60
	return "%d:%02d:%02d" % [hours, minutes_part, seconds_part]


func _update_time_graph() -> void:
	if time_graph == null:
		return
	var total_minutes: int = (END_HOUR - START_HOUR) * 60
	var elapsed: int = clampi(minutes - START_HOUR * 60, 0, total_minutes)
	var progress: float = float(elapsed) / float(total_minutes)
	time_graph.offset_left = 18.0 + 980.0 * progress
	time_graph.offset_right = time_graph.offset_left + 32.0
