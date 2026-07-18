extends SceneTree

const CELL_TEXTURE := preload("res://art/enemy/tex_enemy_1_1_100.png")
const ENEMY_SCENE := preload("res://scene/object/enemy/enemy.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var block := AcidBlockInfo.new()
	block.stomach_shape = [
		PackedInt32Array([1, 0]),
		PackedInt32Array([1, 1]),
	]
	block.texture = _create_custom_texture()
	var info := EnemyInfo.new()
	info.acid_block = block
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	root.add_child(enemy)
	enemy.setup(info, Vector2(80.0, 80.0))

	var shape_texture := enemy.get_preview_texture()
	_expect(shape_texture != null, "StomachShapeから表示Textureを生成する")
	if shape_texture != null:
		_expect(
			shape_texture.get_size() == Vector2(80.0, 80.0),
			"セル画像のピクセル数で2x2のTextureを作る"
		)
		var shape_image := shape_texture.get_image()
		var cell_image := CELL_TEXTURE.get_image()
		_expect(
			_same_pixel(shape_image, cell_image, Vector2i(21, 21), Vector2i(20, 20)),
			"左上セルを敵の中心へ1px寄せる"
		)
		_expect(shape_image.get_pixelv(Vector2i(60, 20)).a == 0.0, "無効な右上セルは透明にする")
		_expect(
			_same_pixel(shape_image, cell_image, Vector2i(21, 59), Vector2i(20, 20)),
			"左下セルを敵の中心へ1px寄せる"
		)
		_expect(
			_same_pixel(shape_image, cell_image, Vector2i(59, 59), Vector2i(20, 20)),
			"右下セルを敵の中心へ1px寄せる"
		)
		_expect(shape_image.get_pixelv(Vector2i(0, 21)).a == 0.0, "敵の左端に1pxの余白を空ける")
		_expect(shape_image.get_pixelv(Vector2i(59, 79)).a == 0.0, "敵の下端に1pxの余白を空ける")
		_expect(shape_image.get_pixelv(Vector2i(21, 39)).a > 0.0, "同じ敵の上下セルを接続する")
		_expect(shape_image.get_pixelv(Vector2i(39, 59)).a > 0.0, "同じ敵の左右セルを接続する")
	_test_single_cell_margin()

	root.remove_child(enemy)
	enemy.free()
	quit(_failures)


func _test_single_cell_margin() -> void:
	var single_shape: Array[Vector2i] = [Vector2i.ZERO]
	var single_texture := EnemySpriteView.create_shape_texture(
		CELL_TEXTURE,
		Vector2i.ONE,
		single_shape
	)
	_expect(single_texture != null, "1セルの敵画像を生成する")
	if single_texture == null:
		return
	var single_image := single_texture.get_image()
	_expect(
		single_image.get_pixelv(Vector2i(0, 20)).a == 0.0,
		"1セルの敵も左端に余白を空ける"
	)
	_expect(
		single_image.get_pixelv(Vector2i(39, 20)).a == 0.0,
		"1セルの敵も右端に余白を空ける"
	)
	_expect(
		single_image.get_pixelv(Vector2i(20, 0)).a == 0.0,
		"1セルの敵も上端に余白を空ける"
	)
	_expect(
		single_image.get_pixelv(Vector2i(20, 39)).a == 0.0,
		"1セルの敵も下端に余白を空ける"
	)


func _create_custom_texture() -> Texture2D:
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	return ImageTexture.create_from_image(image)


func _same_pixel(
	first: Image,
	second: Image,
	first_position: Vector2i,
	second_position: Vector2i
) -> bool:
	return first.get_pixelv(first_position).is_equal_approx(second.get_pixelv(second_position))


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyShapeTextureTest: %s" % message)
