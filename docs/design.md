# Logger Utility - Design Document

## Overview

Logger Utility is a native macOS SwiftUI application that provides a GUI for viewing macOS unified system logs. It wraps the `log` CLI tool, providing real-time streaming, historical log queries with arbitrary time ranges, service/subsystem filtering with presets, and full predicate-building capabilities.

**Target:** macOS 13 Ventura+
**Distribution:** Outside App Store (Developer ID signing or MDM, no sandbox)

---

## Architecture

### Pattern
MVVM with Combine for reactive data flow.

### Tech Stack
- **UI Framework:** SwiftUI with NSTableView (via NSViewRepresentable) for the log table
- **Log Access:** Shell out to `log stream` / `log show` / `log collect` via `Process`, parsing NDJSON output
- **Project Type:** Swift Package (Package.swift)
- **Dependencies:** None (no third-party dependencies)

### Why NSTableView?
SwiftUI `List`/`Table` cannot handle 100K+ rows performantly. `NSTableView` provides fixed row heights, cell reuse, and efficient scrolling required for high-volume log data.

---

## Project Structure

```
Logger Utility/
├── Package.swift
├── Scripts/
│   └── generate_icon.swift             — Generates AppIcon.icns programmatically via CoreGraphics
├── Resources/
│   └── AppIcon.icns                    — App icon (generated, dark terminal window with log-level dots)
├── Sources/LoggerUtility/
│   ├── App/
│   │   ├── LoggerUtilityApp.swift          — @main entry point, window/scene setup
│   │   └── AppState.swift                  — Global state, tab selection
│   ├── Models/
│   │   ├── LogEntry.swift                  — Parsed log entry (from NDJSON)
│   │   ├── LogLevel.swift                  — debug/info/default/error/fault enum
│   │   ├── EventType.swift                 — logEvent, signpostEvent, etc.
│   │   ├── LogFilter.swift                 — Filter config (levels, process, subsystem, predicates, time range)
│   │   ├── PredicateClause.swift           — Single clause: field + operator + value
│   │   ├── PredicateField.swift            — Enum of all predicate fields
│   │   ├── PredicateOperator.swift         — ==, !=, CONTAINS, BEGINSWITH, etc.
│   │   ├── ExportFormat.swift              — logarchive, csv, plainText
│   │   ├── AIProvider.swift                — ChatGPT/Claude/Gemini/Perplexity/Copilot enum
│   │   └── SubsystemPreset.swift           — Known macOS subsystems for dropdown
│   ├── Services/
│   │   ├── LogStreamService.swift          — Wraps `log stream`, publishes via Combine
│   │   ├── LogShowService.swift            — Wraps `log show`, async/await results
│   │   ├── LogCollectService.swift         — Wraps `log collect` for .logarchive export
│   │   ├── LogCommandBuilder.swift         — Builds argument arrays from LogFilter
│   │   ├── LogParser.swift                 — Parses NDJSON lines into LogEntry
│   │   ├── ExportService.swift             — CSV and plain text export
│   │   └── AIPromptService.swift           — Builds AI prompts, clipboard, browser launch
│   ├── ViewModels/
│   │   ├── StreamViewModel.swift           — Live stream state, buffer, pause/resume
│   │   ├── HistoricalViewModel.swift       — Query management, results, cancellation
│   │   ├── FilterViewModel.swift           — Filter/predicate builder state
│   │   └── ExportViewModel.swift           — Export operations and progress
│   ├── Views/
│   │   ├── MainView.swift                  — TabView (Stream / Historical)
│   │   ├── Stream/
│   │   │   ├── StreamView.swift            — Live stream tab
│   │   │   ├── StreamToolbar.swift         — Start/stop, pause, clear, level picker
│   │   │   └── StreamStatusBar.swift       — Event count, rate, connection status
│   │   ├── Historical/
│   │   │   ├── HistoricalView.swift        — Historical query tab
│   │   │   ├── HistoricalToolbar.swift     — Date pickers, "last N" shortcuts
│   │   │   └── QueryStatusBar.swift        — Result count, duration, progress
│   │   ├── Shared/
│   │   │   ├── LogTableView.swift          — NSViewRepresentable wrapping NSTableView
│   │   │   ├── LogDetailView.swift         — Inspector panel for selected entry
│   │   │   ├── FilterPanelView.swift       — Full filter controls sidebar/sheet
│   │   │   ├── PredicateBuilderView.swift  — Visual predicate clause builder
│   │   │   ├── SubsystemPickerView.swift   — Dropdown of presets + custom text
│   │   │   ├── LogLevelPickerView.swift    — Multi-select for log levels
│   │   │   └── ExportSheetView.swift       — Export format/destination picker
│   │   └── Components/
│   │       ├── SearchField.swift           — Quick search over visible logs
│   │       └── ColorDot.swift              — Log level color indicator
│   ├── Utilities/
│   │   ├── RingBuffer.swift                — Fixed-capacity buffer for stream retention
│   │   ├── DateFormatting.swift            — Shared date formatters
│   │   └── Constants.swift                 — Buffer sizes, column widths, colors
│   └── Extensions/
│       ├── Color+LogLevel.swift            — LogLevel → SwiftUI Color
│       ├── Process+Async.swift             — Async/await wrappers for Process
│       └── String+Predicate.swift          — Escaping/quoting for predicate strings
├── Tests/LoggerUtilityTests/
│   ├── LogParserTests.swift
│   ├── LogCommandBuilderTests.swift
│   ├── PredicateClauseTests.swift
│   └── RingBufferTests.swift
└── docs/
    └── design.md
```

