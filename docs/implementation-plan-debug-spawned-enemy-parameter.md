# 生成される悪夢のデバッグ編集 実装計画

## 目的と受入条件

- 悪夢デバッグパネルで、ステージ初期配置の悪夢に加え、そのスキルから生成される寄生型悪夢を選択できる。
- 生成される悪夢の説明、HP、攻撃力、Effect の公開数値・真偽値を既存と同じUIで編集できる。
- 生成先が親 `.tres` 内のサブResourceでも、親悪夢Resourceへ保存され、現在の戦闘へ反映される。
- 連鎖生成と循環参照で選択肢が無限増殖しない。

## 現状と設計判断

- `DebugEnemyParameterPanel` は `EnemyPresetInfo.enemies` の直下だけを列挙し、選択した `EnemyInfo` 自体の `resource_path` へ保存している。
- 生成先は `EnemySkill.effects` 内の export 済み `EnemyInfo` (`enemy_info` / `next_enemy_info`) として保持され、多くは親悪夢Resource内のサブResourceである。
- 新しい敵種別やAutoloadは追加しない。パネルがEffectの公開Resourceプロパティを走査し、親から生成先までのプロパティ経路を保持する。
- 編集時は親悪夢を `duplicate(true)` し、同じ経路にある生成先を編集する。保存と既存signalによる置換の対象は親悪夢とする。

## 実装TODO

- [x] 初期悪夢と生成先を再帰列挙し、表示名と親からの経路を保持する。
- [x] 親悪夢の複製から経路先を解決し、既存パラメーター行を構築する。
- [x] 複製した親悪夢を親の `resource_path` へ保存し、親の置換signalを通知する。
- [x] 生成先の列挙・編集・永続化・親置換を自動テストする。

## 検証TODO

- [x] `git diff --check`
- [x] 標準scriptが未配置のため、Godot 4.6.2でimport・全GDScript parse・Main Scene smokeを個別実行
- [x] `res://tests/debug_enemy_parameter_panel_test.tscn` の実行とログ確認
- [ ] UIの選択肢とレイアウト確認
