class_name DigestSideEffects
extends RefCounted

var player_damage_values: Array[int] = []
var spawn_requests: Array[DigestSpawnRequest] = []


func clear() -> void:
	player_damage_values.clear()
	spawn_requests.clear()
