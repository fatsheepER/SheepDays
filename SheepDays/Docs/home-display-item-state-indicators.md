# Home Display Item State Indicators

本文档记录 `HomeDisplayItemView` 状态指示图标的当前实现、数据流，以及后续扩展新图标或按页面控制图标显示范围时应遵守的方式。

## 目标

状态指示图标用于在事件行右侧展示一组轻量、可选的事件状态，例如：

- 事件是否包含检查清单。
- 事件是否是循环事件。
- 事件是否设置了提醒。
- 事件是否显示在首页。
- 事件是否被置顶。

当前已经落地的第一个实际状态是 `checklist`：只要事件里至少有一个 `ChecklistItem`，就显示 checklist 图标。

核心约束是：

- `HomeDisplayItemView` 不直接读取 SwiftData 的 `Event`，只消费 `HomeDisplayItem` 的轻量展示数据。
- 事件拥有哪些状态，由 `HomeBuilder` 在构造 `HomeDisplayItem` 时投影出来。
- 当前页面允许显示哪些状态，由调用方通过 `visibleStateIndicators` 控制。
- 图标的种类、顺序、SF Symbol 和无障碍文案集中定义，避免散落在多个 View 中。
- 首页默认不显示 `showOnHome` 图标；`NotebookDetailContentView` 这类页面可以选择显示。

## 当前实现

### 状态类型

状态类型定义在 `Core/HomeEngine/Models/HomeDisplayItem.swift`：

```swift
nonisolated enum HomeDisplayItemStateIndicator: Hashable, CaseIterable, Identifiable {
    case checklist
    case recurrence
    case reminder
    case showOnHome
    case pinned
}
```

每个 case 同时负责提供自己的 SF Symbol 和无障碍文案：

| 状态 | 图标 | 语义 |
| --- | --- | --- |
| `.checklist` | `checklist` | 包含检查清单 |
| `.recurrence` | `repeat` | 循环事件 |
| `.reminder` | `bell.fill` | 已设置提醒 |
| `.showOnHome` | `star.fill` | 显示在首页 |
| `.pinned` | `pin.fill` | 已置顶 |

`HomeDisplayItemStateIndicator` 和 `HomeDisplayItem` 都标记为 `nonisolated`，因为项目当前构建参数启用了默认 MainActor 隔离；这些类型是纯展示数据，不应产生 actor 隔离约束。

### 可见范围预设

同一个文件里为 `Set<HomeDisplayItemStateIndicator>` 定义了预设：

```swift
extension Set where Element == HomeDisplayItemStateIndicator {
    static let home: Self = [.checklist]
    static let notebookDetail: Self = [.checklist, .recurrence, .reminder, .showOnHome, .pinned]
    static let allStateIndicators: Self = Self(HomeDisplayItemStateIndicator.allCases)
}
```

这些预设表达的是“某个页面允许显示哪些图标”，不是“事件实际拥有哪些状态”。

当前约定：

- `.home`：首页事件行使用，只显示 checklist。
- `.notebookDetail`：预留给未来事件本详情页使用，允许显示完整状态集合。
- `.allStateIndicators`：调试、预览或临时验证时使用。

如果某个页面只想显示部分图标，也可以直接传自定义集合：

```swift
HomeDisplayItemRow(
    item: item,
    visibleStateIndicators: [.checklist, .reminder]
)
```

### 展示模型

`HomeDisplayItem` 增加了 `stateIndicators`：

```swift
nonisolated struct HomeDisplayItem: Identifiable {
    let stateIndicators: Set<HomeDisplayItemStateIndicator>
}
```

它表示事件实际具备的状态集合。初始化器提供默认值 `[]`，因此没有状态的 preview 或旧调用点仍然可以保持简洁。

### 状态投影

状态投影发生在 `Core/HomeEngine/HomeBuilder.swift`：

```swift
static func makeStateIndicators(from event: Event) -> Set<HomeDisplayItemStateIndicator> {
    var indicators: Set<HomeDisplayItemStateIndicator> = []

    if event.hasChecklistItems {
        indicators.insert(.checklist)
    }

    if !event.reminderPresets.isEmpty {
        indicators.insert(.reminder)
    }

    if event.showOnHome {
        indicators.insert(.showOnHome)
    }

    if event.pinToTop {
        indicators.insert(.pinned)
    }

    return indicators
}
```

当前 `.recurrence` 已在状态类型中预留，但因为循环事件模型还没有实际接入，所以暂时不会被 `HomeBuilder` 插入。

Checklist 当前判定来自 `Event.hasChecklistItems`：

```swift
var hasChecklistItems: Bool {
    !checklistItems.isEmpty
}
```

因此只要事件内添加了至少一个 checklist item，`HomeDisplayItem` 就会包含 `.checklist`。

### 图标渲染

`Features/Home/Components/HomeDisplayItemView.swift` 增加了：

```swift
var visibleStateIndicators: Set<HomeDisplayItemStateIndicator> = .home
```

实际显示的图标是事件状态与页面允许状态的交集：

```swift
var displayedStateIndicators: [HomeDisplayItemStateIndicator] {
    HomeDisplayItemStateIndicator.allCases.filter {
        item.stateIndicators.contains($0) && visibleStateIndicators.contains($0)
    }
}
```

这里使用 `HomeDisplayItemStateIndicator.allCases` 过滤，而不是直接遍历 Set，是为了让图标顺序稳定。后续如果要调整显示顺序，调整 enum case 顺序即可。

每个图标统一使用以下视觉参数：

