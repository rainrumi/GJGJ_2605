extends SceneTree

var _failures := 0


func _initialize() -> void:
	for skill_id in [16010009003]:
		_test_self_digested(skill_id)
		_test_adjacent_digested(skill_id)
		_test_no_survivor(skill_id)
		_test_distant_digested(skill_id)
		_test_distant_survivor(skill_id)
		_test_seed_only_survivor(skill_id)
		_test_seed_digested(skill_id)
		_test_owner_outside(skill_id)
		_test_target_outside(skill_id)
		_test_both_outside(skill_id)
	quit(_failures)


func _test_self_digested(skill_id: int) -> void:
	var fixture := _create_fixture(skill_id)
	var source: Enemy = fixture.source
	var neighbor: Enemy = fixture.neighbor
	var stack: EnemyEffectStack = fixture.stack
	_digest(source, [source])
	stack.execute()
	_expect(not source.is_Acided() and source.current_hp == 50, "%d: 隣接者が残ると自身が復活" % skill_id)
	_expect(not neighbor.is_Acided(), "%d: 生存する隣接者は変化しない" % skill_id)
	_free_fixture(fixture)


func _test_adjacent_digested(skill_id: int) -> void:
	var fixture := _create_fixture(skill_id)
	var source: Enemy = fixture.source
	var neighbor: Enemy = fixture.neighbor
	var stack: EnemyEffectStack = fixture.stack
	_digest(neighbor, [neighbor])
	stack.execute()
	_expect(not neighbor.is_Acided() and neighbor.current_hp == 50, "%d: 自身が残ると隣接者が復活" % skill_id)
	_expect(not source.is_Acided(), "%d: 生存する自身は変化しない" % skill_id)
	_free_fixture(fixture)


func _test_no_survivor(skill_id: int) -> void:
	var fixture := _create_fixture(skill_id)
	var source: Enemy = fixture.source
	var neighbor: Enemy = fixture.neighbor
	var stack: EnemyEffectStack = fixture.stack
	source.data.hp.take_damage(100)
	neighbor.data.hp.take_damage(100)
	source.set_Acided(true)
	neighbor.set_Acided(true)
	var digested_data: Array[EnemyData] = [source.data, neighbor.data]
	source.data.stomach_status.publish_digestion(100, 0, 60, 60, digested_data)
	neighbor.data.stomach_status.publish_digestion(100, 0, 60, 60, digested_data)
	stack.execute()
	_expect(source.is_Acided() and neighbor.is_Acided(), "%d: 全員消化済みなら復活しない" % skill_id)
	_free_fixture(fixture)


func _test_distant_digested(skill_id: int) -> void:
	var fixture := _create_fixture(skill_id, Vector2i(3, 0))
	var neighbor: Enemy = fixture.neighbor
	var stack: EnemyEffectStack = fixture.stack
	_digest(neighbor, [neighbor])
	stack.execute()
	_expect(not neighbor.is_Acided() and neighbor.current_hp == 50, "%d: 離れた悪夢も復活する" % skill_id)
	_free_fixture(fixture)


func _test_distant_survivor(skill_id: int) -> void:
	var fixture := _create_fixture(skill_id, Vector2i(3, 0))
	var source: Enemy = fixture.source
	var stack: EnemyEffectStack = fixture.stack
	_digest(source, [source])
	stack.execute()
	_expect(not source.is_Acided() and source.current_hp == 50, "%d: 離れた悪夢が残れば自身も復活する" % skill_id)
	_free_fixture(fixture)


func _test_seed_only_survivor(skill_id: int) -> void:
	var fixture := _create_fixture(skill_id)
	var source: Enemy = fixture.source
	var neighbor: Enemy = fixture.neighbor
	var stack: EnemyEffectStack = fixture.stack
	neighbor.seed_info = SeedInfo.new()
	_digest(source, [source])
	stack.execute()
	_expect(source.is_Acided(), "%d: 夢の種だけが残っても復活しない" % skill_id)
	_free_fixture(fixture)


