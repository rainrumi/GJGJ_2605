class_name SeedEffectOnNotBattleChangeClearRecovery
extends SeedEffect

@export var recovery_rate := 0.0 # 回復率
@export var disable_recovery := false # 回復無効
@export var extra_choice_start_minutes := -1 # 追加開始
@export var permanent_acid_rate := 0.0 # 永続酸率
@export var clear_until_minutes := -1 # 解除分


# 非戦闘中
func on_not_battle(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass


# 時刻までclear
func on_clear_until_clock(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass
