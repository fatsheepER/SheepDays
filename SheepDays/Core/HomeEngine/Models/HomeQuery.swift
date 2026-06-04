//
//  HomeQuery.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import Foundation

enum HomeQueryScope: String {
    case homeUpcoming
    case memorialPast
}

struct HomeQuery {
    let scope: HomeQueryScope
    let referenceDate: Date
    let notebookSourceFilter: HomeNotebookSourceFilter
    let tagSourceFilter: HomeTagSourceFilter
    let timeRangeFilter: HomeFocusTimeRange
    let groupingMode: HomeGroupingMode
    let sortingMode: HomeSortMode
    let includeAllEvents: Bool  // true => including !showOnHome
}
