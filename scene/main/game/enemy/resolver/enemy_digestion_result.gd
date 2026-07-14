class_name EnemyDigestionResult
extends RefCounted

var enemy: Enemy # 対象敵
var damage_values: Array[int] = [] # 消化値一覧
var total_damage := 0 # 合計消化値
var applied_damage := 0 # 適用消化値
var overkill_damage := 0 # 超過消化値
var hp_before := 0 # 適用前HP
var was_digested := false # 消化済み判定
