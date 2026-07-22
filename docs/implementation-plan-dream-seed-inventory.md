# 夢の種 装備枠・所持枠 Godot 実装計画

## 目的

- 夢の種を、メインスキルが有効な6個上限の装備枠と、効果が無効な無制限の所持枠へ分離する。
- `game.tscn` 上で編成、全所持種のページ閲覧、胃袋へのドラッグ、パネル開閉を行えるようにする。

## 受入条件

- [ ] 装備枠は6枠固定で、装備中の種だけがメインスキル計算に使われる。
- [ ] 所持枠に個数上限はなく、16個単位で前後ページを移動できる。
- [ ] 所有種パネル内の装備枠・所持枠を短押しして編成を変更できる。
- [ ] 両方の枠から夢の種を胃袋へドラッグでき、所持中の種はメインスキル計算に使われない。
- [ ] 全ての表示状態で従来の夢の種ツールチップを表示できる。
- [x] 所有種パネルの装備・所持見出しから、それぞれの効果状態をツールチップで確認できる。
- [ ] パネルを閉じると、装備中の種をキャラクター頭部に重ねてテクスチャのみで表示し、そこからもドラッグできる。
- [ ] 装備・所持状態が戦闘、ステージクリア報酬、次戦闘へ引き継がれる。
- [x] パネル展開中は背景の透明度を維持しつつ、種がある装備枠・所持枠を完全不透明で表示する。
- [x] パネル展開中の装備枠・所持枠を30px角とし、左右21px・枠間10pxで表示する。
- [x] 所持枠の16枠を横4列・縦4行で表示する。
- [x] 装備枠の下端と所持枠の上端の間に、見出しを含む30px以上の縦余白を設ける。
- [x] 薄いピンク色は`#f0e0ff`へ統一し、種がない枠は透明な内側と1pxの縁だけで表示する。

## 現状調査

### Project

- Godot version: 4.6（`project.godot` の feature）
- Script language: GDScript
- Main Scene: `res://scene/main/main.tscn`
- Autoload: `GameSettings`, `DebugState`
- Test / CI: 独自 `SceneTree` テスト。標準検証Scriptの実体と `.agent/godot-agent.env` は未配置。

### 関連ファイル

- Scene: `scene/main/game/game.tscn`, `scene/ui/seed/seed_button.tscn`, `scene/main/stage_clear/stage_clear.tscn`
- Script: `game.gd`, `battle_ui.gd`, `game_seed_controller.gd`, `seed_button.gd`, `seed_button_list.gd`, `main.gd`, `run_state.gd`, `stage_clear.gd`
- Resource / Data: `battle_info.gd`, `SeedInfo`
- ProjectSettings / InputMap: 変更なし

### 現在の責務とデータフロー

- `RunState.planted_flowers` と `StageClear.planted_flowers` が全所持種と有効種を兼ねる。
- `BattleInfo.flowers` を通して `GameSeedController` へ渡し、同じ配列をHUD表示・メイン効果解決・サブスキルドラッグに使用する。
- `SeedButtonList` が可変個数の `SeedButton` を生成し、`BattleUI` と `Game` がドラッグsignalを中継する。

## 確定事項

- 装備上限は6、所持上限はなし。
- 所有種パネルの装備表示は3列2行、所持表示は4列4行・16個単位のページ式。
- 固定パネルと固定枠はSceneへ保存し、種アイコンだけ既存方式どおりruntime生成する。
- 所持枠内にある間はメイン・サブスキルとも無効だが、胃袋へ投入した後は装備枠由来と同様に既存サブスキル処理を有効にする。

## 仮定・未確定事項

- 新規取得種は、装備枠に空きがあれば自動装備し、満杯なら所持枠へ格納する。従来の即時有効化を6個まで維持するため。
- 所有種パネル内の短押しを編成操作に割り当て、閉じた装備表示の短押しは従来の回転操作を維持する。
- パネルは戦闘開始時に閉じ、専用ボタンで開き直せるようにする。

## 設計判断

