# 夢の種パラメーター調整 UI 実装計画

## 目的と受入条件

- 戦闘中、既存の Debug モードが有効な場合だけ調整画面を開ける。
- 所持中の夢の種を選び、`main_description`、主・副スキル、酸化ブロックの公開済み数値・真偽値を変更できる。
- 調整画面は右半分に表示し、長い変数名は改行と縮小文字で判読できる。
- 編集値を現在のランへ反映し、元の夢の種 `.tres` にも保存する。
- Debug モードを解除したら調整画面と起動ボタンを閉じる。

## 現状と設計判断

- Godot 4.6 / GDScript。Main Scene は `res://scene/main/main.tscn`。
- `DebugState` がランタイム Debug 状態を所有し、`DebugPanel` が既存の Debug 操作を表示する。
- 夢の種は `SeedInfo` から `SeedSkill` / `SeedEffect` / `AcidBlockInfo` を参照する共有 Resource である。
- 固定 UI は Scene に保存し、パラメーター行だけ Resource 内容に応じて動的生成する。
- 適用時に `SeedInfo.duplicate(true)` で深く複製し、元 Resource の path へ保存してから所持スロットの対象を差し替える。

## 実装 TODO

- [x] `debug_seed_parameter_panel.tscn/.gd` に種選択、動的パラメーター行、適用・閉じる操作を追加する。
- [x] `debug_panel.tscn/.gd` に Debug 時だけ見える起動ボタンを追加し、Debug 無効化時に画面を閉じる。
- [x] `BattleUI` で所持種を調整画面へ渡し、置換要求を `Game` へ中継する。
- [x] `GameSeedController` に同一所持 Resource を複製済み Resource へ置換する API を追加する。
- [x] Debug 制限、Resource 保存、所持枠置換を自動テストする。
- [x] `debug_seed_parameter_panel.gd` の列挙対象を説明文、酸化ブロック、主・副スキルの各 Effect に限定し、`priority` / `enabled` を非表示にする。
- [x] `sub_description` と副スキル Effect の編集・保存、および不要プロパティ非表示を `debug_seed_parameter_panel_test.gd` で検証する。

## 検証 TODO

- [x] `git diff --check` と差分確認。
- [x] Godot 4.6.2 の直接実行で import / parse を確認（標準検証 Script はリポジトリに未配置）。
- [x] 関連テストで Debug 無効時の非表示、編集適用、Resource の永続化を確認。
- [x] `res://scene/main/game/game.tscn` の headless smoke とログ確認。
- [ ] 画面レイアウトと SpinBox / CheckBox 操作は実表示で確認する（利用可能な場合）。
- [x] 種パネル変更後に関連テスト、対象 Scene の headless smoke、ログ全文確認を再実行する。

## リスク

- Resource の循環参照や編集対象外プロパティ混入: `SeedSkill`、`SeedEffect`、`AcidBlockInfo` の export された数値・真偽値だけを列挙し、訪問済み Resource を追跡する。
- 同じ種が複数枠で同一 Resource を共有: 適用時は同一参照の全所持枠を同じ複製へ置換し、既存の共有意味を保つ。
