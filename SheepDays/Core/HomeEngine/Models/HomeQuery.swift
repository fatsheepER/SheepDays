//
//  HomeQuery.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import Foundation

struct HomeQuery {
    let referenceDate: Date
    let includedNotebookIDs: Set<UUID>
    let includedTagIDs: Set<UUID>
    let timeRange: HomeFocusTimeRange
    let groupingMode: HomeGroupingMode
    let sortingMode: HomeSortMode
    let includeAllEvents: Bool  // true => including !showOnHome
}