func _test_seed_digested(skill_id: int) -> void:
	var fixture := _create_fixture(skill_id)
	var neighbor: Enemy = fixture.neighbor
	var stack: EnemyEffectStack = fixture.stack
	neighbor.seed_info = SeedInfo.new()
	_digest(neighbor, [neighbor])
	stack.execute()
	_expect(neighbor.is_Acided(), "%d: 夢の種の消化では発動しない" % skill_id)
	_free_fixture(fixture)


func _test_owner_outside(skill_id: int) -> void:
	var fixture := _create_fixture(skill_id)
	var source: Enemy = fixture.source
	var neighbor: Enemy = fixture.neighbor
	var stack: EnemyEffectStack = fixture.stack
	source.set_Aciding(false)
	_digest(neighbor, [neighbor])
	stack.execute()
	_expect(not neighbor.is_Acided() and neighbor.current_hp == 50, "%d: 所有者が胃袋外でも発動する" % skill_id)
	_free_fixture(fixture)


func _test_target_outside(skill_id: int) -> void:
	var fixture := _create_fixture(skill_id)
	var neighbor: Enemy = fixture.neighbor
	var stack: EnemyEffectStack = fixture.stack
	neighbor.set_Aciding(false)
	neighbor.take_acid_damage(100, false)
	stack.execute()
	_expect(not neighbor.is_Acided() and neighbor.current_hp == 50, "%d: 胃袋外の消化確定でも復活対象になる" % skill_id)
	_free_fixture(fixture)


func _test_both_outside(skill_id: int) -> void:
	var fixture := _create_fixture(skill_id)
	var source: Enemy = fixture.source
	var neighbor: Enemy = fixture.neighbor
	var stack: EnemyEffectStack = fixture.stack
	source.set_Aciding(false)
	neighbor.set_Aciding(false)
	neighbor.take_acid_damage(100, false)
	stack.execute()
	_expect(not neighbor.is_Acided() and neighbor.current_hp == 50, "%d: 胃袋外の悪夢が残る場合も発動する" % skill_id)
	_free_fixture(fixture)


func _create_fixture(skill_id: int, neighbor_cell := Vector2i.RIGHT) -> Dictionary:
	var path := "res://data/resources/area/area_iriyu/enemy/normal/009/area_iriyu_enemy_normal_009_%03d.tres" % (skill_id % 1000)
	var info := load(path) as EnemyInfo
	var source := _create_enemy(info, Vector2i.ZERO)
	var neighbor := _create_enemy(EnemyInfo.new(), neighbor_cell)
	var enemies: Array[Enemy] = [source, neighbor]
	var effect := source.get_enemy_effects()[0] as EnemyEffectOnSelfOrAdjacentDigestedRevive
	var stack := EnemyEffectStack.new()
	effect.bind_owner(source.data, stack)
	effect.bind_source(source)
	effect.setup_enemies(enemies)
	effect.setup_digestion_triggers(enemies, null)
	effect.bind()
	return {"source": source, "neighbor": neighbor, "effect": effect, "stack": stack}


func _create_enemy(info: EnemyInfo, cell: Vector2i) -> Enemy:
	var enemy := Enemy.new()
	enemy.data.setup(info, 100, 1, true, true)
	enemy.set_stomach_footprint_override(Vector2i.ONE, [Vector2i.ZERO], 1)
	enemy.set_stomach_cell(cell)
	enemy.set_Aciding(true)
	return enemy


func _digest(enemy: Enemy, digested: Array[Enemy]) -> void:
	enemy.data.hp.take_damage(100)
	enemy.set_Acided(true)
	var digested_data: Array[EnemyData] = []
	for target in digested:
		digested_data.append(target.data)
	enemy.data.stomach_status.publish_digestion(100, 0, 60, 60, digested_data)


func _free_fixture(fixture: Dictionary) -> void:
	(fixture.effect as EnemyEffect).unbind()
	(fixture.source as Enemy).free()
	(fixture.neighbor as Enemy).free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("IriyuAdjacentReviveTest: %s" % message)
