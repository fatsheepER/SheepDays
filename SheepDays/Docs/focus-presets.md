# Focus Presets

本文档记录聚焦预设的当前设计、关键语义，以及后续扩展 Focus 设置项和“上次聚焦状态”持久化时应遵守的方式。

## 目标

Focus 预设用于保存一组 `HomeFocusState` 的快照，让用户可以在 `FocusSheetView` 中快速恢复来源、标签、时间范围、排序和分组设置。

同一组预设是全局共享的：用户创建的 preset 不绑定具体页面，可以应用到 Home 首页，也可以应用到 Memorial 页面。页面差异只体现在当前运行时 Focus 状态和“上次聚焦状态”的持久化 scope 上。

当前实现的核心约束是：

- 预设保存的是配置语义；其中 `.all` 保持动态全选含义，不展开成创建时快照。
- 选中某个预设只表示用户刚刚选择或保存了该预设。
- 任意实际设置变更都会清空当前选中预设。
- 允许创建内部设置完全相同的多个预设。
- 不允许两个预设重名，重名判断使用 trim + lowercase。
- 恢复默认不认为选中了任何预设。
- Home 和 Memorial 的上次 Focus 状态会分开持久化，下次启动分别恢复。

## 数据模型

### FocusPreset

`FocusPreset` 是 SwiftData 持久化模型，位于 `Core/Models/FocusPreset.swift`。

| 属性 | 作用 |
| --- | --- |
| `id` | 预设唯一 ID。用于区分预设、删除预设、保存 UI 当前选中态。 |
| `name` | 用户可见名称。创建时会 trim 首尾空白。 |
| `normalizedName` | 名称唯一性判断字段。当前规则是 trim + lowercase，并带有 SwiftData unique 约束。 |
| `colorHex` | 预设颜色。当前创建时从固定色板随机生成，只展示，不提供编辑入口。 |
| `createdAt` | 创建时间。当前预设列表按它倒序显示。 |
| `updatedAt` | 设置更新时间。调用 `updateSettings(_:)` 时更新。 |
| `settingsVersion` | `settingsData` 的结构版本。当前写入 `FocusPresetSettings.currentVersion`。 |
| `settingsData` | `FocusPresetSettings` 经 JSON 编码后的数据，是实际预设配置内容。 |

`FocusPreset` 只负责持久化外壳和编解码：

- 初始化时生成 `id`、`createdAt`、`updatedAt`、`normalizedName`。
- 初始化和 `updateSettings(_:)` 时都会把 `settingsVersion` 写成 `FocusPresetSettings.currentVersion`。
- `decodedSettings()` 当前直接按最新 `FocusPresetSettings` 解码，还没有根据 `settingsVersion` 做迁移分支。

### FocusPresetSettings

`FocusPresetSettings` 是 Codable 值类型，位于 `Core/HomeEngine/Models/FocusPresetSettings.swift`。

它是预设、无名临时 Focus 配置、以及各页面“上次聚焦状态”持久化的共同载体。

当前字段：

| 字段 | 作用 |
| --- | --- |
| `notebookSelection` | 事件本选择语义。支持 `.all`、`.none`、或按 ID 保存显式选择。 |
| `tagSelection` | 标签选择语义。支持 `.all`、`.none`、按名称保存显式选择、或只看无标签项。 |
| `timeRange` | 时间范围。 |
| `sortMode` | 排序方式。 |
| `groupingMode` | 分组方式。 |

`HomeFocusTimeRange`、`HomeSortMode`、`HomeGroupingMode` 都使用稳定 String raw value 并实现 Codable，避免 enum case 顺序变化影响历史数据。

## 快照语义

保存预设时调用：

```swift
FocusPresetSettings.snapshot(from:notebooks:tags:)
```

该方法会把当前 `HomeFocusState` 转成可持久化配置：

- 事件本 `.all` 保存为 `.all`，保持动态全选语义。
- 事件本 `.selected` 直接保存选中 ID。
- 事件本 `.none` 保存为 `.none`。
- 标签 `.all` 保存为 `.all`，保持动态全选语义。
- 标签 `.selected` 会把选中标签 ID 映射成标签名称集合。
- 标签 `.none` 保存为 `.none`。
- 标签 `.untaggedOnly` 保存为独立语义。

这样做是为了让用户选择“全部”时真正代表全部：后续新增事件本或标签后，旧预设和上次 Focus 状态也会自然包含它们。显式选择仍然保持快照语义。

Home 首页的默认状态是 `HomeFocusState()`：

```swift
HomeFocusState(
    notebookSourceFilter: .all,
    tagSourceFilter: .all,
    timeRange: .all,
    sortMode: .targetDateAscending,
    groupingMode: .none
)
```

