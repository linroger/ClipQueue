# Handoff.md

**Last Updated (UTC):** 2026-01-05T09:59:06Z
**Status:** In Progress
**Current Focus:** Implement queue selection ordering/paste behavior, hotkey fallback registration, and menu bar icon fixes.

The key words "MUST", "SHOULD", and "MAY" in this document are to be interpreted as described in RFC 2119.

## 1) Request & Context
- **User’s request (quoted or paraphrased):** Update ClipQueue macOS app to add settings and behaviors: new paste-newline options, auto-resize queue height, fix custom menu bar icon, multi-selection with command/shift click and keyboard actions, favorites and recents tabs with segmented pickers, context menu actions, drag-to-paste to external apps, configurable keyboard shortcuts without modifier requirement, and tab persistence options.
- **Operational constraints / environment:** macOS app (SwiftUI + AppKit) in `/Users/rogerlin/Downloads/ClipQueue-main-2`; network restricted; must use Apple docs MCP, Cupertino MCP, and local Apple sample code from `/Users/rogerlin/SwiftDB` for guidance; use bd (beads) for issue tracking; create and maintain this handoff.
- **Guidelines / preferences to honor:** Follow AGENTS.md playbook; create step-by-step plan with evidence; use RFC-style MUST/SHOULD/MAY; keep edits small; avoid non-ASCII unless needed; use apply_patch for single-file edits.
- **Scope boundaries (explicit non-goals):** No new features outside listed tasks; no refactor unrelated systems.
- **Changes since start (dated deltas):** 2025-02-14T19:20:00Z - created initial handoff with baseline understanding. 2026-01-05T09:21:52Z - re-read Swift files, ran bd onboard/prime, and gathered Apple docs + SwiftDB references for list selection and status items.

## 2) Requirements → Acceptance Checks (traceable)
| Requirement | Acceptance Check (scenario steps) | Expected Outcome | Evidence to Capture |
|---|---|---|---|
| R1: Settings allow newline after paste with Enter or Shift+Enter | Open Preferences → Behavior; toggle new options; paste item with Enter vs Shift+Enter | App inserts newline per selected option only | Screen recording or log + code diff |
| R2: Queue view auto-resizes height based on item count without changing row size | Enable new auto-resize option; shrink queue to few items | Window height reduces proportionally; row height unchanged | Screen recording + code diff |
| R3: Custom menu bar icon displays user-selected SF Symbol or image | Set menu bar icon style to custom or SF Symbol; relaunch or change | Menu bar icon updates from default | Screenshot or log + code diff |
| R4: Multi-selection supports cmd/shift click with delete/enter/control-w actions | Select multiple queue items; press Delete, Enter, Ctrl+W | Delete removes selected; Enter pastes selected in selection order with line breaks; Ctrl+W pastes selected sequentially without extra trailing newline | Screen recording + code diff |
| R5: Favorites/Recents tabs and segmented picker layout rules | Toggle tab visibility options; observe picker layout | Top picker shows Queue+Favorites; bottom shows History+Recents when 4 tabs; if only 3 tabs show single top picker | Screenshot + code diff |
| R6: Drag item from queue to other app textfield pastes content | Drag queue item onto external text field | Dropped text inserts content | Screen recording + code diff |
| R7: Keyboard shortcut editor accepts any key combo (no modifier required) | Record shortcut like Shift+Tab or Tab; save; relaunch; test | Shortcut registers and triggers action even without command/option/control | Screen recording + code diff |
| R8: Tab persistence settings for show/hide window | Set preference to restore Queue or last tab; hide/show window | Tab selection matches setting | Screen recording + code diff |

> Notes: Each requirement must have at least one scenario-level acceptance check and an evidence artifact. Tie failures back to the specific requirement.

## 3) Plan & Decomposition (with rationale)
- **Critical path narrative:** Start with model/preferences and routing changes that unlock UI behavior; then adjust queue view selection + segmented pickers; then update menu bar icon/shortcut registration; finally implement window resizing and drag-to-paste. This order reduces UI uncertainty first and isolates AppDelegate changes later.
- **Step 1:** Create bd issues and map requirements to code areas; confirm current UI/behavior in code. Risks: mis-scoping. Evidence: bd issue IDs (CQ-5u4, CQ-us6, CQ-eyk, CQ-alm, CQ-q42).
- **Step 2:** Add preferences + data model fields for favorites, recents visibility, newline behavior, tab persistence, auto-resize. Risks: state explosion. Evidence: code diff + updated PreferencesView.
- **Step 3:** Update QueueView UI: segmented pickers, favorites/history/recents tabs, multi-selection, keyboard handling, context menu, drag-to-paste. Risks: selection UX regression. Evidence: code diff + local UI check notes.
- **Step 4:** Update AppDelegate/KeyboardShortcutManager: custom icon use, shortcut parsing/registration, window auto-resize logic, tab persistence on show/hide. Risks: hotkey registration failure. Evidence: code diff + console logs.
- **Step 5:** Run targeted verification checks, update handoff.md with evidence. Evidence: logs/screenshots.
- **Decision log reference(s):** TBD as choices made.

