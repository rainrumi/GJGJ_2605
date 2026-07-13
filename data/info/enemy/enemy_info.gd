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
