extends SceneTree

const TARGET_PATH := "res://data/resources/area/area_iriyu/enemy/normal/006/area_iriyu_enemy_normal_006_001.tres"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var definition := load(TARGET_PATH) as EnemyInfo
	_expect(definition != null, "16010006001の定義を読める")
	if definition == null:
		quit(_failures)
		return

	var enemy := Enemy.new()
	enemy.data.setup(definition, 400, 12, true, true)
	enemy.set_Aciding(true)
	enemy.stomach_elapsed_minutes = 30
	var effect := enemy.get_enemy_effects()[0] as EnemyEffectOnAttackChanceScaleDamage
	_expect(effect != null, "攻撃時抽選の効果を使う")
	if effect == null:
		enemy.free()
		quit(_failures)
		return
	_expect(is_equal_approx(effect.chance, 0.8), "発動率は80%")
	_expect(is_equal_approx(effect.attack_multiplier, 3.0), "当選時は3倍")

	var seed_effects := SeedEffectResolver.new()
	seed_effects.setup([])
	var resolver := EnemyAttackResolver.new()
	resolver.setup(seed_effects, EnemyEffectSystem.new(), 0)
	var enemies: Array[Enemy] = [enemy]

	effect.chance = 1.0
	_expect(resolver.resolve(enemies, null, 30) == [36], "当選時の攻撃だけ36ダメージ")
	_expect(enemy.get_damage() == 12, "攻撃力は12のまま")
	_expect(resolver.get_enemy_attack_damage(enemy, enemies, null, 30) == 12, "攻撃力補正値も変わらない")
	effect.chance = 0.0
	_expect(resolver.resolve(enemies, null, 60) == [12], "次の攻撃は再抽選され通常ダメージ")
	effect.chance = 1.0
	_expect(resolver.resolve(enemies, null, 90) == [36], "さらに次の攻撃も再抽選される")
	enemy.data.skills_enabled = false
	_expect(resolver.resolve(enemies, null, 90) == [12], "スキル無効時は3倍にならない")
	enemy.data.skills_enabled = true

	effect.chance = 0.5
	enemy.data.defense_status.extra_attack_count = 2
	seed(42)
	var expected: Array[int] = []
	for _index in range(3):
		expected.append(36 if randf() <= 0.5 else 12)
	seed(42)
	_expect(resolver.resolve(enemies, null, 120) == expected, "追加攻撃も1回ごとに独立抽選する")
	_expect(enemy.get_damage() == 12, "連続攻撃後も攻撃力を変更しない")

	enemy.free()
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Enemy16010006001AttackTest: %s" % message)
