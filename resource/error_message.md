E 0:01:04:308   game_enemy_setup_controller.gd:59 @ _setup_preset_enemies(): Parameter "mesh" is null.
  <C++ ソース>     drivers/gles3/storage/mesh_storage.cpp:673 @ mesh_get_surface_count()
  <スタックトレース>    game_enemy_setup_controller.gd:59 @ _setup_preset_enemies()
                game_enemy_setup_controller.gd:35 @ setup_enemies()
                game.gd:130 @ start_battle()
                main.gd:102 @ show_game()
                main.gd:222 @ _on_stage_select_stage_selected()
                stage_select.gd:75 @ _on_stage_choice_pressed()
                stage_choice_list.gd:74 @ _on_stage_choice_pressed()