```swift
Image(systemName: indicator.systemName)
    .font(.system(size: 15, weight: .semibold, design: .rounded))
    .foregroundStyle(Color(.tertiaryLabel))
    .frame(width: 20)
```

图标组位于事件标题和 badge 之间：

```swift
HStack {
    primaryContent
    Spacer()
    stateIndicatorsView
    badgeView
}
```

### Row 透传

`Features/Home/Components/HomeDisplayItemRow.swift` 同样暴露：

```swift
var visibleStateIndicators: Set<HomeDisplayItemStateIndicator> = .home
```

并传给内部的 `HomeDisplayItemView`。因此普通首页调用不需要改动；未来其它页面复用 `HomeDisplayItemRow` 时，可以选择不同预设。

## 数据流

当前完整链路如下：

1. `Event` 持有业务数据，例如 `checklistItems`、`reminderPresets`、`showOnHome`、`pinToTop`。
2. `HomeBuilder.makeDisplayItem(from:query:)` 构造 `HomeDisplayItem`。
3. `HomeBuilder.makeStateIndicators(from:)` 把 `Event` 投影成 `Set<HomeDisplayItemStateIndicator>`。
4. `HomeDisplayItemRow` 接收 `HomeDisplayItem`，并决定该页面允许显示哪些状态。
5. `HomeDisplayItemView` 计算 `item.stateIndicators` 和 `visibleStateIndicators` 的交集。
6. `HomeDisplayItemView` 用统一样式渲染最终图标。

这个分层避免了展示组件直接依赖 SwiftData 模型，也让不同页面可以共享同一个行组件。

## 页面显示策略

### 首页

首页默认使用：

```swift
visibleStateIndicators: .home
```

当前 `.home` 只包含 `.checklist`。即使 `HomeDisplayItem` 里同时有 `.showOnHome`、`.pinned` 或 `.reminder`，首页也不会显示这些图标。

这符合首页语义：能进入首页的常规事件本身已经满足 `showOnHome` 过滤条件，重复显示星标没有信息增量。

### NotebookDetailContentView

`NotebookDetailContentView` 如果复用 `HomeDisplayItemRow`，可以传：

```swift
HomeDisplayItemRow(
    item: item,
    visibleStateIndicators: .notebookDetail,
    openDetail: { openEventDetail(for: item.sourceEventId) }
)
```

这样同一个事件行在事件本详情页可以显示 `showOnHome` 图标，用于区分哪些事件会同步出现在首页。

### 自定义页面

如果某个页面只关心提醒和 checklist，可以传：

```swift
visibleStateIndicators: [.checklist, .reminder]
```

不要新增一次性的布尔参数，例如 `showsChecklistIcon`、`showsReminderIcon`。状态越多，布尔参数越容易膨胀；统一使用集合更适合后续扩展。

## 扩展新图标

新增一种状态时，按以下步骤修改。

### 1. 添加状态 case

在 `HomeDisplayItemStateIndicator` 中添加 case：

```swift
case archived
```

同时补充 `systemName` 和 `accessibilityLabel`：

```swift
case .archived:
    "archivebox.fill"
```

```swift
case .archived:
    "已归档"
```

图标显示顺序由 enum case 顺序决定。如果希望新图标显示在 checklist 后面，就把 case 放在 `.checklist` 后面。

### 2. 决定哪些页面允许显示

把新状态加入合适的预设：

```swift
static let notebookDetail: Self = [
    .checklist,
    .archived,
    .recurrence,
    .reminder,
    .showOnHome,
    .pinned
]
```

只有明确需要的页面才加入。不要为了“状态存在”就默认让所有页面显示。

### 3. 在 HomeBuilder 中投影状态

在 `makeStateIndicators(from:)` 中插入判定：

```swift
if event.isArchived {
    indicators.insert(.archived)
}
```

如果新状态需要新模型字段，先完成模型和持久化设计，再在这里接入。`HomeDisplayItemView` 不应直接读取 `Event`。

### 4. 更新 Preview

给 `HomeDisplayItemView` 或 `HomeDisplayItemRow` 的 preview 加一个包含新状态的样例：

```swift
stateIndicators: [.checklist, .archived, .reminder]
```

同时使用包含该状态的 `visibleStateIndicators`，确保图标能在预览里出现。

### 5. 验证构建

SwiftUI 或 HomeEngine 代码变更后，至少运行：

```sh
xcodebuild -project SheepDays.xcodeproj -scheme SheepDays -destination 'generic/platform=iOS Simulator' build
```

如果只是修改本文档，可以用：

```sh
git diff --check -- SheepDays/Docs/home-display-item-state-indicators.md
```

## 设计注意事项

- `stateIndicators` 表示事件事实，`visibleStateIndicators` 表示页面显示策略，二者不要混用。
- 不要在 `HomeDisplayItemView` 中追加业务判断，例如 `if event.showOnHome`；展示层只关心传入的展示数据。
- 不要把状态图标写成多个独立可选 `Image`；统一 `ForEach(displayedStateIndicators)` 可以保持样式和顺序一致。
- 新图标优先使用 SF Symbols，并保持 20pt 固定宽度，避免 badge 位置因图标种类变化而抖动。
- 如果新图标只在未来功能中可用，可以先添加 enum case 和预设，但不要在 `HomeBuilder` 中插入，直到模型数据可用。
- 如果某个页面需要不同顺序，优先考虑调整 enum case 顺序；只有在确实存在页面专属顺序需求时，再引入更明确的排序配置。
