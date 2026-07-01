class_name SeedEffectOnProgressTimeDamageLine
extends SeedEffect

@export var damage := 0 # 固定ダメ
@export var edge_only := false # 端のみ
@export var split := false # 分割有無


# 時間経過
func on_progress_time(_state: DreamSeedSkillState, _context: Dictionary) -> void:
	pass
