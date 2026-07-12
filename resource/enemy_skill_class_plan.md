# EnemySkill クラス設計候補

## この文書の扱い

- `resource/use_stage_concept.md` に書かれた敵スキルを実装する前の確認用一覧。
- この段階ではクラス、Resource、既存の `EnemyInfo` は変更しない。
- ID はこの設計一覧内で項目を一意に指すための16進数ID。欠番を再利用せず、追加時は末尾から採番する。
- クラス名は「発生条件 + 結果」が分かる `EnemyEffectOn...` 形式を基本とする。
- 同じ因果で数値だけが異なるスキルは同じクラスの Resource 値で表現する。
- 複数の因果を含むスキルは複数の `EnemyEffect` に分け、`EnemySkill.effects` で組み合わせる。
- 下記の変数はすべて Inspector に公開する候補。数値型には原則として範囲ヒントを付ける。

## 共通クラス

| ID | クラス | 用途 | 外部に表示する変数 |
|---|---|---|---|
| `0x0001` | `EnemyEffect` | 敵効果の親 Resource。効果の適用順と共通の有効状態を持つ。 | `priority: int` 適用順、`enabled: bool` 有効状態 |
| `0x0002` | `EnemySkill` | 1つの敵スキルを構成する効果群を保持する Resource。 | `effects: Array[EnemyEffect]` 効果一覧 |

## 配置・隣接・接触状態による効果

