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
//    let timeWindow: FocusTimeWindow
//    let groupingMode: HomeGroupingMode
//    let sortingMode: HomeSortingMode
    let includeAllEvents: Bool  // true => including !showOnHome
}
