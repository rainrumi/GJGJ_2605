# デバッグ種一覧 Godot 実装計画

## 目的

- デバッグ中に全種から任意の種を取得し、種バッグから任意の所持種を削除できるようにする。

## 受入条件

- [ ] デバッグ有効時だけ「種一覧」ボタンが表示され、押すと既存デバッグ画面と同様のパネルが開く。
- [ ] `seed_catalog.tres` の全種が、種バッグと同じ30px角、10px間隔、横5列で縦方向に表示される。
- [ ] 一覧の種を左クリックすると所持種へ追加され、UIと種効果状態が同期される。
- [ ] デバッグ有効時、種バッグ内の種を右クリックすると、その枠の種だけが削除される。
- [ ] デバッグ無効化時は一覧を閉じ、種バッグの右クリック削除を受け付けない。

## 現状調査

### Project

- Godot version: 4.6
- Script language: GDScript
- Main Scene: `res://scene/main/main.tscn`
- Autoload: `GameSettings`, `DebugState`, `MouseDragState`
- Test / CI: 独自Scene test。標準検証スクリプトは文書に記載されているが、このcheckoutには未配置。

### 関連ファイル

- Scene: `debug_panel.tscn`, `owned_seed_panel.tscn`, `seed_button.tscn`
- Script: `debug_panel.gd`, `battle_ui.gd`, `game.gd`, `game_seed_controller.gd`, `owned_seed_panel.gd`, `seed_button.gd`, `seed_button_list.gd`
- Resource / Data: `data/resources/seeds/seed_catalog.tres`
- ProjectSettings / InputMap: 変更なし

### 現在の責務とデータフロー

- `DebugPanel` がデバッグ操作UIを所有し、`BattleUI` がsignalを中継して `Game` が操作を検証する。
- `GameSeedController` が装備・所持種のruntime状態を所有し、変更後に `Game._sync_seed_sources()` がUIと効果resolverを同期する。
- `SeedButtonList` が `SeedButton` を動的生成し、種バッグも同じ部品を30px角・10px間隔で利用している。

## 確定事項

- 全種の定義元は `seed_catalog.tres` のrarity別配列である。
- 装備上限は6個。既存デバッグ追加は空きがあれば装備、満杯なら所持へ追加する。
- `SeedButton` の右クリックは現在、デバッグ性能チェックに使われる。

## 仮定・未確定事項

- 「取得」は既存のデバッグ種追加と同じく、装備枠に空きがあれば装備、なければ所持へ追加する。
- 種バッグ内では削除を性能チェックより優先し、一覧など他の種ボタンでは既存の性能チェックを維持する。

## 設計判断

- 採用案: `SeedButtonList` を再利用する専用デバッグパネルをSceneとして追加し、取得・削除要求を既存signal経路で `GameSeedController` へ渡す。
- 既存方式へ合わせる点: 固定パネルはScene authoring、可変個数の種ボタンはruntime生成、状態更新はcontrollerへ集約する。
- 採用しなかった案と理由: `Game` からUI階層を直接探索・変更すると既存の責務分割を崩すため採用しない。
- 所有関係: `DebugPanel` が種一覧パネルを所有し、`OwnedSeedPanel` がバッグ内削除入力を所有する。

## 影響範囲

- Authoring変更: デバッグ種一覧Sceneと、`DebugPanel` 内のボタン・パネルinstance。
- Runtime変更: 任意種追加、指定inventory枠削除、関連signal中継。
- Data / Serialization: 既存catalogを読み取るのみ。
- ProjectSettings / InputMap: 変更なし。
- 互換性 / Migration: save schema変更なし。

## 実装 TODO

- [ ] `debug_all_seed_panel.tscn/.gd` に全種を5列表示し、クリック取得要求を送るパネルを追加する。
- [ ] `DebugPanel` と `BattleUI` に一覧開閉・取得signalを接続する。
- [ ] `SeedButton` / `SeedButtonList` / `OwnedSeedPanel` に、バッグ内だけ有効なデバッグ右クリック削除要求を追加する。
- [ ] `GameSeedController` に任意種追加と枠指定削除APIを追加し、`Game` で状態同期する。
- [ ] 一覧layout、取得、削除、デバッグ無効時の境界を関連testへ追加する。

## 検証 TODO

- [ ] `git diff --check` と差分scopeを確認する。
- [ ] 利用可能なGodot binaryを確認し、headless importと変更GDScript parseを実行する。
- [ ] デバッグUI・種inventoryの関連testを実行する。
- [ ] `res://scene/main/game/game.tscn` をsmoke実行し、初期化errorがないことを確認する。
- [ ] 640x360で一覧の5列配置、スクロール、左クリック取得、バッグ右クリック削除を確認する。
- [ ] log全文から新規errorがないことを確認する。

## リスクと切り分け

- Risk: 右クリック削除が既存性能チェックと競合する。
  - Detection: バッグ内・一覧内の右クリックを個別testする。
  - Mitigation: バッグが明示的に削除モードを設定したボタンだけ削除signalを優先する。
- Risk: 同一Resourceを複数所持した場合に別枠を削除する。
  - Detection: 重複種を配置して後方枠を削除するtestを行う。
  - Mitigation: Resource検索ではなくcollectionと表示ページ込みslot indexで削除する。

## 完了時の報告事項

- 変更内容
- 実行した検証commandと対象
- failureと解消内容
- 未検証事項と残リスク

## 追補: SeedButtonサイズのScene集約

- [x] `seed_button.tscn` を30×30で保存し、FrameとIconの配置もScene上で確定する。
- [x] `SeedButton` / `SeedButtonList` からruntimeのサイズ変更APIを削除する。
- [x] 戦闘一覧、種バッグ、デバッグ一覧は余白のみコード設定し、ボタンサイズはSceneをそのまま使う。
- [x] 関連UIテストとsmokeで30×30および5列配置が維持されることを確認する。