| ID | クラス | 用途 | 外部に表示する変数 |
|---|---|---|---|
| `0x0003` | `EnemyEffectOnAdjacentObjectSetAttack` | モノが隣接している間、自身の攻撃力を指定値にする。 | `attack: int` 指定攻撃力、`minimum_count: int` 必要隣接数 |
| `0x0004` | `EnemyEffectOnAdjacentObjectChangeAttack` | 隣接するモノの数に応じて自身、または隣接対象の攻撃力を増減する。 | `target: EffectTarget` 対象、`attack_delta: int` 1体あたりの増減量、`minimum_count: int` 必要数、`chance: float` 発動率、`chance_multiplier: float` 当選時の効果倍率、`max_activations_per_target: int` 対象ごとの発動上限 |->隣接するモノの数に応じて自身の攻撃力変動、隣接するモノの数に応じて隣接対象の攻撃力変動、隣接するモノの数に応じて自身または隣接対象の攻撃力変動。に分離してクラスを作成してください。また、chance_multiplierが必要ない場合と必要な場合がある効果の二種類がある場合はchance_multiplierの有無でクラスを分離してください。
| `0x0005` | `EnemyEffectOnAdjacentStomachChangeAttack` | 胃袋の縁への隣接数に応じて自身の攻撃力を増減する。 | `attack_delta: int` 1接触あたりの増減量 |
| `0x0006` | `EnemyEffectOnAdjacentObjectChangeStats` | 隣接対象と自身のHP・攻撃力を同時に増減する。 | `target_hp_delta: int` 対象HP差分、`target_attack_delta: int` 対象攻撃差分、`self_hp_delta: int` 自身HP差分、`self_attack_delta: int` 自身攻撃差分、`max_activations_per_target: int` 対象ごとの発動上限 |->自身のHP増減、自身の攻撃力増減、隣接対象のHP増減、隣接対象の攻撃力増減でクラスを分離してください。
| `0x0007` | `EnemyEffectOnAdjacentObjectScaleStats` | 隣接対象のHP・攻撃力を倍率変更する。 | `hp_multiplier: float` HP倍率、`attack_multiplier: float` 攻撃倍率、`required_count: int` 必要隣接数 |->隣接対象のHPを倍率変更、隣接対象の攻撃力を倍率変更でクラスを分離してください。
| `0x0008` | `EnemyEffectOnAdjacentObjectChangeMaxHp` | 隣接対象の最大HPを増減し、必要なら現在HPも追従させる。 | `max_hp_delta: int` 最大HP差分、`recover_delta: int` 同時回復量 |->隣接対象の最大HP増減、隣接対象の最大HP増減及び現在HP追従でクラスを分離してください。
| `0x0009` | `EnemyEffectOnAdjacentObjectScaleEffect` | 隣接対象が提供する全効果量を倍率変更する。 | `effect_multiplier: float` 効果倍率、`required_count: int` 必要隣接数 |
| `0x000A` | `EnemyEffectOnAdjacentObjectChangeChance` | 隣接対象が持つ全確率を増減する。 | `chance_delta: float` 確率差分、`required_count: int` 必要隣接数 |
| `0x000B` | `EnemyEffectOnAdjacentObjectShareAcidDamage` | 自身と隣接対象が受ける消化ダメージを均等に分配する。 | `include_self: bool` 自身を分配先に含める、`minimum_count: int` 必要隣接数 |
| `0x000C` | `EnemyEffectOnAdjacentObjectTransferAcidDamage` | 自身が受ける消化ダメージの一部を隣接対象へ肩代わりさせる。 | `transfer_rate: float` 譲渡率、`selection: AdjacentSelection` 分配・最低HPなどの選び方、`minimum_count: int` 必要隣接数 |
| `0x000D` | `EnemyEffectOnAdjacentStomachChangeDigestInterval` | 胃袋の縁への隣接数に応じて自身の消化間隔を増減する。 | `interval_delta_rate: float` 1接触あたりの割合差分、`interval_delta_minutes: int` 1接触あたりの分差分 |
| `0x000E` | `EnemyEffectOnAdjacentStomachChangeTakenAcidDamage` | 胃袋の縁への隣接数に応じて自身が受ける消化ダメージを増減する。 | `damage_delta: int` 1接触あたりの差分、`damage_multiplier: float` 倍率 |
| `0x000F` | `EnemyEffectOnAdjacentEmptyCellChangeTakenAcidDamage` | 空の胃袋マスへの隣接数に応じて自身が受ける消化ダメージを増減する。 | `damage_delta: int` 1マスあたりの差分、`damage_multiplier: float` 倍率 |
| `0x0010` | `EnemyEffectOnTouchAcidLineChangeStats` | 消化ライン接触中に自身のHP・最大HP・攻撃力を増減する。 | `max_hp_delta: int` 最大HP差分、`hp_delta: int` HP差分、`attack_delta: int` 攻撃差分 |->消化ライン接触中に自身のHP変動、消化ライン接触中に自身の最大HP変動、消化ライン接触中に自身の攻撃力変動でクラスを分離してください。
| `0x0011` | `EnemyEffectOnTouchAcidLineChangeAllAcidDamage` | 消化ライン接触中、全てのモノがラインから受ける消化ダメージを増減する。 | `damage_delta: int` ダメージ差分、`damage_multiplier: float` 倍率 |
| `0x0012` | `EnemyEffectOnTouchAcidLineChangeDigestInterval` | 消化ライン、または胃袋マスへの接触中に自身の消化間隔を増減する。 | `contact: ContactKind` 接触条件、`interval_delta_minutes: int` 分差分、`interval_delta_rate: float` 割合差分 |->消化ライン接触中に自身の消化間隔変動、胃袋マス接触中に自身の消化間隔変動でクラスを分離してください。
| `0x0013` | `EnemyEffectOnAwayAcidLineChangeStats` | 消化ラインに接触・隣接していない間、自身のHPや消化ダメージを変更する。 | `condition: LineDistanceCondition` 非接触・非隣接、`max_hp_delta: int` 最大HP差分、`hp_multiplier: float` HP倍率、`acid_damage_delta: int` 消化ダメージ差分 |->消化ライン接触中に自身のHP変動、消化ライン接触中に自身の消化ダメージ変動、消化ライン隣接中に自身のHP変動、消化ライン隣接中に自身の消化ダメージ変動でクラスを分離してください。
| `0x0014` | `EnemyEffectOnBattleChangeHpByEmptyCell` | 戦闘中、空の消化マス数に応じて自身のHP・最大HPを増減する。 | `hp_delta_per_cell: int` 1マスあたりの差分 |->空の消化マス数に応じて自身のHP変動、空の消化マス数に応じて自身の最大HP変動でクラスを分離してください。
| `0x0015` | `EnemyEffectOnBattleChangeDigestIntervalByObjectCount` | 胃袋内のモノ数に応じて自身の消化間隔を増減する。 | `minutes_per_object: int` 1体あたりの分差分 |
| `0x0016` | `EnemyEffectOnBattleChanceScaleAttack` | 戦闘中、自身の攻撃力を確率で倍率変更する。 | `attack_multiplier: float` 攻撃倍率、`chance: float` 発動率、`invert_chance: bool` 確率を無効率として扱うか |
| `0x0017` | `EnemyEffectOnBattleChanceIgnoreAcidDamage` | 受ける消化ダメージを確率で無効化する。 | `chance: float` 無効率、`invert_chance: bool` 確率を効果失敗率として扱うか |
| `0x0018` | `EnemyEffectOnBattleIgnoreLowAcidDamage` | 指定値以下、または未満の消化ダメージを無効化する。 | `threshold: int` 閾値、`comparison: ThresholdComparison` 以下・未満、`threshold_source: ValueSource` 固定値・受継値 |->指定値以下の消化ダメージを無効化、未満の消化ダメージを無効化でクラスを分離してください。
| `0x0019` | `EnemyEffectOnAdjacentObjectChanceScaleTakenAcidDamage` | 隣接対象が受ける消化ダメージを確率で倍率変更する。 | `chance: float` 発動率、`damage_multiplier: float` ダメージ倍率、`required_count: int` 必要隣接数 |

