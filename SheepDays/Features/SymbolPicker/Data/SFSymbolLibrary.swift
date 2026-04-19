//
//  SymbolPickerLibrary.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/18.
//

enum SFSymbolLibrary {
    static let notebookSections: [SFSymbolSection] = [
        SFSymbolSection(
            title: "常用",
            symbols: [
                SFSymbolChoice(systemName: "book.closed", title: "书本"),
                SFSymbolChoice(systemName: "book.closed.fill", title: "书本填充"),
                SFSymbolChoice(systemName: "books.vertical", title: "书架"),
                SFSymbolChoice(systemName: "tray.full.fill", title: "收纳盘"),
                SFSymbolChoice(systemName: "archivebox.fill", title: "归档盒"),
                SFSymbolChoice(systemName: "figure.roll.runningpace", title: "轮椅竞速"),
                SFSymbolChoice(systemName: "dpad", title: "游戏按键"),
                SFSymbolChoice(systemName: "keyboard", title: "键盘"),
                SFSymbolChoice(systemName: "star", title: "五角星"),
                SFSymbolChoice(systemName: "heart", title: "爱心"),
                SFSymbolChoice(systemName: "figure.run", title: "跑步"),
                SFSymbolChoice(systemName: "sun.max", title: "太阳"),
            ]
        ),
        SFSymbolSection(
            title: "工作",
            symbols: [
                SFSymbolChoice(systemName: "briefcase.fill", title: "公文包"),
                SFSymbolChoice(systemName: "building.2.fill", title: "办公楼"),
                SFSymbolChoice(systemName: "desktopcomputer", title: "电脑"),
                SFSymbolChoice(systemName: "hammer.fill", title: "工具")
            ]
        ),
        SFSymbolSection(
            title: "生活",
            symbols: [
                SFSymbolChoice(systemName: "house.fill", title: "居家"),
                SFSymbolChoice(systemName: "heart.fill", title: "喜爱"),
                SFSymbolChoice(systemName: "leaf.fill", title: "自然"),
                SFSymbolChoice(systemName: "figure.walk", title: "步行")
            ]
        ),
        SFSymbolSection(
            title: "出行",
            symbols: [
                SFSymbolChoice(systemName: "airplane", title: "飞机"),
                SFSymbolChoice(systemName: "car.fill", title: "汽车"),
                SFSymbolChoice(systemName: "tram.fill", title: "电车"),
                SFSymbolChoice(systemName: "bicycle", title: "自行车")
            ]
        )
    ]

    static let eventSections: [SFSymbolSection] = [
        SFSymbolSection(
            title: "常用",
            symbols: [
                SFSymbolChoice(systemName: "calendar", title: "日历"),
                SFSymbolChoice(systemName: "calendar.badge.clock", title: "日程"),
                SFSymbolChoice(systemName: "flag.fill", title: "目标"),
                SFSymbolChoice(systemName: "star.fill", title: "星标"),
                SFSymbolChoice(systemName: "checkmark.circle.fill", title: "完成"),
                SFSymbolChoice(systemName: "figure.roll.runningpace", title: "轮椅竞速"),
                SFSymbolChoice(systemName: "dpad", title: "游戏按键"),
                SFSymbolChoice(systemName: "keyboard", title: "键盘"),
                SFSymbolChoice(systemName: "star", title: "五角星"),
                SFSymbolChoice(systemName: "heart", title: "爱心"),
                SFSymbolChoice(systemName: "figure.run", title: "跑步"),
                SFSymbolChoice(systemName: "sun.max", title: "太阳"),
            ]
        ),
        SFSymbolSection(
            title: "节日",
            symbols: [
                SFSymbolChoice(systemName: "gift.fill", title: "礼物"),
                SFSymbolChoice(systemName: "party.popper.fill", title: "派对"),
                SFSymbolChoice(systemName: "sparkles", title: "闪耀"),
                SFSymbolChoice(systemName: "balloon.2.fill", title: "气球")
            ]
        ),
        SFSymbolSection(
            title: "时间",
            symbols: [
                SFSymbolChoice(systemName: "clock.fill", title: "时钟"),
                SFSymbolChoice(systemName: "hourglass", title: "沙漏"),
                SFSymbolChoice(systemName: "bell.fill", title: "提醒"),
                SFSymbolChoice(systemName: "timer", title: "计时器")
            ]
        ),
        SFSymbolSection(
            title: "出行",
            symbols: [
                SFSymbolChoice(systemName: "airplane", title: "飞机"),
                SFSymbolChoice(systemName: "car.fill", title: "汽车"),
                SFSymbolChoice(systemName: "tram.fill", title: "电车"),
                SFSymbolChoice(systemName: "ferry.fill", title: "轮渡")
            ]
        ),
        SFSymbolSection(
            title: "生活",
            symbols: [
                SFSymbolChoice(systemName: "heart.fill", title: "喜爱"),
                SFSymbolChoice(systemName: "house.fill", title: "居家"),
                SFSymbolChoice(systemName: "leaf.fill", title: "自然"),
                SFSymbolChoice(systemName: "moon.stars.fill", title: "夜晚")
            ]
        )
    ]
}
