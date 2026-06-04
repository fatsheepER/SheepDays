# App Theme

本文档记录 SheepDays 主题色的当前实现和后续扩展路径。主题系统的目标是把页面或用户偏好的颜色选择集中到一个环境值里，避免各个组件直接判断业务状态或硬编码 asset 名称。

## 当前实现

主题入口定义在 `Core/Theme/SheepDaysTheme.swift`：

```swift
struct SheepDaysTheme {
    let accentColor: Color
    let secondaryAccentColor: Color
}
```

当前内置两套主题：

- `.standard`：使用 `AccentColor` 和 `SecondaryAccentColor`。
- `.memorial`：使用 `MemorialAccentColor` 和 `SecondaryMemorialAccentColor`。

`secondaryAccentColor` 表示主 accent 的轻量背景色。默认初始化时会从 `accentColor.opacity(0.2)` 派生；内置主题则直接使用 asset 中已经配置好的 secondary color。

主题通过环境注入：

```swift
someView
    .sheepDaysTheme(.memorial)
```

这个 modifier 同时设置 `\.sheepDaysTheme` 和 SwiftUI 控件 tint，因此新增组件应优先读取 `@Environment(\.sheepDaysTheme)`，原生控件 tint 也能跟随主题。

## Home 页面主题

`Features/Home/HomeView.swift` 根据当前分页选择主题：

```swift
var activeHomeTheme: SheepDaysTheme {
    activeHomeContentPage == .expiredMemorials ? .memorial : .standard
}
```

Home 主内容和 bottom sheet 都注入同一套 `activeHomeTheme`。因此当页面切到已过纪念日分页时，以下位置会自动切到 memorial palette：

- `HomeDateView` 的日期主色和日期阴影。
- `SDIncreBadge` 的文字色和 20% secondary 背景色。
- `HomeSheetView` 顶部左右按钮的前景色和背景色。
- `SDSheetActionButtonAppearance.prominent` 的前景色和 20% secondary 背景色。

## 扩展约定

新增主题时，优先扩展 `SheepDaysTheme` 的静态 preset，或在设置模型里保存用户选择后构造 `SheepDaysTheme(accentColor:secondaryAccentColor:)`。

新增组件如果需要使用 App 主题色，应通过环境读取：

```swift
@Environment(\.sheepDaysTheme) private var theme
```

然后使用 `theme.accentColor` 和 `theme.secondaryAccentColor`。不要在组件内部判断 Home 分页、事件类型或具体 asset 名称。

共享组件 preset 如果需要随主题变化，应保留外部 API 的语义名称，在渲染时解析为当前主题色。`SDSheetActionButtonAppearance.prominent` 就是这种模式：调用方继续传 `.prominent`，按钮内部根据环境主题解析颜色。
