class_name DebugAllSeedPanel
extends PanelContainer

signal seed_acquisition_requested(seed: SeedInfo)

const SLOT_SEPARATION := 10
const SEED_TEXTURE_COLOR := Color("f0e0ff")

@export var seed_catalog: SeedCatalogInfo

@onready var seed_list: SeedButtonList = %SeedList
@onready var close_button: Button = %CloseButton


# 初期化
func _ready() -> void:
	seed_list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	seed_list.set_slot_separation(SLOT_SEPARATION)
	seed_list.set_loadout_edit_enabled(true)
	seed_list.set_debug_numbers_visible(true)
	seed_list.set_display_style(true, SEED_TEXTURE_COLOR)
	seed_list.set_seed_sources(_get_all_seeds())
	seed_list.loadout_edit_requested.connect(_on_seed_acquisition_requested)
	close_button.pressed.connect(close_panel)


# panel表示
func open_panel() -> void:
	visible = true


# panel非表示
func close_panel() -> void:
	visible = false


# 全種取得
func _get_all_seeds() -> Array[SeedInfo]:
	var seeds: Array[SeedInfo] = []
	if seed_catalog == null:
		push_error("DebugAllSeedPanel: seed_catalogが設定されていません")
		return seeds
	seeds.append_array(seed_catalog.normal_skills)
	seeds.append_array(seed_catalog.rare_skills)
	seeds.append_array(seed_catalog.epic_skills)
	return seeds


# 種取得要求
func _on_seed_acquisition_requested(_button: SeedButton, seed: SeedInfo) -> void:
	if not DebugState.debug_enabled or seed == null:
		return
	seed_acquisition_requested.emit(seed)