## 4) To-Do & Progress Ledger
- [x] Create bd issues for each feature cluster — **done**; evidence: CQ-5u4, CQ-us6, CQ-eyk, CQ-alm, CQ-q42
- [x] Confirm and fix selection ordering + paste newline behavior — **done**; evidence: code diff in Sources/Views/QueueView.swift
- [x] Verify segmented picker layout and tab navigation shortcut — **done**; evidence: code diff in Sources/Views/QueueView.swift (KeyEventMonitor moved to root)
- [x] Fix menu bar icon customization display — **done**; evidence: code diff in Sources/ClipQueue/AppDelegate.swift
- [x] Allow hotkeys without command/option/control modifiers — **done**; evidence: code diff in Sources/Services/KeyboardShortcutManager.swift
- [ ] Validate drag-to-paste to external apps — planned evidence: code diff + UI check

## 5) Findings, Decisions, Assumptions
- **Finding:** QueueView uses ScrollView/LazyVStack with single selection; no multi-select support built in.
- **Finding:** KeyboardShortcutManager registers fixed defaults; preferences UI toggles recording but does not capture keys.
- **Assumption:** Favorites should be distinct from pinned history; needs explicit model field. Falsification: inspect existing models and history (completed).
- **Finding:** Apple docs confirm SwiftUI `List(selection:)` supports multi-selection with `Set` (https://developer.apple.com/documentation/swiftui/list/init(selection:content:)-4sffx/).
- **Finding:** Apple docs describe `NSStatusItem` customization via `button` (https://developer.apple.com/documentation/appkit/nsstatusitem).
- **Finding:** SwiftDB sample `swiftui-building-a-great-mac-app-with-swiftui/.../ContentView.swift` shows `List(selection:)` for macOS sidebar selection.
- **Finding:** SwiftDB sample `swiftui-restoring-your-app-s-state-with-swiftui/StateRestoration/ContentView.swift` demonstrates `onDrag` with `NSItemProvider`.
- **Decision:** Preserve user selection order by capturing click modifiers and adjusting selectionOrder on selection changes; shift selection falls back to queue order for deterministic paste ordering.
- **Decision:** Register shortcuts without command/option/control via a session event tap fallback; avoid swallowing keystrokes when monitoring is disabled.

## 6) Issues, Mistakes, Recoveries
- No mistakes recorded yet.

## 7) Scenario-Focused Resolution Tests (problem-centric)
- **Repro steps:** Not run yet. **Change applied:** N/A. **Post-change behavior:** N/A. **Verdict:** not resolved.

## 8) Verification Summary (evidence over intuition)
- **Fast checks run:** `xcodebuild -project ClipQueue.xcodeproj -scheme ClipQueue -configuration Debug build` — **passed** (BUILD SUCCEEDED).
- **Acceptance runs:** None yet.
- **Performance/latency snapshots (if relevant):** N/A.

## 9) Remaining Work & Next Steps
- **Open items & blockers:** Implement fixes for selection ordering, hotkey registration without modifier, and menu bar icon updates; confirm tab picker behavior.
- **Risks:** Global hotkey fallback may conflict with system shortcuts; drag-to-paste behavior may require UTType adjustments.
- **Next working interval plan:** Update queue selection/paste logic, adjust hotkey registration fallback, then verify menu bar icon refresh.

## 10) Updates to This File (append-only)
- 2025-02-14T19:20:00Z: created initial handoff with request summary, requirements table, and plan.
- 2025-02-14T19:32:00Z: added bd issue IDs, updated findings with Apple docs + sample references.
- 2026-01-05T09:21:52Z: updated requirements wording, refreshed to-do list, and added Apple docs + SwiftDB references.
- 2026-01-05T09:50:16Z: recorded selection order/paste logic updates, hotkey fallback decision, and menu bar icon changes.
- 2026-01-05T09:59:06Z: recorded successful debug build in verification summary.