## 時間経過・時刻進行による効果

| ID | クラス | 用途 | 外部に表示する変数 |
|---|---|---|---|
| `0x001A` | `EnemyEffectOnProgressTimeChangeAttackByObjectCount` | 時間経過時、場のモノ数に応じた値で自身の攻撃力バフを上書きする。 | `attack_per_object: int` 1体あたりの攻撃力、`include_self: bool` 自身を数えるか |
| `0x001B` | `EnemyEffectOnProgressTimeSpawnEnemy` | 時間が進むたびに指定した敵を生成する。 | `enemy_info: EnemyInfo` 生成元定義、`spawn_skill: EnemySkill` 生成個体のスキル、`spawn_count: int` 生成数、`max_spawn_count: int` 上限、`spawn_area: SpawnArea` 配置範囲、`spawn_hp: int` HP上書き、`spawn_attack: int` 攻撃上書き |
| `0x001C` | `EnemyEffectOnElapsedTimeTakeAcidDamage` | 胃袋内で指定時間が経過するたびに自身が消化ダメージを受ける。 | `interval_minutes: float` 発動間隔（秒表記も分へ換算）、`damage: int` ダメージ |
| `0x001D` | `EnemyEffectOnElapsedTimeAttack` | 胃袋内で指定時間が経過するたびに攻撃する。 | `interval_minutes: int` 発動間隔、`attack_count: int` 攻撃回数、`fixed_damage: int` 固定悪夢ダメージ、`suppress_default_attack: bool` 通常の時間攻撃を止めるか、`damage_source: ValueSource` 通常攻撃力・失ったHP・固定値 |
| `0x001E` | `EnemyEffectOnElapsedTimeChangeAttack` | 胃袋内で指定時間が経過するたびに攻撃力を増減する。 | `interval_minutes: int` 発動間隔、`attack_delta: int` 攻撃差分 |
| `0x001F` | `EnemyEffectOnElapsedTimeChangeMaxHpAndRecover` | 胃袋内で指定時間が経過するたびに最大HPを増減し、HPを回復する。 | `interval_minutes: int` 発動間隔、`max_hp_delta: int` 最大HP差分、`recovery: int` 回復量 |
| `0x0020` | `EnemyEffectOnElapsedTimeRecoverHp` | 胃袋内で指定時間が経過するたびに自身を回復する。 | `interval_minutes: int` 発動間隔、`recovery: int` 固定回復量、`recovery_rate: float` 最大HP割合 |
| `0x0021` | `EnemyEffectOnElapsedTimeRecoverTargets` | 胃袋内で指定時間が経過するたびに隣接対象、または全対象を回復する。 | `interval_minutes: int` 発動間隔、`target: EffectTarget` 対象範囲、`recovery: int` 回復量、`include_self: bool` 自身を含むか、`suppress_default_attack: bool` 通常攻撃を止めるか |->胃袋内で指定時間が経過するたびに隣接対象を回復、胃袋内で指定時間が経過するたびに全対象を回復でクラスを分離してください。
| `0x0022` | `EnemyEffectOnElapsedTimeGrantEffect` | 胃袋内で指定時間が経過するたびに攻撃追加・攻撃無効などの一時効果を付与する。 | `interval_minutes: int` 発動間隔、`target: EffectTarget` 付与対象、`granted_effect: EnemyEffect` 付与効果、`stack_limit: int` 重複上限、`suppress_default_attack: bool` 通常攻撃を止めるか |->胃袋内で指定時間が経過するたびに攻撃追加の一時効果を付与、胃袋内で指定時間が経過するたびに攻撃無効を付与でクラスを分離してください。
| `0x0023` | `EnemyEffectOnElapsedTimeDealAllAcidDamage` | 胃袋内で指定時間が経過すると対象範囲へ消化ダメージを与える。 | `interval_minutes: int` 発動間隔、`target: EffectTarget` 対象範囲、`damage: int` ダメージ、`hit_count: int` 回数 |
| `0x0024` | `EnemyEffectOnClockCountTakeAcidDamage` | 時刻進行が指定回数に達するたびに自身が消化ダメージを受ける。 | `required_count: int` 必要回数、`damage: int` ダメージ |
| `0x0025` | `EnemyEffectOnClockCountAttack` | 時刻進行が指定回数に達するたびに攻撃する。 | `required_count: int` 必要回数、`attack_count: int` 攻撃回数、`fixed_damage: int` 固定悪夢ダメージ |
| `0x0026` | `EnemyEffectOnClockCountChangeAttack` | 時刻進行が指定回数に達するたびに自身の攻撃力を増減する。 | `required_count: int` 必要回数、`attack_delta: int` 攻撃差分 |
| `0x0027` | `EnemyEffectOnClockCountScaleAllAttack` | 時刻進行が指定回数に達するたびに全対象の攻撃力を倍率変更する。 | `required_count: int` 必要回数、`attack_multiplier: float` 攻撃倍率、`target: EffectTarget` 対象範囲 |
| `0x0028` | `EnemyEffectOnClockCountRecoverHp` | 時刻進行が指定回数に達するたびに自身を固定値で回復する。 | `required_count: int` 必要回数、`recovery: int` 回復量 |
| `0x0029` | `EnemyEffectOnClockCountRecoverHpByEnemyCount` | 時刻進行が指定回数に達するたびに胃袋内の敵数に応じて自身を回復する。 | `required_count: int` 必要回数、`recovery_per_enemy: int` 1体あたりの回復量、`include_self: bool` 自身を数えるか |
| `0x002A` | `EnemyEffectOnClockCountDealAllAcidDamage` | 時刻進行が指定回数に達するたびに対象範囲へ消化ダメージを与える。 | `required_count: int` 必要回数、`target: EffectTarget` 対象範囲、`damage: int` ダメージ、`hit_count: int` 回数 |
| `0x002B` | `EnemyEffectOnClockCountChangeAcidDamage` | 時刻進行が指定回数に達するたびに自身の消化ダメージ補正を増減する。 | `required_count: int` 必要回数、`damage_delta: int` 差分、`damage_multiplier: float` 倍率 |
| `0x002C` | `EnemyEffectOnClockCountGrantAdjacentGuard` | 時刻進行が指定回数に達するたびに隣接対象へ次回消化ダメージ無効を付与する。 | `required_count: int` 必要回数、`guard_count: int` 無効回数、`target: EffectTarget` 付与対象 |
| `0x002D` | `EnemyEffectOnDigestionCountChangeAttack` | 胃袋内でモノが指定回数消化されるたびに自身の攻撃力を増減する。 | `required_count: int` 必要消化数、`attack_delta: int` 攻撃差分 |
| `0x002E` | `EnemyEffectOnDigestionCountChangeMaxHpAndRecover` | 胃袋内でモノが指定回数消化されるたびに最大HPを増減し、回復する。 | `required_count: int` 必要消化数、`max_hp_delta: int` 最大HP差分、`recovery: int` 回復量 |
| `0x002F` | `EnemyEffectOnDigestionCountAttack` | 胃袋内でモノが指定回数消化されるたびに攻撃する。 | `required_count: int` 必要消化数、`attack_count: int` 攻撃回数、`fixed_damage: int` 固定悪夢ダメージ |
| `0x0030` | `EnemyEffectOnDigestionCountDealAllAcidDamage` | 胃袋内でモノが指定回数消化されるたびに全対象へ複数回の消化ダメージを与える。 | `required_count: int` 必要消化数、`damage: int` 1回のダメージ、`hit_count: int` 回数、`target: EffectTarget` 対象範囲 |

