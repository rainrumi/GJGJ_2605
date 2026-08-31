E 0:02:14:258   GameEnemySetupController._setup_preset_enemies: Out of bounds get index '3' (on base: 'Array[Vector2]')
  <GDScript ソース>game_enemy_setup_controller.gd:59 @ GameEnemySetupController._setup_preset_enemies()
  <スタックトレース>    game_enemy_setup_controller.gd:59 @ _setup_preset_enemies()
                game_enemy_setup_controller.gd:35 @ setup_enemies()
                game.gd:130 @ start_battle()
                main.gd:102 @ show_game()
                main.gd:222 @ _on_stage_select_stage_selected()
                stage_select.gd:75 @ _on_stage_choice_pressed()
                stage_choice_list.gd:74 @ _on_stage_choice_pressed()

実装完了です。悪夢を6体単位でページ表示し、左右矢印で切り替えられるようにしました。

  ### 変更

  - scene/main/game/controller/enemy/game_enemy_setup_controller.gd:10
      - 1ページ最大6体。
      - 7体目以降を次ページへ配置。
      - 最終ページが1～5体の場合、従来の各体数用座標を適用。
      - 胃袋内の悪夢はページ切替後も表示を維持。

  - scene/main/game/game.tscn:84
      - 左右の ←・→ ボタンを追加。
      - 前後ページが存在する場合だけ対応するボタンを表示。

  - scene/ui/battle_ui/battle_ui.gd:9 / scene/main/game/game.gd:284
      - 既存のUI signal方式でページ切替を接続。

  - tests/game_enemy_pagination_test.gd:50
      - 6体、7体、11体、13体の表示・座標・矢印状態を検証。

  ### 検証

  - Godot 4.6.2でimport：終了コード0
  - 変更Controllerの個別parse：成功
  - tests/all_gdscript_parse_test.gd：終了コード0
  - tests/game_enemy_pagination_test.gd：終了コード0
  - tests/game_enemy_smoke_test.gd：終了コード0
  - OpenGL実描画を640×360基準で確認
      - 1ページ目：6体＋右矢印
      - 2ページ目：1体＋左矢印
      - 矢印文字欠け、悪夢との重なりなし

  - git diff --check：成功

  個別parse時のAutoload未登録エラーはプロジェクトコンテキスト付きparseで解消確認済みです。各既存テスト終了時には、今回と無関係な既存の「2 resources still in use」終了処理ログ
  が残っています。formatter/linterと標準検証スクリプトは未設定でした。