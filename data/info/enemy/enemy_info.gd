class_name EnemyInfo
extends Resource

# ID
@export var skill_id := 0
# 名前
@export var display_name := ""
# 消化状態の情報
@export var acid_block: AcidBlockInfo
# 説明
@export_multiline var description := ""
# スキル有無
@export var nightmare_skill_enabled := true
# スキル
@export var skill: EnemySkill
# メインスキル
@export var main_skill: EnemySkill
# サブスキル
@export var sub_skill: EnemySkill


# メイン定義取得
func get_main_skill_definition() -> EnemySkill:
	return main_skill if main_skill != null else skill


# サブ定義取得
func get_sub_skill_definition() -> EnemySkill:
	return sub_skill if sub_skill != null else skill
