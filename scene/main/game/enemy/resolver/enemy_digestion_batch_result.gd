class_name EnemyDigestionBatchResult
extends RefCounted

var results: Array[EnemyDigestionResult] = [] # 対象別結果
var digested_enemies: Array[Enemy] = [] # 最終消化一覧
var received_damage: Dictionary = {} # 敵別受領値
var turn_start_hp: Dictionary = {} # 開始時HP


# 対象結果取得
func find_result(enemy: Enemy) -> EnemyDigestionResult:
	for result in results:
		if result.enemy == enemy:
			return result
	return null
