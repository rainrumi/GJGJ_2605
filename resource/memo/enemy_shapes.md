# 悪夢の形状一覧

`EnemyInfo.acid_block` の `AcidBlockInfo.stomach_shape` を、現在のワークツリーに存在するゲームデータから走査した一覧です。

## 走査結果

- 生成日: 2026-07-19
- 走査範囲: `res://data/resources` 以下の `.tres` / `.res` 539ファイル
- 検出した `EnemyInfo`: 283件（外部参照・サブリソースを再帰走査し、同一リソース参照は1件に集約）
- `AcidBlockInfo` / `stomach_shape` 設定あり: 175件
- ユニーク形状: 24種類
- `acid_block` 未設定: 108件（形状を持たないため一覧から除外）
- 読み込み失敗: 0件

## 重複判定

- `AcidBlockInfo.get_stomach_size()` の幅・高さと、`get_stomach_shape()` が返す占有セル配置が一致するものを同一形状としています。
- 値 `0` は空きセル、`0` 以外は占有セルです。下図では `#` が占有、`.` が空きを表します。
- 回転・反転で一致する形でも、保存されているセル配置が異なれば別形状です。
- 空配列や全セル `0` は、実行時契約どおり `(0, 0)` の1セルを占有する形として扱います。

## 形状サマリー

| ID | サイズ | セル数 | 使用EnemyInfo数 | データ |
|---:|---:|---:|---:|---|
| 01 | 1 x 1 | 1 | 50 | `[[1]]` |
| 02 | 2 x 1 | 2 | 28 | `[[1, 1]]` |
| 03 | 3 x 1 | 3 | 9 | `[[1, 1, 1]]` |
| 04 | 2 x 2 | 3 | 17 | `[[1, 0], [1, 1]]` |
| 05 | 2 x 2 | 4 | 14 | `[[1, 1], [1, 1]]` |
| 06 | 3 x 2 | 4 | 3 | `[[0, 0, 1], [1, 1, 1]]` |
| 07 | 3 x 2 | 4 | 5 | `[[0, 1, 0], [1, 1, 1]]` |
| 08 | 3 x 2 | 4 | 6 | `[[1, 0, 0], [1, 1, 1]]` |
| 09 | 3 x 2 | 4 | 14 | `[[1, 1, 0], [0, 1, 1]]` |
| 10 | 3 x 2 | 4 | 3 | `[[1, 1, 1], [0, 1, 0]]` |
| 11 | 3 x 2 | 5 | 2 | `[[1, 1, 1], [0, 1, 1]]` |
| 12 | 3 x 3 | 5 | 6 | `[[0, 1, 0], [1, 1, 1], [0, 1, 0]]` |
| 13 | 3 x 3 | 5 | 1 | `[[1, 1, 1], [0, 1, 0], [0, 1, 0]]` |
| 14 | 4 x 2 | 6 | 1 | `[[1, 1, 1, 0], [0, 1, 1, 1]]` |
| 15 | 2 x 3 | 6 | 4 | `[[1, 1], [1, 1], [1, 1]]` |
| 16 | 3 x 3 | 7 | 1 | `[[0, 1, 0], [1, 1, 1], [1, 1, 1]]` |
| 17 | 3 x 3 | 7 | 1 | `[[1, 0, 1], [1, 1, 1], [1, 0, 1]]` |
| 18 | 3 x 3 | 7 | 1 | `[[1, 1, 1], [1, 0, 0], [1, 1, 1]]` |
| 19 | 5 x 3 | 7 | 1 | `[[1, 1, 1, 1, 1], [0, 0, 1, 0, 0], [0, 0, 1, 0, 0]]` |
| 20 | 3 x 4 | 7 | 4 | `[[0, 1, 0], [1, 1, 1], [0, 1, 0], [1, 0, 1]]` |
| 21 | 3 x 3 | 8 | 1 | `[[1, 1, 1], [1, 0, 1], [1, 1, 1]]` |
| 22 | 5 x 3 | 8 | 1 | `[[1, 0, 0, 0, 1], [1, 1, 0, 1, 1], [1, 0, 0, 0, 1]]` |
| 23 | 4 x 4 | 11 | 1 | `[[0, 1, 1, 1], [1, 1, 1, 0], [0, 1, 1, 1], [1, 1, 0, 0]]` |
| 24 | 4 x 4 | 16 | 1 | `[[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]]` |

## 形状詳細

### 01. 1 x 1 / 1セル

```text
#
```

