# CLAUDE.md — Time Viewer

## What this project is

Time Viewer is a macOS menubar app (Swift + SwiftUI) for running multiple countdown timers simultaneously. It lives in the menubar and optionally shows a floating widget above all windows.

See `SPECS.md` for the full product specs and iteration breakdown.

## Current iteration

**Iteration 1** — Menubar icon + Popover, multi-timer support, no persistence.

## Tech stack

- Swift, SwiftUI
- macOS 13+ (Ventura) — uses `MenuBarExtra`
- No external dependencies

## Project structure

```
TimeViewer/
├── TimeViewerApp.swift
├── Models/
│   └── TimerModel.swift
├── Views/
│   ├── PopoverView.swift
│   ├── TimerRowView.swift
│   ├── AddTimerView.swift
│   └── FloatingWidget/
│       ├── FloatingPanel.swift
│       └── FloatingWidgetView.swift
└── Helpers/
    └── DurationParser.swift
```

## How to build and run

```bash
xcodebuild -scheme TimeViewer -configuration Debug build
open build/Debug/TimeViewer.app
```

Or open `TimeViewer.xcodeproj` in Xcode and hit Run.

## Code conventions

- `ObservableObject` + `@Published` for shared state (no TCA, no Redux)
- `TimerStore` is the single source of truth — injected via `.environmentObject`
- One file per type, filename matches type name
- No force unwraps (`!`) — use `guard` or `if let`
- Prefer `struct` over `class` except where reference semantics are required (NSPanel, ObservableObject)

## What NOT to do

- Do not use Combine beyond `Timer.publish` — keep it simple
- Do not add external dependencies without asking
- Do not persist state yet (Iteration 1 scope)
- Do not implement the floating widget yet (Iteration 2)
- Do not implement target-time input yet (Iteration 3)
