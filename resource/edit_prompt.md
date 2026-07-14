# EnemyEffect・EnemyDigestionResolver・Enemy周辺の追加リファクタリング依頼

添付プロジェクトを確認し、前回のSOLID／MVPリファクタリングで残っている問題を修正してください。

今回の目的は、新機能の追加ではありません。

既存のゲーム挙動を維持しながら、以下の問題を解消してください。

1. 状態クラスからEnemyEffect層への依存を除去する
2. `EnemyDigestionResolver`から表示処理とEffect実行管理を分離する
3. `EnemyEffect`基底クラスの責務をさらに縮小する
4. `EnemyEffectInstaller`のService Locator化を解消する
5. `EnemyPresenter`を実際のMVP仲介役として機能させる
6. 潜在的なGDScript解析エラーを修正する
7. 新しい巨大クラスを作らない

既存の`EnemyEffectStack`、`EnemyEffectRequest`、`EnemyEffectActivationData`、`EnemyData`、分割後の`EnemyController`については、問題がない部分を維持してください。

---

# 1. 最優先：潜在的な解析エラーの修正

`EnemyEffectOnAdjacentAcidDamage`および関連する基底クラスを確認してください。

現在、基底クラス内で以下のように`enemies`を参照している可能性があります。

```gdscript
func accepts_activation(data: EnemyEffectActivationData) -> bool:
    return EnemyEffectTargetQuery.get_adjacent_enemies(
        source,
        enemies
    ).has(get_activation_target_from(data))
```

基底クラス自身に`enemies`が宣言されていない場合、GDScriptの解析エラーまたは不明瞭な隠れ依存になります。

以下のいずれかの方法で修正してください。

推奨：

```gdscript
class_name EnemyEffectOnAdjacentAcidDamage
extends EnemyEffect

var enemy_query: EnemyQuery
```

または、必要な敵一覧だけを明示的に注入してください。

```gdscript
func setup_dependencies(
    owner_value: EnemyData,
    enemies_value: Array[EnemyData],
    stack_value: EnemyEffectStack
) -> void:
    owner = owner_value
    enemies = enemies_value
    effect_stack = stack_value
```

派生クラスに偶然同名フィールドが存在することを前提に、基底クラスから参照してはいけません。

## 完了条件

* すべての基底クラスが、自身の使用する識別子を自身または明示的な依存として宣言している
* プロジェクト全体でGDScriptのParse Errorがない
* 継承先の暗黙フィールドへ依存していない

---

# 2. 状態クラスからEnemyEffect層への依存を除去する

以下の状態クラスを確認してください。

* `EnemyHp`
* `BattleClock`
* `EnemyStomachStatus`
* `EnemyDigestionState`
* その他のModel／状態クラス

これらのクラスが、以下のようなEffect専用型をSignal引数として使用している場合は修正してください。

```gdscript
signal acid_damage_preparing(
    data: BeforeAcidDamageActivationData
)

signal acid_damage_applied(
    data: AfterAcidDamageActivationData
)

signal battle_started(
    data: BattleStartActivationData
)

signal progress_resolved(
    data: ProgressTimeActivationData
)
```

Modelまたは状態クラスは、`EnemyEffectActivationData`およびその派生型を認識してはいけません。

状態クラスは、普遍的な出来事だけを通知してください。

例：

```gdscript
class_name EnemyHp
extends RefCounted

signal changed(current_hp: int, maximum_hp: int)
signal damaged(amount: int)
signal healed(amount: int)
signal depleted
```

```gdscript
class_name BattleClock
extends RefCounted

signal progressed(
    elapsed_seconds: int,
    current_seconds: int
)
```

```gdscript
class_name EnemyDigestionState
extends RefCounted

signal digestion_started(enemy: EnemyData)
signal digested(enemy: EnemyData)
signal vomited(enemy: EnemyData)
```

Effect用のActivationDataは、Signalを受信するEffect、中間基底クラス、または専用Adapterで生成してください。

例：

```gdscript
func _on_damaged(amount: int) -> void:
    var activation := DamageActivationData.new()
    activation.target = owner
    activation.amount = amount

    if not accepts_activation(activation):
        return

    effect_stack.request(self, activation)
```

## 禁止事項

