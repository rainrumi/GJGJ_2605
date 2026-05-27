class_name DigestTurnResult
extends RefCounted

var digested_enemies: Array[Enemy] = []
var spawn_requests: Array[DigestSpawnRequest] = []
var player_damage_values: Array[int] = []
var extra_elapsed_minutes := 0
var time_override_minutes := -1