“恢复默认”使用这个状态，并清空 `selectedPresetID`。

Memorial 页面的默认状态使用同一套结构体，只把排序默认值调整为日期降序：

```swift
HomeFocusState.memorialDefault
```

这让 Memorial 默认优先显示最近发生或当天发生的纪念日，同时仍能应用任意用户 preset。

## 加载与数据协调

加载预设时调用：

```swift
settings.resolved(notebooks: allNotebooks, tags: tags)
```

它会返回：

- `focusState`: 可以直接应用到 Home 的当前状态。
- `prunedSettings`: 清理过无效事件本 ID 的预设设置。

协调规则如下。

事件本：

- 加载时使用所有事件本，包括归档事件本。
- `.all` 会恢复成运行时 `.all`，新增事件本会自动加入。
- `.selected` 只恢复保存的 ID，新增事件本不会自动加入显式选择。
- 归档事件本 ID 保留，继续参与筛选语义。
- 如果预设里保存的某个显式事件本 ID 已不存在，加载时会从 `notebookSelection` 移除，并通过 `updateSettings(_:)` 写回预设。

标签：

- `.all` 会恢复成运行时 `.all`，新增标签会自动加入。
- 标签不按 ID 保存，而是按名称保存。
- 名称匹配规则是 trim + lowercase。
- 已删除的标签名不会从预设中删除。
- 当前仍存在同名标签时，加载预设会自然重新匹配。
- 如果某个预设保存的标签名当前不存在，UI 不会显示对应 chip 被选中，但预设内部仍保留该名称。

## UI 行为

`FocusSheetView` 底部的“预设”按钮是一个 `Menu`。它编辑当前打开页面的 Focus scope：在 Home 页打开时写入 Home 状态，在 Memorial 页打开时写入 Memorial 状态。

当前菜单内容：

- `恢复默认`: 恢复 App 默认 Focus 状态，清空选中预设。
- `删除预设`: 仅当当前被判定为选中某个预设时出现，删除后不改变当前 Focus 设置，只清空选中预设。
- `保存当前为预设`: 弹出名称输入 alert。允许保存同设置不同名的预设，不允许重名。
- `选择预设...`: 二级菜单，列出全部预设，并对当前选中预设显示 checkmark。

当前选中预设状态由页面自己的 `selectedPresetID` 表示。它只在两种情况下被设置：

- 用户选择某个预设。
- 用户成功保存当前状态为新预设。

设置项变更统一通过 `applyFocusStateChange(_:)` 清空当前页面的 `selectedPresetID`。如果用户重复点击当前已选中的值，状态没有实际变化，不会清空选中预设。

Header 中的预设 badge 只展示当前页面 `selectedPresetID` 能解析到的预设。badge 展示预设 `name` 和 `colorHex`。

## settingsVersion

`FocusPresetSettings.currentVersion` 当前为 `2`。

创建或更新 `FocusPreset` 时：

```swift
settingsVersion = FocusPresetSettings.currentVersion
```

`FocusPresetSettings` 目前通过自定义 `Codable` 兼容 v1 字段：

```swift
selectedNotebookIDs -> notebookSelection.selectedIDs / .none
```

v1 已经把 `.all` 展开成当时的 ID 或名称集合，无法无损判断它原本是否来自 `.all`，所以旧数据会按显式选择恢复。只有 v2 之后新写入的数据保证 `.all` 是动态全选。

`FocusPreset.decodedSettings()` 仍直接解码 `FocusPresetSettings`：

```swift
try decoder.decode(FocusPresetSettings.self, from: settingsData)
```

后续如果发生更复杂的不兼容变更，应再改造 `decodedSettings()`，按 `settingsVersion` 分支解码旧结构并转换成当前 `FocusPresetSettings`。

推荐迁移形态：

```swift
func decodedSettings() throws -> FocusPresetSettings {
    switch settingsVersion {
    case 1:
        return try Self.decoder.decode(FocusPresetSettings.self, from: settingsData)
    default:
        return try Self.decoder.decode(FocusPresetSettings.self, from: settingsData)
    }
}
```

当旧版本字段语义已经不能由当前结构直接解码时，应新增私有 `FocusPresetSettingsV1` 之类的过渡结构，并提供转换方法。

## 扩展 Focus 设置项

未来高级选项可能包含 toggle、单选、多选、枚举、数值范围等。扩展时优先遵守下面的顺序。

### 1. 先扩展 HomeFocusState

`HomeFocusState` 是当前 UI 和 Home 查询的运行时状态。新增设置项时，先给它增加一个有默认值的字段，例如：

