class_name SeedInfo
extends Resource

enum Rarity {
	NORMAL,
	RARE,
}

enum SubSkillMode {
	None,
	Drag,
}

# ID
@export var skill_id := 0
# レア度
@export var rarity: Rarity = Rarity.NORMAL
# 名前
@export var display_name := ""
# 花の画像
@export var texture: Texture2D
# サブスキルの仕様
@export var sub_skill_mode: SubSkillMode = SubSkillMode.Drag
# メインスキル
@export var main_skill: SeedSkill
# サブスキル
@export var sub_skill: SeedSkill
# 消化状態の情報
@export var acid_block: AcidBlockInfo
# メイン効果の説明
@export_multiline var main_description := ""
# サブ効果の説明
@export_multiline var sub_description := ""


# mainスキル取得
func get_main_skill() -> SeedSkill:
	if main_skill != null:
		return main_skill
	return SeedSkillCatalog.get_main_skill(skill_id)


# subスキル取得
func get_sub_skill() -> SeedSkill:
	if sub_skill != null:
		return sub_skill
	return SeedSkillCatalog.get_sub_skill(skill_id)