---

## Key Data Models

### LogEntry
Parsed from `log --style ndjson` output. Fields:
- `id` (UUID) — unique identifier
- `timestamp` (Date)
- `processID` (Int), `processName` (String)
- `threadID` (UInt64)
- `logLevel` (LogLevel) — default/info/debug/error/fault
- `subsystem`, `category` (String)
- `eventMessage` (String)
- `eventType` (EventType)
- `senderName` (String)
- `activityIdentifier` (UInt64)
- `formatString`, `source` (String)

### LogFilter
Captures all filter state:
- `selectedLevels` — Set of LogLevel
- `process`, `subsystem`, `category`, `sender`, `messageSearch` — String fields
- `predicateClauses` — Array of PredicateClause
- `joinOperator` — AND/OR
- `rawPredicate` — Power user override
- `includeInfo`, `includeDebug`, `includeSource` — Bool flags
- `startDate`, `endDate` — For historical queries

### PredicateClause
A single filter rule: `field` (process, subsystem, category, composedMessage, etc.) + `operator` (==, !=, CONTAINS, BEGINSWITH, ENDSWITH, LIKE, MATCHES) + `value`. Multiple clauses combined with AND/OR.

---

## View Layout

```
MainView (TabView)
├── Stream Tab
│   ├── Toolbar: Start/Stop, Pause, Clear, Search, Filter toggle, Export
│   ├── HSplitView
│   │   ├── FilterPanel (togglable sidebar)
│   │   ├── LogTableView (NSTableView: Timestamp, Level, Process, PID,
│   │   │                 Subsystem, Category, Sender, Message)
│   │   └── LogDetailView (inspector, togglable)
│   └── StatusBar: entry count, rate (entries/sec), status
│
├── Historical Tab
│   ├── Toolbar: Quick durations (5m/15m/1h/24h), DatePickers,
│   │            Query/Cancel, Search, Filter toggle, Export
│   ├── HSplitView
│   │   ├── FilterPanel (togglable sidebar)
│   │   ├── LogTableView (same component)
│   │   └── LogDetailView
│   └── StatusBar: result count, query duration, progress
│
└── FilterPanelView (shared sidebar)
    ├── Process, Subsystem (with presets), Category, Sender fields
    ├── Message search
    ├── Log level multi-select checkboxes
    ├── PredicateBuilderView (add/remove clause rows)
    ├── AND/OR toggle
    ├── Raw predicate text field
    ├── --info, --debug, --source checkboxes
    └── Apply / Reset buttons
```

---

## Ask AI Integration

Zero-cost AI-assisted log analysis via clipboard + browser workflow:

1. User right-clicks a log entry (or uses Cmd+Shift+A, or the detail panel buttons)
2. `AIPromptService.buildPrompt()` constructs a contextual prompt including:
   - macOS version (auto-detected via `ProcessInfo`)
   - All relevant log fields (timestamp, level, process, subsystem, category, message, format string)
   - A question asking for explanation and troubleshooting steps
3. Prompt is copied to clipboard
4. Browser opens to the user's preferred AI provider

### Supported AI Providers
- ChatGPT (chatgpt.com) — default
- Claude (claude.ai/new)
- Gemini (gemini.google.com)
- Perplexity (perplexity.ai)
- Microsoft Copilot (copilot.microsoft.com)

Provider preference is persisted via `@AppStorage` / `UserDefaults`.

### Why clipboard + browser instead of API

| | Clipboard + Browser | API Integration |
|---|---|---|
| Cost | Free | Per-query charges |
| Auth | None needed | API keys, billing |
| Maintenance | Zero | SDK updates, rate limits |
| User trust | They see what's sent | Opaque data transmission |
| Model flexibility | User picks their favorite | Locked to one provider |

---

## Dynamic Subsystem Discovery

After a historical query or during live streaming, the subsystem picker auto-populates with all unique subsystems found in the log data. Subsystems are sorted by frequency with occurrence counts displayed. Apple presets already found in results are deduplicated into a separate "Common" section.

---

## Streaming Architecture

### Real-time (`log stream`)
1. `LogStreamService` launches `Process("/usr/bin/log", ["stream", "--style", "ndjson", ...])`
2. Reads stdout pipe via `FileHandle.readabilityHandler` on background queue
3. Accumulates partial lines, parses complete NDJSON lines via `LogParser`
4. Publishes entries via `PassthroughSubject`, batched every 100ms
5. `StreamViewModel` stores in `RingBuffer` (capped at 100K entries)
6. Pause = stop appending to display (buffer continues filling)
7. Auto-scroll when pinned to bottom

### Historical (`log show`)
1. `LogShowService` launches `Process("/usr/bin/log", ["show", "--style", "ndjson", ...])`
2. Stream-parses NDJSON for large result sets
3. Cancellable via `Task.cancel()` → `process.terminate()`
4. Progress indicator during long queries

---

## Performance Strategy

| Concern | Solution |
|---------|----------|
| High-volume stream | Batch UI updates every 100ms via Combine; RingBuffer caps at 100K entries |
| Table rendering | NSTableView with fixed row heights (20pt) and reusable cells |
| NDJSON parsing | `JSONSerialization` on background queue (~3x faster than JSONDecoder) |
| Large exports | Stream writes via FileHandle |
| Auto-scroll | Only scroll when user is pinned to bottom |
| Text search | `localizedCaseInsensitiveContains`, debounced |

---

## Subsystem Presets

The subsystem dropdown includes these common macOS subsystems:
- com.apple.bluetooth, com.apple.wifi, com.apple.networking
- com.apple.kernel, com.apple.security, com.apple.coredata
- com.apple.SystemConfiguration, com.apple.mdm
- com.apple.loginwindow, com.apple.launchd, com.apple.powerd
- com.apple.diskmanagement, com.apple.spotlight
- com.apple.TimeMachine, com.apple.fileprovider
- com.apple.apfs, com.apple.windowserver, com.apple.screensharing

---

## Export Formats

| Format | Method |
|--------|--------|
| .logarchive | `log collect --output <path> --last <duration>` (may need root) |
| CSV | Stream-write entries via FileHandle |
| Plain Text | Formatted like `log show --style default` output |

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+K | Clear logs |
| Cmd+F | Focus search |
| Cmd+E | Export |
| Cmd+Shift+A | Ask AI about selected log |

---

## Test Coverage

- **LogParserTests** — NDJSON parsing, invalid input, level mapping, timestamps
- **LogCommandBuilderTests** — Stream/show/collect argument building, predicates
- **PredicateClauseTests** — Clause string generation, filter predicates, escaping
- **RingBufferTests** — Capacity, wrapping, subscript, clear, bulk append

---

## Technical Notes

- **No sandbox** — `log stream`/`log show` require full system log access
- **Process lifecycle** — Child processes terminated on app quit
- **Privilege escalation** — `log collect` may need root
- **Distribution** — Developer ID signing or MDM deployment