```swift
var hidesCompletedEvents: Bool = false
```

同时更新 Home 侧实际消费逻辑，例如 `HomeBuilder.matchesFilters`、排序或分组逻辑。

### 2. 再扩展 FocusPresetSettings

如果该设置需要被预设和未来临时状态持久化，就把它加入 `FocusPresetSettings`。

优先选择能稳定编码的类型：

- Bool 适合 toggle。
- String raw value enum 适合单选。
- Set 或 Array 适合多选，但要明确是否需要保持顺序。
- 如果依赖业务对象，优先保存稳定身份或稳定语义，而不是 UI 临时状态。

新增字段应提供默认值或自定义解码 fallback，保证旧 `settingsData` 能继续解码。当前 `FocusPresetSettings` 已使用自定义 Codable，需要继续维护旧数据兼容路径。

### 3. 更新 snapshot 和 resolved

任何新增字段都必须考虑两个方向：

- `snapshot(from:notebooks:tags:)`: 当前运行时状态如何保存成持久化配置。
- `resolved(notebooks:tags:)`: 持久化配置如何恢复成运行时状态。

如果字段依赖会变化的外部实体，还要定义协调规则。例如：

- 新实体默认是否加入旧预设。
- 删除实体后是否 prune。
- 归档实体是否保留。
- 是否按 ID、名称还是其他稳定 key 匹配。

### 4. 更新默认状态和选中态清空

新增设置项后需要检查：

- `HomeFocusState` 默认值是否符合“恢复默认”的 App 语义。
- `FocusSheetView.activeFilterCount` 是否需要计数。
- UI 改动是否通过 `applyFocusStateChange(_:)`，以便实际变化时清空 `selectedPresetID`。
- 重复选择当前值是否会被 guard 掉，避免误清空选中预设。

### 5. 需要时提升 settingsVersion

如果只是新增可向后兼容字段，可以不立即提升版本，但仍建议在明确改变持久化语义时提升 `FocusPresetSettings.currentVersion`。

应提升版本的情况包括：

- 字段含义改变。
- 某个字段从 ID 改为名称，或从名称改为 ID。
- 默认值改变会影响旧预设解释结果。
- 旧数据需要一次性转换。

## 上次 Focus 状态持久化

“上次 Focus 状态”不复用 `FocusPreset` 本身，因为它不需要用户名称、颜色、列表展示和重名规则。

当前使用 `LastFocusStateStore` 按 scope 存入 `UserDefaults`：

- Home: `Focus.lastState`
- Memorial: `Focus.memorial.lastState`

Home key 沿用旧值，因此已有用户的 Home 上次聚焦状态可以继续恢复。每个 payload 包含：

- `settingsVersion`
- `settings: FocusPresetSettings`
- `selectedPresetID: UUID?`

恢复规则：

- App 启动后 `HomeView` 首次出现时分别读取 Home 和 Memorial payload。
- 如果 `selectedPresetID` 存在且对应预设仍存在，优先用该预设当前 settings 恢复，并恢复 header badge / 菜单 checkmark。
- 如果预设不存在或预设恢复失败，fallback 到 payload 内的 `settings`，并清空选中预设身份。
- 手动调整 Focus 设置、选择预设、保存预设、删除当前预设、恢复默认都会立即写回当前页面 scope 的 payload。
- 删除 preset 时会清理所有 scope 中指向该 preset 的 `selectedPresetID`，避免另一个页面残留已删除 preset 的 badge/checkmark。

这样可以让预设和临时状态共享同一套配置、协调和迁移规则，同时避免把临时状态污染到用户可见预设列表。

## 测试建议

新增或修改 Focus 持久化语义时，至少覆盖：

- `.all` 保存后，新增事件本或标签会进入旧预设或上次状态。
- 显式选择保存后，新增事件本或标签不会进入该显式选择。
- 删除事件本后加载预设会 prune ID 并写回。
- 删除标签后加载预设不会删除标签名。
- 同设置不同名允许保存。
- trim + lowercase 后同名不允许保存。
- 设置项实际变化会清空 `selectedPresetID`。
- 选择或保存预设会设置 `selectedPresetID`。
- App 重启后能恢复上次 Focus 状态；上次来自现存预设时能恢复预设 badge/checkmark。
- Home 和 Memorial 的上次状态互不覆盖；同一个 preset 可以分别应用到两个页面。

验证方式保持轻量：

```sh
swift test
xcodebuild -project SheepDays.xcodeproj -scheme SheepDays -destination 'generic/platform=iOS Simulator' build
```

不需要为这个功能常规运行模拟器或截图手测。
