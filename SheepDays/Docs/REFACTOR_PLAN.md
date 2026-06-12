# REFACTOR\_PLAN

You are refactoring a large SwiftUI view file.

Target file:

`<PATH_TO_LARGE_VIEW.swift>`

First, do not edit any code.

Read the file and produce a refactor map with the following sections:

1. Current structure

   * Main entry type
   * Major body sections
   * Existing extracted subviews
   * Existing helper methods
   * Alert/sheet/dialog logic
   * Toolbar/safeAreaInset/bottom controls
   * Gesture/focus/animation/scroll logic

2. State and dependency inventory

   * List all property wrappers.
   * For each `@State`, `@Binding`, `@Bindable`, `@Query`, `@Environment`, `@FocusState`, and callback closure, explain what it appears to control.
   * Identify which states are local UI state and which states affect model persistence or cross-component behavior.

3. Safe extraction candidates

   * Group sections into low-risk, medium-risk, and high-risk extraction candidates.
   * Prefer low-risk visual sections first.
   * Mark any section that should not be extracted yet.

4. Proposed file decomposition

   * Suggest file names.
   * For each proposed file, list the types or helpers it should contain.
   * Keep the decomposition conservative.

5. Refactor order

   * Give a step-by-step order where each step should compile independently.
   * Each step should be small enough for a clean code review.

Do not modify files in this task.

