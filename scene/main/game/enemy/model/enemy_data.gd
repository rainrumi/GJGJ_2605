class_name EnemyData
extends RefCounted

var definition: EnemyInfo # 敵定義
var hp := EnemyHp.new() # 敵HP
var attack := EnemyAttack.new() # 敵攻撃力
var stomach_status := EnemyStomachStatus.new() # 胃内状態
var defense_status := EnemyDefenseStatus.new() # 防御状態
var main_skill: EnemySkill # メインスキル
var sub_skill: EnemySkill # サブスキル
var main_skill_active := false # メイン有効
var skills_enabled := true # スキル有効


# 敵データ初期化
func setup(info: EnemyInfo, maximum_hp: int, attack_value: int, use_main_skill: bool, enable_skills: bool) -> void:
	unbind_skills()
	definition = info
	hp.setup(maximum_hp)
	attack.setup(attack_value)
	stomach_status.reset()
	defense_status.reset()
	main_skill_active = use_main_skill
	skills_enabled = enable_skills
	main_skill = _duplicate_skill(info.get_main_skill_definition() if info != null else null)
	sub_skill = _duplicate_skill(info.get_sub_skill_definition() if info != null else null)


# 使用スキル取得
func get_active_skill() -> EnemySkill:
	if not skills_enabled:
		return null
	return main_skill if main_skill_active else sub_skill


# 効果一覧取得
func get_effects() -> Array[EnemyEffect]:
	var skill := get_active_skill() # 使用スキル
	return skill.get_effects() if skill != null else []


# スキル接続解除
func unbind_skills() -> void:
	if main_skill != null:
		main_skill.unbind()
	if sub_skill != null and sub_skill != main_skill:
		sub_skill.unbind()
	main_skill = null
	sub_skill = null


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