状態クラスから以下へ依存してはいけません。

* `EnemyEffect`
* `EnemyEffectStack`
* `EnemyEffectRequest`
* `EnemyEffectActivationData`
* `EnemyEffectSystem`
* `EnemyEffectInstaller`

状態クラスをEffectイベントの中継器として使用してはいけません。

## SOLID上の目的

* DIP：Modelが上位のEffect実装へ依存しない
* SRP：状態クラスは状態管理と普遍的通知だけを担当する
* OCP：Effect追加のたびに状態クラスを変更しない

---

# 3. EnemyDigestionResolverからView操作を除去する

`EnemyDigestionResolver`を確認し、以下のような表示処理を削除してください。

```gdscript
enemy.show_acid_damage_values(values)
enemy.pulse_damage()
enemy.show_damage(...)
enemy.play_digestion_animation()
```

`EnemyDigestionResolver`は、消化処理の計算と結果生成だけを担当してください。

表示は行わず、結果オブジェクトを返してください。

例：

```gdscript
class_name EnemyDigestionResult
extends RefCounted

var enemy: EnemyData
var damage_values: Array[int] = []
var total_damage := 0
var applied_damage := 0
var overkill_damage := 0
var was_digested := false
```

複数対象を処理する場合：

```gdscript
class_name EnemyDigestionBatchResult
extends RefCounted

var results: Array[EnemyDigestionResult] = []
var digested_enemies: Array[EnemyData] = []
```

Resolverは次のような形にしてください。

```gdscript
func resolve(input: EnemyDigestionInput) -> EnemyDigestionBatchResult:
    var result := EnemyDigestionBatchResult.new()

    for enemy in input.targets:
        result.results.append(
            _resolve_enemy(enemy, input)
        )

    return result
```

表示処理は`EnemyPresenter`へ渡してください。

```gdscript
func present_digestion_result(
    result: EnemyDigestionResult
) -> void:
    view.show_acid_damage_values(
        result.damage_values
    )

    if result.applied_damage > 0:
        view.pulse_damage()

    if result.was_digested:
        view.play_digestion_animation()
```

## 禁止事項

`EnemyDigestionResolver`から以下を呼んではいけません。

* `EnemyView`
* Sprite、Label、Tween
* `enemy.show_*`
* `enemy.pulse_*`
* Tooltip
* アニメーション再生

## SOLID／MVP上の目的

* SRP：Resolverは消化ルールだけを担当する
* MVP：PresenterだけがModelの結果をViewへ反映する

---

# 4. EnemyDigestionResolverからEffect実行管理を分離する

現在`EnemyDigestionResolver`内に、以下のような処理が混在している場合は分離してください。

```gdscript
enemy_effects.prepare(...)
enemy_effects.notify_...(...)
enemy_effects.execute()
```

または、

```gdscript
effect_stack.process()
```

`EnemyDigestionResolver`はEffectStackのバッチ開始・実行・終了を直接管理してはいけません。

消化ユースケースの実行順調整は、以下のいずれかへ移してください。

推奨：

```text
EnemyDigestionProcessor
├─ EnemyDigestionResolver
├─ EnemyEffectStack
└─ EnemyDigestionPresenter
```

例：

```gdscript
class_name EnemyDigestionProcessor
extends RefCounted

var resolver: EnemyDigestionResolver
var effect_stack: EnemyEffectStack

func process(
    input: EnemyDigestionInput
) -> EnemyDigestionBatchResult:
    var result := resolver.resolve(input)
    effect_stack.process_pending()
    return result
```

ただし、EffectのSignalが同期的にRequestを作り、Stackが`call_deferred()`で処理する設計の場合は、Processorから明示的にStackを実行する必要がない可能性があります。

その場合は、Resolverが状態を変更するだけで、対応するModel SignalからEffectがRequestを送信する構造にしてください。

## 推奨する流れ

```text
EnemyDigestionResolver
↓
EnemyHpやEnemyDigestionStateを変更
↓
状態クラスが普遍的Signalを発行
↓
対応EffectがSignalを受信
↓
EffectがRequestを追加
↓
EnemyEffectStackがバッチ処理
```

ResolverからEffect種別を指定して通知してはいけません。

---

# 5. EnemyEffect基底クラスを縮小する