- 採用案: `RunState`、`BattleInfo`、`StageClear`、`GameSeedController` が装備配列と所持配列を明示的に所有し、UIはsignalで編成要求を通知する。
- 既存方式へ合わせる点: `SeedInfo` Resource参照、`SeedButton`、子から親へのsignal中継、可変アイコンのPackedScene生成を再利用する。
- 採用しなかった案と理由: Autoload inventoryはScene遷移を所有する既存`RunState`と責務が重複するため追加しない。
- Scene / Node / Resource / Autoloadの所有関係: 固定UIは新規所有種パネルScene、run中状態は`RunState`、戦闘中の複製状態は`GameSeedController`が所有する。

## 影響範囲

- Authoring変更: 所有種パネルScene追加、`game.tscn`へパネルと開くボタンを配置、閉状態の装備表示を頭部付近へ移動。
- Runtime変更: 編成、ページ移動、開閉、装備・所持両方からのドラッグ、状態同期。
- Data / Serialization: `RunState`と`BattleInfo`へ所持配列追加。外部save schemaは存在しない。
- ProjectSettings / InputMap: なし。
- 互換性 / Migration: `flowers` / `planted_flowers` は装備配列として残し、既存呼び出しとテストを維持する。

## 実装 TODO

- [x] `seed_button.gd` / `seed_button_list.gd` を表示モードと編成短押しへ対応させる。
- [x] `scene/ui/seed/owned_seed_panel.*` に固定パネル、6装備枠、16所持枠、ページ矢印、閉じる操作を追加する。
- [x] `game.tscn` / `battle_ui.gd` に閉状態表示、パネル開閉、signal中継を追加する。
- [x] `game_seed_controller.gd` / `game.gd` に装備・所持の状態操作、効果対象分離、ドラッグ元の正確な削除を追加する。
- [x] `run_state.gd` / `battle_info.gd` / `main.gd` / `stage_clear.gd` に次画面・次戦闘への状態同期を追加する。
- [x] 装備上限、ページング、編成、効果対象、状態同期の回帰testを追加・更新する。
- [x] `seed_button.tscn` / `seed_button.gd` に種あり・空き状態別の固定StyleBoxを設定し、空き状態の切替を既存`SeedButton`内で行う。
- [x] `owned_seed_panel.gd` / `owned_seed_panel.tscn` の展開時枠を30px角へ変更し、装備3×2・所持4×3の間へ20pxの縦余白を設ける。
- [x] `seed_button.tscn` と閉状態の装備種色を`#f0e0ff`へ統一する。
- [x] `dream_seed_inventory_test.gd` に完全不透明な種あり枠、透明背景＋1px縁、30px角、左右21px・枠間10px、上下リスト間20pxの回帰確認を追加する。

## 検証 TODO

- [x] `git diff --check` と差分scopeを確認する。
- [x] project標準のformat/lint設定有無を確認する（未設定）。
- [x] Godot headless importを実行する。
- [x] 変更GDScriptと全GDScriptのparse testを実行する。
- [x] 夢の種所有・UI testと既存game/tooltip/stage-clear関連testを実行する。
- [x] `res://scene/main/game/game.tscn`をheadless起動し、初期化errorがないことを確認する。
- [x] 640x360でパネル開閉、3x2・4x3配置、ページ矢印、ツールチップ、編成、ドラッグを画面確認する。
- [x] log全文から新規errorがないことを確認する。

## リスクと切り分け

- Risk: 戦闘中の装備変更で状態蓄積型メイン効果がresetされる。
  - Detection: 既存`SeedEffectResolver.setup()`呼出箇所と戦闘イベントtestを確認する。
  - Mitigation: 現行の種消費後同期と同じ契約を維持し、表示・効果の不一致を残さない。
- Risk: 同じ`SeedInfo` Resourceを複数所持した際に別個体まで削除する。
  - Detection: 同一Resourceを複数格納したtestで一件だけ減ることを確認する。
  - Mitigation: 配列と先頭indexを明示して一件だけ移動・削除する。

## 完了時の報告事項

- 変更内容
- 実行した検証commandと対象
- failureと解消内容
- 未検証事項と残リスク