## 被ダメージによる効果

| ID | クラス | 用途 | 外部に表示する変数 |
|---|---|---|---|
| `0x0031` | `EnemyEffectOnAcidDamageCountTakeAcidDamage` | 消化ダメージを指定回数受けるたびに追加の消化ダメージを受ける。 | `required_count: int` 必要被弾数、`damage: int` 追加ダメージ |
| `0x0032` | `EnemyEffectOnAcidDamageCountAttack` | 消化ダメージを指定回数受けるたびに攻撃する。 | `required_count: int` 必要被弾数、`attack_count: int` 攻撃回数、`fixed_damage: int` 固定悪夢ダメージ |
| `0x0033` | `EnemyEffectOnAcidDamageAttack` | 消化ダメージを受けるたびに攻撃する。 | `attack_count: int` 攻撃回数、`fixed_damage: int` 固定悪夢ダメージ |
| `0x0034` | `EnemyEffectOnAcidDamageRecoverAll` | 消化ダメージを受けた時、胃袋内の全対象を回復する。 | `recovery: int` 回復量、`target: EffectTarget` 対象範囲、`chance: float` 発動率、`invert_chance: bool` 確率を失敗率として扱うか |
| `0x0035` | `EnemyEffectOnAcidDamageTransfer` | 自身が受けた消化ダメージの一部を隣接対象へ譲渡する。 | `transfer_rate: float` 譲渡率、`selection: AdjacentSelection` 対象選択、`minimum_count: int` 必要隣接数 |
| `0x0036` | `EnemyEffectOnAcidDamageSpawnEnemy` | 消化ダメージを受けた時、被ダメージや自身の能力を引き継いだ敵を生成する。 | `enemy_info: EnemyInfo` 生成元定義、`spawn_skill: EnemySkill` 生成スキル、`spawn_count: int` 生成数、`max_spawn_count: int` 上限、`spawn_area: SpawnArea` 配置範囲、`hp_source: ValueSource` HP参照元、`hp_multiplier: float` HP倍率、`attack_source: ValueSource` 攻撃参照元、`attack_multiplier: float` 攻撃倍率、`inherit_skill: bool` 同じスキルを継ぐか、`self_hp_multiplier_on_success: float` 成功時の自身HP倍率、`self_attack_multiplier_on_success: float` 成功時の自身攻撃倍率 |
| `0x0037` | `EnemyEffectOnDamageSpawnEnemy` | 種別を問わずダメージを受けた時に敵を生成する。 | `enemy_info: EnemyInfo` 生成元定義、`spawn_skill: EnemySkill` 生成スキル、`spawn_count: int` 生成数、`max_spawn_count: int` 上限、`spawn_area: SpawnArea` 配置範囲、`spawn_hp: int` HP上書き、`spawn_attack: int` 攻撃上書き |
| `0x0038` | `EnemyEffectOnAcidDamageAcquireAttack` | 条件下で受けた消化ダメージに応じて攻撃力を得る。 | `attack_rate: float` 被ダメージから得る割合、`chance: float` 発動率、`require_acid_line_touch: bool` ライン接触を要求するか |
| `0x0039` | `EnemyEffectOnAcidDamageChanceScaleTakenDamage` | 消化ダメージを受けた時、確率でそのダメージを倍率変更する。 | `chance: float` 発動率、`damage_multiplier: float` ダメージ倍率 |

