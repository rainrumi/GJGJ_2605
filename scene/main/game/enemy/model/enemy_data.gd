class_name EnemyData
extends RefCounted

signal skills_changed
signal age_changed(minutes: int)
signal special_effects_changed

enum SpecialEffect {
	CALAMITY,
	EXCUSE,
}

var definition: EnemyInfo # 敵定義
var hp := EnemyHp.new() # 敵HP
var attack := EnemyAttack.new() # 敵攻撃力
var stomach_status := EnemyStomachStatus.new() # 胃内状態
var digestion_state: EnemyStomachStatus:
	get: return stomach_status
var defense_status := EnemyDefenseStatus.new() # 防御状態
var main_skill: EnemySkill # メインスキル
var main_skill_active := false # メイン有効
var skills_enabled := true # スキル有効
var age_minutes := 0 # 誕生からの経過分数
var special_effects: Dictionary[int, int] = {} # 個体に付与された特殊効果


# 敵データ初期化
func setup(info: EnemyInfo, maximum_hp: int, attack_value: int, use_main_skill: bool, enable_skills: bool) -> void:
	unbind_skills()
	definition = info
	hp.setup(maximum_hp)
	attack.setup(attack_value)
	stomach_status.reset()
	age_minutes = 0
	age_changed.emit(age_minutes)
	defense_status.reset()
	special_effects.clear()
	special_effects_changed.emit()
	main_skill_active = use_main_skill
	skills_enabled = enable_skills
	main_skill = _duplicate_skill(info.get_main_skill_definition() if info != null else null)
	skills_changed.emit()


func add_age_minutes(value: int) -> void:
	age_minutes += maxi(0, value)
	age_changed.emit(age_minutes)


func add_special_effect(effect: SpecialEffect, amount: int) -> void:
	if amount <= 0:
		return
	special_effects[effect] = special_effects.get(effect, 0) + amount
	special_effects_changed.emit()


func get_special_effect_amount(effect: SpecialEffect) -> int:
	return special_effects.get(effect, 0)


func consume_special_effect(effect: SpecialEffect) -> bool:
	var amount := get_special_effect_amount(effect)
	if amount <= 0:
		return false
	if amount == 1:
		special_effects.erase(effect)
	else:
		special_effects[effect] = amount - 1
	special_effects_changed.emit()
	return true


static func get_special_effect_name(effect: SpecialEffect) -> String:
	match effect:
		SpecialEffect.CALAMITY:
			return "災禍"
		SpecialEffect.EXCUSE:
			return "言い逃れ"
	return ""


# 使用スキル取得
func get_active_skill() -> EnemySkill:
	if not skills_enabled or not main_skill_active:
		return null
	return main_skill


# 効果一覧取得
func get_effects() -> Array[EnemyEffect]:
	var skill := get_active_skill() # 使用スキル
	var active_effects: Array[EnemyEffect] = [] # 有効効果
	if skill != null:
		active_effects.assign(skill.get_effects())
	return active_effects


# スキル接続解除
func unbind_skills() -> void:
	if main_skill != null:
		main_skill.unbind()
	main_skill = null
	skills_changed.emit()


# スキル複製
func _duplicate_skill(skill: EnemySkill) -> EnemySkill:
	if skill == null:
		return null
	var duplicated := skill.duplicate(false) as EnemySkill # 個体スキル
	duplicated.effects = []
	for effect in skill.effects:
		if effect != null:
			duplicated.effects.append(effect.duplicate(true) as EnemyEffect)
	return duplicated