`EnemyEffect`基底クラスを確認し、ActivationDataの具体型ごとの操作や判定を減らしてください。

問題例：

```gdscript
func get_activation_damage() -> int:
    var data := get_activation_data()
    if data is DamageActivationData:
        return data.amount
    return 0
```

```gdscript
func get_elapsed_seconds() -> int:
    var data := get_activation_data()
    if data is TimeActivationData:
        return data.elapsed_seconds
    return 0
```

```gdscript
var lifecycle_allowed := \
    data is AfterAcidDamageActivationData \
    or data is AdjacentAcidDamageActivationData \
    or data is DigestionActivationData
```

このような具体型判定を`EnemyEffect`基底へ集中させると、新しいActivationData追加のたびに基底クラスの修正が必要になります。

これはOCPおよびISPに反します。

## 修正方針

発動契機別の中間基底クラスへ移してください。

例：

```gdscript
class_name EnemyEffectOnDamage
extends EnemyEffect

func get_damage_activation() -> DamageActivationData:
    return get_activation_data() as DamageActivationData
```

```gdscript
class_name EnemyEffectOnTimeProgressed
extends EnemyEffect

func get_time_activation() -> TimeActivationData:
    return get_activation_data() as TimeActivationData
```

```gdscript
class_name EnemyEffectOnDigested
extends EnemyEffect

func get_digestion_activation() -> DigestionActivationData:
    return get_activation_data() as DigestionActivationData
```

`EnemyEffect`基底へ残すものは以下に限定してください。

```text
priority
owner
effect_stack
enabled
runtime state
begin_activation()
end_activation()
get_activation_data()
request_activation()
apply()
bind()
unbind()
```

## 消化済み所有者の発動可否

基底クラスで具体ActivationData型を列挙して判定してはいけません。

以下のようなポリモーフィズムへ変更してください。

Effect側で定義する場合：

```gdscript
func can_activate_when_owner_digested() -> bool:
    return false
```

消化後にも発動可能な中間基底：

```gdscript
class_name EnemyEffectAfterDigestion
extends EnemyEffect

func can_activate_when_owner_digested() -> bool:
    return true
```

またはActivationData側に普遍的な属性として持たせてください。

```gdscript
var allows_digested_owner := false
```

ただし、イベント型の列挙による判定へ戻してはいけません。

---

# 6. EnemyEffectInstallerのService Locator化を解消する

現在、各Effectが以下のようにInstallerから依存を取得している場合は修正してください。

```gdscript
func bind_dependencies(
    installer: EnemyEffectInstaller
) -> void:
    stomach = installer.get_stomach()
    battle_clock = installer.get_battle_clock()
```

これはEffectがInstallerをService Locatorとして利用している状態です。

Effectが何へ依存しているのか、外部から判別しにくくなります。

## 修正方針

InstallerからEffectへ必要な依存だけを直接渡してください。

例：

```gdscript
func install_damage_attack_up(
    effect: EnemyEffectOnDamageAttackUp,
    enemy: EnemyData
) -> void:
    effect.setup(
        enemy.hp,
        enemy.attack,
        effect_stack
    )
```

Effect側：

```gdscript
func setup(
    hp_value: EnemyHp,
    attack_value: EnemyAttack,
    stack_value: EnemyEffectStack
) -> void:
    hp = hp_value
    attack = attack_value
    effect_stack = stack_value
```

ただし、Installer内へ大量の具体クラス判定を追加してはいけません。

以下は禁止します。

```gdscript
if effect is EnemyEffectA:
    ...
elif effect is EnemyEffectB:
    ...
```

## 推奨案

発動契機別基底クラスが、必要な依存を受け取る初期化メソッドを持つ構造にしてください。

```gdscript
class_name EnemyEffectOnDamage
extends EnemyEffect

func setup_damage_trigger(
    hp: EnemyHp,
    stack: EnemyEffectStack
) -> void:
    ...
```

特殊な追加依存だけを具体Effectへ直接注入してください。

Installerの責務は以下に限定してください。

* Resource複製後の実行個体初期化
* 必要な依存の注入
* bindの呼び出し
* unbindの呼び出し

Installerを万能データ取得窓口にしてはいけません。

---