- 使用数: **50件**（`elmena/normal` 2件、`iriyu/boss` 3件、`iriyu/normal` 6件、`lunova/boss` 3件、`lunova/normal` 8件、`riran/boss` 7件、`riran/normal` 21件）
- 例:
  - `area_elmena/enemy/normal/001/area_elmena_enemy_normal_001_001.tres` — SkillID `11010001001` / `E1`
  - `area_elmena/enemy/normal/005/area_elmena_enemy_normal_005_003.tres` — SkillID `11010005003` / `E3`
  - `area_iriyu/enemy/boss/001/area_iriyu_enemy_boss_001_003.tres` — SkillID `16020001003` / `E3`
  - ほか 47件

### 02. 2 x 1 / 2セル

```text
##
```

- 使用数: **28件**（`elmena/boss` 3件、`elmena/normal` 8件、`iriyu/boss` 1件、`iriyu/normal` 5件、`lunova/boss` 1件、`lunova/normal` 4件、`riran/boss` 1件、`riran/normal` 5件）
- 例:
  - `area_elmena/enemy/boss/001/area_elmena_enemy_boss_001_003.tres` — SkillID `11020001003` / `E3`
  - `area_elmena/enemy/boss/001/area_elmena_enemy_boss_001_004.tres` — SkillID `11020001004` / `E4`
  - `area_elmena/enemy/boss/003/area_elmena_enemy_boss_003_004.tres` — SkillID `11020003004` / `E4`
  - ほか 25件

### 03. 3 x 1 / 3セル

```text
###
```

- 使用数: **9件**（`elmena/boss` 3件、`elmena/normal` 2件、`iriyu/normal` 4件）
- 例:
  - `area_elmena/enemy/boss/002/area_elmena_enemy_boss_002_003.tres` — SkillID `11020002003` / `E3`
  - `area_elmena/enemy/boss/002/area_elmena_enemy_boss_002_004.tres` — SkillID `11020002004` / `E4`
  - `area_elmena/enemy/boss/003/area_elmena_enemy_boss_003_003.tres` — SkillID `11020003003` / `E3`
  - ほか 6件

### 04. 2 x 2 / 3セル

```text
#.
##
```

- 使用数: **17件**（`elmena/boss` 3件、`elmena/normal` 1件、`iriyu/boss` 3件、`iriyu/normal` 4件、`riran/boss` 3件、`riran/normal` 3件）
- 例:
  - `area_elmena/enemy/boss/001/area_elmena_enemy_boss_001_001.tres` — SkillID `11020001001` / `E1`
  - `area_elmena/enemy/boss/002/area_elmena_enemy_boss_002_001.tres` — SkillID `11020002001` / `E1`
  - `area_elmena/enemy/boss/003/area_elmena_enemy_boss_003_002.tres` — SkillID `11020003002` / `E2`
  - ほか 14件

### 05. 2 x 2 / 4セル

```text
##
##
```

- 使用数: **14件**（`corotta/normal` 1件、`elmena/normal` 2件、`iriyu/boss` 1件、`iriyu/normal` 3件、`lunova/boss` 2件、`lunova/normal` 1件、`riran/boss` 2件、`riran/normal` 2件）
- 例:
  - `area_corotta/enemy/normal/001/area_corotta_enemy_normal_001_001.tres` — SkillID `10010001001` / `E1`
  - `area_elmena/enemy/normal/003/area_elmena_enemy_normal_003_001.tres` — SkillID `11010003001` / `E1`
  - `area_elmena/enemy/normal/008/area_elmena_enemy_normal_008_001.tres` — SkillID `11010008001` / `E1`
  - ほか 11件

### 06. 3 x 2 / 4セル

```text
..#
###
```

- 使用数: **3件**（`elmena/boss` 1件、`elmena/normal` 2件）
- 例:
  - `area_elmena/enemy/boss/003/area_elmena_enemy_boss_003_005.tres` — SkillID `11020003005` / `E5`
  - `area_elmena/enemy/normal/002/area_elmena_enemy_normal_002_003.tres` — SkillID `11010002003` / `E3`
  - `area_elmena/enemy/normal/009/area_elmena_enemy_normal_009_006.tres` — SkillID `11010009006` / `E6`

### 07. 3 x 2 / 4セル

```text
.#.
###
```

