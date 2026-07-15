class_name EnemyEffectRefreshProcessor
extends RefCounted

signal preprocess_requested(data: RefreshActivationData)
signal refresh_requested(data: RefreshActivationData)

var _known_enemies: Dictionary = {} # 戦闘参加敵


# 敵一覧登録
func register(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		if enemy != null:
			_known_enemies[enemy] = true


# 全補正初期化
func reset_all() -> void:
	for enemy in _known_enemies.keys():
		if enemy != null and is_instance_valid(enemy):
			enemy.data.defense_status.reset()
			enemy.data.attack.reset_modifiers()
			enemy.data.hp.reset_modifiers()
	_known_enemies.clear()


# 一時補正初期化
func clear_refresh_modifiers() -> void:
	for enemy in _known_enemies.keys():
		if enemy != null and is_instance_valid(enemy):
			enemy.data.defense_status.reset_refresh_modifiers()
			enemy.data.attack.reset_modifiers()
			enemy.data.hp.reset_modifiers()


# 更新前要求
func request_preprocess() -> RefreshActivationData:
	var data := RefreshActivationData.new() # 更新前発動値
	preprocess_requested.emit(data)
	return data


# 更新要求
func request_refresh() -> RefreshActivationData:
	var data := RefreshActivationData.new() # 更新発動値
	refresh_requested.emit(data)
	return data


# 最大HP補正適用
func apply_max_hp_modifiers(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		if enemy != null and not enemy.is_Acided():
			enemy.data.hp.apply_modifiers()
