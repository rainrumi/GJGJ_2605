# HPダメージ・蘇生回復UI順次表示 Godot 実装計画

## 目的

- 悪夢の攻撃でHPが0になり、直後に蘇生回復が発生した場合も、HPダメージUIと回復UIを既存テンポで同時に縦並び表示する。

## 受入条件

- [x] ダメージUIと蘇生回復UIを既存のTween時間で同時に表示する。
- [x] ダメージUIを上、蘇生回復UIを下にして、HPバーの上へ重ならずに表示する。
- [x] 表示を終えた両UIを既存テンポで解放する。

## 現状調査

### Project

- Godot version: `project.godot`は4.6、検証環境は4.6.2。
- Script language: GDScript。
- Main Scene: `res://scene/main/main.tscn`。
- Autoload: `GameSettings`、`DebugState`、`MouseDragState`。今回の変更対象外。
- Test / CI: SceneTree形式の独自テスト。標準検証スクリプトはリポジトリ内に存在しないため、Godot CLIを直接使用する。

### 関連ファイル

- Scene: `res://scene/main/game/game.tscn`、`res://scene/ui/hp/hp.tscn`
- Script: `res://scene/main/game/game.gd`、`res://scene/ui/battle_ui/battle_ui.gd`、`res://scene/ui/hp/hp_view.gd`
- Test: `res://tests/hp_revive_recovery_popup_test.gd`
- Resource / Data、ProjectSettings / InputMap: 変更なし。

### 現在の責務とデータフロー

- `Game`は悪夢のダメージ値表示を`BattleUI.show_hp_damage_values()`へ要求した後、HPが0なら`_apply_elapsed_time()`で蘇生HPを計算して`BattleUI.set_hp()`へ渡す。
- `BattleUI`は両要求を所有する`HpView`へ中継する。
- `HpView`はダメージLabelと回復Labelを同じ基準座標へ追加し、独立したTweenを即時再生しているため、同フレームの要求が同じ座標で重なる。

## 設計判断

- 採用案: `HpView`をHP増減ポップアップの単一所有者とし、表示中Labelごとに位置調整用Controlを持たせ、新しい表示が加わるたび既存表示を上へ積む。
- 既存方式へ合わせる点: 既存のLabel生成、スタイル、位置、Tween時間、`queue_free()`を維持する。
- 採用しなかった案: 表示をFIFOで直列化すると既存テンポが変わるため採用しない。回復Labelだけ固定座標をずらす案は、同時表示が3件以上になった場合に再び重なるため採用しない。
- Scene / Node / Resource / Autoloadの所有関係: `HpView`のruntime生成Labelだけを変更し、Scene構造、Resource、Autoloadは変更しない。

## 影響範囲

- Authoring変更: なし。
- Runtime変更: HPダメージ・回復ポップアップを同時再生し、要求順に上から下へ縦並びする。
- Data / Serialization、ProjectSettings / InputMap、Migration: なし。

## 実装 TODO

- [x] `hp_view.gd`へ表示中ポップアップの位置調整用Controlと完了処理を追加する。
- [x] ダメージ表示と回復表示を共通の縦積み処理へ通し、Tweenは同時再生する。
- [x] `hp_revive_recovery_popup_test.gd`へ両UIの同時表示、縦並び、既存時間内の解放を確認する回帰テストを追加する。

## 検証 TODO

- [x] `git diff --check` と差分scopeを確認する。
- [x] Godot headless importを実行する。
- [x] 変更GDScriptをparseする。
- [x] `tests/hp_revive_recovery_popup_test.gd`を実行する。
- [x] `tests/all_gdscript_parse_test.gd`を実行する。
- [x] `res://scene/main/game/game.tscn`をheadless起動し、初期化エラーがないことを確認する。
- [x] ログ全文から新規errorがないことを確認する。
- [ ] 実機表示でダメージ→蘇生回復の順序と見た目を確認する。

## リスクと切り分け

- Risk: 位置調整でLabel自身のTween座標を上書きし、浮上演出が乱れる。
  - Detection: 回帰テストでLabelのglobal位置関係と両Labelの同時解放を確認する。
  - Mitigation: 縦積み位置は親Control、浮上Tweenは子Labelに分離する。

## 完了時の報告事項

- 変更内容
- 実行した検証commandと対象
- failureと解消内容
- 未検証事項と残リスク