- 使用数: **5件**（`elmena/normal` 1件、`riran/normal` 4件）
- 例:
  - `area_elmena/enemy/normal/002/area_elmena_enemy_normal_002_001.tres` — SkillID `11010002001` / `E1`
  - `area_riran/enemy/normal/002/area_riran_enemy_normal_002_001.tres` — SkillID `20010002001` / `E1`
  - `area_riran/enemy/normal/003/area_riran_enemy_normal_003_007.tres` — SkillID `20010003007` / `E7`
  - ほか 2件

### 08. 3 x 2 / 4セル

```text
#..
###
```

- 使用数: **6件**（`elmena/normal` 3件、`iriyu/boss` 2件、`riran/normal` 1件）
- 例:
  - `area_elmena/enemy/normal/002/area_elmena_enemy_normal_002_002.tres` — SkillID `11010002002` / `E2`
  - `area_elmena/enemy/normal/005/area_elmena_enemy_normal_005_002.tres` — SkillID `11010005002` / `E2`
  - `area_elmena/enemy/normal/009/area_elmena_enemy_normal_009_001.tres` — SkillID `11010009001` / `E1`
  - ほか 3件

### 09. 3 x 2 / 4セル

```text
##.
.##
```

- 使用数: **14件**（`elmena/normal` 7件、`iriyu/normal` 5件、`lunova/normal` 1件、`riran/normal` 1件）
- 例:
  - `area_elmena/enemy/normal/003/area_elmena_enemy_normal_003_002.tres` — SkillID `11010003002` / `E2`
  - `area_elmena/enemy/normal/006/area_elmena_enemy_normal_006_002.tres` — SkillID `11010006002` / `E2`
  - `area_elmena/enemy/normal/006/area_elmena_enemy_normal_006_003.tres` — SkillID `11010006003` / `E3`
  - ほか 11件

### 10. 3 x 2 / 4セル

```text
###
.#.
```

- 使用数: **3件**（`iriyu/normal` 1件、`lunova/boss` 1件、`riran/boss` 1件）
- 例:
  - `area_iriyu/enemy/normal/003/area_iriyu_enemy_normal_003_001.tres` — SkillID `16010003001` / `E1`
  - `area_lunova/enemy/boss/001/area_lunova_enemy_boss_001_002.tres` — SkillID `17020001002` / `E2`
  - `area_riran/enemy/boss/001/area_riran_enemy_boss_001_001.tres` — SkillID `20020001001` / `E1`

### 11. 3 x 2 / 5セル

```text
###
.##
```

- 使用数: **2件**（`iriyu/boss` 2件）
- 例:
  - `area_iriyu/enemy/boss/001/area_iriyu_enemy_boss_001_001.tres` — SkillID `16020001001` / `E1`
  - `area_iriyu/enemy/boss/001/area_iriyu_enemy_boss_001_002.tres` — SkillID `16020001002` / `E2`

### 12. 3 x 3 / 5セル

```text
.#.
###
.#.
```

- 使用数: **6件**（`elmena/boss` 1件、`iriyu/boss` 1件、`iriyu/normal` 1件、`lunova/boss` 1件、`lunova/normal` 1件、`riran/boss` 1件）
- 例:
  - `area_elmena/enemy/boss/002/area_elmena_enemy_boss_002_002.tres` — SkillID `11020002002` / `E2`
  - `area_iriyu/enemy/boss/003/area_iriyu_enemy_boss_003_001.tres` — SkillID `16020003001` / `E1`
  - `area_iriyu/enemy/normal/004/area_iriyu_enemy_normal_004_001.tres` — SkillID `16010004001` / `E1`
  - ほか 3件

### 13. 3 x 3 / 5セル

```text
###
.#.
.#.
```

- 使用数: **1件**（`elmena/boss` 1件）
- 例:
  - `area_elmena/enemy/boss/001/area_elmena_enemy_boss_001_002.tres` — SkillID `11020001002` / `E2`

### 14. 4 x 2 / 6セル

```text
###.
.###
```

- 使用数: **1件**（`elmena/normal` 1件）
- 例:
  - `area_elmena/enemy/normal/006/area_elmena_enemy_normal_006_001.tres` — SkillID `11010006001` / `E1`

### 15. 2 x 3 / 6セル

```text
##
##
##
```

- 使用数: **4件**（`iriyu/normal` 2件、`lunova/normal` 1件、`riran/normal` 1件）
- 例:
  - `area_iriyu/enemy/normal/005/area_iriyu_enemy_normal_005_001.tres` — SkillID `16010005001` / `E1`
  - `area_iriyu/enemy/normal/007/area_iriyu_enemy_normal_007_001.tres` — SkillID `16010007001` / `E1`
  - `area_lunova/enemy/normal/009/area_lunova_enemy_normal_009_001.tres` — SkillID `17010009001` / `E1`
  - ほか 1件

