# ふわふわ学校挑戦後のエリア選択 Godot 実装計画

## 目的

- 4日ごとのボス選択でふわふわ学校へ挑戦しても、挑戦前にいた通常エリアを現在地として翌日のエリア候補を生成できるようにする。

## 受入条件

- [x] ふわふわ学校を戦闘対象として選択しても、挑戦前の通常エリア情報が保持される。
- [x] 挑戦後のステージ選択は、保持した通常エリアの `reachable_stage_areas` を参照する。
- [x] 通常エリアを選択した場合は、そのエリアが新しい現在地になる。
- [x] 既存の戦闘対象、進行記録、報酬対象には選択したふわふわ学校の `StageInfo` が渡る。

## 現状調査

### Project

- Godot version: `project.godot` の feature は Godot 4.6。
- Script language: GDScript。
- Main Scene: `res://scene/main/main.tscn`。
- Autoload: `GameSettings`、`DebugState`。
- Test / CI: 独自の `SceneTree` テスト。標準検証スクリプトは文書上指定されているが、`scripts/` 配下に実体がない。

### 関連ファイル

- Scene: `scene/main/main.tscn`、`scene/main/stage_select/stage_select.tscn`。
- Script: `scene/main/main.gd`、`scene/main/run_state.gd`、`scene/main/stage_select/stage_select.gd`、`scene/main/stage_select/stage_selection_service.gd`。
- Resource / Data: `data/resources/area/area_huwahuwa/area_huwahuwa.tres`、`data/info/stage/stage_info.gd`。
- ProjectSettings / InputMap: 変更なし。

### 現在の責務とデータフロー

- `Main` が `StageSelect.stage_selected` を受け、`RunState.selected_stage` を戦闘対象と次回選択時の現在地の両方に使っている。
- `StageSelectionService` は通常日に現在地の `reachable_stage_areas` から候補を作る。
- ふわふわ学校は一時的な高難度専用ステージであり、`reachable_stage_areas` を持たない。

## 確定事項

- ふわふわ学校の `stage_area` は `StageInfo.StageArea.huwahuwaSchool`、`has_normal_stage` は `false`。
- 戦闘、クリア記録、報酬には `RunState.selected_stage` が使われるため、この値は挑戦先のまま維持する必要がある。

## 仮定・未確定事項

- 「挑戦後」は勝敗のどちらも含む。どちらの導線も翌日の `show_stage_select()` に合流するため、現在地を独立保持すれば同じ挙動になる。

## 設計判断

- 採用案: `RunState` に戦闘対象とは別の通常エリア現在地を保持し、ふわふわ学校選択時だけ更新しない。
- 既存方式へ合わせる点: 新規 Autoload や Scene 変更は行わず、既存 `RunState` と `StageSelectionService` の責務を維持する。
- 採用しなかった案と理由: ふわふわ学校 Resource に全エリアの到達先を設定すると、挑戦元ごとの移動契約を失うため採用しない。
- Scene / Node / Resource / Autoloadの所有関係: runtime の現在地は `RunState` が所有し、Resource 定義は変更しない。

## 影響範囲

- Authoring変更: なし。
- Runtime変更: ステージ選択時の現在地更新と、候補生成へ渡す現在地を分離する。
- Data / Serialization: runtime `Resource` のみ。保存形式変更なし。
- ProjectSettings / InputMap: なし。
- 互換性 / Migration: 新規ゲーム開始時に初期ステージを現在地へ設定する。

## 実装 TODO

- [x] `scene/main/run_state.gd` に通常エリア現在地とステージ選択APIを追加する。
- [x] `scene/main/main.gd` から新APIを使い、選択肢生成には通常エリア現在地を渡す。
- [x] ふわふわ学校選択後も元エリアの到達候補が得られる回帰テストを追加する。

## 検証 TODO

- [x] `git diff --check` と差分scopeを確認する。
- [x] Godot headless importを実行する。
- [x] 変更GDScriptをparseする。
- [x] 回帰テストと全GDScript読込テストを実行する。
- [x] `res://scene/main/main.tscn` をheadless smoke実行する。
- [x] log全文を確認し、全コマンド共通の終了時Resource leak以外に新規errorがないことを確認する。

## リスクと切り分け

- Risk: 初期現在地が未設定だと全通常ステージが候補になる。
  - Detection: 新規ゲーム初期化のテストと Main Scene smoke で確認する。
  - Mitigation: 既存の初期ステージ設定処理も同じ選択APIを通す。

## 完了時の報告事項

- 変更内容
- 実行した検証commandと対象
- failureと解消内容
- 未検証事項と残リスク
