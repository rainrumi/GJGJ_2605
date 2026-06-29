class_name StageClearSeedChoiceTexture
extends TextureRect


# 種表示
func setup_choice(seed: SeedInfo) -> void:
	texture = seed.texture if seed != null else null