# 7. EnemyPresenterをMVPの仲介役として拡張する

現在の`EnemyPresenter`が攻撃力表示など一部だけを担当している場合、ModelとViewの接続をPresenterへ移してください。

最低限、以下のModel SignalをPresenterが購読してください。

* `EnemyHp.changed`
* `EnemyHp.damaged`
* `EnemyHp.healed`
* `EnemyHp.depleted`
* `EnemyAttack.changed`
* `EnemyStomachStatus.changed`
* `EnemyDigestionState.digested`
* `EnemyDigestionState.vomited`

例：

```gdscript
class_name EnemyPresenter
extends RefCounted

var model: EnemyData
var view: EnemyView

func bind(
    model_value: EnemyData,
    view_value: EnemyView
) -> void:
    model = model_value
    view = view_value

    model.hp.changed.connect(_on_hp_changed)
    model.hp.damaged.connect(_on_damaged)
    model.attack.changed.connect(_on_attack_changed)
```

```gdscript
func _on_hp_changed(
    current_hp: int,
    maximum_hp: int
) -> void:
    view.update_hp(current_hp, maximum_hp)
```

```gdscript
func _on_damaged(amount: int) -> void:
    view.show_damage(amount)
    view.pulse_damage()
```

`Enemy` NodeをScene上のFacadeとして残すことは許可します。

ただし、以下を新規に`Enemy`へ追加してはいけません。

* ダメージ計算
* 回復量計算
* Effect条件判定
* View表示ロジック
* Tween詳細
* Tooltip生成ロジック

`Enemy`に残す互換メソッドは、ModelまたはPresenterへ転送するだけにしてください。

例：

```gdscript
func take_acid_damage(amount: int) -> int:
    return data.hp.take_damage(amount)
```

---

# 8. EnemyDigestionResolverの追加分割

`EnemyDigestionResolver`が依然として大きい場合、行数だけではなく責務を基準に分けてください。

推奨する構造：

```text
EnemyDigestionResolver
├─ EnemyDigestionDamageCalculator
├─ EnemyDigestionTargetSorter
├─ EnemyDigestionResultBuilder
└─ 必要ならDreamSeedBlockAcidResolver
```

## EnemyDigestionDamageCalculator

担当：

* 基礎酸ダメージ
* 各種倍率
* 防御補正
* 最終ダメージ
* 超過ダメージ

## EnemyDigestionTargetSorter

担当：

* 消化処理順の決定
* priorityや盤面位置による並べ替え

## EnemyDigestionResultBuilder

担当：

* `EnemyDigestionResult`
* `EnemyDigestionBatchResult`
* 消化済み敵一覧

## 禁止事項

分割後の各クラスが、相互に全機能を呼び合う構造にしてはいけません。

巨大クラスのメソッドをファイルへ分けただけの実装は禁止します。

---

# 9. EnemyEffectSystemの責務を限定する

`EnemyEffectSystem`が以下を直接実行している場合は見直してください。

```gdscript
enemy.data.defense_status.reset_refresh_modifiers()
enemy.data.attack.reset_modifiers()
enemy.data.hp.reset_modifiers()
enemy.data.hp.apply_modifiers()
```

これらがEffectライフサイクル上必要であれば、専用クラスへ移してください。

例：

```text
EnemyEffectRefreshProcessor
├─ modifier reset
├─ passive effect request
└─ modifier apply
```

`EnemyEffectSystem`本体は以下に限定してください。

* EffectStackの所有または参照
* Effectインスタンスのbind／unbind
* Installerの呼び出し
* Effect実行ライフサイクルの入口
* 移行期間中のFacade

HP、攻撃、防御の具体的なリセット処理を直接知る必要はありません。

---

# 10. 新しい巨大Context／Managerを作らない

以下のようなクラスを新設して、今回の依存をすべて集めてはいけません。

* `EnemyEffectContext`
* `EnemyEffectRuntime`
* `EnemyEffectServices`
* `EnemyEffectEnvironment`
* `EnemyBattleContext`
* `EnemyManager`
* `EnemyDigestionContext`

以下を同時に保持するクラスは禁止します。

```text
全敵一覧
胃袋
時刻
PlayerHealth
EnemyHp
EnemyAttack
EnemyEffectStack
EnemySpawnQueue
View
Presenter
ダメージ計算
Effect発動
```

