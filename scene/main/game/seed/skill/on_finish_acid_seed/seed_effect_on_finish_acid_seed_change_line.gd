class_name SeedEffectOnFinishAcidSeedChangeLine
extends SeedEffect

@export var line_delta := 0 # 行差分


# 種消化完了
func on_finish_acid_seed(_state: DreamSeedSkillState, context: Dictionary) -> bool:
	var stomach := context.get("stomach") as StomachBoard # 胃ボード
	if stomach == null or line_delta == 0:
		return false
	var previous_rows := stomach.get_acid_line_rows() # 変更前
	var next_rows := maxi(1, previous_rows + line_delta) # 変更後
	if next_rows == previous_rows:
		return false
	stomach.set_acid_line_rows(next_rows)
	return true


# 消化行補正
func get_acid_line_rows_delta() -> int:
	return line_delta