## 隣接対象の被弾・消化による効果

| ID | クラス | 用途 | 外部に表示する変数 |
|---|---|---|---|
| `0x003A` | `EnemyEffectOnAdjacentEnemyAcidRecover` | 隣接する敵が消化ダメージを受けた時、その敵と自身を回復する。 | `recovery_per_adjacent: int` 隣接数あたりの回復量、`recover_source: bool` 自身も回復するか、`recover_victim: bool` 被弾対象も回復するか |->隣接する敵が消化ダメージを受けた時その敵を回復する、隣接する敵が消化ダメージを受けた時自身を回復するでクラスを分離してください。
| `0x003B` | `EnemyEffectOnAdjacentEnemyAcidChangeAttack` | 隣接する敵が消化ダメージを受けた時、自身の攻撃力を増減する。 | `attack_delta: int` 攻撃差分 |
| `0x003C` | `EnemyEffectOnAdjacentObjectDigestedRevive` | 隣接対象が消化された時、その対象を割合回復して復活させる。 | `recovery_rate: float` 最大HP回復率、`target: EffectTarget` 復活対象 |
| `0x003D` | `EnemyEffectOnSelfOrAdjacentDigestedRevive` | 自身または隣接対象が消化された時、グループに生存者がいれば消化対象を復活させる。 | `recovery_rate: float` 最大HP回復率、`require_survivor: bool` 生存者を要求するか、`include_self: bool` 自身を判定・復活対象に含むか |

