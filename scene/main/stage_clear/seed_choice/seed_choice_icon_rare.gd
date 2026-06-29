class_name StageClearSeedChoiceIconRare
extends NinePatchRect


# 種表示
func setup_choice(seed: SeedInfo) -> void:
	visible = _is_rare_seed(seed)


# rare判定
func _is_rare_seed(seed: SeedInfo) -> bool:
	return seed != null and seed.rarity == SeedInfo.Rarity.RARE
