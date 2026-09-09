# resource/TODO.md 実装状況（2026-09-09）

状態: Partial。消化数の仕様とエルメナのシナリオ指定を確認中。

## 実装した範囲

- Mainの既存NovelFlowに交流・報酬メッセージの遷移を追加。ステージ解放ノベル→交流→報酬→戦闘の順に実行する。
- RunStateに直前エリア、日ごとの初回交流、周回内の既読エリア履歴を保持する。ニューゲームで初期化する。
- コロッタ、フェリス、ゴンサル、ミルネ、ネリクス、ザイカの初回エリア会話を優先し、それ以外はcommon 001〜008。同日2回目以降はfalse 001。
- 初回のみHP回復33%、種67%。回復量50/80/100%は等確率、最大HPに対する加算として既存回復方式に合わせる。
- LaraRewardは既存ステージカタログの出現プールを集め、種IDの重複と既存所持制限を考慮する。種は所持枠へ追加する。
- 新規Autoload、ProjectSettings、Scene階層の変更はない。

## 未完了と確認事項

- ラーラの消化数の初期値・増加タイミング・増加量がTODOにも現行RunStateにもない。
- プレイヤーの「悪夢消化数」をステージ勝利数とするか、戦闘内の敵消化数とするか確認中。勝負・表示・エンディングの条件に影響する。
- エルメナ用の交流ファイルがなく、eramiaの本文はエラミア区について書かれている。代用の可否を確認中。現段階ではエルメナはcommonへ進むため、要求未達。
- 勝負ノベル・勝負報酬・消化数HUD・エンディング分岐は未実装。
- 交流ファイルは実ファイルに合わせて拡張子なしを参照。export設定がないため、製品ビルドへのシナリオ同梱は未検証。

## 検証

Godot: `C:/Program Files/Godot/Godot_v4.6.2-stable_win64.exe`。
WindowsではStart-Process -WindowStyle Hidden -Wait -PassThruで終了コードを取得。
全コマンドはプロジェクトルートで実行し、`--log-file .godot/agent-*.log`で記録。

| 引数・コマンド | 結果 |
|---|---|
| `git diff --check` | 成功 |
| `--headless --path . --import` | exit 0。ただし終了時Resource残留エラーあり |
| `--headless --path . --script res://tests/lara_reward_test.gd` | exit 0、0 failures |
| `--headless --path . --script res://tests/main_lara_interaction_test.gd --quit-after 1200` | exit 0、0 failures |
| `--headless --path . --script res://tests/run_state_lara_test.gd` | exit 0、テスト失敗なし |
| `--headless --path . --script res://tests/main_stage_selection_novel_test.gd` | exit 0、テスト失敗なし |
| `--headless --path . --script res://scene/main/main.gd --check-only` | exit 1。Autoload DebugStateを単体parseで解決できない。Mainをロードする上記テストでコンパイルと実行経路を確認 |
| `--headless --path . --quit-after 120` | Main Scene起動はexit 0。終了時Resource残留エラーあり |

ログ全体を確認。各実行で終了時のObjectDB leak / resources still in useが発生しており、エラーなしとは判定しない。既存テストでも同種のエラーが再現するが、変更前の別checkoutとの比較は未実施。既存seedプール等のinvalid UID警告はpathでロードされる。今回UID参照は変更していない。

追加テストの型推論エラーはPackedScene型の指定で修正。テスト用ステージを現行カタログにないIDから取得していた問題は、既存Resourceの明示ロードと有効な行先IDに修正し再実行した。

標準検証スクリプト `scripts/Validate-Godot.ps1` / `scripts/validate-godot.sh` は未配置。formatter/linter設定なし。目視・実入力確認、export、全テストsuiteは未実施。
