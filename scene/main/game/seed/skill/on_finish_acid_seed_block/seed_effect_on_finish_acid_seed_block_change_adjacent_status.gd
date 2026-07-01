class_name SeedEffectOnFinishAcidSeedBlockChangeAdjacentStatus
extends SeedEffect

@export var attack_multiplier_delta := 0.0 # 攻撃差分
@export var hp_multiplier_delta := 0.0 # HP差分
@export var acid_taken_multiplier_delta := 0.0 # 受酸差分


# 種ブロック完了
func on_finish_acid_seed_block(_context: Dictionary) -> void:
	pass