## 自身が消化された時の効果

| ID | クラス | 用途 | 外部に表示する変数 |
|---|---|---|---|
| `0x003E` | `EnemyEffectOnDigestedRevive` | 自身が消化された時、条件と確率に応じて復活する。 | `recovery_rate: float` 最大HP回復率、`chance: float` 発動率、`invert_chance: bool` 確率を失敗率として扱うか、`require_other_object: bool` 他のモノの存在を要求するか、`chance_delta: float` 段階ごとの確率差分、`revives_per_step: int` 確率変化に必要な復活回数 |->自身が消化された時条件に応じて復活する（各条件ごとにクラス分け）、自身が消化された時確率に応じて復活するでクラスを分離してください。
| `0x003F` | `EnemyEffectOnDigestedSpawnEnemy` | 自身が消化された時、固定値・超過ダメージ・消化時間・自身能力を元に敵を生成する。 | `enemy_info: EnemyInfo` 生成元定義、`spawn_skill: EnemySkill` 生成スキル、`spawn_count: int` 生成数、`max_spawn_count: int` 上限、`spawn_area: SpawnArea` 配置範囲、`hp_source: ValueSource` HP参照元、`hp_base: int` HP基準値、`hp_multiplier: float` HP倍率、`hp_delta: int` HP差分、`attack_source: ValueSource` 攻撃参照元、`attack_base: int` 攻撃基準値、`attack_multiplier: float` 攻撃倍率、`attack_delta: int` 攻撃差分、`inherit_skill: bool` 同じスキルを継ぐか |
| `0x0040` | `EnemyEffectOnDigestedChangeTime` | 自身が消化された時、時刻を進める、または巻き戻す。 | `minutes_delta: int` 時刻差分 |
| `0x0041` | `EnemyEffectOnDigestedDealAdjacentAcidDamage` | 自身が消化された時、隣接対象へ固定値・攻撃力・受継いだ超過量に応じた消化ダメージを与える。 | `damage_source: ValueSource` ダメージ参照元、`damage: int` 固定値、`damage_multiplier: float` 参照値倍率、`target: EffectTarget` 対象範囲 |->自身が消化された隣接対象へ固定値に応じた消化ダメージを与える、自身が消化された時隣接対象へ攻撃力に応じた消化ダメージを与える、自身が消化された時隣接対象へ受継いだ超過量に応じた消化ダメージを与えるでクラスを分離してください。
| `0x0042` | `EnemyEffectOnDigestedTransformEnemy` | 自身が消化された時、胃袋外へ出して別の敵定義へ変身させる。 | `next_enemy_info: EnemyInfo` 次形態、`next_skill: EnemySkill` 次形態スキル、`remove_from_stomach: bool` 胃袋外へ出すか |

