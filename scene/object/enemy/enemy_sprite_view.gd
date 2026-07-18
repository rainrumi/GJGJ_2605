class_name EnemySpriteView
extends Sprite2D

const HOVER_SCALE := 1.1
const HOVER_TWEEN_DURATION := 0.1
const DAMAGE_PULSE_SCALE := 1.12
const DAMAGE_PULSE_DURATION := 0.18
const ACIDED_SCALE := 1.2
const ACIDED_TWEEN_DURATION := 0.5
const CELL_INSET_PIXELS := 1

var base_scale := Vector2.ONE
var _hover_tween: Tween
var _damage_pulse_tween: Tween
var _Acided_tween: Tween
var _hovered := false


# セル形状画像生成
static func create_shape_texture(
	cell_texture: Texture2D,
	shape_size: Vector2i,
	shape: Array[Vector2i]
) -> Texture2D:
	if cell_texture == null:
		return null
	var cell_image := cell_texture.get_image() # セル画像
	if cell_image == null or cell_image.is_empty():
		return null
	cell_image.convert(Image.FORMAT_RGBA8)
	var safe_shape_size := Vector2i(maxi(1, shape_size.x), maxi(1, shape_size.y))
	var cell_size := cell_image.get_size() # セル画像寸法
	var texture_size := Vector2i(
		cell_size.x * safe_shape_size.x,
		cell_size.y * safe_shape_size.y
	)
	var shape_image := Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	shape_image.fill(Color.TRANSPARENT)
	var cell_rect := Rect2i(Vector2i.ZERO, cell_size)
	for cell: Vector2i in shape:
		var is_outside_shape := (
			cell.x < 0
			or cell.x >= safe_shape_size.x
			or cell.y < 0
			or cell.y >= safe_shape_size.y
		)
		if is_outside_shape:
			continue
		var cell_position := Vector2i(cell.x * cell_size.x, cell.y * cell_size.y)
		var cell_center_twice := cell_position * 2 + cell_size
		var center_direction := Vector2i(
			signi(texture_size.x - cell_center_twice.x),
			signi(texture_size.y - cell_center_twice.y)
		)
		cell_position += center_direction * CELL_INSET_PIXELS
		shape_image.blend_rect(
			cell_image,
			cell_rect,
			cell_position
		)
	_clear_outer_margin(shape_image, texture_size)
	return ImageTexture.create_from_image(shape_image)


# 個体外周余白設定
static func _clear_outer_margin(shape_image: Image, texture_size: Vector2i) -> void:
	shape_image.fill_rect(
		Rect2i(0, 0, texture_size.x, CELL_INSET_PIXELS),
		Color.TRANSPARENT
	)
	shape_image.fill_rect(
		Rect2i(0, 0, CELL_INSET_PIXELS, texture_size.y),
		Color.TRANSPARENT
	)
	shape_image.fill_rect(
		Rect2i(0, texture_size.y - CELL_INSET_PIXELS, texture_size.x, CELL_INSET_PIXELS),
		Color.TRANSPARENT
	)
	shape_image.fill_rect(
		Rect2i(texture_size.x - CELL_INSET_PIXELS, 0, CELL_INSET_PIXELS, texture_size.y),
		Color.TRANSPARENT
	)


# 画像設定
func setup_texture(next_texture: Texture2D, target_size: Vector2) -> void:
	texture = next_texture
	if texture == null:
		return
	scale = target_size / texture.get_size()
	base_scale = scale


# 表示サイズ更新
func update_display_size(target_size: Vector2) -> void:
	if texture == null:
		return
	scale = target_size / texture.get_size()
	base_scale = scale


# ホバー設定
func set_hovered(value: bool) -> void:
	if _hovered == value:
		return
	_hovered = value
	_kill_hover_tween()
	var target_scale := base_scale
	if _hovered:
		target_scale *= HOVER_SCALE
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_QUAD)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", target_scale, HOVER_TWEEN_DURATION)


# 被弾強調
func pulse_damage() -> void:
	if _damage_pulse_tween != null and _damage_pulse_tween.is_valid():
		_damage_pulse_tween.kill()
	_damage_pulse_tween = create_tween()
	_damage_pulse_tween.set_trans(Tween.TRANS_QUAD)
	_damage_pulse_tween.set_ease(Tween.EASE_OUT)
	_damage_pulse_tween.tween_property(self, "scale", base_scale * DAMAGE_PULSE_SCALE, DAMAGE_PULSE_DURATION * 0.5)
	_damage_pulse_tween.tween_property(self, "scale", base_scale, DAMAGE_PULSE_DURATION * 0.5)


# 消化演出
func play_Acided_tween(enemy_root: Node2D) -> void:
	stop_Acided_tween()
	_kill_hover_tween()
	_hovered = false
	enemy_root.visible = true
	enemy_root.scale = Vector2.ONE
	enemy_root.modulate.a = 1.0
	_Acided_tween = create_tween()
	_Acided_tween.set_parallel(true)
	_Acided_tween.set_trans(Tween.TRANS_QUART)
	_Acided_tween.set_ease(Tween.EASE_OUT)
	_Acided_tween.tween_property(enemy_root, "scale", Vector2.ONE * ACIDED_SCALE, ACIDED_TWEEN_DURATION)
	_Acided_tween.tween_property(enemy_root, "modulate:a", 0.0, ACIDED_TWEEN_DURATION)
	_Acided_tween.chain().tween_callback(func() -> void: enemy_root.visible = false)


# 消化演出停止
func stop_Acided_tween() -> void:
	if _Acided_tween != null and _Acided_tween.is_valid():
		_Acided_tween.kill()


# 見た目初期化
func reset_visuals(enemy_root: Node2D) -> void:
	_kill_hover_tween()
	if _damage_pulse_tween != null and _damage_pulse_tween.is_valid():
		_damage_pulse_tween.kill()
	stop_Acided_tween()
	_hovered = false
	enemy_root.scale = Vector2.ONE
	enemy_root.modulate.a = 1.0
	scale = base_scale


# ホバー停止
func _kill_hover_tween() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
