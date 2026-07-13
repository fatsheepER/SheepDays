//
//  HomeView+Actions.swift
//  SheepDays
//
//  Created by Codex on 2026/6/12.
//

import SwiftUI
import SwiftData

extension HomeView {
    func insertPreviewEvents() {
        do {
            try HomePreviewSupport.removePreviewData(in: modelContext)
            try HomePreviewSupport.insertPreviewData(in: modelContext)
            contentRefreshToken += 1
        } catch {
            assertionFailure("Failed to insert preview events: \(error.localizedDescription)")
        }
    }

    func removePreviewEvents() {
        do {
            try HomePreviewSupport.removePreviewData(in: modelContext)
            try modelContext.save()
            contentRefreshToken += 1
        } catch {
            assertionFailure("Failed to remove preview events: \(error.localizedDescription)")
        }
    }

    func openEventDetailFromHomeRow(for eventID: UUID) {
        guard !suppressHomeRowActions else {
            return
        }

        openEventDetail(for: eventID)
    }

    func openEventDetail(for eventID: UUID) {
        haptics.play(.openDetailTap)
        withAnimation {
            presentEventDetail(for: eventID)
        }
    }

    func presentEventDetail(for eventID: UUID) {
        do {
            let predicate = #Predicate<Event> { event in
                event.id == eventID
            }
            var descriptor = FetchDescriptor<Event>(predicate: predicate)
            descriptor.fetchLimit = 1
            if let event = try modelContext.fetch(descriptor).first {
                selectedEvent = event
                notebookEditorOption = nil
                sheetRoute = .eventDetail
            }
        } catch {
            assertionFailure("Failed to load event detail: \(error.localizedDescription)")
        }
    }

    func jumpHomeDateFromHomeRowIfPossible(_ targetDate: Date?) {
        guard !suppressHomeRowActions else {
            return
        }

        jumpHomeDateIfPossible(targetDate)
    }

    func jumpHomeDateIfPossible(_ targetDate: Date?) {
        guard let targetDate else {
            return
        }

        jumpHomeDate(to: targetDate)
    }

    func jumpHomeDate(to date: Date) {
        cancelDateRestore()

        let normalizedDate = HomeReferenceDate.normalized(date)

        haptics.play(.selectionStep)
        withAnimation {
            referenceDate = normalizedDate
        }
    }

    func presentRelativeValuePromptFromHomeRowIfPossible(_ targetDate: Date?) {
        guard !suppressHomeRowActions else {
            return
        }

        presentRelativeValuePrompt(for: targetDate)
    }

    func presentRelativeValuePrompt(for targetDate: Date?) {
        guard let targetDate else {
            return
        }

        relativeValueInput = ""
        relativeValuePrompt = HomeRelativeValuePrompt(
            targetDate: HomeReferenceDate.normalized(targetDate),
            mode: HomeRelativeValueMode(page: activeHomeContentPage ?? .upcoming)
        )
    }

    var relativeValuePromptIsPresented: Binding<Bool> {
        Binding(
            get: { relativeValuePrompt != nil },
            set: { isPresented in
                if !isPresented {
                    clearRelativeValuePrompt()
                }
            }
        )
    }

    var parsedRelativeDayOffset: Int? {
        let normalizedInput = relativeValueInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "＋", with: "+")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "－", with: "-")

        guard !normalizedInput.isEmpty else {
            return nil
        }

        return Int(normalizedInput)
    }

    func applyRelativeValuePrompt() {
        guard let relativeValuePrompt,
              let relativeDayOffset = parsedRelativeDayOffset,
              let targetDate = relativeValuePrompt.referenceDate(
                forRelativeDayOffset: relativeDayOffset,
                calendar: .current
              ) else {
            haptics.play(.error)
            return
        }

        clearRelativeValuePrompt()
        jumpHomeDate(to: targetDate)
    }

    func clearRelativeValuePrompt() {
        relativeValuePrompt = nil
        relativeValueInput = ""
    }

    func restoreHomeDateToToday(
        stepCount requestedStepCount: Int = Self.todayRestoreStepCount,
        stepDelay: Duration = Self.todayRestoreStepDelay,
        minimumSegmentedDayOffset: Int = Self.todayRestoreMinimumSegmentedDayOffset
    ) {
        dateRestoreTask?.cancel()
        dateRestoreToken += 1
        let restoreToken = dateRestoreToken

        let calendar = Calendar.current
        let targetDate = HomeReferenceDate.normalized(.now, calendar: calendar)
        let startDate = HomeReferenceDate.normalized(referenceDate, calendar: calendar)
        let dayOffset = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? 0

        guard dayOffset != 0 else {
            haptics.play(.error)
            referenceDate = targetDate
            dateRestoreTask = nil
            return
        }

        let totalDistance = abs(dayOffset)
        guard totalDistance >= max(minimumSegmentedDayOffset, 1) else {
            withAnimation {
                haptics.play(.selectionStep)
                referenceDate = targetDate
            }
            dateRestoreTask = nil
            return
        }

        let direction = dayOffset.signum()
        let stepCount = min(totalDistance, max(requestedStepCount, 1))
        let stepDates = (1...stepCount).compactMap { stepIndex in
            let progress = Double(stepIndex) / Double(stepCount)
            let stepDistance = Int((Double(totalDistance) * progress).rounded()) * direction
            return calendar.date(byAdding: .day, value: stepDistance, to: startDate)
        }

        dateRestoreTask = Task { @MainActor in
            for stepIndex in stepDates.indices {
                guard restoreToken == dateRestoreToken, !Task.isCancelled else {
                    return
                }

                withAnimation {
                    haptics.play(.selectionStep)
                    referenceDate = stepDates[stepIndex]
                }

                guard stepIndex < stepDates.index(before: stepDates.endIndex) else {
                    continue
                }

                do {
                    try await Task.sleep(for: stepDelay)
                } catch {
                    return
                }
            }

            guard restoreToken == dateRestoreToken else {
                return
            }

            dateRestoreTask = nil
        }
    }

    func cancelDateRestore() {
        dateRestoreTask?.cancel()
        dateRestoreTask = nil
        dateRestoreToken += 1
    }

    var interactiveReferenceDate: Binding<Date> {
        Binding(
            get: { referenceDate },
            set: { newValue in
                cancelDateRestore()
                referenceDate = HomeReferenceDate.normalized(newValue)
            }
        )
    }

    func dismissEventDetail() {
        haptics.play(.openDetailTap)
        withAnimation(.spring(duration: 0.2)) {
            sheetRoute = .home
            selectedEvent = nil
            notebookEditorOption = nil
        }
        refreshHomeContent()
    }

    func refreshHomeContent() {
        contentRefreshToken += 1
    }

    func dismissNotebookEditor() {
        haptics.play(.openDetailTap)
        withAnimation(.spring(duration: 0.2)) {
            notebookEditorOption = nil
            sheetRoute = .home
            isNotebooksSheetPresented = true
        }
        refreshHomeContent()
    }

    func presentSymbolPicker(_ presentation: SymbolPickerPresentation) {
        haptics.play(.openDetailTap)
        overlayCoordinator.present(
            .symbolPicker(
                presentation: presentation,
                onDismiss: handleSymbolPickerDismissed
            )
        )
    }

    func presentTagList(_ presentation: TagListPresentation) {
        haptics.play(.openDetailTap)
        overlayCoordinator.present(
            .tagList(
                presentation: presentation,
                onDismiss: handleTagListDismissed
            )
        )
    }

    func handleSymbolPickerDismissed() {
        haptics.play(.openDetailTap)
    }

    func handleTagListDismissed() {
        haptics.play(.openDetailTap)
        refreshHomeContent()
    }
}