## 特殊な複合参照効果

| ID | クラス | 用途 | 外部に表示する変数 |
|---|---|---|---|
| `0x0043` | `EnemyEffectOnAdjacentWeakerAbsorb` | 攻撃力が自身より低い隣接対象を消化し、そのHP・攻撃力・スキルを取得する。 | `damage: int` 対象へ与える消化ダメージ、`acquire_hp: bool` HP取得、`acquire_attack: bool` 攻撃力取得、`acquire_skill: bool` スキル取得 |->攻撃力が自身より低い隣接対象を消化しHPを取得する、攻撃力が自身より低い隣接対象を消化し攻撃力を取得する、攻撃力が自身より低い隣接対象を消化しスキルを取得するでクラスを分離してください。
| `0x0044` | `EnemyEffectOnStomachEdgeProgressTimeDealAcidDamage` | 胃袋の端に隣接中、時間経過ごとに胃袋マス接触中の対象を選び消化ダメージを与える。 | `damage: int` ダメージ、`selection: TargetSelection` 対象選択、`target: EffectTarget` 対象範囲 |
| `0x0045` | `EnemyEffectOnProgressTimeDisableDefaultAttack` | 時間経過時の通常攻撃だけを停止する。別の時間効果と組み合わせる。 | `disabled: bool` 通常攻撃停止 |
| `0x0046` | `EnemyEffectOnTouchAcidLineProgressTimeTakeAcidDamage` | 消化ライン接触中、時間が進むたびに接触数に応じた消化ダメージを自身へ与える。 | `damage: int` 固定ダメージ、`damage_per_contact: int` 1接触あたりのダメージ |
| `0x0047` | `EnemyEffectOnElapsedTimeTriggerAdjacentAcidDamage` | 胃袋内で指定時間が経過するたびに、隣接対象へ通常の消化ダメージ処理を指定回数発生させる。 | `interval_minutes: float` 発動間隔、`hit_count: int` 消化回数、`target: EffectTarget` 対象範囲 |

## 補助 enum 候補

enum は独立 Resource クラスを増やさず、該当する親クラスまたは共通スクリプトに定義する想定。