### 16. 3 x 3 / 7セル

```text
.#.
###
###
```

- 使用数: **1件**（`elmena/boss` 1件）
- 例:
  - `area_elmena/enemy/boss/003/area_elmena_enemy_boss_003_001.tres` — SkillID `11020003001` / `E1`

### 17. 3 x 3 / 7セル

```text
#.#
###
#.#
```

- 使用数: **1件**（`elmena/normal` 1件）
- 例:
  - `area_elmena/enemy/normal/004/area_elmena_enemy_normal_004_001.tres` — SkillID `11010004001` / `E1`

### 18. 3 x 3 / 7セル

```text
###
#..
###
```

- 使用数: **1件**（`lunova/normal` 1件）
- 例:
  - `area_lunova/enemy/normal/008/area_lunova_enemy_normal_008_001.tres` — SkillID `17010008001` / `E1`

### 19. 5 x 3 / 7セル

```text
#####
..#..
..#..
```

- 使用数: **1件**（`lunova/normal` 1件）
- 例:
  - `area_lunova/enemy/normal/006/area_lunova_enemy_normal_006_001.tres` — SkillID `17010006001` / `E1`

### 20. 3 x 4 / 7セル

```text
.#.
###
.#.
#.#
```

- 使用数: **4件**（`lunova/boss` 4件）
- 例:
  - `area_lunova/enemy/boss/002/area_lunova_enemy_boss_002_001.tres` — SkillID `17020002001` / `E1`
  - `area_lunova/enemy/boss/002/area_lunova_enemy_boss_002_002.tres` — SkillID `17020002002` / `E2`
  - `area_lunova/enemy/boss/002/area_lunova_enemy_boss_002_003.tres` — SkillID `17020002003` / `E3`
  - ほか 1件

### 21. 3 x 3 / 8セル

```text
###
#.#
###
```

- 使用数: **1件**（`lunova/normal` 1件）
- 例:
  - `area_lunova/enemy/normal/002/area_lunova_enemy_normal_002_001.tres` — SkillID `17010002001` / `E1`

### 22. 5 x 3 / 8セル

```text
#...#
##.##
#...#
```

- 使用数: **1件**（`elmena/normal` 1件）
- 例:
  - `area_elmena/enemy/normal/004/area_elmena_enemy_normal_004_002.tres` — SkillID `11010004002` / `E2`

### 23. 4 x 4 / 11セル

```text
.###
###.
.###
##..
```

- 使用数: **1件**（`elmena/normal` 1件）
- 例:
  - `area_elmena/enemy/normal/004/area_elmena_enemy_normal_004_003.tres` — SkillID `11010004003` / `E3`

### 24. 4 x 4 / 16セル

```text
####
####
####
####
```

- 使用数: **1件**（`lunova/normal` 1件）
- 例:
  - `area_lunova/enemy/normal/001/area_lunova_enemy_normal_001_001.tres` — SkillID `17010001001` / `E1`

## `acid_block` 未設定の内訳

`EnemyInfo` として検出されましたが、`acid_block` が未設定のため形状データを持たないリソースの内訳です。

| エリア / 種別 | 件数 |
|---|---:|
| `corotta/boss` | 3 |
| `corotta/endless` | 1 |
| `corotta/normal` | 8 |
| `elmena/endless` | 1 |
| `eramia/boss` | 3 |
| `eramia/endless` | 1 |
| `eramia/normal` | 9 |
| `felis/boss` | 3 |
| `felis/endless` | 1 |
| `felis/normal` | 9 |
| `gonsal/boss` | 3 |
| `gonsal/endless` | 1 |
| `gonsal/normal` | 9 |
| `huwahuwa/boss` | 5 |
| `huwahuwa/normal` | 9 |
| `iriyu/endless` | 1 |
| `lunova/endless` | 1 |
| `mirune/boss` | 3 |
| `mirune/endless` | 1 |
| `mirune/normal` | 9 |
| `nerix/boss` | 3 |
| `nerix/endless` | 1 |
| `nerix/normal` | 9 |
| `riran/endless` | 1 |
| `zaika/boss` | 3 |
| `zaika/endless` | 1 |
| `zaika/normal` | 9 |

削除済みのワークツリーファイルは走査対象に含めていません。
