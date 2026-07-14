class_name EnemyTurnInput
extends RefCounted

var enemies: Array[Enemy] = [] # 戦闘参加敵
var stomach: StomachBoard # 胃袋盤面
var previous_minutes := 0 # 直前時刻
var minutes := 0 # 現在時刻
var elapsed_minutes := 30 # 経過分数

