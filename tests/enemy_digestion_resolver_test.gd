extends SceneTree

var _failures := 0 # 失敗数


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# Resolver試験
func _run() -> void:
	var source := FileAccess.get_file_as_string(
		"res://scene/main/game/enemy/resolver/enemy_digestion_resolver.gd"
	) # Resolverソース
	_expect(not source.contains("EnemyEffect"), "ResolverがEffect種別を認識しない")
	_expect(not source.contains("show_") and not source.contains("pulse_"), "ResolverがViewを操作しない")
	var enemy := Enemy.new() # 試験敵
	enemy.data.hp.setup(10)
	var result := EnemyDigestionResult.new() # 試験結果
	result.enemy = enemy
	result.hp_before = 10
	var resolver := EnemyDigestionResolver.new() # 消化計算
	resolver.apply_result(result, 15)
	_expect(result.applied_damage == 10, "適用ダメージを適用前HPで制限する")
	_expect(result.overkill_damage == 5, "超過ダメージを適用前HPから計算する")
	_expect(result.was_digested, "HP枯渇を消化結果へ記録する")
	enemy.free()
	quit(_failures)


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyDigestionResolverTest: %s" % message)
