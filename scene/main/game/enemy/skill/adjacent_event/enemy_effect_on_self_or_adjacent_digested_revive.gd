class_name EnemyEffectOnSelfOrAdjacentDigestedRevive
extends EnemyEffectOnDigested



var enemies: Array[Enemy] = [] # 効果依存
var _placed_before_digestion: Dictionary = {}


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []
	_placed_before_digestion.clear()


# 胃袋外の消化は通常の消化結果通知を通らないため、消化確定を直接受け取る。
func bind() -> void:
	super.bind()
	for enemy in enemies:
		if enemy == null:
			continue
		_placed_before_digestion[enemy] = enemy.is_active_in_stomach()
		connect_trigger(enemy.data.stomach_status.placement_changed, _on_placement_changed.bind(enemy))
		connect_trigger(enemy.data.stomach_status.digested, _on_target_digested.bind(enemy))


func _on_placement_changed(is_placed: bool, enemy: Enemy) -> void:
	_placed_before_digestion[enemy] = is_placed


func _on_target_digested(enemy: Enemy) -> void:
	if _placed_before_digestion.get(enemy, false):
		return
	var data := DigestedActivationData.new()
	data.setup(enemy, 0, 0, 0, 0, [enemy] as Array[Enemy])
	queue_activation(data)


# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0
# 生存者必須
@export var require_survivor := true

# 発動条件判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	var target := get_activation_target_from(data)
	if target == null or not target.is_enemy() or not target.is_Acided():
		return false
	return not require_survivor or enemies.any(func(enemy: Enemy) -> bool:
		return enemy != null and enemy.is_enemy() and not enemy.is_Acided()
	)


# 効果適用
func apply() -> void:
	EnemyEffectBattleActions.revive(source, get_activation_target(), recovery_rate)
