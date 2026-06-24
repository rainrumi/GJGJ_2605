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
# 消化状態の情報
@export var drag_block_definition: SeedBlockInfo
# メイン効果の説明
@export_multiline var main_description := ""
# サブ効果の説明
@export_multiline var sub_description := ""