| enum | 用途 | 候補値 |
|---|---|---|
| `EffectTarget` | 効果対象 | `SELF`、`ADJACENT_OBJECTS`、`ADJACENT_ENEMIES`、`ALL_OBJECTS`、`ALL_ENEMIES`、`ACID_LINE_OBJECTS` |
| `AdjacentSelection` | 隣接対象の選択 | `ALL`、`EVEN_SPLIT`、`LOWEST_HP`、`RANDOM_ONE` |
| `TargetSelection` | 範囲内からの選択 | `ALL`、`RANDOM_ONE`、`LOWEST_HP` |
| `ContactKind` | 接触条件 | `ACID_LINE`、`STOMACH_EDGE` |
| `LineDistanceCondition` | ラインから離れた条件 | `NOT_TOUCHING`、`NOT_ADJACENT` |
| `SpawnArea` | 生成位置 | `SAME_CELLS`、`EMPTY_STOMACH`、`EMPTY_ADJACENT`、`OUTSIDE_STOMACH` |
| `ValueSource` | 数値の参照元 | `FIXED`、`SELF_CURRENT_HP`、`SELF_MAX_HP`、`SELF_ATTACK`、`TAKEN_DAMAGE`、`OVERKILL_DAMAGE`、`DIGESTED_MINUTES`、`LOST_HP`、`INHERITED_VALUE` |
| `ThresholdComparison` | 閾値比較 | `LESS_THAN`、`LESS_OR_EQUAL` |

## `EnemyInfo` への接続候補

新規クラス確定後、既存の `EnemyInfo` には次の公開変数を追加する想定。

| 変数 | 概要 |
|---|---|
| `skill: EnemySkill` | この敵が使用するスキル。未設定ならスキルなしとして扱う。 |

既存の `skill_id`、`display_name`、`acid_block`、`description`、`nightmare_skill_enabled` は名前と挙動を維持する。`nightmare_skill_enabled` は当面 `skill` の実行可否フラグとして利用し、削除・改名しない。

## 文書内の複合スキルの分割例

- 「消化ライン接触中、HPを200、攻撃力を10増やす」: `0x0010` 1個。
- 「隣接対象のHPを100減らし、攻撃力を10増やす」: `0x0006` 1個。
- 「隣接対象の効果を3倍にし、被消化ダメージを20%で3倍」: `0x0009` と `0x0019`。
- 「消化時に30分巻き戻し、敵を2体生成」: `0x0040` と `0x003F`。
- 「消化時に変身し、胃袋端への隣接中は時間ごとに200ダメージ」: `0x0042` と `0x0044`。
- 「時間経過時に通常攻撃せず、30分ごとに攻撃無効を付与」: `0x0045` と `0x0022`。
- 「被消化ダメージで分裂し、成功時に自身の最大HPと攻撃力を半減」: `0x0036` 1個。
- 「ライン接触中、時間経過ごとに10×接触数の消化ダメージ」: `0x0046` 1個。
- 「30分ごとに隣接するモノが1回消化ダメージを受ける」: `0x0047` 1個。

## 実装前に決めたい点

1. `EnemyInfo.skill_id` は既存互換のIDとして残し、実体は `skill` を優先する方針でよいか。->はい。skill_idはEnemyInfoのカスタムリソースごとに指定するので問題ありません。
2. HPを増減する効果は、特記がない場合に「最大HPと現在HPを同量変更」と解釈してよいか。->いいえ。明記が無い場合は現在HP内で変動することが望まれます。最大HPが200で、HP300回復の場合はHP200まで回復します。
3. 「消化間隔を割合増加」と「分で増加」を同じ効果クラスの2変数で扱う方針でよいか。->いいえ。計算方法を分ける必要があるためクラスも分けることが望まれます。SOLID原則に倣ってください。
4. 生成敵の可変ステータスは `EnemyInfo` 自体を書き換えず、戦闘中の個体値として上書きする方針でよいか。->質問の意図が不明ですが、敵を生成する際のインスタンスEnemyInfoの固有ステータスを変更してください。変更したデータをエネミー生成クラスに投げて生成させてください。
5. 確率は Inspector 上で `0.0` から `1.0` の値として統一してよいか。->はい。
6. 文書中の「20秒」はゲーム内時刻の `1/3分` として扱い、時間間隔を `float` 分で保持してよいか。->いいえ。そのように分離するのであれば全体の数値はintの秒として管理するのが望ましいです。しかし、既に存在するseedクラスなどでそのように実装していればfloat分で管理してください。

## 追加要望
- SOLID原則を意識してスキルのクラスを分離してください。