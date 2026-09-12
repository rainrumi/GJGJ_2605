# 調査根拠と検証結果

## 参照した正本

- ステージ一覧・接続：`data/resources/area/stage_catalog.tres`、各 `area_*.tres`
- 敵編成：各エリアの `area_*_enemy.tres` と `enemy/{normal,boss,endless}/*_preset.tres`
- 消化・時間：`scene/main/game/enemy/resolver/enemy_digestion_resolver.gd`、`enemy_turn_processor.gd`、`scene/main/game/game.gd`
- 胃袋判定：`scene/object/stomach/stomach_board.gd` の `get_bottom_row_cell_count()`、`EnemyEffectTargetQuery`
- 夢の種：`scene/main/game/seed/skill/seed_effect_resolver.gd`、`data/resources/seeds/skills/*.tres`
- 生成：`scene/main/game/controller/enemy/game_enemy_setup_controller.gd`、`scene/main/game/enemy/model/enemy_spawn_queue.gd`

## 確認したルール

- 基準消化は `EnemyController.ACID_DAMAGE=50`、基準進行は30分。
- 初期胃袋は `RunState.DEFAULT_STOMACH_COLUMNS=4`、`DEFAULT_STOMACH_ROWS=5`、消化ラインは1行。
- 敵は胃袋外では通常攻撃対象にならず、胃袋内かつ有効化された個体だけが消化・攻撃へ参加する。
- 消化ライン接触セル数が消化ダメージへ掛かる。形状の回転と底への配置が基本手順になる。
- 手動吐き戻しの標準被弾率は `REMOVE_FROM_STOMACH_DAMAGE_RATE=0.05`。トコンの現行メイン値は50%。
- 装備上限は `MAX_EQUIPPED_SEEDS=6`。種を胃袋へ投入するとサブスキル使用回数を1消費し、消化済みソースは枯渇処理へ回る。
- `EnemySpawnQueue` の `max_spawn_count` は効果インスタンスごとの上限。生成セルは `SAME_CELLS`、`EMPTY_ADJACENT` などの範囲と空きセルで決まる。

## 実行した検証

| コマンド | 結果 | 検出範囲・残り |
|---|---|---|
| `Godot_v4.6.2-stable_win64.exe --headless --path . --import` | 終了コード0 | Resource import完了。既存の無効UID警告と終了時2リソース解放エラーが出る。今回の文書追加によるparse errorはなし |
| `--headless --path . --script tests/enemy_effect_stomach_activation_test.gd` | 終了コード0 | 効果の有効化条件。ログ上の失敗なし |
| `--headless --path . --script tests/rtg_n4_spawn_position_test.gd` | 終了コード0 | RTG-N-4の生成HP（48/32/16）、元セル、HP0で停止。既存UID警告と終了時解放エラーあり |
| `--headless --path . --script tests/enemy_digestion_resolver_test.gd` | 終了コード0だがログにSCRIPT ERROR | テスト側がResolver依存をsetupしない既存問題（Nilの `record_damaged_object`）。攻略文書の変更原因ではないため修正していない。成功扱いにしない |

Godot実行ログには既存の `invalid UID` 警告、`ObjectDB instances leaked`、`2 resources still in use at exit` が含まれる。これらは今回追加したMarkdownとは無関係だが、プロジェクト全体がエラーなしとは報告しない。

## 未検証・残リスク

- 全ステージの全配置・全装備・乱数を探索していないため、U/T/Dの数値は最適性の証明ではない。
- 実機のマウス操作、回転、落下、表示時刻、視覚的な被弾表示は未確認。headlessテストは視覚・入力の代替にならない。
- オトギリソウ、ノイバラ、復活・無効化・増殖の同一ターン解決順は、対象編成ごとにログを取りながら再確認する。
- 空の敵配列を持つふわふわ学校・エンドレスと、ステージ定義がないその他エリアは攻略対象外。敵データ追加後に再計算する。
