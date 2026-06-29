class_name StageSelectDebugSeedPoolPanel
extends PanelContainer

const MAX_FONT_SIZE := 7
const MIN_FONT_SIZE := 4
const VISIBLE_LINE_BUDGET := 52
const NAME_COLOR := "#ff4040"

@onready var title_label: Label = $Margin/Items/TitleLabel
@onready var seed_pool_text: RichTextLabel = $Margin/Items/DebugSeedScroll/SeedPoolText

var _hovered_stage_definition: StageInfo


# 初期化
func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not DebugState.debug_enabled_changed.is_connected(_on_debug_enabled_changed):
		DebugState.debug_enabled_changed.connect(_on_debug_enabled_changed)


# 対象設定
func set_stage(stage_definition: StageInfo) -> void:
	_hovered_stage_definition = stage_definition
	_update_panel()


# 変更処理
func _on_debug_enabled_changed(_is_enabled: bool) -> void:
	_update_panel()


# panel更新
func _update_panel() -> void:
	seed_pool_text.text = ""
	if not DebugState.debug_enabled or _hovered_stage_definition == null:
		visible = false
		return
	title_label.text = "%s" % _hovered_stage_definition.location
	var seeds := _get_seed_pool_skills(_hovered_stage_definition)
	seed_pool_text.text = _get_seed_pool_text(seeds)
	_apply_seed_pool_text_size(seeds)
	visible = true


# 種pool取得
func _get_seed_pool_skills(stage_definition: StageInfo) -> Array[SeedInfo]:
	var seeds: Array[SeedInfo] = []
	if stage_definition == null or stage_definition.drop_seed_pool == null:
		return seeds
	for seed in stage_definition.drop_seed_pool.get_all_skills():
		if seed != null:
			seeds.append(seed)
	return seeds


# 種pool文言取得
func _get_seed_pool_text(seeds: Array[SeedInfo]) -> String:
	if seeds.is_empty():
		return "No seed pool"
	var blocks: Array[String] = []
	for seed in seeds:
		blocks.append(_get_seed_pool_item_text(seed))
	return "\n".join(blocks)


# 文言サイズ適用
func _apply_seed_pool_text_size(seeds: Array[SeedInfo]) -> void:
	var font_size := MAX_FONT_SIZE
	var line_count := _get_estimated_line_count(seeds)
	if line_count > VISIBLE_LINE_BUDGET:
		font_size = max(
			MIN_FONT_SIZE,
			floori(float(MAX_FONT_SIZE) * float(VISIBLE_LINE_BUDGET) / float(line_count))
		)
	seed_pool_text.add_theme_font_size_override("normal_font_size", font_size)


# 行数見積もり
func _get_estimated_line_count(seeds: Array[SeedInfo]) -> int:
	if seeds.is_empty():
		return 1
	var line_count := 0
	for seed in seeds:
		line_count += 2
		line_count += _get_wrapped_extra_line_count(SeedDescription.get_main_description(seed), 74)
		if SeedDescription.has_sub_skill(seed):
			line_count += _get_wrapped_extra_line_count(SeedDescription.get_sub_description(seed), 74)
	return line_count


# 折返し行数
func _get_wrapped_extra_line_count(text: String, characters_per_line: int) -> int:
	var text_length := text.strip_edges().length()
	if text_length <= characters_per_line:
		return 0
	return int(floori(float(text_length - 1) / float(characters_per_line)))


# 種item文言
func _get_seed_pool_item_text(seed: SeedInfo) -> String:
	var lines: Array[String] = [
		"%s  ID:%d" % [_get_seed_title_text(seed), seed.skill_id],
		"M:%s" % _get_bbcode_text(SeedDescription.get_main_description(seed)),
	]
	if SeedDescription.has_sub_skill(seed):
		lines.append("S:%s" % _get_bbcode_text(SeedDescription.get_sub_description(seed)))
	return "\n".join(lines)


# 種名文言
func _get_seed_title_text(seed: SeedInfo) -> String:
	var seed_name := ""
	if seed != null:
		seed_name = _get_bbcode_text(seed.display_name)
	var colored_name := "[color=%s]%s[/color]" % [NAME_COLOR, seed_name]
	if seed != null and seed.rarity == SeedInfo.Rarity.RARE:
		return "%s [lb]Rare]" % colored_name
	return colored_name


# bbcode文言
func _get_bbcode_text(text: String) -> String:
	return text.replace("[", "[lb]")
