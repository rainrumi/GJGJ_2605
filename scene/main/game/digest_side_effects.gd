class_name AcidSideEffects
extends RefCounted

var player_damage_values: Array[int] = []
var spawn_requests: Array[AcidSpawnRequest] = []


# 対象消去
func clear() -> void:
	player_damage_values.clear()
	spawn_requests.clear()