依存を一つのオブジェクトへまとめて各Effectへ渡す方法は禁止します。

---

# 11. テスト要件

以下のテストを追加または修正してください。

## 状態クラス

* `EnemyHp`がEnemyEffect関連型へ依存していない
* `BattleClock`がEnemyEffect関連型へ依存していない
* `EnemyDigestionState`がEnemyEffect関連型へ依存していない
* 状態変更時に普遍的Signalだけが発行される

## Effect

* Signal受信後にActivationDataをEffect側で作成する
* Request前に条件判定される
* 新しいActivationDataを追加しても`EnemyEffect`基底を変更する必要がない
* 消化済み所有者の発動可否がポリモーフィズムで判定される
* 不要な依存をInstallerから取得できない

## DigestionResolver

* ResolverがViewメソッドを呼ばない
* ResolverがEffectの具体イベントを通知しない
* 正しいダメージ結果を返す
* 超過ダメージが適用前HPを基準に計算される
* EffectStackの実行順管理を持たない

## Presenter

* HP変更SignalでViewが更新される
* ダメージSignalで演出が実行される
* 攻撃力変更Signalで表示が更新される
* ResolverからViewを直接呼ばず、Presenter経由で表示される
* unbind後はModel Signalを受信しない

## 解析・回帰

* 全GDScriptをロードしてParse Errorがない
* すべての既存Effect Resourceをロードできる
* Gameシーンを起動できる
* 消化、復活、隣接効果、時間経過効果が従来どおり動作する

---

# 12. 実装完了条件

以下をすべて満たした時点で完了としてください。

## Model

* 状態クラスが`EnemyEffectActivationData`へ依存していない
* 状態クラスが`EnemyEffectSystem`へ依存していない
* 普遍的なSignalだけを発行している

## EnemyEffect

* 基底クラスに具体ActivationData型の大量判定がない
* 発動契機別の処理が中間基底へ移動している
* Event enumによる分岐がない
* 必要な依存だけを保持している
* InstallerをService Locatorとして使用していない

## EnemyDigestionResolver

* Viewを操作していない
* Effect種別を指定して通知していない
* EffectStackの実行管理をしていない
* 消化計算と結果生成に責務が限定されている
* 必要に応じて計算、並び替え、結果生成が分離されている

## MVP

* EnemyPresenterがModel SignalをViewへ反映している
* EnemyViewがゲーム状態を変更していない
* Enemy Nodeの表示ロジックが減っている
* ControllerおよびResolverがViewを直接操作していない

## 品質

* `EnemyEffectOnAdjacentAcidDamage`を含む全スクリプトが解析可能
* 新しい巨大クラスが作られていない
* 循環依存がない
* 既存動作を維持している
* 追加・既存テストがすべて成功している

---

# 13. 実装順序

以下の順で作業してください。

1. 全GDScriptのParse Errorを修正する
2. ModelからActivationData依存を除去する
3. 普遍的Signalへ変更する
4. Effect側でActivationDataを生成する
5. `EnemyDigestionResolver`からView操作を除去する
6. `EnemyDigestionResolver`からEffect実行管理を除去する
7. `EnemyEffect`基底の具体型判定を中間基底へ移す
8. InstallerのService Locator利用を除去する
9. PresenterへModelとViewの接続を移す
10. `EnemyEffectSystem`の状態リセット処理を分離する
11. 必要なテストを追加する
12. 全ゲーム動作を回帰確認する

各段階でプロジェクトが起動できる状態を維持してください。

---

# 14. 作業完了報告

実装後、以下を報告してください。

1. 修正したクラス一覧
2. 新規作成したクラス一覧
3. 削除した依存関係
4. Modelから削除したEffect関連型
5. `EnemyDigestionResolver`から移動した処理
6. `EnemyEffect`基底から移動した処理
7. Presenterへ移した表示処理
8. 残している互換Facade
9. 未完了箇所
10. 実行したテストと結果
11. Parse Errorがないことの確認結果
12. 既存動作へ影響する可能性がある箇所

コードを別ファイルへ移したことではなく、責務と依存方向が正しくなったことを成果として扱ってください。
